`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/30 17:10:13
// Design Name: 
// Module Name: cov_mean
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


module cov_median(
    input wire vga_clk,
    input wire rst_n,

    input wire[9:0] pixel_x,
    input wire[9:0] pixel_y,
    input wire[23:0] rgb_data,  //先输入RGB888，后面再转回RGB444

    output wire[11:0] median_out
    );

    wire[7:0] r;
    wire[7:0] g;
    wire[7:0] b;

    wire[3:0] r_median_out;
    wire[3:0] g_median_out;
    wire[3:0] b_median_out;

    assign r = rgb_data[23:16];
    assign g = rgb_data[15:8];
    assign b = rgb_data[7:0];

    cov_median_single_color cov_median_red(
        .vga_clk(vga_clk),
        .rst_n(rst_n),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .single_color(r),

        .median_single_color_out(r_median_out)
    );

    cov_median_single_color cov_median_green(
        .vga_clk(vga_clk),
        .rst_n(rst_n),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .single_color(g),

        .median_single_color_out(g_median_out)
    );

    cov_median_single_color cov_median_blue(
        .vga_clk(vga_clk),
        .rst_n(rst_n),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .single_color(b),

        .median_single_color_out(b_median_out)
    );

    assign median_out = {r_median_out,g_median_out,b_median_out};
endmodule
