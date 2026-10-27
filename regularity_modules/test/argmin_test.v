`timescale 1ns / 1ps

module argmin_case #(parameter integer N = 8, DW = 16)(output reg done);
    localparam integer OW = (N > 1) ? $clog2(N) : 1;
    reg [N*DW-1:0] a;
    wire [OW-1:0] out;
    reg [OW-1:0] expected;
    reg [DW-1:0] best;
    integer i, j, t, checks;

    argmin #(.N(N), .DW(DW)) dut (.a(a), .out(out));

    task check;
        begin
            expected = 0;
            best = a[0 +: DW];
            for (j = 1; j < N; j = j + 1) begin
                if (a[j*DW +: DW] < best) begin
                    best = a[j*DW +: DW];
                    expected = j;
                end
            end
            #1;
            checks = checks + 1;
            if (out !== expected)
                $fatal(1, "argmin N=%0d DW=%0d a=%h expected=%h got=%h",
                       N, DW, a, expected, out);
        end
    endtask

    initial begin
        done = 0;
        checks = 0;
        a = 0; check;
        a = {N*DW{1'b1}}; check;
        // Put a unique maximum and minimum at every index.
        for (i = 0; i < N; i = i + 1) begin
            a = 0; a[i*DW +: DW] = {DW{1'b1}}; check;
            a = {N*DW{1'b1}}; a[i*DW +: DW] = 0; check;
        end
        // Repeated extremes at nonzero indices exercise tie priority.
        if (N > 2) begin
            a = 0;
            a[DW +: DW] = {DW{1'b1}};
            a[(N-1)*DW +: DW] = {DW{1'b1}}; check;
            a = ~a; check;
        end
        if (N*DW <= 10) begin
            for (t = 0; t < (1 << (N*DW)); t = t + 1) begin
                a = t; check;
            end
        end
        for (t = 0; t < 100; t = t + 1) begin
            for (i = 0; i < N*DW; i = i + 1) a[i] = $random;
            check;
        end
        $display("PASS argmin N=%0d DW=%0d (%0d checks)", N, DW, checks);
        done = 1;
    end
endmodule

module argmin_test;
    wire [6:0] done;
    argmin_case #(.N(1), .DW(1)) single_bit (done[0]);
    argmin_case #(.N(1), .DW(8)) single_element (done[1]);
    argmin_case #(.N(3), .DW(3)) odd_count (done[2]);
    argmin_case #(.N(8), .DW(1)) bit_elements (done[3]);
    argmin_case #(.N(8), .DW(16)) eight_elements (done[4]);
    argmin_case #(.N(5), .DW(33)) wide_elements (done[5]);
    argmin_case #(.N(64), .DW(16)) large_count (done[6]);
    initial begin
        wait (&done);
        $display("All argmin tests passed.");
        $finish;
    end
endmodule
