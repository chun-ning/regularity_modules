`timescale 1ns / 1ps

module clamp_case #(parameter integer DW = 16)(output reg done);
    localparam [DW-1:0] MIN_VALUE = {1'b1, {(DW-1){1'b0}}};
    localparam [DW-1:0] MAX_VALUE = {1'b0, {(DW-1){1'b1}}};
    reg signed [DW-1:0] a, lo, hi;
    wire signed [DW-1:0] out;
    reg signed [DW-1:0] expected;
    integer x, l, h, t, bit_index, checks;

    clamp #(.DW(DW)) dut (.a(a), .lo(lo), .hi(hi), .out(out));

    task check;
        begin
            if (a < lo) expected = lo;
            else if (a > hi) expected = hi;
            else expected = a;
            #1;
            checks = checks + 1;
            if (out !== expected)
                $fatal(1, "DW=%0d a=%0d lo=%0d hi=%0d expected=%0d got=%0d",
                       DW, a, lo, hi, expected, out);
        end
    endtask

    initial begin
        done = 0;
        checks = 0;
        lo = MIN_VALUE; hi = MAX_VALUE;
        a = lo; check;
        a = hi; check;
        a = 0; check;
        lo = 0; hi = 0;
        a = MIN_VALUE; check;
        a = MAX_VALUE; check;
        a = 0; check;
        lo = MIN_VALUE; hi = -1;
        a = MAX_VALUE; check;
        a = -1; check;
        lo = MAX_VALUE; hi = MIN_VALUE;
        a = 0; check; // Reversed bounds retain lower-check priority.

        // Exhaust every input and bound combination at small widths.
        if (DW <= 4) begin
            for (x = 0; x < (1 << DW); x = x + 1)
                for (l = 0; l < (1 << DW); l = l + 1)
                    for (h = 0; h < (1 << DW); h = h + 1) begin
                        a = x; lo = l; hi = h; check;
                    end
        end
        for (t = 0; t < 200; t = t + 1) begin
            for (bit_index = 0; bit_index < DW; bit_index = bit_index + 1) begin
                a[bit_index] = $random;
                lo[bit_index] = $random;
                hi[bit_index] = $random;
            end
            check;
        end
        $display("PASS clamp DW=%0d (%0d checks)", DW, checks);
        done = 1;
    end
endmodule

module clamp_test;
    wire [3:0] done;
    clamp_case #(.DW(1)) one_bit (done[0]);
    clamp_case #(.DW(4)) exhaustive (done[1]);
    clamp_case #(.DW(16)) defaults (done[2]);
    clamp_case #(.DW(33)) wide (done[3]);
    initial begin
        wait (&done);
        $display("All clamp tests passed.");
        $finish;
    end
endmodule
