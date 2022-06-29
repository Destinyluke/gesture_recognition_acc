`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/10 17:20:47
// Design Name: 
// Module Name: led
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


module led(
    input wire[3:0] led_in,
    output reg[7:0] led 
    );

    always @(*) begin
        case(led_in) 
            4'd0: led = 8'b10000000;
            4'd1: led = 8'b00000001;
            4'd2: led = 8'b00000010;
            4'd3: led = 8'b00000100;
            4'd4: led = 8'b00001000;
            4'd5: led = 8'b00010000;
            4'd6: led = 8'b00100000;
            4'd7: led = 8'b01000000;
            default: led = 8'b00000000;
        endcase
    end
endmodule
