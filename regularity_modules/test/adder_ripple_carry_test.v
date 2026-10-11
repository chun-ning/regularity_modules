`timescale 1ns / 1ps

module adder_test #(parameter integer N = 8); // Change N here
    localparam [N-1:0] ONE = 1;
    localparam [N-1:0] FIVE = 5;
    localparam [N-1:0] THREE = 3;
    localparam [N-1:0] MAX_VALUE = {N{1'b1}};
    localparam [N-1:0] SIGN_BIT = 1 << (N-1);
    
    // Truncating the repeated pair also supports odd widths.
    localparam [N-1:0] ALTERNATING = {N{2'b10}};
    localparam [N:0] BASIC_SUM = {1'b0, FIVE} + {1'b0, THREE};
    localparam [N:0] BASIC_SUM_CIN = BASIC_SUM + 1'b1;

    reg  [N-1:0] a;
    reg  [N-1:0] b;
    reg          carry_in;
    wire [N-1:0] sum;
    wire         carry_out;

    integer errors;

    adder_ripple_carry #(.N(N)) dut (
        .a(a),
        .b(b),
        .carry_in(carry_in),
        .sum(sum),
        .carry_out(carry_out)
    );

    // PASS/FAIL message
    task check;
        input [255:0] test_name;
        input [N-1:0] expected;
        input         expected_carry;
        begin
            #1;
            if ((sum !== expected) ||
                (carry_out !== expected_carry)) begin
                errors = errors + 1;
                $display("FAIL: test=%s a=%h b=%h carry_in=%b expected sum=%h carry_out=%b got sum=%h carry_out=%b",
                         test_name, a, b, carry_in, expected, expected_carry,
                         sum, carry_out);
            end else begin
                $display("PASS: test=%s a=%h b=%h carry_in=%b sum=%h carry_out=%b",
                         test_name, a, b, carry_in, sum, carry_out);
            end
        end
    endtask

    initial begin
        $dumpfile("test/waves/adder.vcd");
        $dumpvars(0, adder_test);

        errors = 0;
        if (N < 1) $fatal(1, "N must be at least 1.");

        // ADD: 5 + 3 (operands truncate to N bits for small widths)
        a = FIVE;
        b = THREE;
        carry_in = 1'b0;
        check("ADD", BASIC_SUM[N-1:0], BASIC_SUM[N]);

        // ADD: carry in
        a = 5;
        b = 3;
        carry_in = 1'b1;
        check("ADD + carry in", BASIC_SUM_CIN[N-1:0], BASIC_SUM_CIN[N]);

        // ADD: zero operands
        a = 0;
        b = 0;
        carry_in = 1'b0;
        check("ADD zero", 0, 1'b0);

        // ADD: carry in with zero operands
        a = 0;
        b = 0;
        carry_in = 1'b1;
        check("ADD zero + carry in", ONE, 1'b0);

        // ADD: maximum value without carry out
        a = MAX_VALUE;
        b = 0;
        carry_in = 1'b0;
        check("ADD maximum", MAX_VALUE, 1'b0);

        // ADD: carry propagates through all N bits
        a = MAX_VALUE;
        b = 1;
        carry_in = 1'b0;
        check("ADD + carry out", 0, 1'b1);

        // ADD: carry in propagates through all N bits
        a = MAX_VALUE;
        b = 0;
        carry_in = 1'b1;
        check("ADD carry in + carry out", 0, 1'b1);

        // ADD: two maximum operands
        a = MAX_VALUE;
        b = MAX_VALUE;
        carry_in = 1'b0;
        check("ADD two maximums", (MAX_VALUE - 1), 1'b1);

        // ADD: two maximum operands with carry in
        a = MAX_VALUE;
        b = MAX_VALUE;
        carry_in = 1'b1;
        check("ADD maximums + carry in", MAX_VALUE, 1'b1);

        // ADD: signed boundary (the adder has no overflow output)
        a = (SIGN_BIT - 1);
        b = 1;
        carry_in = 1'b0;
        check("ADD signed boundary", SIGN_BIT, 1'b0);

        // ADD: complementary alternating bits
        a = ALTERNATING;
        b = ~ALTERNATING;
        carry_in = 1'b0;
        check("ADD alternating bits", MAX_VALUE, 1'b0);

        if (errors == 0) begin
            $display("All adder tests passed.");
        end else begin
            $fatal(1, "Adder tests failed with %0d error(s).", errors);
        end

        $finish;
    end
endmodule
