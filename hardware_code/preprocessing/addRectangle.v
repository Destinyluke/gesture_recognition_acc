`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/29 16:23:14
// Design Name: 
// Module Name: addRectangle
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

//根据centroid生成的left,right,top,bottom,生成图像的绿色矩形框
module addRectangle(
    input wire[9:0] left,
    input wire[9:0] right,
    input wire[9:0] top,
    input wire[9:0] bottom,
    input wire[11:0] background,
    input wire[9:0] pixel_x,
    input wire[9:0] pixel_y,

    output reg[11:0] data_out
    );

    parameter RECT_WIDTH = 3'd5;

    wire top_en;
    wire bottom_en;
    wire left_en;
    wire right_en;

    assign top_en = ((pixel_x > left-RECT_WIDTH) && 
                    (pixel_x < right+RECT_WIDTH) &&
                    (pixel_y > top-RECT_WIDTH) &&
                    (pixel_y < top))? 1'b1: 1'b0;

    assign bottom_en = ((pixel_x > left-RECT_WIDTH) && 
                    (pixel_x < right+RECT_WIDTH) &&
                    (pixel_y > bottom) &&
                    (pixel_y < bottom+RECT_WIDTH))? 1'b1: 1'b0;
    
    assign left_en = ((pixel_x > left-RECT_WIDTH) && 
                    (pixel_x < left) &&
                    (pixel_y > top-RECT_WIDTH) &&
                    (pixel_y < bottom+RECT_WIDTH))? 1'b1: 1'b0;
    
    assign right_en = ((pixel_x > right) && 
                    (pixel_x < right+RECT_WIDTH) &&
                    (pixel_y > top-RECT_WIDTH) &&
                    (pixel_y < bottom+RECT_WIDTH))? 1'b1: 1'b0;

    always @(*) begin
        if(top_en || bottom_en || left_en || right_en) begin
            data_out = 12'b0000_1111_0000;
        end
        else begin
            data_out = background;
        end
    end
    


endmodule
