`timescale 1ns / 1ps
module if_else_case #(parameter integer N = 4)(output reg done);
    reg condition;
    reg [N-1:0] if_value, else_value;
    wire [N-1:0] out;
    reg [N-1:0] expected;
    integer i, j, t, checks;
    if_else #(.N(N)) dut (condition, if_value, else_value, out);
    task check;
        begin
            expected = condition ? if_value : else_value;
            #1;
            checks = checks + 1;
            if (out !== expected)
                $fatal(1, "if_else N=%0d condition=%b expected=%h got=%h",
                       N, condition, expected, out);
        end
    endtask
    initial begin
        done=0; checks=0;
        if (N <= 4) begin
            for (i=0; i<(1 << N); i=i+1)
                for (j=0; j<(1 << N); j=j+1) begin
                    if_value=i; else_value=j;
                    condition=0; check;
                    condition=1; check;
                end
        end
        for (t=0; t<100; t=t+1) begin
            for (i=0; i<N; i=i+1) begin
                if_value[i]=$random; else_value[i]=$random;
            end
            condition=0; check;
            condition=1; check;
        end
        $display("PASS if_else N=%0d (%0d checks)", N, checks);
        done=1;
    end
endmodule
module if_else_test;
    wire [2:0] done;
    if_else_case #(.N(1)) single_bit(done[0]);
    if_else_case #(.N(4)) exhaustive(done[1]);
    if_else_case #(.N(128)) wide(done[2]);
    initial begin
        wait (&done);
        $display("All if_else tests passed.");
        $finish;
    end
endmodule
