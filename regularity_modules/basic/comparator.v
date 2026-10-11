// ============================================================
// comparator.v
// ============================================================
// N sets the operand width, must be >= 1
module comparator #(parameter integer N = 128)(a, b, out);

    input   [N-1:0] a;
    input   [N-1:0] b;
    output  [1:0] out;

    // Unsigned comparison: 0 = less than, 1 = equal, 2 = greater than.
    wire [1:0] result [N:0];
    assign result[N] = 2'd1;

    genvar i;
    generate
        for (i = N-1; i >= 0; i = i - 1) begin : compare_bits
            wire [1:0] compare;
            assign compare = (!a[i] & b[i]) ? 2'd0 :
                             (!(a[i] ^ b[i]) ? 2'd1 :
                             ((a[i] & !b[i]) ? 2'd2 : 2'd3));

            // Keep a higher-bit decision, otherwise compare this bit
            assign result[i] = (result[i+1] != 2'd1) ? result[i+1] :
                               (compare == 2'd0) ? 2'd0 :
                               (compare == 2'd2) ? 2'd2 : 2'd1;
        end
    endgenerate

    assign out = result[0];

endmodule
