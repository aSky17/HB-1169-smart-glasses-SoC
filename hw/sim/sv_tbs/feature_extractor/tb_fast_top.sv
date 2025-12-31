// tb_fast_top.sv

`timescale 1ns /1 ps

module tb_fast_top;

    localparam int DATA_WIDTH = 8;
    localparam int N = 9;
    localparam int CLK_PERIOD = 10;

    logic clk;
    logic rst_n;

    logic window_valid;
    logic [DATA_WIDTH-1:0] window[0:6][0:6];
    logic [DATA_WIDTH-1:0] threshold;

    logic out_valid;
    logic is_corner;
    logic [DATA_WIDTH-1:0] score;

    // DUT
    fast_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .FAST_N(N)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .window_valid (window_valid),
        .window       (window),
        .threshold    (threshold),
        .out_valid    (out_valid),
        .is_corner    (is_corner),
        .score        (score)
    );

    /* verilator lint_off BLKSEQ */
    always #(CLK_PERIOD/2) clk = ~clk;
    /* verilator lint_on BLKSEQ */

    integer r, c;
    integer errors;

    initial begin
        $dumpfile("fast_top.vcd");
        $dumpvars(0, tb_fast_top);
    end

    initial begin
        clk = 0;
        rst_n = 0;
        window_valid = 0;
        threshold = 8'd20;
        errors = 0;

        // Clear window
        for (r = 0; r < 7; r++)
            for (c = 0; c < 7; c++)
                window[r][c] = 8'd0;

        // Reset
        #(3*CLK_PERIOD);
        rst_n = 1;

        // TEST: Bright FAST corner 
        // Center = 100
        // FAST circle pixels around = 130–150
        // Min diff = 20 → score = 20'

        //fill the entire window with the center value
        for (r = 0; r < 7; r++)
            for (c = 0; c < 7; c++)
                window[r][c] = 8'd100;

        // FAST-16 circle (radius = 3)
        window[0][3] = 8'd140;
        window[0][4] = 8'd135;
        window[1][5] = 8'd130;
        window[2][6] = 8'd150;
        window[3][6] = 8'd145;
        window[4][6] = 8'd140;
        window[5][5] = 8'd135;
        window[6][4] = 8'd130;
        window[6][3] = 8'd121;
        window[6][2] = 8'd130;
        window[5][1] = 8'd135;
        window[4][0] = 8'd140;
        window[3][0] = 8'd145;
        window[2][0] = 8'd150;
        window[1][1] = 8'd135;
        window[0][2] = 8'd130;

        @(posedge clk);
        window_valid = 1'b1;

        @(posedge clk);
        window_valid = 1'b0;

        // Wait for pipeline output
        while (!out_valid)
            @(posedge clk);

        //checking results
        $display("FAST TOP RESULT:");
        $display("is_corner = %0b", is_corner);
        $display("score     = %0d", score);

        if (is_corner !== 1'b1) begin
            $error("FAST TOP FAILED: expected is_corner = 1");
            errors++;
        end

        if (score !== 8'd21) begin
            $error("FAST TOP FAILED: expected score = 20");
            errors++;
        end

        // final result
        if (errors == 0)
            $display("FAST TOP END-TO-END TEST PASSED");
        else
            $display("FAST TOP END-TO-END TEST FAILED(%0d errors)", errors);

        $finish;
    end

endmodule
