`timescale 1ns/1ps

module dummy_accel (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [7:0]  a,
  input  logic [7:0]  b,
  output logic [8:0]  sum
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      sum <= '0;
    else
      sum <= a + b;
  end
endmodule
