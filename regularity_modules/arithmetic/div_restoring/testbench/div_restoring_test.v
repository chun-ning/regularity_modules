`timescale 1ns / 1ps

module div_restoring_test #(parameter integer N = 8); // Change N here
    localparam [N-1:0] ONE = 1;
    localparam [N-1:0] FIVE = 5;
    localparam [N-1:0] THREE = 3;
    localparam [N-1:0] MAX_VALUE = {N{1'b1}};
    localparam [N-1:0] HIGH_BIT = ONE << (N-1);
    localparam [N-1:0] ALTERNATING = {N{2'b10}};

    reg  [N-1:0] a;
    reg  [N-1:0] b;
    wire [N-1:0] quotient;
    wire [N-1:0] remainder;

    integer errors;

    div_restoring #(.N(N)) dut (
        .a(a),
        .b(b),
        .quotient(quotient),
        .remainder(remainder)
    );

    // PASS/FAIL message
    task check;
        input [255:0] test_name;
        input [N-1:0] expected_quotient;
        input [N-1:0] expected_remainder;
        begin
            #1;
            if ((quotient !== expected_quotient) ||
                (remainder !== expected_remainder)) begin
                errors = errors + 1;
                $display("FAIL: test=%s a=%h b=%h expected quotient=%h remainder=%h got quotient=%h remainder=%h",
                         test_name, a, b, expected_quotient, expected_remainder,
                         quotient, remainder);
            end else begin
                $display("PASS: test=%s a=%h b=%h quotient=%h remainder=%h",
                         test_name, a, b, quotient, remainder);
            end
        end
    endtask

    initial begin
        $dumpfile("testbench/waves/div_restoring.vcd");
        $dumpvars(0, div_restoring_test);

        errors = 0;
        if (N < 1) $fatal(1, "N must be at least 1.");

        // DIV: 5 / 3 (operands truncate to N bits for small widths)
        a = FIVE;
        b = THREE;
        check("DIV", FIVE / THREE, FIVE % THREE);

        // DIV: reversed operands
        a = THREE;
        b = FIVE;
        check("DIV reversed", THREE / FIVE, THREE % FIVE);

        // DIV: zero dividend
        a = 0;
        b = MAX_VALUE;
        check("DIV zero dividend", 0, 0);

        // DIV: identity
        a = MAX_VALUE;
        b = ONE;
        check("DIV by one", MAX_VALUE, 0);

        // DIV: equal operands
        a = MAX_VALUE;
        b = MAX_VALUE;
        check("DIV equal operands", ONE, 0);

        // DIV: dividend strictly smaller than divisor
        a = HIGH_BIT - ONE;
        b = HIGH_BIT;
        check("DIV smaller dividend", 0, HIGH_BIT - ONE);

        // DIV: highest operand bit is unsigned
        a = MAX_VALUE;
        b = HIGH_BIT;
        check("DIV by high bit", ONE, HIGH_BIT - ONE);

        // DIV: exact power-of-two division
        a = HIGH_BIT;
        b = HIGH_BIT;
        check("DIV high bits", ONE, 0);

        // DIV: alternating bits
        a = ALTERNATING;
        b = THREE;
        check("DIV alternating bits", ALTERNATING / THREE, ALTERNATING % THREE);

        // DIV: defined division-by-zero behavior
        a = MAX_VALUE;
        b = 0;
        check("DIV by zero", MAX_VALUE, MAX_VALUE);

        a = 0;
        b = 0;
        check("DIV zero by zero", MAX_VALUE, 0);

        if (errors == 0) begin
            $display("All div tests passed.");
        end else begin
            $fatal(1, "Div tests failed with %0d error(s).", errors);
        end

        $finish;
    end
endmodule
