`timescale 1ns / 1ps

module tb_nms_top;

    localparam int SCORE_WIDTH  = 8;
    localparam int IMAGE_WIDTH  = 8;
    localparam int IMAGE_HEIGHT = 8;

    localparam int X_WIDTH = $clog2(IMAGE_WIDTH);
    localparam int Y_WIDTH = $clog2(IMAGE_HEIGHT);

    logic clk;
    logic rst_n;     // async reset for DUT
    logic tb_rst;    // sync reset for TB logic

    logic pixel_valid;
    logic is_corner_in;
    logic [SCORE_WIDTH-1:0] score_in;

    logic nms_valid;
    logic [SCORE_WIDTH-1:0] nms_score;
    logic [X_WIDTH-1:0]     nms_x;
    logic [Y_WIDTH-1:0]     nms_y;

    nms_top #(
        .SCORE_WIDTH (SCORE_WIDTH),
        .IMAGE_WIDTH (IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT)
    ) dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .pixel_valid (pixel_valid),
        .is_corner_in(is_corner_in),
        .score_in    (score_in),
        .nms_valid   (nms_valid),
        .nms_score   (nms_score),
        .nms_x       (nms_x),
        .nms_y       (nms_y)
    );

    /* verilator lint_off BLKSEQ */
    always #5 clk = ~clk;
    /* verilator lint_on BLKSEQ */

    int cycle;
    always_ff @(posedge clk) begin
        if (!tb_rst)
            cycle <= 0;
        else
            cycle <= cycle + 1;
    end

    int score_img  [0:IMAGE_HEIGHT-1][0:IMAGE_WIDTH-1];
    bit golden_nms [0:IMAGE_HEIGHT-1][0:IMAGE_WIDTH-1];

    task automatic build_test_image;
        int x, y;
        begin
            for (y = 0; y < IMAGE_HEIGHT; y++)
                for (x = 0; x < IMAGE_WIDTH; x++)
                    score_img[y][x] = 10;

            score_img[2][3] = 90;
            score_img[3][1] = 80;
            score_img[5][5] = 120;
        end
    endtask

    task automatic compute_golden_nms;
        int x, y, dx, dy;
        bit is_max;
        begin
            for (y = 0; y < IMAGE_HEIGHT; y++) begin
                for (x = 0; x < IMAGE_WIDTH; x++) begin
                    golden_nms[y][x] = 0;

                    if (x == 0 || y == 0 ||
                        x == IMAGE_WIDTH-1 ||
                        y == IMAGE_HEIGHT-1)
                        continue;

                    is_max = 1;
                    for (dy = -1; dy <= 1; dy++)
                        for (dx = -1; dx <= 1; dx++)
                            if (!(dx == 0 && dy == 0))
                                if (score_img[y][x] <= score_img[y+dy][x+dx])
                                    is_max = 0;

                    golden_nms[y][x] = is_max;
                end
            end
        end
    endtask

    int in_x, in_y;

    always_ff @(posedge clk) begin
        if (!tb_rst) begin
            in_x <= 0;
            in_y <= 0;
        end else if (pixel_valid) begin
            $display("IN  : cycle=%0d  pixel=(%0d,%0d) score=%0d",
                     cycle, in_x, in_y, score_in);

            if (in_x == IMAGE_WIDTH-1) begin
                in_x <= 0;
                in_y <= in_y + 1;
            end else begin
                in_x <= in_x + 1;
            end
        end
    end

    int errors;
    int expected_cnt;
    int observed_cnt;

    always_ff @(posedge clk) begin
        if (!tb_rst) begin
            observed_cnt <= 0;
            errors       <= 0;
        end else if (nms_valid) begin
            observed_cnt <= observed_cnt + 1;

            $display("OUT : cycle=%0d  NMS=(%0d,%0d) score=%0d  GOLDEN=%0d",
                     cycle, nms_x, nms_y, nms_score,
                     golden_nms[nms_y][nms_x]);

            if (!golden_nms[nms_y][nms_x]) begin
                $error("False NMS @ (%0d,%0d), score=%0d",
                       nms_x, nms_y, nms_score);
                errors <= errors + 1;
            end
        end
    end

    initial begin
        int x, y;

        clk = 0;
        rst_n = 0;
        tb_rst = 0;
        pixel_valid = 0;
        is_corner_in = 1'b1;
        score_in = 0;
        in_x = 0;
        in_y = 0;

        build_test_image();
        compute_golden_nms();

        expected_cnt = 0;
        for (y = 0; y < IMAGE_HEIGHT; y++)
            for (x = 0; x < IMAGE_WIDTH; x++)
                if (golden_nms[y][x])
                    expected_cnt++;

        $display("Expected NMS points = %0d", expected_cnt);

        #20;
        rst_n  = 1;   // async reset release to DUT
        tb_rst = 1;   // sync reset release for TB

        @(posedge clk);
        pixel_valid = 1;

        for (y = 0; y < IMAGE_HEIGHT; y++)
            for (x = 0; x < IMAGE_WIDTH; x++) begin
                score_in = score_img[y][x][SCORE_WIDTH-1:0];
                @(posedge clk);
            end

        pixel_valid = 0;

        repeat (IMAGE_WIDTH + 10) @(posedge clk);

        if (errors == 0 && observed_cnt == expected_cnt)
            $display("NMS TEST PASSED");
        else begin
            $display("NMS TEST FAILED");
            $display("  errors       = %0d", errors);
            $display("  expected_cnt = %0d", expected_cnt);
            $display("  observed_cnt = %0d", observed_cnt);
        end

        $finish;
    end

endmodule
