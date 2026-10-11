`timescale 1ns / 1ps

module carry_skip_checker #(parameter integer N = 8)(output reg done);
    reg [N-1:0] a, b;
    reg carry_in;
    wire [N-1:0] sum;
    wire carry_out;
    reg [N:0] expected;
    integer i, j, k;
    integer checks;

    adder_carry_skip #(.N(N)) dut (
        .a(a), .b(b), .carry_in(carry_in),
        .sum(sum), .carry_out(carry_out)
    );

    task check;
        begin
            expected = {1'b0, a} + {1'b0, b} + carry_in;
            #1;
            if ({carry_out, sum} !== expected)
                $fatal(1, "N=%0d a=%h b=%h carry_in=%b expected=%h got=%h",
                       N, a, b, carry_in, expected, {carry_out, sum});
            checks = checks + 1;
        end
    endtask

    initial begin
        done = 0;
        checks = 0;

        a = 0; b = 0; carry_in = 0; check;
        carry_in = 1; check;
        // All blocks propagate: exercise both values of the bypassed carry.
        a = {N{1'b1}}; b = 0; carry_in = 0; check;
        carry_in = 1; check;
        // Generate a carry at bit zero and propagate it across the blocks.
        b = 1; carry_in = 0; check;
        // Every bit generates carry, including the final carry-out.
        b = a; check;
        carry_in = 1; check;

        // Stop an incoming carry at each bit, including block boundaries.
        for (i = 0; i < N; i = i + 1) begin
            a = {N{1'b1}}; a[i] = 0;
            b = 0; carry_in = 1; check;
        end

        // Exhaust all inputs for small widths and two complete blocks.
        if (N <= 8) begin
            for (i = 0; i < (1 << N); i = i + 1)
                for (j = 0; j < (1 << N); j = j + 1)
                    for (k = 0; k < 2; k = k + 1) begin
                        a = i; b = j; carry_in = k; check;
                    end
        end

        for (i = 0; i < 1000; i = i + 1) begin
            // Fill every bit, including operands wider than $random's 32 bits.
            for (j = 0; j < N; j = j + 1) begin
                a[j] = $random;
                b[j] = $random;
            end
            carry_in = $random; check;
            b = ~a; carry_in = 0; check;
            carry_in = 1; check;
        end

        $display("PASS: carry-skip N=%0d (%0d checks)", N, checks);
        done = 1;
    end
endmodule

module adder_carry_skip_test;
    wire [7:0] done;
    carry_skip_checker #(.N(1))   width1(done[0]);
    carry_skip_checker #(.N(3))   width3(done[1]);
    carry_skip_checker #(.N(4))   width4(done[2]);
    carry_skip_checker #(.N(5))   width5(done[3]);
    carry_skip_checker #(.N(8))   width8(done[4]);
    carry_skip_checker #(.N(9))   width9(done[5]);
    carry_skip_checker #(.N(17))  width17(done[6]);
    carry_skip_checker #(.N(128)) width128(done[7]);

    initial begin
        if ($test$plusargs("dump")) begin
            $dumpfile("test/waves/adder_carry_skip.vcd");
            $dumpvars(0, adder_carry_skip_test);
        end
        wait (&done);
        $display("All carry-skip adder tests passed.");
        $finish;
    end
endmodule
