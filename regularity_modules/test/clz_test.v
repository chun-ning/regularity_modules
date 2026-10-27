`timescale 1ns / 1ps

module clz_case #(parameter integer DW = 16)(output reg done);
    reg [DW-1:0] a;
    wire [$clog2(DW):0] out;
    integer expected, i, j, t, checks;

    clz #(.DW(DW)) dut (.a(a), .out(out));

    task check;
        begin
            // Highest set-bit position gives the number of leading zeros.
            expected = DW;
            for (j = 0; j < DW; j = j + 1)
                if (a[j]) expected = DW-1-j;
            #1;
            checks = checks + 1;
            if (out !== expected)
                $fatal(1, "clz DW=%0d a=%h expected=%0d got=%0d",
                       DW, a, expected, out);
        end
    endtask

    initial begin
        done = 0; checks = 0;
        a = 0; check;
        a = {DW{1'b1}}; check;
        // Exercise every possible leading-zero count and varied suffixes.
        for (i = 0; i < DW; i = i + 1) begin
            a = 0; a[i] = 1'b1; check;
            a = a | (a - 1'b1); check;
            a = 0; check;
        end
        if (DW <= 8) begin
            for (t = 0; t < (1 << DW); t = t + 1) begin
                a = t; check;
            end
        end
        for (t = 0; t < 200; t = t + 1) begin
            for (i = 0; i < DW; i = i + 1) a[i] = $random;
            // Vary the leading-zero count instead of mostly testing 0 or 1.
            a = a >> (t % DW);
            check;
        end
        $display("PASS clz DW=%0d (%0d checks)", DW, checks);
        done = 1;
    end
endmodule

module clz_test;
    wire [5:0] done;
    clz_case #(.DW(1)) one_bit (done[0]);
    clz_case #(.DW(3)) odd_width (done[1]);
    clz_case #(.DW(8)) exhaustive (done[2]);
    clz_case #(.DW(16)) defaults (done[3]);
    clz_case #(.DW(33)) wide (done[4]);
    clz_case #(.DW(128)) width128 (done[5]);
    initial begin
        wait (&done);
        $display("All clz tests passed.");
        $finish;
    end
endmodule
