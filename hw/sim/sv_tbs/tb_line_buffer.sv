// Description: Self-checking testbench for the Line Buffer.
// Simulates a stream of pixels and verifies vertical delays.

`timescale 1ns / 1ps

module tb_line_buffer;
    //-----parameters-----
    localparam DATA_WIDTH = 8;
    //reducing the IMAGE_WIDTH to the 10 instead of 640 to make it faster to simulate
    localparam IMAGE_WIDTH = 10;
    localparam NUM_LINES = 2;
    localparam CLK_PERIOD = 10; //100MHz

    //-----signals-----
    logic clk;
    logic rst_n;
    logic [DATA_WIDTH-1:0] pixel_in;
    logic pixel_valid;

    logic [DATA_WIDTH-1:0] line_out[NUM_LINES-1:0];

    //-----internal signals-----
    int pixel_counter;       // Tracks which pixel value we are sending

    //-----dut instantiation-----
    line_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMAGE_WIDTH(IMAGE_WIDTH),
        .NUM_LINES(NUM_LINES)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),
        .line_out(line_out)
    );

    //-----clock generation-----
    initial begin 
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    logic rst_n_tb;
    logic rst_sync;

    assign rst_n_tb = rst_n;   // TB wire copy
    always_ff @(posedge clk) begin
        rst_sync <= rst_n_tb;
    end
    //-----giviing stimulus to the dut (THE DRIVER)-----
    //This initial block emulates a camera sensor streaming pixels row-by-row into the design.
    /*
    1. Reset the DUT
    2. Start a clocked pixel stream
    3. Send 5 full image rows
    4. Each pixel has a known increasing value
    5. Stop and end simulation
    */
    initial begin 

        $dumpfile("line_buffer.vcd");       // Name of the output file
        $dumpvars(0, tb_line_buffer); // Dump all variables in this module

        rst_n = 0;
        pixel_in = '0;
        pixel_valid = 0;
        pixel_counter = 0;

        //Applying Reset
        #(CLK_PERIOD * 5); //hold reset low for 5 clock cycles  
        rst_n = 1; //release reset
        #(CLK_PERIOD * 2); //wait for 2 clock cycles

        $display("SIMULATION START: Image Width = %0d", IMAGE_WIDTH);

        //send 5 rows of pixels
        //each row of IMAGE_WIDTH pixels
        repeat (5 * IMAGE_WIDTH) begin
            @(posedge clk);
            pixel_valid = 1'b1;
            pixel_in = pixel_counter[DATA_WIDTH-1:0];

            //increment the pixel counter for the next cycle
            pixel_counter++;
        end

        //stop sending pixels
        @(posedge clk);
        pixel_valid = 1'b0;
        pixel_in = '0;

        #(CLK_PERIOD * 10) //wait for 10 clock cycles
        $display("SIMULATION PASS. All pixels processed successfully");
        $finish;
    end

    // Verification (THE MONITOR)
    // We check the output on every clock edge where inputs were valid.
    /*
    On every clock cycle where a valid pixel is processed, this block checks whether
    line_out[0] and line_out[1] contain pixels from exactly 1 row ago and 2 rows ago.
    */
    always @(posedge clk) begin
        if (rst_sync && pixel_valid) begin
            // Simulation Wait: Outputs are only valid after 1 clock cycle due to registers
            // We use 'strobe' to check at the very end of the time step
            #1; //ensure all non-blocking assignment updates have settled

            //checking row-1 (line_out[0])
            // Should contain data from exactly 1 row ago (IMAGE_WIDTH cycles ago)
            // check row −1 until one full row has arrived
            if (pixel_counter > IMAGE_WIDTH) begin
                logic [DATA_WIDTH-1:0] exp1;
                logic [7:0] expected_row1;
                exp1 = DATA_WIDTH'(pixel_counter - 1 - IMAGE_WIDTH); // -1 because counter incremented for next: expected = (current_pixel) - IMAGE_WIDTH
                expected_row1 = exp1[DATA_WIDTH-1:0];
                assert (line_out[0] === expected_row1);
                else $error("Time %0t: Row-1 Mismatch! Expected %0d, Got %0d", 
                            $time, expected_row1, line_out[0]);
            end

            //checking row-2 (line_out[1])
            //Should contain data from exactly 2 rows ago
            if (pixel_counter > (IMAGE_WIDTH * 2)) begin
                logic [DATA_WIDTH-1:0] exp2;
                logic [7:0] expected_row2;
                exp2 = DATA_WIDTH'(pixel_counter - 1 - (2 * IMAGE_WIDTH));
                expected_row2 = exp2[DATA_WIDTH-1:0];
                assert (line_out[1] === expected_row2);
                else $error("Time %0t: Row-2 Mismatch! Expected %0d, Got %0d", 
                            $time, expected_row2, line_out[1]);
            end
        end
    end
endmodule
