`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/27 16:39:01
// Design Name: 
// Module Name: centroid
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


module centroid(
    input wire          vga_clk,
    input wire          rst_n,
    input wire[11:0]    img_data,
    // input wire          vsync_r_pos,
    input wire[9:0]     pixel_x,
    input wire[9:0]     pixel_y,

    output wire[9:0]    left,
    output wire[9:0]    right,
    output wire[9:0]    top,
    output wire[9:0]    bottom
    );

    reg div_en; //除法使能
    wire div_valid1; //除法数据有效信号1
    wire div_valid2; //除法数据有效信号2

    reg[18:0] M00_reg;
    reg[26:0] M01_reg;
    reg[26:0] M10_reg;
    reg[18:0] M00;
    reg[26:0] M01;
    reg[26:0] M10;

    wire[23:0] M00_expand;
    wire[31:0] M01_expand;
    wire[31:0] M10_expand;

    assign M00_expand = {5'b00000,M00};
    assign M01_expand = {5'b00000,M01};
    assign M10_expand = {5'b00000,M10};

    //计算M00
    always @(posedge vga_clk or negedge rst_n) begin
        if(!rst_n) begin
            M00 <= 19'd0;
            M00_reg <= 19'd0;
        end
        else if(pixel_x == 10'd639-1'b1 && pixel_y == 479) begin
            M00_reg <= 19'd0;
            M00 <= M00_reg;
        end
        else begin
            if(img_data == 12'hfff) begin
                M00_reg <= M00_reg + 1'b1;
            end
            else begin
                M00_reg <= M00_reg;
            end
        end
    end

    //计算M01
    always @(posedge vga_clk or negedge rst_n) begin
        if(!rst_n) begin
            M01 <= 27'd0;
            M01_reg <= 27'd0;
        end
        else if(pixel_x == 10'd639-1'b1 && pixel_y == 479) begin
            M01_reg <= 27'd0;
            M01 <= M01_reg;
        end
        else begin
            if(img_data == 12'hfff) begin
                M01_reg <= M01_reg + pixel_y;
            end
            else begin
                M01_reg <= M01_reg;
            end
        end
    end

    //计算M10
    always @(posedge vga_clk or negedge rst_n) begin
        if(!rst_n) begin
            M10 <= 27'd0;
            M10_reg <= 27'd0;
        end
        else if(pixel_x == 10'd639-1'b1 && pixel_y == 479) begin
            M10_reg <= 27'd0;
            M10 <= M10_reg;
        end
        else begin
            if(img_data == 12'hfff) begin
                M10_reg <= M10_reg + pixel_x;
            end
            else begin
                M10_reg <= M10_reg;
            end
        end
    end

    //产生除法器使能
    always @(posedge vga_clk or negedge rst_n) begin
        if(!rst_n) begin
            div_en <= 1'b0;
        end
        else if(pixel_x == 639 && pixel_y == 479) begin
            div_en <= 1'b1;
        end
        else begin
            div_en <= 1'b0;
        end
    end

    //计算下边界
    reg[9:0] line_white;    //存放每一行中白色像素的数量

    always @(posedge vga_clk or negedge rst_n) begin
        if(!rst_n) begin
            line_white <= 10'd0;
        end
        else if(pixel_x == 639) begin   //每一行结束时清零一次
            line_white <= 10'd0;
        end
        else if(img_data == 12'hfff) begin
            line_white <= line_white + 1'b1;
        end
        else begin
            line_white <= line_white;
        end
    end

    reg[9:0] lower_boundary;    //下边界的纵坐标
    reg over;   //找到边界的指示信号

    always @(posedge vga_clk or negedge rst_n) begin
        if(!rst_n) begin
            lower_boundary <= 10'd470;
            over <= 1'b0;
        end
        else if(pixel_y > 10'd290 && pixel_y < 10'd480 && pixel_x == 10'd639 ) begin //对于290 < y < 480的情况，因为要找下边界，所以只考虑图像的下部
            if(line_white<10'd16 && over==0) begin   //如果其中一行的白色像素少于16个，就记录下来那行的纵坐标，认为那是下边界
                lower_boundary <= pixel_y;
                over <= 1'b1;
            end
            else begin
                lower_boundary <= lower_boundary;
            end
        end
        else if(pixel_y > 10'd1 && pixel_y < 10'd240) begin  //对于1 < y < 240的情况，也就是图像的上部，不予以考虑
            over <= 1'b0;
        end
        else begin
            over <= over;
            lower_boundary <= lower_boundary;
        end
    end

    //计算重心坐标
    reg[9:0] x_centroid;
    reg[9:0] y_centroid;
    wire[55:0] x_centroid_tmp;
    wire[55:0] y_centroid_tmp;
    
    div_gen_0 u0_div_gen_0(
        .aclk(vga_clk),
        .s_axis_divisor_tvalid(div_en),
        .s_axis_divisor_tdata(M00_expand),
        .s_axis_dividend_tvalid(div_en),
        .s_axis_dividend_tdata(M10_expand),
        .m_axis_dout_tvalid(div_valid1),
        .m_axis_dout_tdata(x_centroid_tmp)
    );

    div_gen_0 u1_div_gen_0(
        .aclk(vga_clk),
        .s_axis_divisor_tvalid(div_en),
        .s_axis_divisor_tdata(M00_expand),
        .s_axis_dividend_tvalid(div_en),
        .s_axis_dividend_tdata(M01_expand),
        .m_axis_dout_tvalid(div_valid2),
        .m_axis_dout_tdata(y_centroid_tmp)
    );

    always @(posedge vga_clk or negedge rst_n) begin
        if(!rst_n) begin
            x_centroid <= 10'd0;
            y_centroid <= 10'd0;
        end
        else if(div_valid1 && div_valid2) begin
            x_centroid <= x_centroid_tmp[33:24];
            y_centroid <= y_centroid_tmp[33:24];
        end
        else begin
            x_centroid <= x_centroid;
            y_centroid <= y_centroid;
        end
    end

    //得到边框
    wire[9:0] length;
    wire[9:0] length1;
    wire[9:0] length2;

    assign length = lower_boundary - y_centroid;
    assign length1 = length + ((length*52)>>6); //length1 = 1.8*length
    assign length2 = length + length + ((length*52)>>6); //length2 = 2.8*length

    assign bottom = lower_boundary;
    assign top = (y_centroid>length2)? (y_centroid-length2): 10'd10;
    assign left = (x_centroid>length2)? (x_centroid-length2): 10'd10;
    assign right = ((x_centroid+length2)<10'd640)? (x_centroid+length2): 10'd630;
endmodule
