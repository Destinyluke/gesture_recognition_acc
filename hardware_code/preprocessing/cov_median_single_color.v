`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/03 15:12:05
// Design Name: 
// Module Name: cov_median_single_color
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

//对图像的一个通道进行中值滤波
module cov_median_single_color(
    input wire vga_clk,
    input wire rst_n,

    input wire[9:0] pixel_x,
    input wire[9:0] pixel_y,
    input wire[7:0] single_color,

    output reg[3:0] median_single_color_out
    );

    wire[7:0] med;

    reg line_clk;
    reg state;
    initial state = 1'b0;

    reg[7:0] line_buf0[639:0];
    reg[7:0] line_buf1[639:0];
    reg[7:0] p0;
    reg[7:0] p1;
    reg[7:0] p2;
    reg[9:0] conv_out;

    wire[7:0] s1,s2,s3,s4,s5,s6;

    assign s1 = line_buf0[pixel_x-2];
    assign s2 = line_buf0[pixel_x-1];
    assign s3 = line_buf0[pixel_x];
    assign s4 = line_buf1[pixel_x-2];
    assign s5 = line_buf1[pixel_x-1];
    assign s6 = line_buf1[pixel_x];

    //line_clk上升沿的时候代表转下一行
    always @(posedge vga_clk) begin
        if(pixel_y>0 && pixel_y<479) begin
            if(pixel_x == 0) begin
                line_clk <= 1'b1;
            end
            else begin
                line_clk <= 1'b0;
            end
        end
    end

    always @(posedge line_clk) begin
        if(pixel_y == 1'b1) begin
            state <= 1'b0;
        end
        else begin
            state <= ~state;
        end
    end

    always @(posedge vga_clk) begin
        case(state)
            1'b0: begin
                line_buf0[pixel_x] <= single_color; //缓存当前值
                line_buf1[pixel_x] <= line_buf1[pixel_x];
                p2 <= single_color;
                p1 <= p2;
                p0 <= p1;
                if(pixel_x>=2 && pixel_y>=3) begin
                    conv_out <= med;
                end
            end
            1'b1: begin
                line_buf1[pixel_x] <= single_color; //缓存当前值
                line_buf0[pixel_x] <= line_buf0[pixel_x];
                p2 <= single_color;
                p1 <= p2;
                p0 <= p1;
                if(pixel_x>=2 && pixel_y>=3) begin
                    conv_out <= med;
                end
            end
            default: begin
                conv_out <= conv_out;
                line_buf0[pixel_x] <= line_buf0[pixel_x];
                line_buf1[pixel_x] <= line_buf1[pixel_x];
            end
        endcase
    end

    med_get u_med_get(
        .s1(s1),
        .s2(s2),
        .s3(s3),
        .s4(s4),
        .s5(s5),
        .s6(s6),
        .s7(p0),
        .s8(p1),
        .s9(p2),

        .med(med)
    );

    always @(*) begin
        median_single_color_out = conv_out[7:4];
    end
endmodule
