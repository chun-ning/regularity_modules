// ============================================================
// abs.v
// ============================================================
// N sets the operand and sum width, must be >= 1
module abs #(parameter integer N = 128)(
    input signed [N-1:0] a, // signed, twos-compliment
    output       [N-1:0] out
    );

    wire [N-1:0] inverted_a;
    wire [N-1:0] negative_a;

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : invert_a
            assign inverted_a[i] = a[i] ^ 1'b1;
        end
    endgenerate

    adder_ripple_carry #(.N(N)) negate_adder (
        .a(inverted_a),
        .b({N{1'b0}}),
        .carry_in(1'b1),
        .sum(negative_a),
        .carry_out()
    );

    mux #(.N(N)) magnitude_mux (
        .a(a),
        .b(negative_a),
        .sel(a[N-1]),
        .out(out)
    );

endmodule
