`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/27 13:22:25
// Design Name: 
// Module Name: cmos_capture_data
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


module cmos_capture_data(
    input       rst_n,      //复位信号
    //摄像头接口
    input       cam_pclk,   //cmos数据像素时钟   
    input       cam_vsync,  //cmos场同步信号
    input       cam_href,   //cmos行同步信号
    input[7:0]  cam_data,   //cmos数据
    //用户接口
    output      cmos_frame_vsync,   //帧有效信号
    output      cmos_frame_href,    //行有效信号
    output      cmos_frame_valid,   //数据有效使能信号
    output[15:0] cmos_frame_data,   //有效数据
    output[18:0] cmos_frame_addr,    //BRAM写地址
    output      cmos_pos_vsync       //场同步信号的上升沿
    );

    //寄存器全部配置完成后，先等待10帧数据
    //带寄存器配置生效后再开始采集图像
    parameter WAIT_FRAME = 4'd10;   //寄存器数据稳定等待的帧个数

    //reg define
    reg     cam_vsync_d0;
    reg     cam_vsync_d1;
    reg     cam_href_d0;
    reg     cam_href_d1;
    reg[3:0] cmos_ps_cnt;   //等待帧数稳定计数器
    reg     frame_val_flag; //帧有效的标志

    reg[7:0] cam_data_d0;
    reg[15:0] cmos_data_t;  //用于8位转16位的临时寄存器
    reg     byte_flag;
    reg     byte_flag_d0;
    reg[18:0] addr;

    //wire define
    // wire    pos_vsync;

    //采输入场同步信号的上升沿
    assign cmos_pos_vsync = (~cam_vsync_d1) & cam_vsync_d0;

    //输出帧有效信号
    assign cmos_frame_vsync = frame_val_flag? cam_vsync_d1: 1'b0;
    //输出行有效信号
    assign cmos_frame_href = frame_val_flag? cam_href_d1: 1'b0;
    //输出数据使能有效信号
    assign cmos_frame_valid = frame_val_flag? byte_flag_d0: 1'b0;
    //输出数据
    assign cmos_frame_data = frame_val_flag? cmos_data_t: 1'b0;
    //BRAM写地址
    assign cmos_frame_addr = frame_val_flag? addr: 19'd0;

    //采输入场同步信号的上升沿
    always @(posedge cam_pclk or negedge rst_n) begin
        if(!rst_n) begin
            cam_vsync_d0 <= 1'b0;
            cam_vsync_d1 <= 1'b0;
            cam_href_d0 <= 1'b0;
            cam_href_d1 <= 1'b0;
        end
        else begin
            cam_vsync_d0 <= cam_vsync;
            cam_vsync_d1 <= cam_vsync_d0;
            cam_href_d0 <= cam_href;
            cam_href_d1 <= cam_href_d0;
        end
    end

    //对帧数进行计数
    always @(posedge cam_pclk or negedge rst_n) begin
        if(!rst_n) begin
            cmos_ps_cnt <= 4'd0;
        end
        else if(cmos_pos_vsync && (cmos_ps_cnt < WAIT_FRAME)) begin
            cmos_ps_cnt <= cmos_ps_cnt + 4'd1;
        end
    end

    //帧有效标志
    always @(posedge cam_pclk or negedge rst_n) begin
        if(!rst_n) begin
            frame_val_flag <= 1'b0;
        end
        else if((cmos_ps_cnt == WAIT_FRAME) && cmos_pos_vsync) begin
            frame_val_flag <= 1'b1;
        end
    end

    //8位数据转16位RGB565数据
    always @(posedge cam_pclk or negedge rst_n) begin
        if(!rst_n) begin
            cmos_data_t <= 16'd0;
            cam_data_d0 <= 8'd0;
            byte_flag <= 1'b0;
        end
        else if(cam_href) begin
            byte_flag <= ~byte_flag;
            cam_data_d0 <= cam_data;
            if(byte_flag) begin
                cmos_data_t <= {cam_data_d0,cam_data};
            end
        end
        else begin
            byte_flag <= 1'b0;
            cam_data_d0 <= 8'b0;
        end
    end

    //产生输出数据有效信号(cmos_frame_valid)
    always @(posedge cam_pclk or negedge rst_n) begin
        if(!rst_n) begin
            byte_flag_d0 <= 1'b0;
        end
        else begin
            byte_flag_d0 <= byte_flag;
        end
    end

    //产生BRAM的写地址
    always @(posedge cam_pclk or negedge rst_n) begin
        if(!rst_n) begin
            addr <= 19'd0;
        end
        else if(cmos_pos_vsync) begin
            addr <= 19'd0;
        end
        else if((addr <= 307200) && cmos_frame_valid) begin
            addr <= addr + 1'b1;
        end
        else begin
            addr <= addr;
        end
    end


endmodule
