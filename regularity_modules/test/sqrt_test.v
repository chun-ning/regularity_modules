`timescale 1ns / 1ps

module sqrt_test #(parameter integer N = 8);
    localparam integer R = (N+1)/2;
    localparam integer W = 2*R+2;
    reg [N-1:0] a;
    wire [R-1:0] out;
    reg [W-1:0] root_wide, square, next_square;
    reg [W-1:0] candidate, boundary;
    integer i, j, errors, checks;
    reg [31:0] random_word;

    sqrt #(.N(N)) dut (.a(a), .out(out));

    // Integer inequalities uniquely identify floor(sqrt(a)), without
    // reproducing the DUT recurrence or losing precision to real arithmetic.
    task check;
        begin
            #1;
            root_wide = {{(W-R){1'b0}}, out};
            square = root_wide * root_wide;
            next_square = (root_wide + 1'b1) * (root_wide + 1'b1);
            checks = checks + 1;
            if ((^out === 1'bx) || square > a || next_square <= a) begin
                errors = errors + 1;
                $display("FAIL: N=%0d a=%h out=%h", N, a, out);
            end
        end
    endtask

    initial begin
        errors = 0;
        checks = 0;
        if (N < 1) $fatal(1, "N must be at least 1.");
        if ($test$plusargs("dump")) begin
            $dumpfile("test/waves/sqrt.vcd");
            $dumpvars(0, sqrt_test);
        end
        a = 0; check;
        a = 1; check;
        a = {N{1'b1}}; check;
        // Perfect squares and neighbors around every representable power
        // of two, including boundaries above the host integer width.
        for (i = 0; i < R; i = i+1) begin
            candidate = {{(W-1){1'b0}}, 1'b1} << i;
            boundary = candidate * candidate;
            a = boundary - 1'b1; check;
            a = boundary; check;
            a = boundary + 1'b1; check;
        end
        if (N <= 10) begin
            for (i = 0; i < (1 << N); i = i+1) begin
                a = i; check;
            end
        end else begin
            for (i = 0; i < 500; i = i+1) begin
                for (j = 0; j < N; j = j+1) begin
                    if (j % 32 == 0) random_word = $random;
                    a[j] = random_word[j % 32];
                end
                check;
            end
        end
        if (errors) $fatal(1, "Sqrt tests failed: %0d errors.", errors);
        $display("All sqrt tests passed (N=%0d, %0d checks).", N, checks);
        $finish;
    end
endmodule
