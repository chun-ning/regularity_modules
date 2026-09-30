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

    reg signed [17:0] x_init;
    reg signed [17:0] y_init;
    reg signed [15:0] z_init;

    always @(*) begin
        // angle > +90 degrees
        if (angle > 16'sd16384) begin
            x_init = -K;
            y_init = 18'sd0;
            // subtract 180 degrees
            z_init = angle - 16'sh8000;
        end
        // angle < -90 degrees
        else if (angle < -16'sd16384) begin

            x_init = -K;
            y_init = 18'sd0;
            // add 180 degrees
            z_init = angle + 16'sh8000;
        end else begin
            x_init = K;
            y_init = 18'sd0;
            z_init = angle;
        end
    end

    assign x[0] = x_init;
    assign y[0] = y_init;
    assign z[0] = z_init;


    // ------------------------------------------------------------
    // Unrolled combinational CORDIC stages
    // ------------------------------------------------------------

    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : CORDIC_STAGE
            assign x[i+1] = (z[i] >= 0) ? x[i] - (y[i] >>> i) : x[i] + (y[i] >>> i);
            assign y[i+1] = (z[i] >= 0) ? y[i] + (x[i] >>> i) : y[i] - (x[i] >>> i);
            assign z[i+1] = (z[i] >= 0) ? z[i] - atan_const(i) : z[i] + atan_const(i);
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

    assign cosine = (x[STAGES] > 18'sd32767) ? 16'sd32767 : (x[STAGES] < -18'sd32768)
                    ? -16'sd32768 : x[STAGES][15:0];
    assign sine = (y[STAGES] > 18'sd32767) ? 16'sd32767 : (y[STAGES] < -18'sd32768)
                    ? -16'sd32768 : y[STAGES][15:0];


endmodule