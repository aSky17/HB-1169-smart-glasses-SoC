`timescale  1ns / 1ps

module tb_fast_circle_sampler;

    //parameters
    parameter int DATA_WIDTH = 8;
    parameter int CLK_PERIOD = 10; 

    //dut signals
    logic clk;
    logic rst_n;
    logic window_valid;
    logic [DATA_WIDTH-1:0] window[0:6][0:6];

    logic circle_valid;
    logic [DATA_WIDTH-1:0] center_pixel;
    logic [DATA_WIDTH-1:0] circle_pixel[0:15];

    logic [DATA_WIDTH-1:0] tmp_val;

    //instantitating dut
    fast_circle_sampler #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .window_valid(window_valid),
        .window(window),
        .circle_valid(circle_valid),
        .center_pixel(center_pixel),
        .circle_pixel(circle_pixel)
    );

    // Clock generation
    /* verilator lint_off BLKSEQ */
    always #(CLK_PERIOD/2) clk = ~clk;
    /* verilator lint_on BLKSEQ */


    // Reference model storage
    logic [DATA_WIDTH-1:0] exp_center;
    logic [DATA_WIDTH-1:0] exp_circle [0:15];

    // Testing
    initial begin
        int r, c;
        int errors = 0;

        // Init
        clk = 0;
        rst_n = 0;
        window_valid = 0;

        // Clear window
        for (r = 0; r < 7; r++)
            for (c = 0; c < 7; c++)
                window[r][c] = '0;

        // Reset
        #(3*CLK_PERIOD);
        rst_n = 1;

        // Load deterministic test pattern
        for (r = 0; r < 7; r++) begin
            for (c = 0; c < 7; c++) begin
                tmp_val = { r[3:0], c[3:0] };
                window[r][c] = tmp_val;
            end
        end


        // Expected values
        exp_center = window[3][3];

        exp_circle[0]  = window[0][3];
        exp_circle[1]  = window[0][4];
        exp_circle[2]  = window[1][5];
        exp_circle[3]  = window[2][6];
        exp_circle[4]  = window[3][6];
        exp_circle[5]  = window[4][6];
        exp_circle[6]  = window[5][5];
        exp_circle[7]  = window[6][4];
        exp_circle[8]  = window[6][3];
        exp_circle[9]  = window[6][2];
        exp_circle[10] = window[5][1];
        exp_circle[11] = window[4][0];
        exp_circle[12] = window[3][0];
        exp_circle[13] = window[2][0];
        exp_circle[14] = window[1][1];
        exp_circle[15] = window[0][2];

        // Drive valid
        @(posedge clk);
        window_valid = 1'b1;

        @(posedge clk);
        window_valid = 1'b0;

        // Wait until DUT says data is valid
        while (!circle_valid) @(posedge clk);

        // Self-check
        if (!circle_valid) begin
            $error("circle_valid not asserted!");
            errors++;
        end

        if (center_pixel !== exp_center) begin
            $error("CENTER MISMATCH: got %0h exp %0h",
                   center_pixel, exp_center);
            errors++;
        end

        for (int i = 0; i < 16; i++) begin
            if (circle_pixel[i] !== exp_circle[i]) begin
                $error("CIRCLE[%0d] MISMATCH: got %0h exp %0h",
                       i, circle_pixel[i], exp_circle[i]);
                errors++;
            end
        end

        // Result
        if (errors == 0) begin
            $display("FAST CIRCLE SAMPLER TEST PASSED");
        end else begin
            $display("FAST CIRCLE SAMPLER TEST FAILED (%0d errors)", errors);
        end

        $finish;
    end
endmodule
