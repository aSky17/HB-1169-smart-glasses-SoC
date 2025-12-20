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
    input logic rst_n,
    input logic [DATA_WIDTH-1:0] pixel_in,
    input logic pixel_valid,
    
    output logic [DATA_WIDTH-1:0] line_out[NUM_LINES-1:0];
);

    // Internal: NUM_LINES shift buffers, each as a FIFO of depth IMAGE_WIDTH
    logic [DATA_WIDTH-1:0] line_buf[NUM_LINES-1:0][IMAGE_WIDTH-1:0];
    logic [$clog2(IMAGE_WIDTH)-1:0] wptr;

    // Write pointer increments with each valid pixel
    // if it wraps, we move to the next row, logically
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wptr <= 0;    

        // It only moves if pixel_valid is high. If the camera pauses (blanking interval),
        // the buffer pauses too. This ensures alignment isn't lost during video blanking periods.    
        end else if(pixel_valid) begin 
            if (wpt == IMAGE_WIDTH-1) begin
                wptr <= 0;
            end else begin
                wptr <= wptr + 1''b1;
            end
        end
        // no need of else case as always_ff infer to a flip-flop, 
        // so if pixel_valid is low, wptr will hold its value
    end

    // Line Buffer Operation:
    // linebuf[0] <- stores previous row
    // linebuf[1] <- stores row before linebuf[0]

    // When a new pixel arrives:
    //   - shift all data up: the pixel that was in linebuf[i][wptr]
    //     moves to linebuf[i+1][wptr]
    //   - pixel_in goes into linebuf[0]
    //
    // This creates row-wise delays.

    genvar i;
    generate
        for (i = 0; i < NUM_LINES-1; i = i + 1) begin : gen_linebuf
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    line_buf[i][wptr] <= '0;
                end else if (pixel_valid) begin
                    if (i == 0) begin
                        line_buf[i][wptr] <= pixel_in; // first row gets new pixel
                    end else begin
                        line_buf[i][wptr] <= line_buf[i-1][wptr]; // other rows get the pixel from the previous row
                    end
                end
        end
    endgenerate

    // Output assignment: previous rows at aligned column

    generate
        for (i = 0; i < NUM_LINES; i = i + 1) begin : gen_output
            assign line_out[i] = line_buf[i][wptr];
        end
    endgenerate

endmodule
