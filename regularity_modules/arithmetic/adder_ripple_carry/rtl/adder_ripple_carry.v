// ============================================================
// adder_ripple_carry.v
// ============================================================
// N sets the operand and sum width, must be >= 1
module adder_ripple_carry #(parameter integer N = 128)(a, b, carry_in, sum, carry_out);

    input   [N-1:0] a;
    input   [N-1:0] b;
    input           carry_in;
    output  [N-1:0] sum;
    output          carry_out;

    wire [N:0] carry;

    assign carry[0] = carry_in;

    genvar i;

    generate
        for (i = 0; i < N; i = i + 1) begin : ripple_carry
            assign sum[i] = a[i] ^ b[i] ^ carry[i];
            assign carry[i+1] = (a[i] & b[i]) | (a[i] & carry[i]) | (b[i] & carry[i]);
        end
    endgenerate

    assign carry_out = carry[N];

endmodule
