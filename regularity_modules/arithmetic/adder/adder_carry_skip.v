// ============================================================
// adder_carry_skip.v
// ============================================================
// N sets the operand and sum width, must be >= 1
module adder_carry_skip #(parameter integer N = 128)(a, b, carry_in, sum, carry_out);

    input   [N-1:0] a;
    input   [N-1:0] b;
    input           carry_in;
    output  [N-1:0] sum;
    output          carry_out;

    localparam integer BLOCK_SIZE = 4;
    localparam integer BLOCKS = (N + BLOCK_SIZE - 1) / BLOCK_SIZE;

    wire [N-1:0] p;
    wire [BLOCKS:0] carry;

    assign p = a ^ b;
    assign carry[0] = carry_in;

    genvar block_index, bit_index;
    generate
        for (block_index = 0; block_index < BLOCKS; block_index = block_index + 1) begin : carry_skip
            localparam integer START = block_index * BLOCK_SIZE;
            localparam integer WIDTH = (N - START < BLOCK_SIZE) ? N - START : BLOCK_SIZE;
            wire [WIDTH:0] ripple;

            assign ripple[0] = carry[block_index];
            for (bit_index = 0; bit_index < WIDTH; bit_index = bit_index + 1) begin : ripple_carry
                assign sum[START+bit_index] = p[START+bit_index] ^ ripple[bit_index];
                assign ripple[bit_index+1] = (a[START+bit_index] & b[START+bit_index]) |
                                             (p[START+bit_index] & ripple[bit_index]);
            end

            // Skip the block when every bit propagates the incoming carry
            if_else #(.N(1)) skip_select (
                .condition(&p[START +: WIDTH]), .if_value(carry[block_index]),
                .else_value(ripple[WIDTH]), .out(carry[block_index+1])
            );
        end
    endgenerate

    assign carry_out = carry[BLOCKS];

endmodule
