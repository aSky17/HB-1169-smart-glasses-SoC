`timescale 1ns / 1ps

module tb_window_buffer;

    // ----- Parameters -----
    localparam int DATA_WIDTH  = 8;
    localparam int IMAGE_WIDTH = 10; 
    localparam int WIN_SIZE    = 3;
    localparam int CLK_PERIOD  = 10;

    // ----- Signals -----
    logic clk;
    logic rst_n;
    logic pixel_valid;
    logic [DATA_WIDTH-1:0] pixel_in;
    logic [DATA_WIDTH-1:0] line_out [WIN_SIZE-2:0];

    logic [DATA_WIDTH-1:0] window_out [WIN_SIZE-1:0][WIN_SIZE-1:0];
    logic window_valid;

    // ----- DUT Instantiation -----
    window_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMAGE_WIDTH(IMAGE_WIDTH),
        .WIN_SIZE(WIN_SIZE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_valid(pixel_valid),
        .pixel_in(pixel_in),
        .line_out(line_out),
        .window_out(window_out),
        .window_valid(window_valid)
    );

    // ----- Clock Generation -----
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ----- Driver Process -----
    initial begin
        $dumpfile("window_buffer.vcd");
        $dumpvars(0, tb_window_buffer);

        // Blocking assignments (=) for stimulus initialization
        rst_n = 0;
        pixel_in = '0;
        pixel_valid = 0;
        for (int i=0; i<WIN_SIZE-1; i++) line_out[i] = '0;

        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        $display("---------------------------------------------------------");
        $display("STARTING WINDOW BUFFER SIMULATION");
        $display("---------------------------------------------------------");

        for (int r = 0; r < 5; r++) begin
            for (int c = 0; c < IMAGE_WIDTH; c++) begin
                @(posedge clk);
                pixel_valid = 1'b1;
                // Explicitly cast the result to 8 bits to satisfy WIDTHTRUNC
                pixel_in    = DATA_WIDTH'((r * 10) + c); 
                
                if (r >= 1) line_out[0] = DATA_WIDTH'(((r-1) * 10) + c); 
                if (r >= 2) line_out[1] = DATA_WIDTH'(((r-2) * 10) + c);
            end
        end

        @(posedge clk);
        pixel_valid = 1'b0;
        
        #(CLK_PERIOD * 10);
        $display("SIMULATION COMPLETE");
        $finish;
    end

    // ----- Monitor/Checker -----
    always @(negedge clk) begin
        // Removed rst_n to satisfy SYNCASYNCNET
        if (window_valid) begin
            $display("Time: %5t | Center Pixel: %3d", $time, window_out[1][1]);
            
            // Verifying the sliding property: Neighbors should be sequential
            if (window_out[0][1] != (window_out[0][0] + 1'b1)) begin
                $error("Mismatch: Window[0][0]=%0d, Window[0][1]=%0d", 
                        window_out[0][0], window_out[0][1]);
            end
        end
    end

endmodule
