`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/10 10:55:26
// Design Name: 
// Module Name: timer
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

//识别时间统计模块
module timer(
    input wire          clk_50m,
    input wire          rst_n,
    (*mark_debug="true"*)input wire          flag,        //表示一次总识别完成

    output reg[31:0]    ms_cnt_final        //一次识别的时间
    );

    parameter CLK_FREQ = 32'd5000_0000;

    reg[31:0] cnt;
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            cnt <= 32'd0;
        end
        else if(cnt >= CLK_FREQ/1000-1) begin   // reset to zero every 1ms
            cnt <= 32'd0;
        end
        else begin
            cnt <= cnt + 32'd1;
        end
    end

    (*mark_debug="true"*)reg flag_d0;
    reg flag_d1;
    //uart_en打两拍
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            flag_d0 <= 1'b0;
            flag_d1 <= 1'b0;
        end
        else begin
            flag_d0 <= flag;
            flag_d1 <= flag_d0;
        end
    end

    (*mark_debug="true"*)reg[31:0] ms_cnt;
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            ms_cnt <= 32'd0;
        end
        else if(flag_d0) begin   
            ms_cnt <= 32'd0;
        end
        else if(cnt == 32'd1) begin
            ms_cnt <= ms_cnt + 32'd1;
        end
        else begin
            ms_cnt <= ms_cnt;
        end
    end

    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            ms_cnt_final <= 32'd0;
        end
        else if(flag) begin
            ms_cnt_final <= ms_cnt;
        end
        else begin
            ms_cnt_final <= ms_cnt_final;
        end
    end
endmodule
