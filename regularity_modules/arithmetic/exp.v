// ============================================================
// exp.v
// ============================================================
// Signed fixed-point exp approximation matching LogikBench.
// DW >= 9, 1 <= QW < DW. Constants are tuned for QW=8.
// Combinational: range reduction, cubic polynomial, scaling, saturation.
module exp #(parameter integer DW = 16,
             parameter integer QW = 8)(x, out);
    input signed [DW-1:0] x;
    output signed [DW-1:0] out;

    localparam integer PW = DW + 4;
    localparam integer TW = 2*DW + 1;
    localparam [DW-1:0] LOG2E = 369;
    localparam [DW-1:0] MAXV = {1'b0, {(DW-1){1'b1}}};
    localparam [DW-1:0] KHI = DW-QW-1;
    localparam [DW-1:0] KLO = -(QW+1);
    localparam [PW-1:0] C1 = 177, C2 = 61, C3 = 14;
    localparam [PW-1:0] ONEQ = (1 << QW);

    wire [DW-1:0] magnitude, magnitude_input, kk, neg_kk, shift_amount;
    wire [2*DW-1:0] unsigned_product, signed_product, product_input, m;
    wire [QW-1:0] frac;
    wire [PW-1:0] p1, p0, pv;
    wire [TW-1:0] left_stage [0:DW];
    wire [TW-1:0] right_stage [0:DW];
    wire [TW-1:0] shifted;
    wire high_eq, high_gt, low_eq, low_lt, value_gt;
    wire saturate_high, underflow;
    wire [DW-1:0] clipped, low_checked;

    // Convert x to unsigned magnitude, then restore the product sign.
    assign magnitude_input = x ^ {DW{x[DW-1]}};
    adder_ripple_carry #(.N(DW)) abs_x (
        .a(magnitude_input), .b({DW{1'b0}}), .carry_in(x[DW-1]),
        .sum(magnitude), .carry_out()
    );
    mul_array #(.N(DW)) range_product (
        .a(magnitude), .b(LOG2E), .product(unsigned_product)
    );
    assign product_input = unsigned_product ^ {(2*DW){x[DW-1]}};
    adder_ripple_carry #(.N(2*DW)) restore_sign (
        .a(product_input), .b({(2*DW){1'b0}}), .carry_in(x[DW-1]),
        .sum(signed_product), .carry_out()
    );
    // Fixed arithmetic shifts are wiring, with sign extension.
    assign m = {{QW{signed_product[2*DW-1]}}, signed_product[2*DW-1:QW]};
    assign kk = m[QW +: DW];
    assign frac = m[QW-1:0];

    exp_poly_step #(.PW(PW), .QW(QW)) polynomial_1 (
        .p(C3), .frac(frac), .c(C2), .out(p1)
    );
    exp_poly_step #(.PW(PW), .QW(QW)) polynomial_2 (
        .p(p1), .frac(frac), .c(C1), .out(p0)
    );
    exp_poly_step #(.PW(PW), .QW(QW)) polynomial_3 (
        .p(p0), .frac(frac), .c(ONEQ), .out(pv)
    );

    adder_ripple_carry #(.N(DW)) negate_k (
        .a(~kk), .b({DW{1'b0}}), .carry_in(1'b1),
        .sum(neg_kk), .carry_out()
    );
    mux #(.N(DW)) shift_magnitude (
        .a(kk), .b(neg_kk), .sel(kk[DW-1]), .out(shift_amount)
    );
    assign left_stage[0] = {{(TW-PW){1'b0}}, pv};
    assign right_stage[0] = left_stage[0];

    // Each mux layer conditionally shifts by a constant power of two.
    // Oversized shifts explicitly produce zero rather than wrapping.
    genvar s;
    generate
        for (s = 0; s < DW; s = s + 1) begin : barrel_shift
            wire [TW-1:0] left_candidate, right_candidate;
            if (s < $clog2(TW)) begin : in_range
                localparam integer DIST = 2**s;
                assign left_candidate = {left_stage[s][TW-DIST-1:0], {DIST{1'b0}}};
                assign right_candidate = {{DIST{1'b0}}, right_stage[s][TW-1:DIST]};
            end else begin : oversized
                assign left_candidate = {TW{1'b0}};
                assign right_candidate = {TW{1'b0}};
            end
            mux #(.N(TW)) left_mux (
                .a(left_stage[s]), .b(left_candidate),
                .sel(shift_amount[s]), .out(left_stage[s+1])
            );
            mux #(.N(TW)) right_mux (
                .a(right_stage[s]), .b(right_candidate),
                .sel(shift_amount[s]), .out(right_stage[s+1])
            );
        end
    endgenerate
    mux #(.N(TW)) direction_mux (
        .a(left_stage[DW]), .b(right_stage[DW]),
        .sel(kk[DW-1]), .out(shifted)
    );

    exp_signed_cmp #(.W(DW)) high_compare (
        .a(kk), .b(KHI), .eq(high_eq), .gt(high_gt), .lt()
    );
    exp_signed_cmp #(.W(DW)) low_compare (
        .a(kk), .b(KLO), .eq(low_eq), .gt(), .lt(low_lt)
    );
    exp_signed_cmp #(.W(TW)) value_compare (
        .a(shifted), .b({{(TW-DW){1'b0}}, MAXV}),
        .eq(), .gt(value_gt), .lt()
    );
    or (saturate_high, high_eq, high_gt);
    or (underflow, low_eq, low_lt);
    mux #(.N(DW)) value_clip (
        .a(shifted[DW-1:0]), .b(MAXV), .sel(value_gt), .out(clipped)
    );
    mux #(.N(DW)) low_clip (
        .a(clipped), .b({DW{1'b0}}), .sel(underflow), .out(low_checked)
    );
    mux #(.N(DW)) high_clip (
        .a(low_checked), .b(MAXV), .sel(saturate_high), .out(out)
    );
endmodule

// One Horner stage. Match the reference's PW-bit multiplication context:
// discard the high product bits BEFORE the fractional right shift.
module exp_poly_step #(parameter integer PW = 20, QW = 8)(p, frac, c, out);
    input [PW-1:0] p, c;
    input [QW-1:0] frac;
    output [PW-1:0] out;
    wire [2*PW-1:0] product;
    mul_array #(.N(PW)) multiply (
        .a(p), .b({{(PW-QW){1'b0}}, frac}), .product(product)
    );
    adder_ripple_carry #(.N(PW)) add_constant (
        .a({{QW{1'b0}}, product[PW-1:QW]}), .b(c),
        .carry_in(1'b0), .sum(out), .carry_out()
    );
endmodule

// Sign-bit inversion maps two's-complement order to unsigned order.
module exp_signed_cmp #(parameter integer W = 16)(a, b, eq, gt, lt);
    input [W-1:0] a, b;
    output eq, gt, lt;
    wire [W-1:0] ordered_a, ordered_b;
    assign ordered_a = {~a[W-1], a[W-2:0]};
    assign ordered_b = {~b[W-1], b[W-2:0]};
    cmp #(.DW(W)) compare (
        .a(ordered_a), .b(ordered_b), .aeqb(eq), .agtb(gt), .altb(lt)
    );
endmodule
