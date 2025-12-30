`timescale 1ns / 1ps

module tb_fast_thresh_cmp;

    localparam int DATA_WIDTH   = 8;
    localparam int THRESH_WIDTH = 8;
    localparam int CLK_PERIOD   = 10;

    logic clk;
    logic rst_n;

    logic                     in_valid;
    logic [DATA_WIDTH-1:0]    center_pixel;
    logic [DATA_WIDTH-1:0]    circle_pixel [0:15];
    logic [THRESH_WIDTH-1:0]  threshold;

    logic                     out_valid;
    logic [15:0]              bright_mask;
    logic [15:0]              dark_mask;

    fast_thresh_cmp #(
        .DATA_WIDTH(DATA_WIDTH),
        .THRESH_WIDTH(THRESH_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .center_pixel(center_pixel),
        .circle_pixel(circle_pixel),
        .threshold(threshold),
        .out_valid(out_valid),
        .bright_mask(bright_mask),
        .dark_mask(dark_mask)
    );

    /* verilator lint_off BLKSEQ */
    always #(CLK_PERIOD/2) clk = ~clk;
    /* verilator lint_on BLKSEQ */

    logic [15:0] exp_bright;
    logic [15:0] exp_dark;

    integer i;
    integer errors;

    initial begin
        $dumpfile("fast_thresh_cmp.vcd");
        $dumpvars(0, tb_fast_thresh_cmp);
        clk        = 0;
        rst_n      = 0;
        in_valid   = 0;
        errors     = 0;

        center_pixel = '0;
        threshold    = '0;
        for (i = 0; i < 16; i++)
            circle_pixel[i] = '0;

        #(3*CLK_PERIOD);
        rst_n = 1;

        center_pixel = 8'd100;
        threshold    = 8'd20;

        for (i = 0; i < 16; i++) begin
            if (i < 4)
                circle_pixel[i] = 8'd60;
            else if (i < 12)
                circle_pixel[i] = 8'd100;
            else
                circle_pixel[i] = 8'd140;
        end

        exp_bright = 16'b1111_0000_0000_0000;
        exp_dark   = 16'b0000_0000_0000_1111;

        @(posedge clk);
        in_valid = 1'b1;

        @(posedge clk);
        in_valid = 1'b0;

        while (!out_valid)
            @(posedge clk);

        $display("Center     : %0d", center_pixel);
        $display("Threshold  : %0d", threshold);
        $display("Bright mask: %b", bright_mask);
        $display("Dark mask  : %b", dark_mask);

        if (bright_mask !== exp_bright) begin
            $error("BRIGHT MASK MISMATCH: got %b exp %b",
                   bright_mask, exp_bright);
            errors++;
        end

        if (dark_mask !== exp_dark) begin
            $error("DARK MASK MISMATCH: got %b exp %b",
                   dark_mask, exp_dark);
            errors++;
        end

        if (errors == 0)
            $display("FAST THRESH CMP TEST PASSED");
        else
            $display("FAST THRESH CMP TEST FAILED (%0d errors)", errors);

        $finish;
    end

endmodule

