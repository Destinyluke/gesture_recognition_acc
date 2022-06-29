`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/08 16:35:37
// Design Name: 
// Module Name: baudgen
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

//波特率生成器模块
module baudgen(
    input wire clk,
    input wire resetn,
    output wire baudtick
    );

    reg[21:0] count_reg;
    wire[21:0] count_next;

    //计数器
    always @(posedge clk or negedge resetn) begin
        if(!resetn) begin
            count_reg <= 0;
        end
        else begin
            count_reg <= count_next;
        end
    end

    //波特率=9600=25MHz/(162*16)
    assign count_next = ((count_reg == 161)? 0: count_reg+1'b1);

    assign baudtick = ((count_reg == 161)? 1'b1: 1'b0);
endmodule
