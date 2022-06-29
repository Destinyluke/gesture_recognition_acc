`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/23 13:35:43
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input       sys_clk,    //系统时钟
    input       sys_rst_n,  //系统复位，低电平有效

    //uart启动旋钮
    input       uart_knob,

    //按键
    input       btn1,
    input       btn2,
    input       btn3,

    //旋钮开关
    input[1:0]  mode,

    //摄像头接口
    input       cam_pclk,   //cmos数据像素时钟
    input       cam_vsync,  //cmos场同步信号
    input       cam_href,   //cmos行同步信号
    input[7:0]  cam_data,   //cmos数据
    output      cam_rst_n,  //cmos复位信号，低电平有效
    output      cam_pwdn,   //cmos低功耗模式选择
    output      cam_xclk,   //cmos系统时钟
    output      cam_scl,    //cmos SCCB_SCL线
    inout       cam_sda,    //cmos SCCB_SDA线

    //VGA接口
    output[3:0] VGA_R,
    output[3:0] VGA_G,
    output[3:0] VGA_B,
    output      VGA_HSYNC,
    output      VGA_VSYNC,

    //led
    output[7:0] led_out,

    //用于指示按键的led
    output[2:0] choice_led,

    //uart tx
    output tx
    );

    //parameter define
    parameter SLAVE_ADDR = 7'h21;   //OV7725的器件地址为7'h21
    parameter BIT_CTRL = 1'b0;  //OV7725的字节地址为8位 0:8位 1:16位
    parameter CLK_FREQ = 26'd25_000_000;  //i2c_dri模块的驱动时钟频率 25MHZ
    parameter I2C_FREQ = 18'd250_000; //i2C的SCL时钟频率，不超过400KHZ
    parameter CMOS_H_PIXEL = 24'd640; //CMOS水平方向像素个数
    parameter CMOS_V_PIXEL = 24'd480; //CMOS垂直方向像素个数

    //wire define
    wire clk_25m;   //25MHZ时钟，提供给VGA驱动时钟
    wire clk_50m;   //50MHZ时钟，提供给timer
    wire locked;
    wire rst_n;

    wire i2c_exec;  //i2c触发执行信号
    wire[15:0] i2c_data;    //i2c要配置的地址与数据（高8位地址，低8位数据）
    wire cam_init_done; //摄像头初始化完成
    wire i2c_done;  //i2c寄存器配置完成信号
    wire i2c_dri_clk;   //i2c操作时钟

    wire wr_en; //BRAM写使能
    wire[15:0] rgb565_data; //rgb565数据
    wire[11:0] rgb444_data; //rgb444数据
    wire       cmos_pos_vsync;  //摄像头场同步信号上升沿

    wire[11:0] ram_data_o;  //BRAM输出数据
    wire[18:0] ram_addr_i;  //BRAM写地址
    wire[18:0] ram_addr_o;  //BRAM读地址

    wire[11:0] vga_data;    //输出给VGA的12位信号
    wire[9:0] pixel_x;      //x坐标
    wire[9:0] pixel_y;      //y坐标
    wire vga_valid;         //vga有效信号
    wire vga_valid_pre3;
    wire vsync_r_pos;       //VGA场同步信号上升沿
    wire hsync_r_pos;       //VGA行同步信号上升沿

    wire[11:0] median_data; //中值滤波后的输出
    wire[11:0] erzhihua_data;   //二值化后的输出
    wire[11:0] erode_data;  //腐蚀后的输出
    wire[11:0] dilate_data; //第一次膨胀后的输出
    wire[11:0] dilate_data1;    //第二次膨胀后的输出
    wire[11:0] rectangle_data;  //加矩形框后的输出
    wire[11:0] final_data;  //最后的vga输出

    wire[9:0] left; //矩形框左边界
    wire[9:0] right; //矩形框右边界
    wire[9:0] top; //矩形框上边界
    wire[9:0] bottom; //矩形框下边界

    wire[3:0] finger_number;    //单次识别得到的手指数量
    wire begin_count;   //计数使能，使能finger_count进行一次计数
    wire[3:0] led_in;   //统计得到的手指数量，也是led模块的输入
    wire uart_en;       //uart的使能信号

    wire Int1;  //按键1
    wire Int2;  //按键2
    wire Int3;  //按键3

    (*mark_debug="true"*)wire[31:0] ms_cnt_final;    //计时器结果，显示处理一帧的时间


    assign rst_n = sys_rst_n && locked;
    assign cam_rst_n = 1'b1;
    assign cam_pwdn = 1'b0;
    assign cam_xclk = clk_25m;  //系统时钟为25MHz

    assign rgb444_data = {rgb565_data[15:12],rgb565_data[10:7],rgb565_data[4:1]};

    assign VGA_R = vga_data[11:8];
    assign VGA_G = vga_data[7:4];
    assign VGA_B = vga_data[3:0];

    //锁相环
    clk_wiz_0 u_clk(
        .clk_in1        (sys_clk),
        .resetn         (sys_rst_n),

        .clk_out1       (clk_25m),
        .clk_out2       (clk_50m),
        .locked         (locked)
    );

    //i2c配置模块
    i2c_ov7725_rgb565_cfg u_i2c_cfg(
        .clk            (i2c_dri_clk),
        .rst_n          (rst_n),

        .i2c_done       (i2c_done),
        .i2c_exec       (i2c_exec),
        .i2c_data       (i2c_data),
        .init_done      (cam_init_done)
    );

    //i2c驱动模块
    i2c_dri
        #(
            .SLAVE_ADDR (SLAVE_ADDR),
            .CLK_FREQ   (CLK_FREQ),
            .I2C_FREQ   (I2C_FREQ)
        )
        u_i2c_dri(
            .clk        (clk_25m),
            .rst_n      (rst_n),
            
            .i2c_exec   (i2c_exec),
            .bit_ctrl   (BIT_CTRL),
            .i2c_rh_wl  (1'b0),     //固定为0，只用到了IIC驱动的写操作
            .i2c_addr   (i2c_data[15:8]),
            .i2c_data_w (i2c_data[7:0]),
            .i2c_data_r (),
            .i2c_done   (i2c_done),
            .scl        (cam_scl),
            .sda        (cam_sda),

            .dri_clk    (i2c_dri_clk)   //i2c操作时钟
        );

    //CMOS图像数据采集模块
    cmos_capture_data u_cmos_capture_data(
        .rst_n          (rst_n && cam_init_done),   //系统初始化完成之后再开始采集数据

        .cam_pclk       (cam_pclk),
        .cam_vsync      (cam_vsync),
        .cam_href       (cam_href),
        .cam_data       (cam_data),

        .cmos_frame_vsync(),
        .cmos_frame_href(),
        .cmos_frame_valid(wr_en),   //数据有效使能信号
        .cmos_frame_data (rgb565_data),  //有效数据
        .cmos_frame_addr (ram_addr_i),   //BRAM写地址
        .cmos_pos_vsync  (cmos_pos_vsync)   //场同步信号上升沿
    );

    blk_mem_gen_0 u_blk_mem_gen_0(
        .addra          (ram_addr_i),
        .clka           (cam_pclk),
        .dina           (rgb444_data),
        .wea            (wr_en),

        .addrb          (ram_addr_o),
        .clkb           (clk_25m),
        .doutb          (ram_data_o)
    );

    vga_driver u_vga_driver(
        .vga_clk        (clk_25m),
        .rst_n          (rst_n),
        .rgb_data       (ram_data_o),
        
        .vga_data       (vga_data),
        .vga_hsync      (VGA_HSYNC),
        .vga_vsync      (VGA_VSYNC),
        .pixel_x        (pixel_x),
        .pixel_y        (pixel_y),
        .vga_valid      (vga_valid),
        .vga_valid_pre3 (vga_valid_pre3),
        .vsync_r_pos    (vsync_r_pos),
        .hsync_r_pos    (hsync_r_pos)
    );

    frame_ctrl u_frame_ctrl(
        .vga_clk        (clk_25m),
        .rst_n          (rst_n),
        .vga_valid_pre3 (vga_valid_pre3),
        .pixel_x        (pixel_x),
        .pixel_y        (pixel_y),

        .read_addr      (ram_addr_o)
    );

    cov_median u_cov_median(
        .vga_clk        (clk_25m),
        .rst_n          (rst_n),
        .pixel_x        (pixel_x),
        .pixel_y        (pixel_y),
        .rgb_data       ({ram_data_o[11:8],4'b1111,ram_data_o[7:4],4'b1111,ram_data_o[3:0],4'b1111}),

        .median_out     (median_data)
    );

    pb_debounce u_pb_debounce1(
        .clk            (clk_25m),
        .resetn         (rst_n),
        .pb_in          (btn1),
        .pb_out         (),
        .pb_tick        (Int1)
    );

    pb_debounce u_pb_debounce2(
        .clk            (clk_25m),
        .resetn         (rst_n),
        .pb_in          (btn2),
        .pb_out         (),
        .pb_tick        (Int2)
    );

    pb_debounce u_pb_debounce3(
        .clk            (clk_25m),
        .resetn         (rst_n),
        .pb_in          (btn3),
        .pb_out         (),
        .pb_tick        (Int3)
    );

    rgb2ycbcr u_rgb2ycbcr(
        .clk            (clk_25m),
        .rst_n          (rst_n),         
        .Int1           (Int1),
        .Int2           (Int2),
        .Int3           (Int3),
        .imgPixel_in    (median_data),
        .imgPixel_out   (erzhihua_data),
        .choice_led     (choice_led)
    );

    // rgb2hsv u_rgb2hsv(
    //     .vga_clk(clk_25m),
    //     .rst_n(rst_n),
    //     .imgPixel_in(median_data),
        
    //     .imgPixel_out(erzhihua_data)
    // );

    cov_erode u_cov_erode(
        .vga_clk        (clk_25m),
        .rst_n          (rst_n),
        .pixel_x        (pixel_x),
        .pixel_y        (pixel_y),
        .erzhihua_data  ({erzhihua_data,erzhihua_data}),

        .erode_out      (erode_data)
    );

    cov_dilate u1_cov_dilate(
        .vga_clk        (clk_25m),
        .rst_n          (rst_n),
        .pixel_x        (pixel_x),
        .pixel_y        (pixel_y),
        .erzhihua_data  ({erode_data,erode_data}),

        .dilate_out     (dilate_data)
    );

    cov_dilate u2_cov_dilate(
        .vga_clk        (clk_25m),
        .rst_n          (rst_n),
        .pixel_x        (pixel_x),
        .pixel_y        (pixel_y),
        .erzhihua_data  ({dilate_data,dilate_data}),

        .dilate_out     (dilate_data1)
    );

    centroid u_centroid(
        .vga_clk        (clk_25m),
        .rst_n          (rst_n),
        .img_data       (dilate_data1),
        .pixel_x        (pixel_x),
        .pixel_y        (pixel_y),
        
        .left           (left),
        .right          (right),
        .top            (top),
        .bottom         (bottom)
    );

    addRectangle u_addRectangle(
        .left           (left),
        .right          (right),
        .top            (top),
        .bottom         (bottom),
        .background     (dilate_data1),
        .pixel_x        (pixel_x),
        .pixel_y        (pixel_y),

        .data_out       (rectangle_data)
    );

    find_fingers u_find_fingers(  
        .vga_clk        (clk_25m),
        .rst_n          (rst_n),
        .mode           (mode),
        .img_data       (rectangle_data),
        .left           (left),
        .right          (right),
        .top            (top),
        .bottom         (bottom),
        .pixel_x        (pixel_x),
        .pixel_y        (pixel_y),
        .hsync_r_pos    (hsync_r_pos),
        
        .final_data     (final_data),
        .finger_number  (finger_number),
        .begin_count    (begin_count)
    );

    finger_count u_finger_count(
        .clk            (clk_25m),
        .rst_n          (rst_n),
        .finger_number  (finger_number),
        .begin_count    (begin_count),

        .final_number   (led_in),
        .uart_en        (uart_en)
    );

    led u_led(
        .led_in         (led_in),
        .led            (led_out)
    );

    correct_count u_correct_count(
        .clk_25m        (clk_25m),
        .rst_n          (rst_n),
        .uart_knob      (uart_knob),
        .final_number   (led_in),
        .uart_en        (uart_en),

        .tx             (tx)
    );

    timer u_timer(
        .clk_50m        (clk_50m),
        .rst_n          (rst_n),
        .flag           (uart_en),

        .ms_cnt_final   (ms_cnt_final)
    );
endmodule
