// ============================================================
// sqrt.v
// ============================================================
// Unsigned combinational floor(sqrt(a)). N must be >= 1.
// out has ceil(N/2) bits. Odd input widths are zero-padded.
// Restoring digit recurrence, unrolled like div_restoring.
module sqrt #(parameter integer N = 128)(a, out);
    input [N-1:0] a;
    output [(N+1)/2-1:0] out;

    localparam integer R = (N+1)/2;
    localparam integer W = R+2;
    wire [2*R-1:0] padded;
    wire [R-1:0] root [0:R];
    wire [W-1:0] remainder [0:R];

    assign padded = {{(2*R-N){1'b0}}, a};
    assign root[0] = {R{1'b0}};
    assign remainder[0] = {W{1'b0}};

    genvar i;
    generate
        for (i = 0; i < R; i = i+1) begin : restoring_sqrt
            wire [W-1:0] shifted, trial;
            wire [W:0] difference;

            // Bring down two radicand bits; try the next root bit.
            assign shifted = (remainder[i] << 2) |
                             {{(W-2){1'b0}}, padded[2*(R-i)-1 -: 2]};
            assign trial = {root[i], 2'b01};
            assign difference = {1'b0, shifted} - {1'b0, trial};
            assign root[i+1] = (root[i] << 1) |
                              {{(R-1){1'b0}}, ~difference[W]};
            if_else #(.N(W)) restore_select (
                .condition(difference[W]), .if_value(shifted),
                .else_value(difference[W-1:0]), .out(remainder[i+1])
            );
        end
    endgenerate

    assign out = root[R];
endmodule
