// ============================================================
// comparator.v
// ============================================================
// N sets the operand width, must be >= 1
module comparator #(parameter integer N = 128)(a, b, out);

    input   [N-1:0] a;
    input   [N-1:0] b;
    output  [1:0] out;

    // Unsigned comparison: 0 = less than, 1 = equal, 2 = greater than.
    wire [N:0] equal, greater;
    assign equal[N] = 1'b1;
    assign greater[N] = 1'b0;

    genvar i;
    generate
        for (i = N-1; i >= 0; i = i - 1) begin : compare_bits
            wire same, not_b, bit_greater;
            // This bit decides only when all higher bits are equal.
            xnor (same, a[i], b[i]);
            not (not_b, b[i]);
            and (equal[i], equal[i+1], same);
            and (bit_greater, equal[i+1], a[i], not_b);
            or (greater[i], greater[i+1], bit_greater);
        end
    endgenerate

    // If neither greater nor equal is asserted, a is less than b.
    assign out = {greater[0], equal[0]};

endmodule
