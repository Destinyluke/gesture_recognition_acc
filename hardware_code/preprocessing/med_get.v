`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/30 18:33:03
// Design Name: 
// Module Name: med_get
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

//计算中值
module med_get(
    input wire[7:0] s1,
    input wire[7:0] s2,
    input wire[7:0] s3,
    input wire[7:0] s4,
    input wire[7:0] s5,
    input wire[7:0] s6,
    input wire[7:0] s7,
    input wire[7:0] s8,
    input wire[7:0] s9,

    output reg[7:0] med
    );

    //定义变量
    reg[7:0] MAX1,MAX2,MAX3,MAX4;
    reg[7:0] MIN1,MIN2,MIN3,MIN4;
    reg[7:0] MED1,MED2,MED3,MED4;

    initial begin
        MAX1 <= 8'd0;
        MAX2 <= 8'd0;
        MAX3 <= 8'd0;
        MAX4 <= 8'd0;

        MIN1 <= 8'd0;
        MIN2 <= 8'd0;
        MIN3 <= 8'd0;
        MIN4 <= 8'd0;

        MED1 <= 8'd0;
        MED2 <= 8'd0;
        MED3 <= 8'd0;
        MED4 <= 8'd0;
    end

    //MAX1
    always @(*) begin
        if(s1 >= s2 && s1 >= s3) begin
            MAX1 <= s1;
        end
        else if(s2 >= s3 && s2 >= s1) begin
            MAX1 <= s2;
        end
        else if(s3 >= s1 && s3 >= s2) begin
            MAX1 <= s3;
        end
    end

    //MAX2
    always @(*) begin
        if(s4 >= s5 && s4 >= s6) begin
            MAX2 <= s4;
        end
        else if(s5 >= s4 && s5 >= s6) begin
            MAX2 <= s5;
        end
        else if(s6 >= s4 && s6 >= s5) begin
            MAX2 <= s6;
        end
    end

    //MAX3
    always @(*) begin
        if(s7 >= s8 && s7 >= s9) begin
            MAX3 <= s7;
        end
        else if(s8 >= s7 && s8 >= s9) begin
            MAX3 <= s8;
        end
        else if(s9 >= s7 && s9 >= s8) begin
            MAX3 <= s9;
        end
    end

    //MIN1
    always @(*) begin
        if(s1 <= s2 && s1 <= s3) begin
            MIN1 <= s1;
        end
        else if(s2 <= s3 && s2 <= s1) begin
            MIN1 <= s2;
        end
        else if(s3 <= s1 && s3 <= s2) begin
            MIN1 <= s3;
        end
    end

    //MIN2
    always @(*) begin
        if(s4 <= s5 && s4 <= s6) begin
            MIN2 <= s4;
        end
        else if(s5 <= s4 && s5 <= s6) begin
            MIN2 <= s5;
        end
        else if(s6 <= s4 && s6 <= s5) begin
            MIN2 <= s6;
        end
    end  

    //MIN3
    always @(*) begin
        if(s7 <= s8 && s7 <= s9) begin
            MIN3 <= s7;
        end
        else if(s8 <= s7 && s8 <= s9) begin
            MIN3 <= s8;
        end
        else if(s9 <= s7 && s9 <= s8) begin
            MIN3 <= s9;
        end
    end 

    //MED1
    always @(*) begin
        if((s1 >= s2 && s1 <= s3) || (s1 >= s3 && s1 <= s2)) begin
            MED1 <= s1;
        end
        else if((s2 >= s3 && s2 <= s1) || (s2 <= s3 && s2 >= s1)) begin
            MED1 <= s2;
        end
        else if((s3 >= s1 && s3 <= s2) || (s3 <= s1 && s3 >= s2)) begin
            MED1 <= s3;
        end
    end

    //MED2
    always @(*) begin
        if((s4 >= s5 && s4 <= s6) || (s4 >= s6 && s4 <= s5)) begin
            MED2 <= s4;
        end
        else if((s5 >= s6 && s5 <= s4) || (s5 <= s6 && s5 >= s4)) begin
            MED2 <= s5;
        end
        else if((s6 >= s4 && s6 <= s5) || (s6 <= s4 && s6 >= s5)) begin
            MED2 <= s6;
        end
    end

    //MED3
    always @(*) begin
        if((s7 >= s8 && s7 <= s9) || (s7 >= s9 && s7 <= s8)) begin
            MED3 <= s7;
        end
        else if((s8 >= s9 && s8 <= s7) || (s8 <= s9 && s8 >= s7)) begin
            MED3 <= s8;
        end
        else if((s9 >= s7 && s9 <= s8) || (s9 <= s7 && s9 >= s8)) begin
            MED3 <= s9;
        end
    end

    //MAX4
    always @(*) begin
        if(MIN1 >= MIN2 && MIN1 >= MIN3) begin
            MAX4 <= MIN1;
        end
        else if(MIN2 >= MIN1 && MIN2 >= MIN3) begin
            MAX4 <= MIN2;
        end
        else if(MIN3 >= MIN1 && MIN3 >= MIN2) begin
            MAX4 <= MIN3;
        end
    end

    //MIN4
    always @(*) begin
        if(MAX1 <= MAX2 && MAX1 <= MAX3) begin
            MIN4 <= MAX1;
        end
        else if(MAX2 <= MAX1 && MAX2 <= MAX3) begin
            MIN4 <= MAX2;
        end
        else if(MAX3 <= MAX1 && MAX3 <= MAX2) begin
            MIN4 <= MAX3;
        end
    end

    //MED4
    always @(*) begin
        if((MED1 >= MED2 && MED1 <= MED3) || (MED1 >= MED3 && MED1 <= MED2)) begin
            MED4 <= MED1;
        end
        else if((MED2 >= MED1 && MED2 <= MED3) || (MED2 >= MED3 && MED2 <= MED1)) begin
            MED4 <= MED2;
        end
        else if((MED3 >= MED2 && MED3 <= MED1) || (MED3 >= MED1 && MED3 <= MED2)) begin
            MED4 <= MED3;
        end
    end

    //get median from MIN4 MAX4 MED4
    always @(*) begin
        if((MIN4 >= MAX4 && MIN4 <= MED4) || (MIN4 >= MED4 && MIN4 <= MAX4)) begin
            med <= MIN4;
        end
        else if((MAX4 >= MIN4 && MAX4 <= MED4) || (MAX4 >= MED4 && MAX4 <= MIN4)) begin
            med <= MAX4;
        end
        else if((MED4 >= MAX4 && MED4 <= MIN4) || (MED4 >= MIN4 && MED4 <= MAX4)) begin
            med <= MED4;
        end
    end
endmodule
