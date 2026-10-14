`timescale 1ns / 1ps

module log2_test #(parameter integer N = 8); // Change N here
    localparam integer OUT_WIDTH = (N > 1) ? $clog2(N) : 1;
    localparam [N-1:0] ONE = 1;
    localparam [N-1:0] MAX_VALUE = {N{1'b1}};
    localparam [N-1:0] ALTERNATING = {N{2'b10}};

    reg [N-1:0] a;
    wire [OUT_WIDTH-1:0] out;
    integer errors, checks, i, j, errors_before;
    reg report_pass;

    log2 #(.N(N)) dut (.a(a), .out(out));

    task check;
        input [255:0] test_name;
        reg [N-1:0] remaining;
        integer expected;
        begin
            // Independent reference: count divisions by two until at most one.
            // Both zero and one return zero by the module's convention.
            remaining = a;
            expected = 0;
            while (remaining > 1) begin
                remaining = remaining >> 1;
                expected = expected + 1;
            end
            #1;
            checks = checks + 1;
            if (out !== expected[OUT_WIDTH-1:0]) begin
                errors = errors + 1;
                $display("FAIL: test=%s a=%h expected out=%0d got out=%0d",
                         test_name, a, expected, out);
            end else if (report_pass) begin
                $display("PASS: test=%s a=%h out=%0d", test_name, a, out);
            end
        end
    endtask

    initial begin
        $dumpfile("test/waves/log2.vcd");
        $dumpvars(0, log2_test);
        if (N < 1) $fatal(1, "N must be at least 1.");
        errors = 0;
        checks = 0;
        report_pass = 1;

        a = 0; check("LOG2 zero");
        a = ONE; check("LOG2 one");
        a = MAX_VALUE; check("LOG2 maximum value");
        a = ALTERNATING; check("LOG2 alternating bits");
        a = ~ALTERNATING; check("LOG2 complementary bits");

        // Check every encoded index and the transition to each new power of two.
        for (i = 0; i < N; i = i + 1) begin
            a = ONE << i; check("LOG2 power of two");
            a = (ONE << i) - ONE; check("LOG2 below power of two");
            if ((ONE << i) < MAX_VALUE) begin
                a = (ONE << i) + ONE; check("LOG2 above power of two");
            end
        end
        a = 0; check("LOG2 return to zero");

        // Bulk checks retain detailed failure output without printing every pass.
        report_pass = 0;
        if (N <= 8) begin
            errors_before = errors;
            for (i = 0; i < (1 << N); i = i + 1) begin
                a = i;
                check("LOG2 exhaustive");
            end
            $display("%s: test=LOG2 exhaustive N=%0d cases=%0d errors=%0d",
                     (errors == errors_before) ? "PASS" : "FAIL",
                     N, (1 << N), errors - errors_before);
        end

        errors_before = errors;
        for (i = 0; i < 100; i = i + 1) begin
            // Randomize all bits, including widths greater than 32.
            for (j = 0; j < N; j = j + 1) a[j] = $random;
            check("LOG2 random");
        end
        $display("%s: test=LOG2 random N=%0d cases=100 errors=%0d",
                 (errors == errors_before) ? "PASS" : "FAIL",
                 N, errors - errors_before);

        if (errors == 0)
            $display("All log2 tests passed: N=%0d (%0d checks).", N, checks);
        else
            $fatal(1, "Log2 tests failed with %0d error(s).", errors);
        $finish;
    end
endmodule
