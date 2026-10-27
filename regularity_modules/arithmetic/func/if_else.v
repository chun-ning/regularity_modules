// ============================================================
// if_else.v
// ============================================================
// Combinational N-bit if/else selection using gates. N must be >= 1.
// condition=1 selects if_value; condition=0 selects else_value.
module if_else #(parameter integer N = 128)(condition, if_value, else_value, out);
    input condition;
    input [N-1:0] if_value, else_value;
    output [N-1:0] out;

    wire not_condition;
    not (not_condition, condition);

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : select_bits
            wire if_path, else_path;
            and (if_path, if_value[i], condition);
            and (else_path, else_value[i], not_condition);
            or (out[i], if_path, else_path);
        end
    endgenerate
endmodule
