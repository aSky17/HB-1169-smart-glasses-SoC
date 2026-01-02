// nms_top.sv
// NMS windowing is just a score window, not a pixel window
// delay the center pixel until all neighbors exist
// use previous row line buffer
// use horizontal registers for left/right
// Full 3×3 window for center (x, y):
// Position 	Source
// (x-1, y-1)	linebuf + shift
// (x, y-1)	linebuf
// (x+1, y-1)	linebuf + lookahead
// (x-1, y)	shift reg
// (x, y)	delayed center
// (x+1, y)	shift reg
// (x-1, y+1)	current row shift
// (x, y+1)	score_in
// (x+1, y+1)	future in same row

// Description:
// - Top-level Non-Maximum Suppression for FAST keypoints
// - Uses center-delay strategy with common line_buffe

`timescale 1ns / 1ps

module nms_top #(
    parameter int SCORE_WIDTH = 8,
    parameter int IMAGE_WIDTH = 640,
    parameter int IMAGE_HEIGHT = 480
) (
    input logic clk,
    input logic rst_n,

    //input from FAST
    input logic pixel_valid,
    input logic is_corner_in,
    input logic  [SCORE_WIDTH-1:0] score_in,

    //output keypoint
    output logic nms_valid, //is a local maximum or not
    output logic [SCORE_WIDTH-1:0] nms_score,
    //coordinates of the surviving corner, xdxdxd
    output logic [$clog2(IMAGE_WIDTH)-1:0] nms_x,
    output logic [$clog2(IMAGE_HEIGHT)-1:0] nms_y
);
    
    localparam int X_WIDTH = $clog2(IMAGE_WIDTH);
    localparam int Y_WIDTH = $clog2(IMAGE_HEIGHT);

    // x,y counters (stream position)
    logic [X_WIDTH-1:0] x_cnt;
    logic [Y_WIDTH-1:0] y_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt <= '0;
            y_cnt <= '0;
        end else if (pixel_valid) begin
            if (x_cnt == IMAGE_HEIGHT-1) begin
                x_cnt <= '0;
                y_cnt <= y_cnt + 1'b1;
            end else begin
                x_cnt = x_cnt + 1'b1;
            end
        end
    end

    // line buffer for previous rows
    logic [SCORE_WIDTH-1:0] previous_row_scores[0:1]; // previous_row_score[0] -> (x,y-1) || previous_row_score[1] -> (x,y-2)

    line_buffer #(
        .DATA_WIDTH(SCORE_WIDTH),
        .IMAGE_WIDTH(IMAGE_WIDTH),
        .NUM_LINES(2)
    ) u_nms_linebuf(
        .clk(clk),
        .rst_n(rst_n),
        .pixel_in(score_in),
        .pixel_valid(pixel_valid),
        .line_out(previous_row_scores)
    );

    // horizontal shift registers (3 COLUMNS)
    // left neighbor arrived earlier, right neighborr arrives later --> shift registers  aligns them in one cycle
    logic [SCORE_WIDTH-1:0] row0 [0:2]; // (x-1,y-1), (x,y-1), (x+1,y-1)  -> y-1
    logic [SCORE_WIDTH-1:0] row1 [0:2]; // (x-1,y), (x,y), (x+1,y)        -> y
    logic [SCORE_WIDTH-1:0] row2 [0:2]; // (x-1,y+1), (x,y+1), (x+1,y+1)  -> y+1

    always_ff @(posedge clk) begin
        if (pixel_valid) begin
            //shift left
            row0[0] <= row0[1];
            row0[1] <= row0[2];

            row1[0] <= row1[1];
            row1[1] <= row1[2];

            row2[0] <= row2[1];
            row2[1] <= row2[2];

            //insert newest column
            row0[2] <= previous_row_scores[0]; // (x,y-1)
            row1[2] <= previous_row_scores[1]; // delayed center row
            row2[2] <= previous_row_scores[2]; // (x, y+1)
        end
    end

    // Delay center metadata (score, is_corner, x, y)
    // Latency = IMAGE_WIDTH + 1
    logic [SCORE_WIDTH-1:0] center_score_d;
    logic center_is_corner_d;
    logic [X_WIDTH-1:0] center_x_d;
    logic [Y_WIDTH-1:0] center_y_d;

    always_ff @(posedge clk) begin
        if (pixel_valid) begin
            center_score_d <= previous_row_scores[1]; // center pixel is not the current input, it is the pixel from one row earlier bcz decision happens when (x,y+1) arrives
            center_is_corner_d <= is_corner_in;
            center_x_d <= x_cnt;
            center_y_d <= y_cnt - 1'b1;  // current input is row y+1, center is y
        end
    end

    // assemble neighbor scores for comparator
    assign neighbor[0] = row0[0]; // top-left
    assign neighbor[1] = row0[1]; // top
    assign neighbor[2] = row0[2]; // top-right
    assign neighbor[3] = row1[0]; // left
    assign neighbor[4] = row1[2]; // right
    assign neighbor[5] = row2[0]; // bottom-left
    assign neighbor[6] = row2[1]; // bottom
    assign neighbor[7] = row2[2]; // bottom-right

    //NMS comparator
    logic center_is_max;

    nms_compare #(
        .SCORE_WIDTH(SCORE_WIDTH)
    ) u_nms_compare (
        .is_corner_center(center_is_corner_d),
        .score_center(center_score_d),
        .score_neighbor(neighbor),
        .corner_is_max(center_is_max)
    );

    // border suppression(border lacks neighbor) + output register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nms_valid <= 1'b0;
        end else begin
            nms_valid <= pixel_valid &&
                         center_is_max && 
                         (center_x_d > 0) &&
                         (center_x_d < IMAGE_WIDTH-1) &&
                         (center_y_d > 0) &&
                         (center_y_d < IMAGE_HEIGHT-1);

            if (nms_valid) begin
                nms_score <= center_score_d;
                nms_x <= center_x_d;
                nms_y <= center_y_d;
            end
        end
    end

endmodule