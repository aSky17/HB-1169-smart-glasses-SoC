// frame_buffer.sv
// stores complete image frame and provides random pixel access
// Description: 
//      - Sequential write, rnadom read
//      - Synchronous memory (2 cycle read latency) 
//          Cycle 0: You set read_x, read_y, and read_enable.
//          Cycle 1: rd_addr is updated. 
//          Cycle 2: read_pixel is updated with data from mem[rd_addr]
//      - No reset on pixel memory
//      - Only counter controls are reset
//      - Boundary handling should be done by the orientor or the descriptor 

`timescale 1ns / 1ps

module frame_buffer #(
    parameter int DATA_WIDTH = 8,
    parameter int IMAGE_WIDTH = 640,
    parameter int IMAGE_HEIGHT = 480
) (
    input logic clk,
    input logic rst_n,

    input logic pixel_valid,
    input logic [DATA_WIDTH-1:0] pixel_in,

    input logic read_enable,
    input logic [$clog2(IMAGE_WIDTH)-1:0] read_x,
    input logic [$clog2(IMAGE_HEIGHT)-1:0] read_y,
    output logic [DATA_WIDTH-1:0] read_pixel
);

    localparam int FRAME_SIZE = IMAGE_HEIGHT * IMAGE_WIDTH;
    localparam int ADDR_WIDTH = $clog2(FRAME_SIZE);

    ///memory
    logic [DATA_WIDTH-1:0] mem [0:FRAME_SIZE-1];

    //write address generation
    logic [$clog2(IMAGE_WIDTH)-1:0] wr_x;
    logic [$clog2(IMAGE_HEIGHT)-1:0] wr_y;
    logic [ADDR_WIDTH-1:0] wr_addr;

    //column counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_x <= '0;
        end else if (pixel_valid) begin
            if (wr_x == IMAGE_WIDTH-1) begin
                wr_x <= '0;
            end else begin
                wr_x <= wr_x + 1'b1;
            end
        end
    end

    //row counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_y <= '0;
        end else if (pixel_valid && wr_x == IMAGE_WIDTH-1) begin
            if (wr_y == IMAGE_HEIGHT-1) begin
                wr_y <= '0;
            end else begin
                wr_y <= wr_y + 1'b1;
            end
        end
    end

    //linear addr
    assign wr_addr = wr_y * IMAGE_WIDTH + wr_x;

    // write port (synchronous)
    always_ff @(posedge clk) begin
        if (pixel_valid) begin
            mem[wr_addr] <= pixel_in;
        end
    end

    //read address
    logic [ADDR_WIDTH-1:0] rd_addr;

    always_ff @(posedge clk) begin
        if (read_enable) begin
            rd_addr <= rd_y * IMAGE_WIDTH + rd_x;
        end 
    end

    always_ff @(posedge clk) begin
        if (read_enable) begin
            read_pixel <= mem[rd_addr];
        end
    end
    
endmodule