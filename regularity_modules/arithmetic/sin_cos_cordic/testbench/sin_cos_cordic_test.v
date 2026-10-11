`timescale 1ns / 1ps

module sin_cos_cordic_test;
    localparam real PI = 3.14159265358979323846;
    // Default 15-stage CORDIC: allow < 0.001 absolute error for rounded
    // angle constants, finite iterations, and truncated internal shifts.
    localparam integer TOLERANCE = 32;

    reg signed [15:0] angle;
    wire signed [15:0] sine, cosine;
    integer errors, checks, i;
    integer expected_sine, expected_cosine;
    integer sine_error, cosine_error;
    integer max_error;
    reg report_pass;
    real radians;

    sin_cos_cordic dut (.angle(angle), .sine(sine), .cosine(cosine));

    function integer to_q15;
        input real value;
        integer rounded;
        begin
            rounded = $rtoi(value * 32768.0 + ((value >= 0.0) ? 0.5 : -0.5));
            if (rounded > 32767) rounded = 32767;
            if (rounded < -32768) rounded = -32768;
            to_q15 = rounded;
        end
    endfunction

    task check;
        input [255:0] test_name;
        begin
            // actual encoded angle
            radians = $itor($signed(angle)) * (2.0 * PI / 65536.0);
            expected_sine = to_q15($sin(radians));
            expected_cosine = to_q15($cos(radians));
            #1;
            sine_error = $signed(sine) - expected_sine;
            cosine_error = $signed(cosine) - expected_cosine;
            if (sine_error < 0) sine_error = -sine_error;
            if (cosine_error < 0) cosine_error = -cosine_error;
            if (sine_error > max_error) max_error = sine_error;
            if (cosine_error > max_error) max_error = cosine_error;
            checks = checks + 1;

            // Explicitly reject unknowns; numeric comparisons alone miss X/Z.
            if ((^sine === 1'bx) || (^cosine === 1'bx) ||
                sine_error > TOLERANCE || cosine_error > TOLERANCE) begin
                errors = errors + 1;
                $display("FAIL: test=%s angle=%0d expected sine=%0d cosine=%0d got sine=%0d cosine=%0d tolerance=%0d",
                         test_name, angle, expected_sine, expected_cosine,
                         sine, cosine, TOLERANCE);
            end else if (report_pass) begin
                $display("PASS: test=%s angle=%0d sine=%0d cosine=%0d expected sine=%0d cosine=%0d",
                         test_name, angle, sine, cosine, expected_sine, expected_cosine);
            end
        end
    endtask

    initial begin
        $dumpfile("testbench/waves/sin_cos_cordic.vcd");
        $dumpvars(0, sin_cos_cordic_test);
        errors = 0;
        checks = 0;
        max_error = 0;
        report_pass = 1;

        angle = 0;      check("CORDIC zero");
        angle = 8192;   check("CORDIC +45 degrees");
        angle = 16384;  check("CORDIC +90 degrees");
        angle = 24576;  check("CORDIC +135 degrees");
        angle = -32768; check("CORDIC -180 degrees");
        angle = -24576; check("CORDIC -135 degrees");
        angle = -16384; check("CORDIC -90 degrees");
        angle = -8192;  check("CORDIC -45 degrees");
        angle = 5461;   check("CORDIC about +30 degrees");
        angle = -5461;  check("CORDIC about -30 degrees");

        // One phase count either side of quadrant preprocessing boundaries.
        angle = 16383;  check("CORDIC below +90");
        angle = 16385;  check("CORDIC above +90");
        angle = -16385; check("CORDIC below -90");
        angle = -16383; check("CORDIC above -90");
        angle = 32767;  check("CORDIC positive angle limit");
        angle = -32767; check("CORDIC above -180");
        angle = -1;     check("CORDIC below zero");
        angle = 1;      check("CORDIC above zero");

        // Sample the entire signed phase range, including both endpoints.
        // Keep bulk output concise while printing every failing input.
        report_pass = 0;
        for (i = -32768; i <= 32767; i = i + 257) begin
            angle = i;
            check("CORDIC full-range sweep");
        end

        if (errors == 0)
            $display("All CORDIC tests passed: %0d checks, maximum error=%0d Q1.15 counts (tolerance=%0d).",
                     checks, max_error, TOLERANCE);
        else
            $fatal(1, "CORDIC tests failed with %0d error(s).", errors);
        $finish;
    end
endmodule
