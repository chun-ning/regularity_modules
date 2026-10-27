`timescale 1ns / 1ps

module exp_case #(parameter integer DW=16, QW=8)(output reg done);
    reg signed [DW-1:0] x;
    wire signed [DW-1:0] out, expected;
    integer t, i, checks;
    exp #(.DW(DW), .QW(QW)) dut (.x(x), .out(out));
    exp_reference #(.DW(DW), .QW(QW)) reference (.x(x), .out(expected));
    task check;
        begin
            #1;
            checks = checks + 1;
            if (out !== expected)
                $fatal(1, "exp DW=%0d QW=%0d x=%0d expected=%0d got=%0d",
                       DW, QW, x, expected, out);
        end
    endtask
    initial begin
        done=0; checks=0;
        x=0; check;
        x=1; check;
        x=-1; check;
        x={1'b1, {(DW-1){1'b0}}}; check;
        x={1'b0, {(DW-1){1'b1}}}; check;
        if (DW == 16 && QW == 8) begin
            // Every input code across underflow, polynomial, and saturation.
            for (t=-1800; t<=1500; t=t+1) begin x=t; check; end
        end
        if (DW <= 9) begin
            for (t=0; t<(1 << DW); t=t+1) begin x=t; check; end
        end
        for (t=0; t<200; t=t+1) begin
            for (i=0; i<DW; i=i+1) x[i]=$random;
            check;
        end
        $display("PASS exp DW=%0d QW=%0d (%0d checks)", DW, QW, checks);
        done=1;
    end
endmodule

module exp_test;
    wire [4:0] done;
    exp_case #(.DW(16), .QW(8)) defaults(done[0]);
    exp_case #(.DW(9), .QW(8)) narrow(done[1]);
    exp_case #(.DW(12), .QW(4)) fractional_four(done[2]);
    exp_case #(.DW(24), .QW(8)) wide(done[3]);
    exp_case #(.DW(16), .QW(12)) fractional_twelve(done[4]);
    initial begin
        wait (&done);
        $display("All exp tests passed.");
        $finish;
    end
endmodule

// Behavioral reference copied from LogikBench for exact equivalence checks.
//#############################################################################
// Copyright: Zero ASIC. All rights Reserved.
// Author: Andreas Olofsson
// License:  MIT (see LICENSE file in LogikBench repository)
//#############################################################################
module exp_reference #(parameter DW = 16,	// total width
             parameter QW = 8	// fractional bits, Q(DW-QW).QW (QW=8 tuned)
             )
   (
    //Inputs
    input signed [DW-1:0]  x,
    //Outputs
    output signed [DW-1:0] out // e^x, saturated to the output range
    );

   // exp(x) = 2^(x*log2e) = 2^k * 2^f, with k = floor(x*log2e) and f the
   // fractional part in [0,1). The integer part k is a shift; 2^f is a cubic
   // polynomial (Taylor of 2^f). Range reduction + polynomial is the standard
   // hardware/math-library method for exp. Result is saturated to the signed
   // output range (and flushes to 0 when it underflows). Constants are Q8.8.
   localparam signed [DW-1:0] MAXV = (1 <<< (DW-1)) - 1;   // +max
   localparam		      KHI  = DW - QW - 1;        // k >= KHI  -> saturate high (e.g. 7)
   localparam		      KLO  = -(QW + 1);          // k <= KLO  -> underflow to 0 (e.g. -9)
   localparam signed [DW:0]   LOG2E = 369; // log2(e)  in Q8.8
   localparam [DW:0]	      C1   = 177;  // ln2      (2^f Taylor coeffs)
   localparam [DW:0]	      C2   = 61;   // ln2^2/2
   localparam [DW:0]	      C3   = 14;   // ln2^3/6
   localparam [DW:0]	      ONEQ = (1 <<< QW);  // 1.0

   wire signed [2*DW-1:0]     m;     // x*log2e, Q8.8
   wire signed [DW-1:0]	      kk;    // integer part floor(x*log2e)
   wire [QW-1:0]	      frac; // fractional part
   wire [DW+3:0]	      p2, p1, p0, pv;   // 2^frac polynomial (positive)
   wire signed [2*DW:0]	      shifted;

   assign m     = (x * LOG2E) >>> QW;
   assign kk    = m >>> QW;
   assign frac  = m[QW-1:0];

   // 2^frac by Horner: pv = ((C3*f + C2)*f + C1)*f + 1  (Q8.8, in [1,2))
   assign p2 = C3;
   assign p1 = ((p2 * frac) >> QW) + C2;
   assign p0 = ((p1 * frac) >> QW) + C1;
   assign pv = ((p0 * frac) >> QW) + ONEQ;

   // 2^k scaling: left shift for k>=0, right shift for k<0
   assign shifted = (kk >= 0) ? ($signed({1'b0, pv}) <<< kk)
     : ($signed({1'b0, pv}) >>> (-kk));

   assign out = (kk >= KHI)      ? MAXV :
                (kk <= KLO)      ? {DW{1'b0}} :
                (shifted > MAXV) ? MAXV :
                shifted[DW-1:0];

endmodule
