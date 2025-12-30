// fast_thresh_cmp.sv
// FAST threshold comparison stage
// Generates bright and dark masks for FAST segment test
// Tells which of the 16 circle pixels are significantly brighter than center
// and which are significantly darker than center
// eg: bright_mask = 1111_0000_0000_0000 means Pixels 12, 13, 14, 15 are bright, All others are not
// dark_mask = 0000_0000_0000_1111 means Pixels 0, 1, 2, 3 are dark All others are not
// we need BOTH bright and dark masks because FAST corners can be
// 1. Bright object on dark background
// 2. Dark object on bright background

`timescale 1ns / 1ps

module fast_thresh_cmp #(
    parameter int DATA_WIDTH   = 8,
    parameter int THRESH_WIDTH = 8
)(
    input  logic clk,
    input  logic rst_n,

    input  logic in_valid,
    input  logic [DATA_WIDTH-1:0] center_pixel,
    input  logic [DATA_WIDTH-1:0] circle_pixel [0:15],
    input  logic [THRESH_WIDTH-1:0] threshold,

    output logic out_valid,
    output logic [15:0] bright_mask,
    output logic [15:0] dark_mask
);
    

    //stage-1 registers
    logic in_valid_r;
    logic [DATA_WIDTH-1:0] center_pixel_r;
    logic [DATA_WIDTH-1:0] circle_pixel_r [0:15];
    logic [THRESH_WIDTH-1:0] threshold_r;

    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_valid_r <= 1'b0;
            center_pixel_r <= '0;
            threshold_r <= '0;
            for (i = 0; i < 16; i++)
                circle_pixel_r[i] <= '0;
        end else begin
            in_valid_r      <= in_valid;
            center_pixel_r <= center_pixel;
            threshold_r    <= threshold;
            for (i = 0; i < 16; i = i + 1)
                circle_pixel_r[i] <= circle_pixel[i];
        end
    end

    logic [15:0] bright_mask_c;
    logic [15:0] dark_mask_c;

    logic [DATA_WIDTH:0] center_plus_t;
    logic [DATA_WIDTH:0] center_minus_t;


    integer j;
    always_comb begin
        center_plus_t  = center_pixel_r + threshold_r;
        center_minus_t = center_pixel_r - threshold_r;

        for (j = 0; j < 16; j++) begin
            bright_mask_c[j] = ({1'b0, circle_pixel_r[j]} > center_plus_t);
            dark_mask_c[j]   = ({1'b0, circle_pixel_r[j]} < center_minus_t);
        end
    end


    //stage-2: registering output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid   <= 1'b0;
            bright_mask <= '0;
            dark_mask   <= '0;
        end else begin
            out_valid   <= in_valid_r;
            bright_mask <= bright_mask_c;
            dark_mask   <= dark_mask_c;
        end
    end
endmodule
