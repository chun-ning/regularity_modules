`timescale 1ns / 1ps

module abs_test #(parameter integer N = 8); // Change N here
    localparam [N-1:0] ONE = 1;
    localparam [N-1:0] MIN_VALUE = ONE << (N-1);
    localparam [N-1:0] MAX_POSITIVE = MIN_VALUE - ONE;
    localparam [N-1:0] ALTERNATING = {N{2'b10}};

    reg signed [N-1:0] a;
    wire [N-1:0] out;
    integer errors, checks, i, j, errors_before;
    reg report_pass;

    abs #(.N(N)) dut (.a(a), .out(out));

    task check;
        input [255:0] test_name;
        reg signed [N:0] extended;
        reg [N:0] expected;
        begin
            // Widen before negation so the most-negative input cannot overflow.
            extended = {a[N-1], a};
            expected = (extended < 0) ? -extended : extended;
            #1;
            checks = checks + 1;
            if ({1'b0, out} !== expected) begin
                errors = errors + 1;
                $display("FAIL: test=%s a=%h expected out=%h got out=%h",
                         test_name, a, expected[N-1:0], out);
            end else if (report_pass) begin
                $display("PASS: test=%s a=%h out=%h", test_name, a, out);
            end
        end
    endtask

    initial begin
        $dumpfile("testbench/waves/abs.vcd");
        $dumpvars(0, abs_test);
        if (N < 1) $fatal(1, "N must be at least 1.");
        errors = 0;
        checks = 0;
        report_pass = 1;

        a = 0; check("ABS zero");
        // Positive one is representable only when N >= 2.
        if (N > 1) begin
            a = ONE; check("ABS positive one");
        end
        a = -1; check("ABS negative one");
        a = MAX_POSITIVE; check("ABS maximum positive");
        a = MIN_VALUE; check("ABS minimum negative");
        a = MIN_VALUE + ONE; check("ABS above minimum negative");
        a = -MAX_POSITIVE; check("ABS negated maximum positive");
        a = ALTERNATING; check("ABS alternating bits");
        a = ~ALTERNATING; check("ABS complementary bits");
        a = 0; check("ABS return to zero");

        // Bulk checks retain detailed failure output without printing every pass.
        report_pass = 0;
        if (N <= 8) begin
            errors_before = errors;
            for (i = 0; i < (1 << N); i = i + 1) begin
                a = i;
                check("ABS exhaustive");
            end
            $display("%s: test=ABS exhaustive N=%0d cases=%0d errors=%0d",
                     (errors == errors_before) ? "PASS" : "FAIL",
                     N, (1 << N), errors - errors_before);
        end

        errors_before = errors;
        for (i = 0; i < 100; i = i + 1) begin
            // Randomize all bits, including widths greater than 32.
            for (j = 0; j < N; j = j + 1) a[j] = $random;
            check("ABS random");
        end
        $display("%s: test=ABS random N=%0d cases=100 errors=%0d",
                 (errors == errors_before) ? "PASS" : "FAIL",
                 N, errors - errors_before);

        if (errors == 0)
            $display("All abs tests passed: N=%0d (%0d checks).", N, checks);
        else
            $fatal(1, "Abs tests failed with %0d error(s).", errors);
        $finish;
    end
endmodule
