// tb_fast_segment_test.sv

`timescale 1ns / 1ps

module tb_fast_segment_test;

    localparam int N = 9; //FAST-9
    localparam int CLK_PERIOD = 10;

    logic clk;
    logic rst_n;

    logic in_valid;
    logic [15:0] bright_mask;
    logic [15:0] dark_mask;

    logic out_valid;
    logic is_corner;

    
    fast_segment_test #(
        .N(N)    
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .bright_mask(bright_mask),
        .dark_mask(dark_mask),
        .out_valid(out_valid),
        .is_corner(is_corner)
    );


    /* verilator lint_off BLKSEQ */
    always #(CLK_PERIOD/2) clk = ~clk;
    /* verilator lint_on BLKSEQ */

    initial begin
        $dumpfile("fast_segment_test.vcd");
        $dumpvars(0, tb_fast_segment_test);
    end

    integer errors;

    initial begin
        clk = 0;
        rst_n = 0;
        in_valid = 0;
        bright_mask = 16'b0;
        dark_mask = 16'b0;
        errors = 0;

        //reset
        #(3*CLK_PERIOD);
        rst_n = 1;
        
        // TEST 1: VALID FAST CORNER (bright arc of 9)
        // Bits 12 to 4 (wrap-around) = 9 contiguous 1s
        bright_mask = 16'b1111_1111_1000_0000;
        dark_mask = 16'b0;

        @(posedge clk);
        in_valid = 1'b1;

        @(posedge clk);
        in_valid = 1'b0;

        while (!out_valid)
            @(posedge clk);
        
        $display("TEST 1:");
        $display("bright_mask = %b", bright_mask);
        $display("is_corner   = %0b", is_corner);

        if (is_corner !== 1'b1) begin
            $error("TEST 1 FAILED: expected is_corner=1");
            errors++;
        end

        // TEST 2: INVALID (no contiguous run of 9)
        bright_mask = 16'b1010_1010_1010_1010; // alternating
        dark_mask   = 16'b0;

        @(posedge clk);
        in_valid = 1'b1;

        @(posedge clk);
        in_valid = 1'b0;

        while (!out_valid)
            @(posedge clk);

        $display("TEST 2:");
        $display("bright_mask = %b", bright_mask);
        $display("is_corner   = %0b", is_corner);

        if (is_corner !== 1'b0) begin
            $error("TEST 2 FAILED: expected is_corner=0");
            errors++;
        end

        // TEST 3: VALID DARK ARC
        bright_mask = 16'b0;
        dark_mask   = 16'b0000_1111_1111_1110; // 9 contiguous dark

        @(posedge clk);
        in_valid = 1'b1;

        @(posedge clk);
        in_valid = 1'b0;

        while (!out_valid)
            @(posedge clk);

        $display("TEST 3:");
        $display("dark_mask = %b", dark_mask);
        $display("is_corner = %0b", is_corner);

        if (is_corner !== 1'b1) begin
            $error("TEST 3 FAILED: expected is_corner=1");
            errors++;
        end

        //result
        if (errors == 0)
            $display("FAST SEGMENT TEST PASSED");
        else
            $display("FAST SEGMENT TEST FAILED(%0d errors)", errors);

        $finish;
    end

endmodule
