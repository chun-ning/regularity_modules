`timescale 1ns / 1ps

module mul_array_test #(parameter integer N = 8);
    localparam [N-1:0] MAX_VALUE = {N{1'b1}};
    localparam [N-1:0] ALTERNATING = {N{2'b10}};

    reg [N-1:0] a, b;
    wire [2*N-1:0] product;
    reg [2*N-1:0] expected;
    reg [N-1:0] swap;
    integer i, j;
    integer checks;
    integer errors;
    integer errors_before;
    reg report_pass;

    mul_array #(.N(N)) dut (
        .a(a), .b(b), .product(product)
    );

    task check;
        input [255:0] test_name;
        begin
            // Zero-extend both operands to retain the full unsigned product.
            expected = {{N{1'b0}}, a} * {{N{1'b0}}, b};
            #1;
            if (product !== expected) begin
                errors = errors + 1;
                $display("FAIL: test=%s a=%h b=%h expected product=%h got product=%h",
                         test_name, a, b, expected, product);
            end else if (report_pass) begin
                $display("PASS: test=%s a=%h b=%h product=%h",
                         test_name, a, b, product);
            end
            checks = checks + 1;
        end
    endtask

    initial begin
        if (N < 1) $fatal(1, "N must be at least 1.");
        // Waveforms are optional because exhaustive testing produces large files.
        if ($test$plusargs("dump")) begin
            $dumpfile("test/waves/mul_array.vcd");
            $dumpvars(0, mul_array_test);
        end

        checks = 0;
        errors = 0;
        report_pass = 1;
        a = 0; b = 0; check("MUL zero");
        b = MAX_VALUE; check("MUL zero multiplicand");
        a = MAX_VALUE; b = 0; check("MUL zero multiplier");
        b = 1; check("MUL by one");
        a = 1; b = MAX_VALUE; check("MUL one by maximum");
        a = MAX_VALUE; check("MUL two maximums");
        a = 5; b = 3; check("MUL");
        a = ALTERNATING; b = ~ALTERNATING; check("MUL alternating bits");

        // Exercise every partial-product row and the unsigned high bits.
        for (i = 0; i < N; i = i + 1) begin
            a = MAX_VALUE; b = 0; b[i] = 1'b1; check("MUL maximum by power of two");
            swap = a; a = b; b = swap; check("MUL swapped");
            b = a; check("MUL power of two squared");
        end

        // Exhaustive by default (8 bits); skip for larger parameter overrides.
        // Summarize bulk tests; failures still show the exact operands.
        report_pass = 0;
        if (N <= 8) begin
            errors_before = errors;
            for (i = 0; i < (1 << N); i = i + 1)
                for (j = 0; j < (1 << N); j = j + 1) begin
                    a = i; b = j; check("MUL exhaustive");
                end
            $display("%s: test=MUL exhaustive N=%0d cases=%0d errors=%0d",
                     (errors == errors_before) ? "PASS" : "FAIL",
                     N, (1 << (2*N)), errors - errors_before);
        end

        errors_before = errors;
        for (i = 0; i < 100; i = i + 1) begin
            // Fill every bit even when N exceeds $random's 32-bit width.
            for (j = 0; j < N; j = j + 1) begin
                a[j] = $random;
                b[j] = $random;
            end
            check("MUL random");
            swap = a; a = b; b = swap; check("MUL random swapped");
        end

        $display("%s: test=MUL random N=%0d cases=200 errors=%0d",
                 (errors == errors_before) ? "PASS" : "FAIL",
                 N, errors - errors_before);

        if (errors == 0)
            $display("All array multiplier tests passed: N=%0d (%0d checks).", N, checks);
        else
            $fatal(1, "Array multiplier tests failed with %0d error(s).", errors);
        $finish;
    end
endmodule
