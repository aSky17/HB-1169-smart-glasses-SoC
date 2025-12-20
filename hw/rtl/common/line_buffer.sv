// line_buffer.sv
// This module is a line buffer for the SLAM system.
// Parameterized line buffer for image streaming pipelines
// It is used to store the current, previous, and next lines of the image.

/* Example:
current_pixel        = pixel_in
pixel_from_row-1     = line_out[0]
pixel_from_row-2     = line_out[1]
pixel_from_row-3     = line_out[2]
...
*/

module line_buffer #(
    parameter int DATA_WIDTH = 8;
    parameter int IMAGE_WIDTH = 640;
    parameter int NUM_LINES = 2; // number of previous rows to store
) (
    input logic clk,
    input logic [DATA_WIDTH-1:0] pixel_in,
    input logic pixel_valid,
    
    output logic [DATA_WIDTH-1:0] line_out[NUM_LINES-1:0];
);

    // Internal: NUM_LINES shift buffers, each as a FIFO of depth IMAGE_WIDTH
    logic [DATA_WIDTH-1:0] line_buf[NUM_LINES-1:0][IMAGE_WIDTH-1:0];
    logic [$clog2(IMAGE_WIDTH)-1:0] ptr = '0; //same pointer for read and write

    // COLUMN POINTER
    // pointer increments with each valid pixel
    // if it wraps, we move to the next row, logically
    always_ff @(posedge clk) begin   
        if(pixel_valid) begin 
            if (ptr == IMAGE_WIDTH-1) begin
                ptr <= '0;
            end else begin
                ptr <= ptr + 1''b1;
            end
        end
        // no need of else case as always_ff infer to a flip-flop, 
        // so if pixel_valid is low, wptr will hold its value
    end

    // Line buffer shifting logic
    integer i;
    always_ff @(posedge clk) begin
        if (pixel_valid) begin
            // shift from bottom to top
            for (i = NUM_LINES-1; i > 0; i--) begin
                line_buf[i][ptr] <= line_buf[i-1][ptr];
            end

            // newest pixel goes into first line buffer
            line_buf[0][ptr] <= pixel_in;
        end
    end

    // Registered outputs (synchronous read)
    generate
        genvar j;
        for (j = 0; j < NUM_LINES; j++) begin : GEN_OUT
            always_ff @(posedge clk) begin
                if (pixel_valid)
                    line_out[j] <= line_buf[j][ptr];
            end
        end
    endgenerate

endmodule

/* Issues came: (in earlier versions)

1. The Reset Issue (rst_n)
Code: linebuf[i][wptr] <= '0; inside the reset block.
Problem: Real RAM blocks (BRAM/SRAM) cannot be reset instantly. To reset 100k bits of memory, you need a loop that runs for many cycles.
Result: The synthesis tool will refuse to use BRAM. It will implement this entire array using Flip-Flops (Registers).
Cost: For a 640px wide buffer, this uses ~10,000 registers. For 1080p, it uses ~30,000. This is huge and inefficient.

2. The Asynchronous Read
Code: assign line_out = linebuf[wptr];
Problem: High-density Block RAMs are Synchronous Read (the data comes out 1 clock cycle after you provide the address). This code demands the data immediately (combinational path).
Result: Again, this forces the tool to use LUTRAM (Distributed RAM) or Registers, which are expensive and scarce compared to Block RAM.
*/

// Resetting line_buf[][] forces register inference
// to infer BRAM, we completely remove the reset block and the rst_n signal

// BRAMs are write-first / read-first / no-change, but always clocked
// Combinational reads (assign line_out = ...) break BRAM inference