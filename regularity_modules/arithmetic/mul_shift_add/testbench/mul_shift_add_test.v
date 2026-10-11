`timescale 1ns / 1ps

module mul_shift_add_test #(parameter integer N = 8); // Change N here
    localparam [N-1:0] ONE = 1;
    localparam [N-1:0] FIVE = 5;
    localparam [N-1:0] THREE = 3;
    localparam [N-1:0] MAX_VALUE = {N{1'b1}};
    localparam [N-1:0] HIGH_BIT = ONE << (N-1);

    // Truncating the repeated pair also supports odd widths.
    localparam [N-1:0] ALTERNATING = {N{2'b10}};
    localparam [N-1:0] COMPLEMENT = ~ALTERNATING;
    localparam [2*N-1:0] BASIC_PRODUCT = {{N{1'b0}}, FIVE} * {{N{1'b0}}, THREE};
    localparam [2*N-1:0] MAX_PRODUCT = {{N{1'b0}}, MAX_VALUE} * {{N{1'b0}}, MAX_VALUE};
    localparam [2*N-1:0] ALTERNATING_PRODUCT = {{N{1'b0}}, ALTERNATING} * {{N{1'b0}}, COMPLEMENT};

    reg  [N-1:0] a;
    reg  [N-1:0] b;
    wire [2*N-1:0] product;

    integer errors;

    mul_shift_add #(.N(N)) dut (
        .a(a),
        .b(b),
        .product(product)
    );

    // PASS/FAIL message
    task check;
        input [255:0] test_name;
        input [2*N-1:0] expected;
        begin
            #1;
            if (product !== expected) begin
                errors = errors + 1;
                $display("FAIL: test=%s a=%h b=%h expected product=%h got product=%h",
                         test_name, a, b, expected, product);
            end else begin
                $display("PASS: test=%s a=%h b=%h product=%h",
                         test_name, a, b, product);
            end
        end
    endtask

    initial begin
        $dumpfile("testbench/waves/mul_shift_add.vcd");
        $dumpvars(0, mul_shift_add_test);

        errors = 0;
        if (N < 1) $fatal(1, "N must be at least 1.");

        // MUL: 5 * 3 (operands truncate to N bits for small widths)
        a = FIVE;
        b = THREE;
        check("MUL", BASIC_PRODUCT);

        // MUL: swapped operands
        a = THREE;
        b = FIVE;
        check("MUL swapped", BASIC_PRODUCT);

        // MUL: zero operands
        a = 0;
        b = 0;
        check("MUL zero", 0);

        // MUL: zero multiplicand
        a = 0;
        b = MAX_VALUE;
        check("MUL zero multiplicand", 0);

        // MUL: zero multiplier
        a = MAX_VALUE;
        b = 0;
        check("MUL zero multiplier", 0);

        // MUL: identity in either operand
        a = MAX_VALUE;
        b = ONE;
        check("MUL by one", {{N{1'b0}}, MAX_VALUE});

        a = ONE;
        b = MAX_VALUE;
        check("MUL one by maximum", {{N{1'b0}}, MAX_VALUE});

        // MUL: full-width product
        a = MAX_VALUE;
        b = MAX_VALUE;
        check("MUL two maximums", MAX_PRODUCT);

        // MUL: highest operand bit is unsigned
        a = HIGH_BIT;
        b = HIGH_BIT;
        check("MUL high bits", {{N{1'b0}}, ONE} << (2*N-2));

        // MUL: highest multiplier bit selects the final partial product
        a = MAX_VALUE;
        b = HIGH_BIT;
        check("MUL maximum by high bit", {{N{1'b0}}, MAX_VALUE} << (N-1));

        // MUL: complementary alternating bits
        a = ALTERNATING;
        b = COMPLEMENT;
        check("MUL alternating bits", ALTERNATING_PRODUCT);

        if (errors == 0) begin
            $display("All multiplier tests passed.");
        end else begin
            $fatal(1, "Multiplier tests failed with %0d error(s).", errors);
        end

        $finish;
    end
endmodule
