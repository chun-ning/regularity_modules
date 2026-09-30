// ============================================================
// mul_shift_add.v
// ============================================================
// Unsigned
// N sets the operand width, must be >= 1; product is 2*N bits
module mul_shift_add #(parameter integer N = 128)(a, b, product);

    input   [N-1:0] a;
    input   [N-1:0] b;
    output  [2*N-1:0] product;

    wire [2*N-1:0] partial_sum [0:N];

    assign partial_sum[0] = {2*N{1'b0}};

    genvar i;

    generate
        for (i = 0; i < N; i = i + 1) begin : shift_and_add
            wire [2*N-1:0] partial_product;

            assign partial_product = {{N{1'b0}}, (a & {N{b[i]}})} << i;
            assign partial_sum[i+1] = partial_sum[i] + partial_product;
        end
    endgenerate

    assign product = partial_sum[N];

endmodule
