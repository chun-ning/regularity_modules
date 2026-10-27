// ============================================================
// clz.v
// ============================================================
// Count leading (MSB-side) zeros, returning DW for an all-zero input.
// DW must be >= 1. Combinational gate-level implementation.
module clz #(parameter integer DW = 16)(a, out);

    input [DW-1:0] a;
    output [$clog2(DW):0] out;

    localparam integer OW = $clog2(DW) + 1;
    wire [OW-1:0] count [0:DW];
    wire [DW:0] found;

    assign count[0] = {OW{1'b0}};
    assign found[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < DW; i = i + 1) begin : count_bits
            wire increment;
            // Increment only before the first one, while this bit is zero.
            or (found[i+1], found[i], a[DW-1-i]);
            nor (increment, found[i], a[DW-1-i]);
            adder_ripple_carry #(.N(OW)) increment_count (
                .a(count[i]), .b({OW{1'b0}}), .carry_in(increment),
                .sum(count[i+1]), .carry_out()
            );
        end
    endgenerate

    assign out = count[DW];
endmodule
