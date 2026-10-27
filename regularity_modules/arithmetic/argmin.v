// ============================================================
// argmin.v
// ============================================================
// Index of the minimum of N unsigned DW-bit elements.
// N and DW must be >= 1. Ties select the lowest index.
// Element zero occupies a[DW-1:0]; N=1 returns a one-bit zero.
module argmin #(parameter integer N = 8,
                 parameter integer DW = 16)(a, out);

    input [N*DW-1:0] a;
    output [((N > 1) ? $clog2(N) : 1)-1:0] out;

    localparam integer IW = (N > 1) ? $clog2(N) : 1;
    wire [DW-1:0] value [0:N-1];
    wire [IW-1:0] index [0:N-1];

    assign value[0] = a[0 +: DW];
    assign index[0] = {IW{1'b0}};

    genvar i;
    generate
        for (i = 1; i < N; i = i + 1) begin : compare_elements
            localparam [IW-1:0] CURRENT_INDEX = i;
            wire [1:0] comparison;
            wire sel;

            comparator #(.N(DW)) compare (
                .a(a[i*DW +: DW]), .b(value[i-1]), .out(comparison)
            );
            // Comparator encoding: 00 = less, 01 = equal, 10 = greater.
            nor (sel, comparison[1], comparison[0]);
            mux #(.N(DW)) value_mux (
                .a(value[i-1]), .b(a[i*DW +: DW]),
                .sel(sel), .out(value[i])
            );
            mux #(.N(IW)) index_mux (
                .a(index[i-1]), .b(CURRENT_INDEX),
                .sel(sel), .out(index[i])
            );
        end
    endgenerate

    assign out = index[N-1];
endmodule
