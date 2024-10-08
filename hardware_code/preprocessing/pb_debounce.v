`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/08 10:28:44
// Design Name: 
// Module Name: pb_debounce
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

//按键控制模块
module pb_debounce(
    input wire clk,
    input wire resetn,
    input wire pb_in,

    output wire pb_out,
    output reg pb_tick
    );

    localparam st_idle = 2'b00;
    localparam st_wait1 = 2'b01;
    localparam st_one = 2'b10;
    localparam st_wait0 = 2'b11;

    reg[1:0] current_state = st_idle;
    reg[1:0] next_state = st_idle;

    reg[21:0] db_clk = {21{1'b1}};
    reg[21:0] db_clk_next = {21{1'b1}};

    always @(posedge clk or negedge resetn) begin
        if(!resetn) begin
            current_state <= st_idle;
            db_clk <= 0;
        end
        else begin
            current_state <= next_state;
            db_clk <= db_clk_next;
        end
    end

    always @(*) begin
        next_state = current_state;
        db_clk_next = db_clk;
        pb_tick = 0;

        case(current_state)
            st_idle: begin      //没有按下按键
                if(pb_in) begin
                    db_clk_next = {21{1'b1}};
                    next_state = st_wait1;
                end
            end

            st_wait1: begin     //按下按键，等待信号稳定
                if(pb_in) begin
                    db_clk_next = db_clk - 1;
                    if(db_clk_next == 0) begin
                        next_state = st_one;
                        pb_tick = 1'b1;
                    end
                end
            end

            st_one: begin       //信号稳定并且输出
                if(~pb_in) begin
                    next_state = st_wait0;
                    db_clk_next = {21{1'b1}};
                end
            end

            st_wait0: begin     //确定按键释放，并且返回idle状态
                if(~pb_in) begin
                    db_clk_next = db_clk - 1;
                    if(db_clk_next == 0) begin
                        next_state = st_idle;
                    end
                end
                else begin
                    next_state = st_one;
                end
            end
        endcase
    end

    assign pb_out = (current_state == st_one || current_state == st_wait0) ? 1'b1: 1'b0;
    
endmodule
