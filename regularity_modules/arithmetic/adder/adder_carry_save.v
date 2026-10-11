// ============================================================
// adder_carry_save.v
// ============================================================
// N sets the operand and sum width, must be >= 1
// a + b + c = sum + carry_out
module adder_carry_save #(parameter integer N = 128)(a, b, c, sum, carry_out);

    input   [N-1:0] a;
    input   [N-1:0] b;
    input   [N-1:0] c;
    output  [N-1:0] sum;
    output  [N:0]   carry_out;

    assign carry_out[0] = 1'b0;

    genvar i;

    generate
        for (i = 0; i < N; i = i + 1) begin : carry_save
            assign sum[i] = a[i] ^ b[i] ^ c[i];
            assign carry_out[i+1] = (a[i] & b[i]) | (a[i] & c[i]) | (b[i] & c[i]);
        end
    endgenerate

endmodule
