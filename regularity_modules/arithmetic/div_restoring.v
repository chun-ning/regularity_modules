// ============================================================
// div_restoring.v
// ============================================================
// Unsigned
// N sets the operand, quotient, and remainder width, must be >= 1
// Division by zero returns quotient = all ones and remainder = a
module div_restoring #(parameter integer N = 128)(a, b, quotient, remainder);

    input   [N-1:0] a;
    input   [N-1:0] b;
    output  [N-1:0] quotient;
    output  [N-1:0] remainder;

    wire [N:0] partial_remainder [0:N];

    assign partial_remainder[0] = {(N+1){1'b0}};

    genvar i;

    generate
        for (i = 0; i < N; i = i + 1) begin : restoring_division
            wire [N:0] shifted_remainder;
            wire [N+1:0] difference;

            // Bring down the next dividend bit, starting with the MSB
            assign shifted_remainder = {partial_remainder[i][N-1:0], a[N-1-i]};
            assign difference = {1'b0, shifted_remainder} - {2'b0, b};

            // restores the remainder and produces a zero quotient bit
            assign quotient[N-1-i] = ~difference[N+1];
            assign partial_remainder[i+1] = difference[N+1] ? shifted_remainder : difference[N:0];
        end
    endgenerate

    assign remainder = partial_remainder[N][N-1:0];

endmodule
