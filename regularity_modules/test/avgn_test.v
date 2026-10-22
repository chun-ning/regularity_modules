`timescale 1ns / 1ps

module avgn_case #(parameter integer N = 8, DW = 16)(output reg done);
    localparam integer SW = DW + $clog2(N);
    reg [N*DW-1:0] a;
    wire [DW-1:0] out;
    reg [SW-1:0] total, expected;
    integer i, j, t, checks;

    avgn #(.N(N), .DW(DW)) dut (.a(a), .out(out));

    task check;
        begin
            total = 0;
            for (j = 0; j < N; j = j + 1)
                total = total + a[j*DW +: DW];
            expected = total / N;
            #1;
            checks = checks + 1;
            if (out !== expected[DW-1:0])
                $fatal(1, "N=%0d DW=%0d a=%h expected=%h got=%h",
                       N, DW, a, expected, out);
        end
    endtask

    initial begin
        done = 0;
        checks = 0;
        a = 0; check;
        a = {N*DW{1'b1}}; check; // Maximum sum must not overflow.
        a = 1; check; // Fractional averages round down when N > 1.
        for (i = 0; i < N; i = i + 1) begin
            a = 0;
            a[i*DW +: DW] = {DW{1'b1}};
            check;
        end
        if (N*DW <= 10) begin
            for (t = 0; t < (1 << (N*DW)); t = t + 1) begin
                a = t;
                check;
            end
        end
        for (t = 0; t < 100; t = t + 1) begin
            for (i = 0; i < N*DW; i = i + 1) a[i] = $random;
            check;
        end
        $display("PASS avgn N=%0d DW=%0d (%0d checks)", N, DW, checks);
        done = 1;
    end
endmodule

module avgn_test;
    wire [5:0] done;
    avgn_case #(.N(1), .DW(1)) single_bit (done[0]);
    avgn_case #(.N(1), .DW(8)) single_element (done[1]);
    avgn_case #(.N(3), .DW(3)) non_power_of_two (done[2]);
    avgn_case #(.N(8), .DW(1)) bit_elements (done[3]);
    avgn_case #(.N(8), .DW(16)) defaults (done[4]);
    avgn_case #(.N(5), .DW(33)) wide_elements (done[5]);
    initial begin
        wait (&done);
        $display("All avgn tests passed.");
        $finish;
    end
endmodule
