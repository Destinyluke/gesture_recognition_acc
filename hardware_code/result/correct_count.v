`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/08 17:12:47
// Design Name: 
// Module Name: correct_count
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

//统计准确率模块
module correct_count(
    input wire          clk_25m,
    input wire          rst_n,
    input wire          uart_knob,
    input wire[3:0]     final_number,
    input wire          uart_en,

    output wire         tx
    );

    wire b_tick;    //波特率信号
    wire tx_done;   //UART状态
    wire[7:0] uart_wdata;   //加速器和FIFO之间的数据
    wire tx_full;   //发送器fifo满信号
    wire tx_empty;  //发送器fifo空信号
    wire[7:0] tx_data;  //FIFO与tx之间的数据
    wire send_done;     //uart传输完成指示信号
    wire uart_wr;   //uart写使能

    assign uart_wdata = {4'b0000,final_number};

    reg[7:0] count;     //uart传输个数计数器

    always @(posedge clk_25m or negedge rst_n) begin
        if(!rst_n) begin
            count <= 8'd0;
        end
        else if(count <= 8'd100 && uart_en && uart_knob) begin
            count <= count + 8'd1;
        end
        else begin
            count <= count;
        end
    end

    assign send_done = (count <= 8'd100)? 1'b0: 1'b1; 

    assign uart_wr = uart_en && (!send_done) && uart_knob;

    //波特率生成器模块
    baudgen u_baudgen(
        .clk        (clk_25m),
        .resetn     (rst_n),
        .baudtick   (b_tick)
    );

    //发送器fifo
    fifo #(.DWIDTH(8),.AWIDTH(8)) u_fifo_tx(
        .clk        (clk_25m),
        .resetn     (rst_n),
        .rd         (tx_done),
        .wr         (uart_wr),
        .w_data     (uart_wdata[7:0]),
        .empty      (tx_empty),
        .full       (tx_full),
        .r_data     (tx_data[7:0])
    );

    //UART发送器
    uart_tx u_uart_tx(
        .clk        (clk_25m),
        .resetn     (rst_n),
        .tx_start   (!tx_empty),
        .b_tick     (b_tick),
        .d_in       (tx_data[7:0]),
        .tx_done    (tx_done),
        .tx         (tx)
    );
endmodule
