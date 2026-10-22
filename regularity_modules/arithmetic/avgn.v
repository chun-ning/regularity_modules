// ============================================================
// avgn.v
// ============================================================
// N unsigned DW-bit elements, N and DW must both be >= 1
module avgn #(parameter integer N = 8,
              parameter integer DW = 16)(a, out);

    input   [N*DW-1:0] a;
    output  [DW-1:0] out;

    localparam integer SW = DW + $clog2(N); // widen to avoid sum overflow
    localparam [SW-1:0] DIVISOR = N;
    wire [SW-1:0] acc [0:N-1];
    wire [SW-1:0] quotient;

    assign acc[0] = {{(SW-DW){1'b0}}, a[0 +: DW]};

    genvar i;
    generate
        for (i = 1; i < N; i = i + 1) begin : g_sum
            adder_ripple_carry #(.N(SW)) add (
                .a(acc[i-1]),
                .b({{(SW-DW){1'b0}}, a[i*DW +: DW]}),
                .carry_in(1'b0),
                .sum(acc[i]),
                .carry_out()
            );
        end
    endgenerate

    div_restoring #(.N(SW)) divide (
        .a(acc[N-1]),
        .b(DIVISOR),
        .quotient(quotient),
        .remainder()
    );

    assign out = quotient[DW-1:0]; // remainder discarded (round down)
endmodule
