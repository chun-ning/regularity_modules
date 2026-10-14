// ============================================================
// log2.v
// ============================================================
// Unsigned floor(log2(a)); zero returns zero
// N sets the operand width, must be >= 1
module log2 #(parameter integer N = 128)(a, out);

    input   [N-1:0] a;
    output  [((N > 1) ? $clog2(N) : 1)-1:0] out;

    localparam integer OUT_WIDTH = (N > 1) ? $clog2(N) : 1;

    wire [N:0] found;
    wire [N-1:0] highest;
    wire [OUT_WIDTH-1:0] result [0:N];

    assign found[N] = 1'b0;
    assign result[N] = {OUT_WIDTH{1'b0}};

    genvar i;
    generate
        for (i = N-1; i >= 0; i = i - 1) begin : priority_bits
            localparam [OUT_WIDTH-1:0] INDEX = i;
            wire no_higher_bit;

            // Select this bit only if no higher bit is set
            assign no_higher_bit = !found[i+1];
            assign highest[i] = a[i] & no_higher_bit;
            assign found[i] = found[i+1] | a[i];

            assign result[i] = result[i+1] | (INDEX & {OUT_WIDTH{highest[i]}});
        end
    endgenerate

    assign out = result[0];

endmodule
