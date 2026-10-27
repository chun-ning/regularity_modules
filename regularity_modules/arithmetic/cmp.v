// ============================================================
// cmp.v
// ============================================================
// Unsigned comparison using gates; DW must be >= 1.
module cmp #(parameter integer DW = 16)(a, b, aeqb, agtb, altb);

    input [DW-1:0] a;
    input [DW-1:0] b;
    output aeqb;
    output agtb;
    output altb;

    wire [DW:0] equal, greater, less;
    assign equal[DW] = 1'b1;
    assign greater[DW] = 1'b0;
    assign less[DW] = 1'b0;

    genvar i;
    generate
        for (i = DW-1; i >= 0; i = i - 1) begin : compare_bits
            wire same, not_a, not_b, bit_greater, bit_less;
            // A lower bit decides only when all higher bits are equal.
            xnor (same, a[i], b[i]);
            not (not_a, a[i]);
            not (not_b, b[i]);
            and (equal[i], equal[i+1], same);
            and (bit_greater, equal[i+1], a[i], not_b);
            and (bit_less, equal[i+1], not_a, b[i]);
            or (greater[i], greater[i+1], bit_greater);
            or (less[i], less[i+1], bit_less);
        end
    endgenerate

    assign aeqb = equal[0];
    assign agtb = greater[0];
    assign altb = less[0];
endmodule
