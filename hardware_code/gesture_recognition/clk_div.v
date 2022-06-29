`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/08 15:14:59
// Design Name: 
// Module Name: clk_div
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

//横向扫描
module clk_div(
    input wire      hsync_r_pos,
    input wire      rst_n,
    output wire     clk_div
    );

    reg[3:0] counter;

    always @(posedge hsync_r_pos or negedge rst_n) begin
        if(!rst_n) begin
            counter <= 4'b0;
        end
        else if(counter == 4'd4) begin
            counter <= 4'b0;
        end
        else begin
            counter <= counter + 1'b1;
        end
    end

    assign clk_div = (counter == 4'd4)? 1'b1: 1'b0;
endmodule
