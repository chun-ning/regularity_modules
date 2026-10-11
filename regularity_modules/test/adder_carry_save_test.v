`timescale 1ns / 1ps

module adder_carry_save_test #(parameter integer N = 8); // Change N here
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
    reg  [N-1:0] c;
    wire [N-1:0] sum;
    wire [N:0]   carry_out;
    reg  [N+1:0] actual;

    integer errors;

    adder_carry_save #(.N(N)) dut (
        .a(a),
        .b(b),
        .c(c),
        .sum(sum),
        .carry_out(carry_out)
    );

    task check;
        input [255:0] test_name;
        input [N-1:0] expected;
        input         expected_carry;
        begin
            #1;
            actual = {2'b0, sum} + {1'b0, carry_out};
            if ((actual !== {1'b0, expected_carry, expected}) ||
                (carry_out[0] !== 1'b0)) begin
                errors = errors + 1;
                $display("FAIL: test=%s a=%h b=%h c=%h expected=%h got=%h sum=%h carry_out=%h",
                         test_name, a, b, c, {1'b0, expected_carry, expected},
                         actual, sum, carry_out);
            end else begin
                $display("PASS: test=%s a=%h b=%h c=%h total=%h sum=%h carry_out=%h",
                         test_name, a, b, c, actual, sum, carry_out);
            end
        end
    endtask

    initial begin
        $dumpfile("test/waves/adder_carry_save.vcd");
        $dumpvars(0, adder_carry_save_test);

        errors = 0;
        if (N < 1) $fatal(1, "N must be at least 1.");

        // ADD: 5 + 3 (operands truncate to N bits for small widths)
        a = FIVE;
        b = THREE;
        c = 1'b0;
        check("ADD", BASIC_SUM[N-1:0], BASIC_SUM[N]);

        // ADD: carry in
        a = 5;
        b = 3;
        c = 1'b1;
        check("ADD + carry in", BASIC_SUM_CIN[N-1:0], BASIC_SUM_CIN[N]);

        // ADD: zero operands
        a = 0;
        b = 0;
        c = 1'b0;
        check("ADD zero", 0, 1'b0);

        // ADD: carry in with zero operands
        a = 0;
        b = 0;
        c = 1'b1;
        check("ADD zero + carry in", ONE, 1'b0);

        // ADD: maximum value without carry out
        a = MAX_VALUE;
        b = 0;
        c = 1'b0;
        check("ADD maximum", MAX_VALUE, 1'b0);

        // ADD: total carries beyond N bits
        a = MAX_VALUE;
        b = 1;
        c = 1'b0;
        check("ADD + carry out", 0, 1'b1);

        // ADD: third operand causes total to carry beyond N bits
        a = MAX_VALUE;
        b = 0;
        c = 1'b1;
        check("ADD carry in + carry out", 0, 1'b1);

        // ADD: two maximum operands
        a = MAX_VALUE;
        b = MAX_VALUE;
        c = 1'b0;
        check("ADD two maximums", (MAX_VALUE - 1), 1'b1);

        // ADD: two maximum operands with carry in
        a = MAX_VALUE;
        b = MAX_VALUE;
        c = 1'b1;
        check("ADD maximums + carry in", MAX_VALUE, 1'b1);

        // ADD: signed boundary (the adder has no overflow output)
        a = (SIGN_BIT - 1);
        b = 1;
        c = 1'b0;
        check("ADD signed boundary", SIGN_BIT, 1'b0);

        // ADD: complementary alternating bits
        a = ALTERNATING;
        b = ~ALTERNATING;
        c = 1'b0;
        check("ADD alternating bits", MAX_VALUE, 1'b0);

        if (errors == 0) begin
            $display("All carry-save adder tests passed.");
        end else begin
            $fatal(1, "Carry-save adder tests failed with %0d error(s).", errors);
        end

        $finish;
    end
endmodule
