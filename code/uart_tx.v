`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/08 19:09:58
// Design Name: 
// Module Name: uart_tx
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

//发送器模块
module uart_tx(
    input wire clk,
    input wire resetn,
    input wire tx_start,
    input wire b_tick,      //波特率生成时钟
    input wire[7:0] d_in,   //输入数据
    output reg tx_done,     //传输完成
    output wire tx          //将数据输出到RS-232
    );

    //定义状态
    localparam idle_st = 2'b00;
    localparam start_st = 2'b01;
    localparam data_st = 2'b11;
    localparam stop_st = 2'b10;

    //内部信号
    reg[1:0] current_state;
    reg[1:0] next_state;
    reg[3:0] b_reg;         //波特率/过采样计数器
    reg[3:0] b_next;
    reg[2:0] count_reg;     //数据位计数器
    reg[2:0] count_next;
    reg[7:0] data_reg;      //数据寄存器
    reg[7:0] data_next;
    reg tx_reg;
    reg tx_next;

    //状态机
    always @(posedge clk or negedge resetn) begin
        if(!resetn) begin
            current_state <= idle_st;
            b_reg <= 0;
            count_reg <= 0;
            data_reg <= 0;
            tx_reg <= 1'b1;
        end
        else begin
            current_state <= next_state;
            b_reg <= b_next;
            count_reg <= count_next;
            data_reg <= data_next;
            tx_reg <= tx_next;
        end
    end

    //下状态逻辑
    always @(*) begin
        next_state = current_state;
        tx_done = 1'b0;
        b_next = b_reg;
        count_next = count_reg;
        data_next = data_reg;
        tx_next = tx_reg;
        
        case(current_state)
            idle_st: begin
                tx_next = 1'b1;
                if(tx_start) begin
                    next_state = start_st;
                    b_next = 0;
                    data_next = d_in;
                end
            end
            start_st: begin     //发送起始位
                tx_next = 1'b0;
                if(b_tick) begin
                    if(b_reg == 15) begin
                        next_state = data_st;
                        b_next = 0;
                        count_next = 0;
                    end
                    else begin
                        b_next = b_reg + 1'b1;
                    end
                end
            end
            data_st: begin      //发送串行数据
                tx_next = data_reg[0];

                if(b_tick) begin
                    if(b_reg == 15) begin
                        b_next = 0;
                        data_next = data_reg >> 1;
                        if(count_reg == 7) begin    //8个数据位
                            next_state = stop_st;
                        end
                        else begin
                            count_next = count_reg + 1'b1;
                        end
                    end
                    else begin
                        b_next = b_reg + 1'b1;
                    end
                end
            end
            stop_st: begin      //发送停止位
                tx_next = 1'b1;
                if(b_tick) begin
                    if(b_reg == 15) begin   //1个停止位
                        next_state = idle_st;
                        tx_done = 1'b1;
                    end
                    else begin
                        b_next = b_reg + 1'b1;
                    end
                end
            end
        endcase
    end

    assign tx = tx_reg;
endmodule
