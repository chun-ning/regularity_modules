// ============================================================
// addtree.v
// ============================================================
// Sum N unsigned DW-bit elements. N and DW must be >= 1.
// Element zero occupies a[DW-1:0]. No sum bits are discarded.
// The binary tree is balanced for power-of-two N.
module addtree #(parameter integer N = 64,
                 parameter integer DW = 16)(a, out);

    input [N*DW-1:0] a;
    output [DW+$clog2(N)-1:0] out;

    localparam integer OW = DW + $clog2(N);
    wire [OW-1:0] node [1:2*N-1];

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : leaves
            assign node[N+i] = {{(OW-DW){1'b0}}, a[i*DW +: DW]};
        end
        for (i = 1; i < N; i = i + 1) begin : add_nodes
            adder_ripple_carry #(.N(OW)) add (
                .a(node[2*i]), .b(node[2*i+1]), .carry_in(1'b0),
                .sum(node[i]), .carry_out()
            );
        end
    endgenerate

    assign out = node[1];
endmodule
