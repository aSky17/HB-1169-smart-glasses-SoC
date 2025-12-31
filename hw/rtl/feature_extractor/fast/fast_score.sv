// fast_score.sv
// we want to check how strong is a corner, so we'll calculate a fast score
// Score = minimum absolute difference over the detected arc
// so fast_score defines a corner strength so that NMS can keep strong corners, suppress weak ones, choose the best corner in a neighborhood
// Intuition: A corner is stronger if the circle pixels are much more different from the center
// we take the min difference of the circle_pixel[i] and center_pixel 
// If you want to find the maximum possible threshold that still makes this pixel a corner, you look for the smallest difference in that arc.
// the minimum difference represents the "stability" or "robustness" of that corner.
// This corner is only as strong as its weakest supporting pixel.
// also we need bright_mask and dark_mask to ensure that we calculate the score of only pixels who has initially passed the threshold test

`timescale 1ns / 1ps

module fast_score #(
    parameter int DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst_n,

    input logic in_valid,
    input logic is_corner,
    input logic [DATA_WIDTH-1:0] center_pixel,
    input logic [DATA_WIDTH-1:0] circle_pixel[0:15],
    input logic [15:0] bright_mask,
    input logic [15:0] dark_mask,

    output logic output_valid,
    output logic [DATA_WIDTH-1:0] score
);
    
    //stage-1 registers
    logic in_valid_r;
    logic is_corner_r;
    logic [DATA_WIDTH-1:0] center_pixel_r;
    logic [DATA_WIDTH-1:0] circle_pixel_r[0:15];
    logic [15:0] bright_mask_r;
    logic [15:0] dark_mask_r;

    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_valid_r <= 1'b0;
            is_corner_r <= 1'b0;
            center_pixel_r <= '0;
            bright_mask_r <= '0;
            dark_mask_r <= '0;
            for (i = 0; i < 16; i++)
                circle_pixel_r[i] <= '0;
        end else begin
            in_valid_r <= in_valid;
            is_corner_r <= is_corner;
            center_pixel_r <= center_pixel;
            bright_mask_r <= bright_mask;
            dark_mask_r <= dark_mask;
            for (i = 0; i < 16; i++)
                circle_pixel_r[i] <= circle_pixel[i];
        end
    end

    //score computation: combinational block
    logic [DATA_WIDTH-1:0] score_c;
    logic [DATA_WIDTH-1:0] diff;

    integer j;
    always_comb begin
        //initializing score to max
        score_c = {DATA_WIDTH{1'b1}};

        if (!is_corner_r) begin
            score_c = '0;
        end else begin
            for (j = 0; j < 16; j++) begin

                if (bright_mask_r[j]) begin
                    diff = circle_pixel_r[j] - center_pixel_r;
                    if (diff < score_c) begin
                        score_c = diff;
                    end
                end

                if (dark_mask_r[j]) begin
                    diff = center_pixel_r - circle_pixel_r[j];
                    if (diff < score_c) begin
                        score_c = diff;
                    end
                end
            end
        end
    end

    //stage-2 registering output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_valid <= 1'b0;
            score <= '0;
        end else begin
            output_valid <= in_valid_r;
            score <= score_c;
        end
    end

endmodule
