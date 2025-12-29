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

    // Reference Coordinates (row, col) based on FAST-16 standard
    // These should match your DUT's mapping exactly.
    int expected_coords[16][2] = '{
        '{0,3}, '{0,4}, '{1,5}, '{2,6}, 
        '{3,6}, '{4,6}, '{5,5}, '{6,4}, 
        '{6,3}, '{6,2}, '{5,1}, '{4,0}, 
        '{3,0}, '{2,0}, '{1,1}, '{0,2}
    };

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

    //clk generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //verification
    initial begin
        
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_fast_circle_sampler);

        // 1. Initialize & Reset
        clk = 0;
        rst_n = 0;
        window_valid = 0;
        clear_window();
        
        // Hold reset for a few cycles
        repeat(10) @(posedge clk);
        rst_n = 1;
        
        // Wait for one cycle after reset to ensure logic is settled
        @(posedge clk);

        // 2. Drive Coordinate-Encoded Pattern
        $display("--- Starting Coordinate-Encoded Test ---");
        drive_pattern();
        window_valid = 1;
        
        // FIRST Edge: DUT samples 'window' and 'window_valid'
        @(posedge clk); 
        @(posedge clk);      // hold valid across edge
        window_valid = 0; // De-assert so we only test one window

        // SECOND Edge: DUT updates 'circle_pixel' with 'circle_c'
        @(posedge clk); 
        
        // 3. Small delay to move past the NBA region (crucial for Verilator)
        #1; 
        
        // 4. Check Results
        check_results();

        // 5. Test Reset during Valid (Corner Case)
        $display("--- Testing Reset Behavior ---");
        window_valid = 1;
        repeat(2) @(posedge clk);
        rst_n = 0;
        @(posedge clk);
        #1;
        if (circle_valid !== 0) $error("FAILED: circle_valid not cleared on reset");
        
        $display("--- Simulation Finished ---");
        $finish;
    end

    //tasks
    task automatic drive_pattern();
        logic [7:0] tmp;
        for (int r = 0; r < 7; r++) begin
            for (int c = 0; c < 7; c++) begin
                /* verilator lint_off WIDTHTRUNC */
                tmp = (r << 4) | c;   // intentional truncation
                /* verilator lint_on WIDTHTRUNC */
                window[r][c] = tmp;
            end
        end
    endtask

    task automatic clear_window();
        for (int r = 0; r < 7; r++) begin
            for (int c = 0; c < 7; c++) begin
                window[r][c] = 0;
            end
        end
    endtask

    task automatic check_results();
        logic [7:0] exp_val;
        int err_count = 0;

        // Check Center Pixel (3,3) -> 0x33
        if (center_pixel !== 8'h33) begin
            $error("Center Pixel Error: Expected 0x33, Got 0x%h", center_pixel);
            err_count++;
        end

        // Check Circle Pixels
        for (int i = 0; i < 16; i++) begin
            exp_val = 8'((expected_coords[i][0] << 4) | expected_coords[i][1]);
            if (circle_pixel[i] !== exp_val) begin
                $error("Circle Pixel [%0d] Error: Expected 0x%h, Got 0x%h", i, exp_val, circle_pixel[i]);
                err_count++;
            end
        end

        if (err_count == 0) 
            $display("SUCCESS: All 16 circle pixels and center pixel mapped correctly!");
        else
            $display("FAILURE: Found %0d mapping errors.", err_count);
    endtask


endmodule
