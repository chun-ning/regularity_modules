`timescale 1ns / 1ps

module comparator_checker #(parameter integer N = 8)(output reg done);
    reg [N-1:0] a, b;
    wire [1:0] out;
    reg [1:0] expected;
    integer i, j;
    integer checks;

    comparator #(.N(N)) dut (.a(a), .b(b), .out(out));

    task check;
        begin
            // Unsigned reference: less = 0, equal = 1, greater = 2.
            expected = (a < b) ? 2'd0 : (a > b) ? 2'd2 : 2'd1;
            #1;
            if (out !== expected)
                $fatal(1, "N=%0d a=%h b=%h expected=%d got=%d",
                       N, a, b, expected, out);
            checks = checks + 1;
        end
    endtask

    initial begin
        done = 0;
        checks = 0;
        a = 0; b = 0; check;
        a = {N{1'b1}}; check;
        b = a; check;
        a = 0; check;

        // Each bit must override all lower bits, including the unsigned MSB.
        for (i = 0; i < N; i = i + 1) begin
            a = 0; a[i] = 1; b = a - 1'b1; check;
            b = a; a = b - 1'b1; check;
            // Return to equality to catch stale combinational state.
            a = b; check;
        end

        if (N <= 8) begin
            for (i = 0; i < (1 << N); i = i + 1)
                for (j = 0; j < (1 << N); j = j + 1) begin
                    a = i; b = j; check;
                end
        end

        for (i = 0; i < 1000; i = i + 1) begin
            // Randomize every bit even when N exceeds 32.
            for (j = 0; j < N; j = j + 1) begin
                a[j] = $random;
                b[j] = $random;
            end
            check;
            b = a; check;
        end

        $display("PASS: comparator N=%0d (%0d checks)", N, checks);
        done = 1;
    end
endmodule

module comparator_test;
    wire [4:0] done;
    comparator_checker #(.N(1))   width1(done[0]);
    comparator_checker #(.N(4))   width4(done[1]);
    comparator_checker #(.N(8))   width8(done[2]);
    comparator_checker #(.N(17))  width17(done[3]);
    comparator_checker #(.N(128)) width128(done[4]);

    initial begin
        if ($test$plusargs("dump")) begin
            $dumpfile("test/waves/comparator.vcd");
            $dumpvars(0, comparator_test);
        end
        wait (&done);
        $display("All comparator tests passed.");
        $finish;
    end
endmodule
