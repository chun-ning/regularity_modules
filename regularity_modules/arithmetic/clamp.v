// ============================================================
// clamp.v
// ============================================================
// limits a signed DW-bit value to the inclusive range [lo, hi]
// DW must be >= 1. Bounds are normally ordered lo <= hi.
module clamp #(parameter integer DW = 16)(a, lo, hi, out);

    input signed  [DW-1:0] a;
    input signed  [DW-1:0] lo;
    input signed  [DW-1:0] hi;
    output signed [DW-1:0] out;

    wire [DW-1:0] ordered_a, ordered_lo, ordered_hi;
    wire [1:0] compare_lo, compare_hi;
    wire below_lo, above_hi;
    wire [DW-1:0] upper_clamped;

    // Invert each sign bit to map signed order to unsigned order.
    // All remaining bits pass directly to the existing comparators.
    genvar i;
    generate
        for (i = 0; i < DW; i = i + 1) begin : order_bits
            if (i == DW-1) begin : sign_bit
                not (ordered_a[i], a[i]);
                not (ordered_lo[i], lo[i]);
                not (ordered_hi[i], hi[i]);
            end else begin : lower_bits
                assign ordered_a[i] = a[i];
                assign ordered_lo[i] = lo[i];
                assign ordered_hi[i] = hi[i];
            end
        end
    endgenerate

    comparator #(.N(DW)) lower_compare (
        .a(ordered_a), .b(ordered_lo), .out(compare_lo)
    );
    comparator #(.N(DW)) upper_compare (
        .a(ordered_a), .b(ordered_hi), .out(compare_hi)
    );

    // Comparator encoding: 00 = less, 01 = equal, 10 = greater.
    nor (below_lo, compare_lo[1], compare_lo[0]);
    assign above_hi = compare_hi[1];

    mux #(.N(DW)) upper_mux (
        .a(a), .b(hi), .sel(above_hi), .out(upper_clamped)
    );
    // Lower-bound check has priority, matching LogikBench even if lo > hi.
    mux #(.N(DW)) lower_mux (
        .a(upper_clamped), .b(lo), .sel(below_lo), .out(out)
    );
endmodule
