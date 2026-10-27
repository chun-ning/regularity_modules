module sin_cos_cordic #(
    parameter integer STAGES = 15
)(
    input  signed [15:0] angle,

    output signed [15:0] sine,
    output signed [15:0] cosine
);
    // ------------------------------------------------------------
    // Fixed-point conventions
    //
    // angle:
    //   65536 counts = 360 degrees
    //   16384        =  90 degrees
    //    8192        =  45 degrees
    //
    // x/y:
    //   Q1.15
    //   32768 ~= 1.0
    //
    // CORDIC gain compensation:
    //   K ~= 0.607252935
    //   K * 32768 ~= 19898
    // ------------------------------------------------------------

    localparam signed [17:0] K = 18'sd19898;

    // Extra bits internally to avoid overflow
    wire signed [17:0] x [0:STAGES];
    wire signed [17:0] y [0:STAGES];

    wire signed [15:0] z [0:STAGES];

    `include "func/atan_const.v"

    // ------------------------------------------------------------
    // Angle preprocessing
    // 
    // Basic coverage: +/-90 degrees
    // Angles outside of range: rotate by 180 degrees, move into convergence range
    // ------------------------------------------------------------

    wire signed [17:0] x_init;
    wire signed [17:0] y_init;
    wire signed [15:0] z_init;
    wire above_range, below_range, outside_range;
    wire [15:0] positive_adjusted, negative_adjusted, lower_selected;

    assign above_range = angle > 16'sd16384;
    assign below_range = angle < -16'sd16384;
    or (outside_range, above_range, below_range);
    assign positive_adjusted = angle - 16'sh8000;
    assign negative_adjusted = angle + 16'sh8000;
    if_else #(.N(18)) initial_x (
        .condition(outside_range), .if_value(-K), .else_value(K), .out(x_init)
    );
    assign y_init = 18'sd0;
    if_else #(.N(16)) negative_angle (
        .condition(below_range), .if_value(negative_adjusted),
        .else_value(angle), .out(lower_selected)
    );
    if_else #(.N(16)) positive_angle (
        .condition(above_range), .if_value(positive_adjusted),
        .else_value(lower_selected), .out(z_init)
    );

    assign x[0] = x_init;
    assign y[0] = y_init;
    assign z[0] = z_init;


    // ------------------------------------------------------------
    // Unrolled combinational CORDIC stages
    // ------------------------------------------------------------

    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : CORDIC_STAGE
            wire [17:0] x_positive, x_negative, y_positive, y_negative;
            wire [15:0] z_positive, z_negative;
            wire positive_rotation;
            assign positive_rotation = ~z[i][15];
            assign x_positive = x[i] - (y[i] >>> i);
            assign x_negative = x[i] + (y[i] >>> i);
            assign y_positive = y[i] + (x[i] >>> i);
            assign y_negative = y[i] - (x[i] >>> i);
            assign z_positive = z[i] - atan_const(i);
            assign z_negative = z[i] + atan_const(i);
            if_else #(.N(18)) select_x (
                .condition(positive_rotation), .if_value(x_positive),
                .else_value(x_negative), .out(x[i+1])
            );
            if_else #(.N(18)) select_y (
                .condition(positive_rotation), .if_value(y_positive),
                .else_value(y_negative), .out(y[i+1])
            );
            if_else #(.N(16)) select_z (
                .condition(positive_rotation), .if_value(z_positive),
                .else_value(z_negative), .out(z[i+1])
            );
        end
    endgenerate

    // ------------------------------------------------------------
    // Output
    //
    // Q1.15 (1 bit sign, 15 bits fractional bits)
    //
    //  32767 ~= +1.0
    //      0  =   0.0
    // -32768  =  -1.0
    // ------------------------------------------------------------

    wire [15:0] cosine_low_checked, sine_low_checked;
    if_else #(.N(16)) cosine_low (
        .condition(x[STAGES] < -18'sd32768), .if_value(-16'sd32768),
        .else_value(x[STAGES][15:0]), .out(cosine_low_checked)
    );
    if_else #(.N(16)) cosine_high (
        .condition(x[STAGES] > 18'sd32767), .if_value(16'sd32767),
        .else_value(cosine_low_checked), .out(cosine)
    );
    if_else #(.N(16)) sine_low (
        .condition(y[STAGES] < -18'sd32768), .if_value(-16'sd32768),
        .else_value(y[STAGES][15:0]), .out(sine_low_checked)
    );
    if_else #(.N(16)) sine_high (
        .condition(y[STAGES] > 18'sd32767), .if_value(16'sd32767),
        .else_value(sine_low_checked), .out(sine)
    );
endmodule
