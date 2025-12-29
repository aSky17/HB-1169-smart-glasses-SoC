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

    logic [DATA_WIDTH-1:0] center_c;
    logic [DATA_WIDTH-1:0] circle_c[0:15];

    always_comb begin

        //center pixel is at (3,3)
        center_c = window[3][3];
        
        //Bresenham circle: 16 pixels , radius = 3 i.e., 7x7 ka window
        circle_c[0] = window[0][3];
        circle_c[1]  = window[0][4];
        circle_c[2]  = window[1][5];
        circle_c[3]  = window[2][6];
        circle_c[4]  = window[3][6];
        circle_c[5]  = window[4][6];
        circle_c[6]  = window[5][5];
        circle_c[7]  = window[6][4];
        circle_c[8]  = window[6][3];
        circle_c[9]  = window[6][2];
        circle_c[10] = window[5][1];
        circle_c[11] = window[4][0];
        circle_c[12] = window[3][0];
        circle_c[13] = window[2][0];
        circle_c[14] = window[1][1];
        circle_c[15] = window[0][2];
    end
    
    //registering the outputs
    integer i;
    always_ff @( posedge clk or negedge rst_n ) begin
        if (!rst_n) begin
            center_pixel <= '0;
            circle_valid <= 1'b0;
            for (i = 0; i < 16;i++ ) begin
                circle_pixel[i] <= '0;
            end
        end else begin
            circle_valid <= window_valid;

            if (window_valid) begin

                center_pixel <= center_c;
                for (i = 0; i < 16;i++ ) begin
                    circle_pixel[i] <= circle_c[i];
                end 
            end
        end
    end
    
endmodule