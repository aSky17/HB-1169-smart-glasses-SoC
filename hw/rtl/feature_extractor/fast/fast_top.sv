// fast_top.sv
// Top level FAST corner detector
// integrates:
// -fast_circle_sampler.sv
// -fast_thresh_cmp.sv
// -fast_segment_test.sv
// -fast_score.sv

`timescale 1ns / 1ps

module fast_top #(
    parameter int DATA_WIDTH = 8,
    parameter int FAST_N = 9
) (
    input logic clk,
    input  logic rst_n,

    input logic window_valid,
    input logic [DATA_WIDTH-1:0] window[0:6][0:6],
    input logic [DATA_WIDTH-1:0] threshold,
    
    output logic out_valid,
    output logic is_corner,
    output logic [DATA_WIDTH-1:0] score
);

    // Cicle sampler outputs
    logic circle_valid;
    logic [DATA_WIDTH-1:0] center_pixel;
    logic [DATA_WIDTH-1:0] circle_pixel[0:15];

    // Threshold compare outputs
    logic threshold_valid;
    logic [15:0] bright_mask;
    logic [15:0] dark_mask;

    // Segment test outputs
    logic segment_valid;
    logic is_corner_int;

    // Score outputs
    logic score_valid;
    logic [DATA_WIDTH-1:0] score_int;

    //instantiating fast_circle_sampler
    fast_circle_sampler #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_circle_sampler (
        .clk(clk),
        .rst_n(rst_n),
        .window_valid (window_valid),
        .window(window),
        .circle_valid(circle_valid),
        .center_pixel(center_pixel),
        .circle_pixel(circle_pixel)
    );

    //instantiating fast_thresh_cmp
    fast_thresh_cmp #(
        .DATA_WIDTH(DATA_WIDTH),
        .THRESH_WIDTH(DATA_WIDTH)
    ) u_thresh_cmp (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(circle_valid),
        .center_pixel(center_pixel),
        .circle_pixel(circle_pixel),
        .threshold(threshold),
        .out_valid(threshold_valid),
        .bright_mask(bright_mask),
        .dark_mask(dark_mask)
    );

    //instantiating fast_segment_test
    fast_segment_test #(
        .N(FAST_N)
    ) u_segment_test (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(threshold_valid),
        .bright_mask(bright_mask),
        .dark_mask(dark_mask),
        .out_valid(segment_valid),
        .is_corner(is_corner_int)
    );

    //instantiating fast_score
    fast_score #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_fast_score (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(segment_valid),
        .is_corner(is_corner_int),
        .center_pixel(center_pixel),
        .circle_pixel(circle_pixel),
        .bright_mask(bright_mask),
        .dark_mask(dark_mask),
        .output_valid(score_valid),
        .score(score_int)
    );

    // final outputs
    assign out_valid = score_valid;
    assign is_corner = is_corner_int;
    assign score = score_int;

endmodule
