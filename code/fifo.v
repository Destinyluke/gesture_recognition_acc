`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/08 16:44:56
// Design Name: 
// Module Name: fifo
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


module fifo #(parameter DWIDTH=8, AWIDTH=1)
(
    input wire clk,
    input wire resetn,
    input wire rd,
    input wire wr,
    input wire[DWIDTH-1:0] w_data,

    output wire empty,
    output wire full,
    output wire[DWIDTH-1:0] r_data
    );

    //声明内部信号
    reg[DWIDTH-1:0] array_reg[2**AWIDTH-1:0];
    reg[AWIDTH-1:0] w_ptr_reg;
    reg[AWIDTH-1:0] w_ptr_next;
    reg[AWIDTH-1:0] w_ptr_succ;
    reg[AWIDTH-1:0] r_ptr_reg;
    reg[AWIDTH-1:0] r_ptr_next;
    reg[AWIDTH-1:0] r_ptr_succ;

    reg full_reg;
    reg empty_reg;
    reg full_next;
    reg empty_next;

    wire w_en;

    always @(posedge clk) begin
        if(w_en) begin
            array_reg[w_ptr_reg] <= w_data;
        end
    end

    assign r_data = array_reg[r_ptr_reg];

    assign w_en = wr & ~full_reg;

    //状态机
    always @(posedge clk or negedge resetn) begin
        if(!resetn) begin
            w_ptr_reg <= 0;
            r_ptr_reg <= 0;
            full_reg <= 1'b0;
            empty_reg <= 1'b1;
        end
        else begin
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg <= full_next;
            empty_reg <= empty_next;
        end
    end

    //下状态逻辑
    always @(*) begin
        w_ptr_succ = w_ptr_reg + 1;
        r_ptr_succ = r_ptr_reg + 1;

        w_ptr_next = w_ptr_reg;
        r_ptr_next = r_ptr_reg;
        full_next = full_reg;
        empty_next = empty_reg;

        case({w_en,rd})
            2'b01: begin
                if(~empty_reg) begin
                    r_ptr_next = r_ptr_succ;
                    full_next = 1'b0;
                    if(r_ptr_succ == w_ptr_reg)
                        empty_next = 1'b1;
                end
            end
            2'b10: begin
                if(~full_reg) begin
                    w_ptr_next = w_ptr_succ;
                    empty_next = 1'b0;
                    if(w_ptr_succ == r_ptr_reg)
                        full_next = 1'b1;
                end
            end
            2'b11: begin
                w_ptr_next = w_ptr_succ;
                r_ptr_next = r_ptr_succ;
            end
        endcase
    end

    //设置满full和空empty标志
    assign full = full_reg;
    assign empty = empty_reg;
endmodule
