`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/14 16:19:27
// Design Name: 
// Module Name: find_fingers
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

//手势识别模块
module find_fingers(
    input wire      vga_clk,
    input wire      rst_n,
    input wire[1:0] mode,
    input wire[11:0] img_data,
    input wire[9:0] left,
    input wire[9:0] right,
    input wire[9:0] top,
    input wire[9:0] bottom,
    input wire[9:0] pixel_x,
    input wire[9:0] pixel_y,
    input wire      hsync_r_pos,

    output reg[11:0] final_data,
    output reg[3:0] finger_number,
    output reg begin_count
    );

    parameter Y_TOTAL = 10'd480;
    wire clk_div;
    reg [9:0] x_buffer [479:0];   
    reg [9:0] y_buffer [479:0];

    //读入初始化文件,根据自己地址决定
    initial begin
        $readmemh("C:/Users/hzc/Desktop/luke/graduate_learning/Accelerator/accelerator9.0/init.hex",x_buffer);
    end

    clk_div u0_clk_div(     
        .hsync_r_pos(hsync_r_pos),
        .rst_n(rst_n),
        .clk_div(clk_div)
    );

    reg[11:0] img_data1;
    reg[11:0] img_data2;

//--------------防止重复计数--------------
//在扫描完所有点之后结束finger_num计数
 reg [1:0] finished_scan;
 always @(posedge vga_clk or negedge rst_n) begin
     if (!rst_n) begin
        finished_scan <= 2'b0;
     end
    else if ((pixel_x==10'd639) && (pixel_y==10'd479)) begin
         finished_scan <= finished_scan + 1'b1;
     end
     else begin
       finished_scan <= finished_scan;
     end
 end

 //-------------扫描有效区----------------
//分配第一帧确定手的上下左右
reg scan_en;                       
always @(posedge vga_clk or negedge rst_n) begin
    if (!rst_n) begin
        scan_en <= 1'b0;
    end
    else if ((pixel_x>left) && (pixel_x<right) && (pixel_y>top) && (pixel_y<bottom) && (finished_scan == 2'b01 || finished_scan == 2'b10 || finished_scan == 2'b11)) begin
        scan_en <= 1'b1;
    end
    else if ((pixel_x<left) || (pixel_x>right) || (pixel_y<top) || (pixel_y>bottom) && (finished_scan == 2'b01 || finished_scan == 2'b10 || finished_scan == 2'b11)) begin
        scan_en <= 1'b0;
    end
    else begin
        scan_en <= scan_en;
    end
end

//--------------存储边缘点的x值x_buffer----------------  
//初始化,保存极小值
integer i=0;
always @(posedge vga_clk) begin
    if ((pixel_x == 10'd0) && (pixel_y == 10'd0) && (finished_scan == 2'b10)) begin
        for (i = 0; i < Y_TOTAL; i=i+1) begin
            x_buffer[i] <= 10'h3ff;
        end        
    end    
    else if((img_data==12'hfff) && (pixel_x<x_buffer[pixel_y]) && (clk_div==1'b1) && (finished_scan==2'b10) && scan_en) begin
        x_buffer[pixel_y] <= pixel_x;
    end
    else begin
        x_buffer[pixel_y] <= x_buffer[pixel_y];
    end
end

//--------------求分割范围内的极小值-----------------
reg [3:0] finger_tmp; 
reg [9:0] pos_xbuffer0;      //防止两行一样的图像像素点实现
reg [9:0] pos_xbuffer1;      //防止两行一样的图像像素点实现

wire   sizhi;
wire damuzhi;

always @(posedge vga_clk or negedge rst_n) begin
    if (!rst_n || (finished_scan == 2'b10)) begin
        finger_tmp <= 4'b0;    
        pos_xbuffer0 <= 12'b0;
        pos_xbuffer1 <= 12'b0;     
    end
    else if (img_data==12'hfff && (x_buffer[pixel_y]<x_buffer[pixel_y+5]) && (x_buffer[pixel_y]<=x_buffer[pixel_y-5]) && (x_buffer[pixel_y]<=x_buffer[pixel_y-10]) && (x_buffer[pixel_y]<x_buffer[pixel_y+10]) && (x_buffer[pixel_y]<=x_buffer[pixel_y-15]) && (x_buffer[pixel_y]<x_buffer[pixel_y+15]) && (x_buffer[pixel_y]<=x_buffer[pixel_y-20]) && (x_buffer[pixel_y]<x_buffer[pixel_y+20]) && (finished_scan == 2'b11) && (sizhi||damuzhi)&& (pixel_x==x_buffer[pixel_y]) && scan_en) begin   //区域像素点的横坐标,识别1
            pos_xbuffer0 <= pixel_x;           //将当前值做一下缓冲
            pos_xbuffer1 <= pos_xbuffer0;       
        if (pos_xbuffer0 == pixel_x || pos_xbuffer1 == pixel_x) begin
            finger_tmp <= finger_tmp;           //如果是三行一样的像素点,那么就只计算一次
        end
        else begin
            finger_tmp <= finger_tmp + 1'b1;             
        end
    end
    else begin
        finger_tmp <= finger_tmp;
        pos_xbuffer0 <= pos_xbuffer0;
        pos_xbuffer1 <= pos_xbuffer1;
    end
end

//--------------四指和大拇指的识别区域---------------
//在扫描有效区的一般区域上面
//尝试先判断一下四指以上
wire [9:0] fenge;
assign fenge = (left < right)? ((right-left)>>1): 10'd0;                        //小于横向区域的0.5
assign sizhi = (pixel_x < fenge) ? 1'b1 : 1'b0;
assign damuzhi = ((pixel_x >= (fenge + 10'd10)) && (finger_tmp == 4'd4)) ? 1'b1 : 1'b0;            //只有这种情况才会进行大拇指的继续判断

//用于统计多帧
always @(posedge vga_clk or negedge rst_n) begin
    if(!rst_n) begin
        finger_number <= 4'b0;
        begin_count <= 1'b0;
    end
    else if((finished_scan==2'b11) && (pixel_x==10'd639) && (pixel_y==10'd479)) begin
        finger_number <= finger_tmp;
        begin_count <= 1'b1;
    end
    else begin
        finger_number <= finger_number;
        begin_count <= 1'b0;
    end
end

//通过旋钮调整VGA的输出,从而可以看到轮廓图像和识别到的极值点
always @(posedge vga_clk or negedge rst_n) begin
    if(!rst_n) begin
        final_data <= 12'd0;
    end
    else if(mode==2'b00) begin
        final_data <= img_data;
    end
    else if(mode==2'b01) begin
        if(finished_scan==2'b11) begin
            if(x_buffer[pixel_y]==pixel_x) begin
                final_data <= 12'b1111_1111_1111;
            end
            else begin
                final_data <= 12'd0;
            end
        end
    end
    else if(mode==2'b11) begin
        if(img_data==12'hfff && (x_buffer[pixel_y]<x_buffer[pixel_y+5]) && (x_buffer[pixel_y]<=x_buffer[pixel_y-5]) && (x_buffer[pixel_y]<=x_buffer[pixel_y-10]) && (x_buffer[pixel_y]<x_buffer[pixel_y+10]) && (x_buffer[pixel_y]<=x_buffer[pixel_y-15]) && (x_buffer[pixel_y]<x_buffer[pixel_y+15]) && (x_buffer[pixel_y]<=x_buffer[pixel_y-20]) && (x_buffer[pixel_y]<x_buffer[pixel_y+20]) && (finished_scan == 2'b11) && (sizhi||damuzhi)&& (pixel_x==x_buffer[pixel_y]) && scan_en) begin
            final_data <= 12'b1111_1111_1111;
        end
        else begin
            final_data <= 12'd0;
        end
    end
    else begin
        final_data <= final_data;
    end
end



endmodule
