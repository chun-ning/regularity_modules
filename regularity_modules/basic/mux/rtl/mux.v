// N-bit 2-to-1 gate-level mux: sel = 0 selects a, sel = 1 selects b
// N must be >= 1
module mux #(parameter integer N = 128)(
    input  [N-1:0] a,
    input  [N-1:0] b,
    input          sel,
    output [N-1:0] out
);
    wire not_sel;
    not (not_sel, sel);

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : select_bit
            wire a_path, b_path;
            and (a_path, a[i], not_sel);
            and (b_path, b[i], sel);
            or  (out[i], a_path, b_path);
        end
    endgenerate
endmodule
