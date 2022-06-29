`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/26 16:54:15
// Design Name: 
// Module Name: frame_ctrl
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


module frame_ctrl(
    input wire      vga_clk,
    input wire      rst_n,
    input wire      vga_valid_pre3,

    input wire[9:0] pixel_x,
    input wire[9:0] pixel_y,

    output reg[18:0] read_addr
    );

    parameter FRAME_SIZE = 19'd307200;

    always @(posedge vga_clk or negedge rst_n) begin
        if(!rst_n) begin
            read_addr <= 19'h7ffff;
        end
        else if(vga_valid_pre3) begin
            read_addr <= read_addr + 1'b1;
        end
        else if(read_addr >= FRAME_SIZE-1) begin
            read_addr <= 19'd0;
        end
        else begin
            read_addr <= read_addr;
        end
    end


endmodule
