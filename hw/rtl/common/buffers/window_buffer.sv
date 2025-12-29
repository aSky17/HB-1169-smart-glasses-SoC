//window_buffer.sv
//works as a sliding window - kinda a lens for an image with pixels arranged in the grid format
//horizontal shift registers and vertical line buffers

`timescale 1ns / 1ps

module window_buffer #(
    parameter int DATA_WIDTH = 8,
    parameter int IMAGE_WIDTH = 640,
    parameter int WIN_SIZE = 3
) (
    input logic clk,
    input logic rst_n,
    input logic pixel_valid,
    input logic [DATA_WIDTH-1:0] pixel_in,

    //from line buffer
    input logic [DATA_WIDTH-1:0] line_out[WIN_SIZE-2:0],

    output logic [DATA_WIDTH-1:0] window_out [WIN_SIZE-1:0][WIN_SIZE-1:0],
    output logic window_valid
);

    localparam int H_CNT_WIDTH = $clog2(IMAGE_WIDTH);

    //shift_registers
    logic [DATA_WIDTH-1:0] shift_reg [WIN_SIZE-1:0][WIN_SIZE-1:0];
    logic [H_CNT_WIDTH-1:0] h_cnt;

    // Column counter
    localparam int PTR_WIDTH = $clog2(IMAGE_WIDTH);
    localparam int LAST_COL_INT = IMAGE_WIDTH - 1;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            h_cnt <= '0;
        else if (pixel_valid) begin
            if (h_cnt == LAST_COL_INT[PTR_WIDTH-1:0])
                h_cnt <= '0;
            else
                h_cnt <= h_cnt + 1'b1;
        end
    end

    // Horizontal shifting    
    integer r, c;
    always_ff @(posedge clk) begin
        if (pixel_valid) begin

            //implements a parallel shift register 
            //The pixel at [c+1] (the newer one) moves into the slot at [c] (the older one).
            //The pixel that was at [0] (the oldest) is pushed out and discarded.
            for (r = 0; r < WIN_SIZE; r++) begin
                for (c = 0; c < WIN_SIZE-1; c++) begin
                    shift_reg[r][c] <= shift_reg[r][c+1];
                end
            end

            // Insert new rightmost column
            shift_reg[0][WIN_SIZE-1] <= pixel_in;
            for (r = 1; r < WIN_SIZE; r++) begin
                shift_reg[r][WIN_SIZE-1] <= line_out[r-1];
            end
        end
    end
    
    // Window output wiring
    genvar i, j;
    generate
        for (i = 0; i < WIN_SIZE; i++) begin : ROWS
            for (j = 0; j < WIN_SIZE; j++) begin : COLS
                assign window_out[i][j] = shift_reg[i][j];
            end
        end
    endgenerate

    // Window valid
    localparam logic [H_CNT_WIDTH-1:0] WIN_START_THRESHOLD = (H_CNT_WIDTH)'(WIN_SIZE - 1);
    // Window valid: It should ONLY be high if pixel_valid is currently high
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            window_valid <= 1'b0;
        else
            // Added pixel_valid here to ensure the signal drops when the stream stops
            window_valid <= pixel_valid && (h_cnt >= WIN_START_THRESHOLD);
    end
    
endmodule
