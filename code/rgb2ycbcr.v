`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/02 11:00:32
// Design Name: 
// Module Name: rgb2ycbcr
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


module rgb2ycbcr(
    input wire       clk,
    input wire       rst_n,
    (*mark_debug="true"*)input wire       Int1,
    (*mark_debug="true"*)input wire       Int2,
    (*mark_debug="true"*)input wire       Int3,
    input wire[11:0] imgPixel_in,
    
    output wire[11:0] imgPixel_out,
    (*mark_debug="true"*)output reg[2:0]   choice_led
    );

    wire[7:0] R;
    wire[7:0] G;
    wire[7:0] B;

    wire[15:0] Y0;
    wire[15:0] Cb0;
    wire[15:0] Cr0;

    wire[7:0] Y1;
    wire[7:0] Cb1;
    wire[7:0] Cr1;

    reg[7:0] Cr_left_thershold;
    reg[7:0] Cr_right_thershold;
    reg[7:0] Cb_left_thershold;
    reg[7:0] Cb_right_thershold;
    (*mark_debug="true"*)reg[7:0] y_left_thershold;
    (*mark_debug="true"*)reg[7:0] y_right_thershold;

    reg[11:0] erzhihua;

    assign R = {imgPixel_in[11:8],4'b0000}; //RGB444转RGB888
    assign G = {imgPixel_in[7:4],4'b0000};
    assign B = {imgPixel_in[3:0],4'b0000};

    assign imgPixel_out = erzhihua;

/********************************************************
            RGB to YCbCr
 Y  = (77 *R    +    150*G    +    29 *B        )>>8
 Cb = (-43*R    -    85 *G    +    128*B + 32768)>>8
 Cr = (128*R    -    107*G    -    21 *B + 32768)>>8
*********************************************************/
    assign Y0 = R*8'd77 + G*8'd150 + B*8'd29;
    assign Cb0 = B*8'd128 - R*8'd43 - G*8'd85 + 16'd32768;
    assign Cr0 = R*8'd128 - G*8'd107 - B*8'd21 + 16'd32768;

    assign Y1 = Y0[15:8];
    assign Cb1 = Cb0[15:8];
    assign Cr1 = Cr0[15:8];

    always @(posedge clk or negedge rst_n) begin
        // if((Cr1>133) && (Cr1<173) && (Cb1>77) && (Cb1<127)) begin
        // if((Cr1>=132) && (Cr1<=151) && (Cb1>=87) && (Cb1<=142) && (Y1>=50) && (Y1<=255)) begin
        if(!rst_n) begin
            erzhihua <= 12'h000;
        end
        // else if((Cr1>136) && (Cr1<173) && (Cb1>77) && (Cb1<127) && (Y1>=50) && (Y1<=255)) begin
        else if((Cr1>Cr_left_thershold) && (Cr1<Cr_right_thershold) && (Cb1>Cb_left_thershold) && (Cb1<Cb_right_thershold) && (Y1>=y_left_thershold) && (Y1<=y_right_thershold)) begin
            erzhihua <= 12'hfff;
        end
        else begin
            erzhihua <= 12'h000;
        end
    end

    //通过按键调整阈值
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            Cr_left_thershold <= 8'd135;
            Cr_right_thershold <= 8'd173;
            Cb_left_thershold <= 8'd77;
            Cb_right_thershold <= 8'd132;
            y_left_thershold <= 8'd50;
            y_right_thershold <= 8'd255;
        end
        else if(Int1) begin
            case(choice_led)
                3'd0: begin
                    y_left_thershold <= y_left_thershold - 1'b1;
                end
                3'd1: begin
                    y_right_thershold <= y_right_thershold - 1'b1;
                end
                3'd2: begin
                    Cb_left_thershold <= Cb_left_thershold - 1'b1;
                end
                3'd3: begin
                    Cb_right_thershold <= Cb_right_thershold - 1'b1;
                end
                3'd4: begin
                    Cr_left_thershold <= Cr_left_thershold - 1'b1;
                end
                3'd5: begin
                    Cr_right_thershold <= Cr_right_thershold - 1'b1;
                end
                default: ;
            endcase
        end
        else if(Int2) begin
            case(choice_led)
                3'd0: begin
                    y_left_thershold <= y_left_thershold + 1'b1;
                end
                3'd1: begin
                    y_right_thershold <= y_right_thershold + 1'b1;
                end
                3'd2: begin
                    Cb_left_thershold <= Cb_left_thershold + 1'b1;
                end
                3'd3: begin
                    Cb_right_thershold <= Cb_right_thershold + 1'b1;
                end
                3'd4: begin
                    Cr_left_thershold <= Cr_left_thershold + 1'b1;
                end
                3'd5: begin
                    Cr_right_thershold <= Cr_right_thershold + 1'b1;
                end
                default: ;
            endcase
        end
        else begin
            Cr_left_thershold <= Cr_left_thershold;
            Cr_right_thershold <= Cr_right_thershold;
            Cb_left_thershold <= Cb_left_thershold;
            Cb_right_thershold <= Cb_right_thershold;
            y_left_thershold <= y_left_thershold;
            y_right_thershold <= y_right_thershold;
        end
    end

    //选择需要调整的阈值
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            choice_led <= 3'd0;
        end
        else if(Int3) begin
            if(choice_led == 3'd5) begin
                choice_led <= 3'd0;
            end
            else begin
                choice_led <= choice_led + 1'b1;
            end
        end
        else begin
            choice_led <= choice_led;
        end
    end
endmodule
