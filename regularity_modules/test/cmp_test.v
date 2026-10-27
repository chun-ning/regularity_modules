`timescale 1ns / 1ps

module cmp_case #(parameter integer DW = 16)(output reg done);
    reg [DW-1:0] a, b;
    wire aeqb, agtb, altb;
    reg [2:0] expected;
    integer i, j, t, checks;

    cmp #(.DW(DW)) dut (.a(a), .b(b), .aeqb(aeqb), .agtb(agtb), .altb(altb));

    task check;
        begin
            expected = {a == b, a > b, a < b};
            #1;
            checks = checks + 1;
            if ({aeqb, agtb, altb} !== expected)
                $fatal(1, "cmp DW=%0d a=%h b=%h expected=%b got=%b",
                       DW, a, b, expected, {aeqb, agtb, altb});
        end
    endtask

    initial begin
        done = 0; checks = 0;
        a = 0; b = 0; check;
        a = {DW{1'b1}}; b = a; check;
        b = 0; check;
        a = 0; b = {DW{1'b1}}; check;
        // A higher differing bit must outweigh all lower bits.
        for (i = 0; i < DW; i = i + 1) begin
            a = 0; a[i] = 1'b1; b = a - 1'b1; check;
            b = a; a = b - 1'b1; check;
        end
        if (DW <= 4) begin
            for (i = 0; i < (1 << DW); i = i + 1)
                for (j = 0; j < (1 << DW); j = j + 1) begin
                    a = i; b = j; check;
                end
        end
        for (t = 0; t < 200; t = t + 1) begin
            for (i = 0; i < DW; i = i + 1) begin
                a[i] = $random;
                b[i] = $random;
            end
            check;
            b = a; check;
        end
        $display("PASS cmp DW=%0d (%0d checks)", DW, checks);
        done = 1;
    end
endmodule

module cmp_test;
    wire [3:0] done;
    cmp_case #(.DW(1)) one_bit (done[0]);
    cmp_case #(.DW(4)) exhaustive (done[1]);
    cmp_case #(.DW(16)) defaults (done[2]);
    cmp_case #(.DW(33)) wide (done[3]);
    initial begin
        wait (&done);
        $display("All cmp tests passed.");
        $finish;
    end
endmodule
