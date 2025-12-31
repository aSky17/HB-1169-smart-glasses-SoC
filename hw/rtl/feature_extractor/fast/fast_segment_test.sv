// fast_segment_test.sv
// now the question is do these 16 bits contain a long enough contiguous arc of 1s?
// Detects contiguous run of N bright or dark pixels on FAST circle
// Uses bit-ring duplication trick
// A pixel is a corner if either: there are N contiguous 1s in bright_mask, or
// there are N contiguous 1s in dark_mask
// N can be 9 or 12; 12 becomes more strict sampling
// Issue? the circle is fking circular [15] [0] [1] [2] ... [14], so the contiguity can wrap around
// Eg of a valid FAST-9:  bits 13,14,15,0,1,2,3,4,5 --> Linear logic alone can’t catch this.
// Logic: so we duplicate the bits --> take the 16  bit mask and duplicate it
// mask16 = abcdefghijklmnop
// mask32 = abcdefghijklmnopabcdefghijklmno
// Now any circular run of length ≤ 16 becomes a linear run in ring.

`timescale 1ns / 1ps

module fast_segment_test #(
    parameter int N = 9 // can be 9 or 12 
) (
    input logic clk,
    input logic rst_n,
    input logic in_valid,
    input logic [15:0] bright_mask,
    input logic [15:0] dark_mask,

    output logic out_valid,
    output logic is_corner
);

    //stage-1 registers
    logic in_valid_r;
    logic [15:0] bright_mask_r;
    logic [15:0] dark_mask_r;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_valid_r <= 1'b0;
            bright_mask_r <= '0;
            dark_mask_r <= '0;
        end else begin
            in_valid_r <= in_valid;
            bright_mask_r <= bright_mask;
            dark_mask_r <= dark_mask;
        end
    end

    //combinational wires
    //duplicating the circle as a line so that contiguous detection is correct
    logic [31:0] bright_ring;
    logic [31:0] dark_ring;

    logic bright_hit;
    logic dark_hit;

    integer i;
    always_comb begin

        bright_ring = {bright_mask_r, bright_mask_r};
        dark_ring = {dark_mask_r, dark_mask_r};

        bright_hit = 1'b0;
        dark_hit = 1'b0;

        for (i = 0; i < 32-N; i++) begin
            if (&bright_ring[i +: N]) begin
                bright_hit = 1'b1;
            end

        /*** HARDWARE REALIZATION
        *After Unrolling:
        *   begin
        *       bright_hit_0 = (&bright_ring[0 +: N]);
        *       bright_hit_1 = (&bright_ring[1 +: N]);
        *       bright_hit_2 = (&bright_ring[2 +: N]);
        *       
        *       // The final output is the result of all assignments combined
        *       bright_hit = bright_hit_0 | bright_hit_1 | bright_hit_2; 
        *   end
        */

            if (&dark_ring[i +: N]) begin
                dark_hit = 1'b1;
            end
        end
    end

    // Stage-2 registering output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            is_corner <= 1'b0;
        end else begin
            out_valid <= in_valid_r;
            is_corner <= bright_hit | dark_hit;
        end
    end

endmodule


