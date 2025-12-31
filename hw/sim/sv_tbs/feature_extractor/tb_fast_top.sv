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

    integer r, c, k;
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
        // window[6][3] = 8'd121;
        window[6][2] = 8'd130;
        window[5][1] = 8'd135;
        window[4][0] = 8'd140;
        window[3][0] = 8'd145;
        window[2][0] = 8'd150;
        window[1][1] = 8'd135;
        window[0][2] = 8'd130;

        // WINDOW STREAMING PHASE
        for (k = 0; k < 20; k++) begin
            @(posedge clk);

            // Vary ONE supporting pixel slightly each cycle
            // Simulates motion / contrast variation
            window[6][3] = 8'd121 + 8'(k);  // min diff increases over time

            window_valid = 1'b1;
        end
        @(posedge clk);
        window_valid = 1'b0;

        // Let pipeline drain
        repeat (10) @(posedge clk);

        $display("WINDOW STREAMING TEST DONE");
        $finish;

    end

    always @(posedge clk) begin
        if (dut.circle_valid) begin
            $display("---- FAST WINDOW ----");
            $display("center = %0d", dut.center_pixel);

            for (int i = 0; i < 16; i++) begin
                $display("circle[%0d] = %0d", i, dut.circle_pixel[i]);
            end
        end
    end


    always @(posedge clk) begin
        if (dut.threshold_valid) begin
            $display("bright_mask = %b", dut.bright_mask);
            $display("dark_mask   = %b", dut.dark_mask);
        end
    end

    always @(posedge clk) begin
        if (dut.segment_valid) begin
            $display("segment hit → is_corner = %0b", dut.is_corner);
        end
    end

    always @(posedge clk) begin
        if (dut.score_valid && dut.is_corner) begin
            $display("---- SCORE DETAILS ----");
            for (int i = 0; i < 16; i++) begin
                if (dut.bright_mask[i]) begin
                    $display("BRIGHT[%0d] diff=%0d",
                        i, dut.circle_pixel[i] - dut.center_pixel);
                end
                if (dut.dark_mask[i]) begin
                    $display("DARK[%0d] diff=%0d",
                        i, dut.center_pixel - dut.circle_pixel[i]);
                end
            end
            $display("FINAL SCORE = %0d", dut.score);
        end
    end


    // Logging FAST outputs
    always @(posedge clk) begin
        if (out_valid) begin
            $display("[%0t] is_corner=%0b score=%0d",
                     $time, is_corner, score);

            if (is_corner && score <= threshold) begin
                $error("INVALID SCORE: score=%0d threshold=%0d",
                       score, threshold);
                errors <= errors + 1;
            end
        end
    end

endmodule
