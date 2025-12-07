`timescale 1ns/1ps

module tb_dummy_accel;

  logic clk;
  logic rst_n;
  logic [7:0] a, b;
  logic [8:0] sum;

  // DUT instantiation
  dummy_accel dut (
    .clk (clk),
    .rst_n (rst_n),
    .a (a),
    .b (b),
    .sum (sum)
  );

  // Clock generation: 10ns period
  initial clk = 0;
  always #5 clk <= ~clk;

  initial begin
    // Waveform dump (optional)
    $dumpfile("tb_dummy_accel.vcd");
    $dumpvars(0, tb_dummy_accel);

    // Reset
    rst_n = 0;
    a = 0;
    b = 0;
    #20;
    rst_n = 1;

    // Apply a few test vectors
    #10; a = 8'd10; b = 8'd5;
    #10; a = 8'd100; b = 8'd7;
    #10; a = 8'd255; b = 8'd1;

    #50;
    $display("Test completed. Last sum = %0d", sum);
    $finish;
  end

endmodule
