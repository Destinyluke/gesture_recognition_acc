`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/25 21:23:13
// Design Name: 
// Module Name: vga_driver
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


module vga_driver(
    input wire          vga_clk,
    input wire          rst_n,
    input wire[11:0]    rgb_data,   //RGB444

    output wire[11:0]   vga_data,   //RGB444
    output wire         vga_hsync,  
    output wire         vga_vsync,
    output wire[9:0]    pixel_x,
    output wire[9:0]    pixel_y,
    output wire         vga_valid,
    output wire         vga_valid_pre3,
    output wire         vsync_r_pos,   
    output wire         hsync_r_pos
    );

    //分辨率 640*480
    parameter H_SYNC = 10'd96,
              H_BACK = 10'd40,
              H_LEFT = 10'd8,
              H_VALID = 10'd640,
              H_RIGHT = 10'd8,
              H_FRONT = 10'd8,
              H_TOTAL = 10'd800;

    parameter V_SYNC = 10'd2,
              V_BACK = 10'd25,
              V_TOP = 10'd8,
              V_VALID = 10'd480,
              V_BOTTOM = 10'd8,
              V_FRONT = 10'd2,
              V_TOTAL = 10'd525;
    
    reg[9:0] h_cnt;
    reg[9:0] v_cnt;

    reg     vsync_r_ff0;
    reg     vsync_r_ff1;

    reg     hsync_r_ff0;
    reg     hsync_r_ff1;

    wire     vga_data_valid;
    wire     vga_data_valid_pre3;

    assign vga_valid = vga_data_valid;
    assign vga_valid_pre3 = vga_data_valid_pre3;

    //行扫描
    always @(posedge vga_clk or negedge rst_n) begin
        if(!rst_n) begin
            h_cnt <= 10'd0;
        end
        else if(h_cnt == H_TOTAL-1) begin
            h_cnt <= 10'd0;
        end
        else begin
            h_cnt <= h_cnt + 1'b1;
        end
    end

    //列扫描
    always @(posedge vga_clk or negedge rst_n) begin
        if(!rst_n) begin
            v_cnt <= 10'd0;
        end
        else if((h_cnt == H_TOTAL-1) && (v_cnt == V_TOTAL-1)) begin
            v_cnt <= 10'd0;
        end
        else if(h_cnt == H_TOTAL-1) begin
            v_cnt <= v_cnt + 1'b1;
        end
    end

    always @(posedge vga_clk or negedge rst_n) begin
        if(!rst_n) begin
            vsync_r_ff0 <= 0;
            vsync_r_ff1 <= 0;
        end
        else begin
            vsync_r_ff0 <= vga_vsync;
            vsync_r_ff1 <= vsync_r_ff0;
        end
    end

    assign vsync_r_pos = (vsync_r_ff0 && ~vsync_r_ff1);
    
    always @(posedge vga_clk or negedge rst_n) begin
        if(!rst_n) begin
            hsync_r_ff0 <= 0;
            hsync_r_ff1 <= 0;
        end
        else begin
            hsync_r_ff0 <= vga_hsync;
            hsync_r_ff1 <= hsync_r_ff0;
        end
    end

    assign hsync_r_pos = (hsync_r_ff0 && ~hsync_r_ff1);

    assign vga_hsync = (h_cnt <= H_SYNC-1'b1)? 1'b0: 1'b1;
    assign vga_vsync = (v_cnt <= V_SYNC-1'b1)? 1'b0: 1'b1;

    assign vga_data_valid = ((h_cnt >= H_SYNC+H_BACK+H_LEFT) &&
                            (h_cnt < H_SYNC+H_BACK+H_LEFT+H_VALID) &&
                            (v_cnt >= V_SYNC+V_BACK+V_TOP) &&
                            (v_cnt < V_SYNC+V_BACK+V_TOP+V_VALID))? 1'b1: 1'b0;
    
    assign vga_data_valid_pre3 = ((h_cnt >= H_SYNC+H_BACK+H_LEFT-2'd3) &&
                            (h_cnt < H_SYNC+H_BACK+H_LEFT+H_VALID-2'd3) &&
                            (v_cnt >= V_SYNC+V_BACK+V_TOP) &&
                            (v_cnt < V_SYNC+V_BACK+V_TOP+V_VALID))? 1'b1: 1'b0;

    assign vga_data = vga_data_valid? rgb_data: 12'd0;

    assign pixel_x = vga_data_valid? (h_cnt-H_SYNC-H_BACK-H_LEFT): 10'h3ff;

    assign pixel_y = vga_data_valid? (v_cnt-V_SYNC-V_BACK-V_TOP): 10'h3ff;
endmodule
