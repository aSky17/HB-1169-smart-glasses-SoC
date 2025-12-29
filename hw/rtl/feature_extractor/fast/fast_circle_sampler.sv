// -----------------------------------------------------------------------------
// fast_circle_sampler.sv
// -----------------------------------------------------------------------------
// Extracts FAST-16 circle pixels from a 7x7 window.
// This module ONLY maps pixels. No comparisons, no thresholds.
//
// FAST circle radius = 3
//
// Window indexing convention:
//   window[row][col]
//   row = 0 : newest row (top)
//   row = 6 : oldest row (bottom)
//
// Center pixel = window[3][3]
//
// FAST-16 circle order (OpenCV-compatible):
//   0 : (0,3)   1 : (0,4)   2 : (1,5)   3 : (2,6)
//   4 : (3,6)   5 : (4,6)   6 : (5,5)   7 : (6,4)
//   8 : (6,3)   9 : (6,2)  10 : (5,1)  11 : (4,0)
//  12 : (3,0)  13 : (2,0)  14 : (1,1)  15 : (0,2)
// -----------------------------------------------------------------------------

`timescale  1ns / 1ps
module fast_circle_sampler #(
    parameter int DATA_WIDTH = 8;
) (
    input logic clk, 
    input logic rst_n,

    input logic window_valid,
    input logic [DATA_WIDTH-1:0] window[0:6][0:6],

    output logic circle_valid,
    output logic [DATA_WIDTH-1:0] center_pixel,
    output logic [DATA_WIDTH-1:0] circle_pixel[0:15] 
);

    
    
endmodule