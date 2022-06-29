`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/22 15:02:55
// Design Name: 
// Module Name: finger_count
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


module finger_count(
    input wire      clk,
    input wire      rst_n,
    input wire[3:0] finger_number,
    input wire begin_count,

    output reg[3:0] final_number,
    output wire uart_en
    );

    reg uart_flag;
    reg uart_flag_d0;
    reg uart_flag_d1;
    (*mark_debug="true"*)reg[4:0] count;
    // reg[2:0] zero_num;
    (*mark_debug="true"*)reg[4:0] one_num;
    (*mark_debug="true"*)reg[4:0] two_num;
    (*mark_debug="true"*)reg[4:0] three_num;
    (*mark_debug="true"*)reg[4:0] four_num;
    (*mark_debug="true"*)reg[4:0] five_num;
    (*mark_debug="true"*)reg[4:0] zero_num;
    (*mark_debug="true"*)reg[4:0] others;
    // initial begin
    //     count = 4'd0;
    // end

    //帧计数器
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            count <= 5'd0;
        end
        else if(begin_count) begin
            count <= count + 1'b1;
        end
        else if(count == 5'd10) begin
            count <= 5'd0;
        end
        else begin
            count <= count;
        end
    end

    //统计手势1、2、3的个数
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            zero_num <= 5'd0;
            one_num <= 5'd0;
            two_num <= 5'd0;
            three_num <= 5'd0;
            four_num <= 5'd0;
            five_num <= 5'd0;
            others <= 5'd0;
        end
        else if(begin_count) begin
            case(finger_number)
                4'd0: begin
                    zero_num <= zero_num + 1'b1;
                end
                4'd1: begin
                    one_num <= one_num + 1'b1;
                end
                4'd2: begin
                    two_num <= two_num + 1'b1;
                end
                4'd3: begin
                    three_num <= three_num + 1'b1;
                end
                4'd4: begin
                    four_num <= four_num + 1'b1;
                end
                4'd5: begin
                    five_num <= five_num + 1'b1;
                end
                default: begin
                   others <= others + 1'b1; 
                end
            endcase
        end
        else if(count == 5'd10) begin
            zero_num <= 5'd0;
            one_num <= 5'd0;
            two_num <= 5'd0;
            three_num <= 5'd0;
            four_num <= 5'd0;
            five_num <= 5'd0;
            others <= 5'd0;
        end
        else begin
            zero_num <= zero_num;
            one_num <= one_num;
            two_num <= two_num;
            three_num <= three_num;
            four_num <= four_num;
            five_num <= five_num;
            others <= others;
        end
    end

    // //根据个数比较得出最终显示的led
    // always @(posedge clk or negedge rst_n) begin
    //     if(!rst_n) begin
    //         final_number <= 4'd0;
    //     end
    //     else if(count == 5'd29) begin
    //         if(one_num >= two_num && one_num >= three_num) begin
    //             final_number <= 4'd1;
    //         end
    //         else if(two_num >= one_num && two_num >= three_num) begin
    //             final_number <= 4'd2;
    //         end
    //         else if(three_num >= one_num && three_num >= two_num) begin
    //             final_number <= 4'd3;
    //         end
    //         else begin
    //             final_number <= final_number;
    //         end
    //     end
    //     else begin
    //         final_number <= final_number;
    //     end
    // end
    
    //取出现的最高手势作为最终显示的手势，例如出现了3，则认为手势是3
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            final_number <= 4'd0;
        end
        else if(count == 5'd9) begin
            if(five_num != 5'd0) begin
                final_number <= 4'd5;
            end
            else if(four_num != 5'd0) begin
                final_number <= 4'd4;
            end
            else if(three_num != 5'd0) begin
                final_number <= 4'd3;
            end
            else if(two_num != 5'd0) begin
                final_number <= 4'd2;
            end
            else if(one_num != 5'd0) begin
                final_number <= 4'd1;
            end
            else if(zero_num != 5'd0) begin
                final_number <= 4'd0;
            end
            else begin
                final_number <= final_number;
            end
        end
        else begin
            final_number <= final_number;
        end
    end

    //在count=29的时候使能uart_flag
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            uart_flag <= 1'b0;
        end
        else if(count == 5'd9) begin
            uart_flag <= 1'b1;
        end
        else begin
            uart_flag <= 1'b0;
        end
    end

    //uart_flag打两拍，去获得它的上升沿
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            uart_flag_d0 <= 1'b0;
            uart_flag_d1 <= 1'b0;
        end
        else begin
            uart_flag_d0 <= uart_flag;
            uart_flag_d1 <= uart_flag_d0;
        end
    end

    assign uart_en = uart_flag_d0 && (~uart_flag_d1);

    // always @(*) begin
    //     if(count == 4'd15) begin
    //         count = 4'd0;
            // if(zero_num >= one_num && zero_num >= two_num) begin
            //     final_number = 4'd0;
            // end
            // else if(one_num >= zero_num && one_num >= two_num) begin
            //     final_number = 4'd1;
            // end
            // else if(two_num >= zero_num && two_num >= one_num) begin
            //     final_number = 4'd2;
            // end
    //         if(three_num >= one_num && three_num >= two_num) begin
    //             final_number = 4'd3;
    //         end
    //         else if(one_num >= three_num && one_num >= two_num) begin
    //             final_number = 4'd1;
    //         end
    //         else if(two_num >= three_num && two_num >= one_num) begin
    //             final_number = 4'd2;
    //         end
    //         else begin
    //             final_number = final_number;
    //         end
    //     end
    //     else if(begin_count) begin
    //         count = count + 1'b1;
    //         case(finger_number)
    //             // 4'd0: zero_num = zero_num + 1'b1;
    //             4'd1: one_num = one_num + 1'b1;
    //             4'd2: two_num = two_num + 1'b1;
    //             4'd3: three_num = three_num + 1'b1;
    //             default: begin
    //                 // zero_num = zero_num;
    //                 one_num = one_num;
    //                 two_num = two_num;
    //                 three_num = three_num;
    //             end
    //         endcase
    //     end
    //     else begin
    //         count = count;
    //         zero_num = zero_num;
    //         one_num = one_num;
    //         two_num = two_num;
    //         final_number = final_number;
    //     end
    // end


endmodule
