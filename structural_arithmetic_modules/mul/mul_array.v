// ============================================================
// mul_array.v
// ============================================================
// N sets the operand width, must be >= 1; product is 2*N bits
// Unsigned
module mul_array #(parameter integer N = 128)(a, b, product);

    input   [N-1:0] a;
    input   [N-1:0] b;
    output  [2*N-1:0] product;

    wire [N:0] row_sum [0:N-1];

    assign row_sum[0] = {1'b0, (a & {N{b[0]}})};
    assign product[0] = row_sum[0][0];

    genvar row, col;
    generate
        for (row = 1; row < N; row = row + 1) begin : array_row
            wire [N-1:0] partial_product;
            wire [N:0] carry;

            assign partial_product = a & {N{b[row]}};
            assign carry[0] = 1'b0;

            // Add this partial-product row to the remaining upper sum
            for (col = 0; col < N; col = col + 1) begin : full_adder
                wire x, y;
                assign x = row_sum[row-1][col+1];
                assign y = partial_product[col];
                assign row_sum[row][col] = x ^ y ^ carry[col];
                assign carry[col+1] = (x & y) | ((x ^ y) & carry[col]);
            end

            assign row_sum[row][N] = carry[N];
            // Later rows cannot affect this product bit
            assign product[row] = row_sum[row][0];
        end
    endgenerate

    assign product[2*N-1:N] = row_sum[N-1][N:1];

endmodule
