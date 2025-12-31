// tb_fast_score.sv

`timescale 1ns / 1ps

module tb_fast_score;

    localparam int DATA_WIDTH = 8;
    localparam int CLK_PERIOD = 10;

    logic clk;
    logic rst_n;

    logic in_valid;
    logic is_corner;
    logic [DATA_WIDTH-1:0] center_pixel;
    logic [DATA_WIDTH-1:0] circle_pixel[0:15];
    logic [15:0] bright_mask;
    logic [15:0] dark_mask;

    logic output_valid;
    logic [DATA_WIDTH-1:0] score;

    fast_score #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .is_corner(is_corner),
        .center_pixel(center_pixel),
        .circle_pixel(circle_pixel),
        .bright_mask(bright_mask),
        .dark_mask(dark_mask),
        .output_valid(output_valid),
        .score(score)
    );

    /* verilator lint_off BLKSEQ */
    always #(CLK_PERIOD/2) clk = ~clk;
    /* verilator lint_on BLKSEQ */

    initial begin
        $dumpfile("fast_score.vcd");
        $dumpvars(0, tb_fast_score);
    end

    integer i;
    integer errors;

    initial begin
        clk = 0;
        rst_n = 0;
        in_valid = 0;
        is_corner = 0;
        center_pixel = '0;
        bright_mask = '0;
        dark_mask = '0;
        errors = 0;

        for (i = 0; i < 16; i++)
            circle_pixel[i] = '0;

        #(3*CLK_PERIOD);
        rst_n = 1;

        // TEST 1: BRIGHT CORNER
        // center 100;
        // bright pixels are at indices 12-15
        // differences = [40, 30, 25, 20]
        // so, score = 20
        center_pixel = 8'd100;
        is_corner = 1'b1;
        for (i = 0; i < 16; i++) begin
            circle_pixel[i] = 8'd100;
        end
        circle_pixel[12] = 8'd140; // diff = 40
        circle_pixel[13] = 8'd130; // diff = 30
        circle_pixel[14] = 8'd125; // diff = 25
        circle_pixel[15] = 8'd120; // diff = 20

        bright_mask = 16'b1111_0000_0000_0000;
        dark_mask   = 16'b0;

        @(posedge clk);
        in_valid = 1'b1;

        @(posedge clk);
        in_valid = 1'b0;

        while (!output_valid)
            @(posedge clk);

        $display("TEST 1 (BRIGHT): score = %0d", score);

        if (score !== 8'd20) begin
            $error("TEST 1 FAILED: expected score=20");
            errors++;
        end

        // TEST 2: DARK CORNER
        // center 100;
        // dark pixels are at indices 0-3
        // differences = [40, 35, 30, 25]
        // so, score = 25
        center_pixel = 8'd100;
        is_corner = 1'b1;

        for (i = 0; i < 16; i++)
            circle_pixel[i] = 8'd100;

        circle_pixel[0] = 8'd60; // diff = 40
        circle_pixel[1] = 8'd65; // diff = 35
        circle_pixel[2] = 8'd70; // diff = 30
        circle_pixel[3] = 8'd75; // diff = 25

        bright_mask = 16'b0;
        dark_mask   = 16'b0000_0000_0000_1111;

        @(posedge clk);
        in_valid = 1'b1;

        @(posedge clk);
        in_valid = 1'b0;

        while (!output_valid)
            @(posedge clk);

        $display("TEST 2 (DARK): score = %0d", score);

        if (score !== 8'd25) begin
            $error("TEST 2 FAILED: expected score=25");
            errors++;
        end

        //TEST 3: NOT A CORNER
        is_corner = 1'b0;
        bright_mask = 16'b0;
        dark_mask = 16'b0;

        @(posedge clk);
        in_valid = 1'b1;
        
        @(posedge clk);
        in_valid = 1'b0;

        while (!output_valid)
            @(posedge clk);

        $display("TEST 3 (NOT CORNER): score = %0d", score);

        if (score !== 8'd0) begin
            $error("TEST 3 FAILED: expected score=0");
            errors++;
        end

        //result
        if (errors == 0)
            $display("FAST SCORE TEST PASSED");
        else
            $display("FAST SCORE TEST FAILED (%0d errors)", errors);

        $finish;
    end

endmodule
