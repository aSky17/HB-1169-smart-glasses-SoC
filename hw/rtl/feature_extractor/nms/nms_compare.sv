// nms_compare.sv
// Description: Pure combinational Non-maximum suppression comparator for FAST keypoints
// center wins iff
//    - is_corner_center == 1'b1
//    - score_center > all 8 neighbor scores
// Notes:
//    - strict comparison (not >=)
//    - neighbor is_corner is intentionally ignored
//    - border handling is not implemented

`timescale 1ns / 1ps

module nms_compare #(
    parameter int SCORE_WIDTH = 8
) (
    input logic is_corner_center,
    input logic [SCORE_WIDTH-1:0] score_center,
    input logic [SCORE_WIDTH-1:0] score_neighbor[0:7],
    output logic corner_is_max
);

    logic gt_all;
    
    integer i;
    always_comb begin
        //default
        gt_all = 1'b1;
        corner_is_max = 1'b0;

        //center must be a FAST corner 
        if (is_corner_center) begin
            //comparing center against all neighbors
            for (i = 0; i < 8; i++) begin
                if (score_center <= score_neighbor[i]) begin
                    gt_all = 1'b0;
                end
            end
            corner_is_max = gt_all;
        end
    end


endmodule
