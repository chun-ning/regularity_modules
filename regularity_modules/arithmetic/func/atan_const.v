// ------------------------------------------------------------
// atan(2^-i) constants
//
// Same phase scale:
// 65536 = 360 degrees
// ------------------------------------------------------------

function automatic signed [15:0] atan_const;
    input integer index;
    begin
        case (index)
            0:  atan_const = 16'sd8192;
            // atan(1) = 45.000000 deg

            1:  atan_const = 16'sd4836;
            // atan(1/2) = 26.565051 deg

            2:  atan_const = 16'sd2555;
            // atan(1/4) = 14.036243 deg

            3:  atan_const = 16'sd1297;
            // atan(1/8) = 7.125016 deg

            4:  atan_const = 16'sd651;
            // atan(1/16) = 3.576334 deg

            5:  atan_const = 16'sd326;
            // atan(1/32) = 1.789911 deg

            6:  atan_const = 16'sd163;
            // atan(1/64) = 0.895174 deg

            7:  atan_const = 16'sd81;
            // atan(1/128) = 0.447614 deg

            8:  atan_const = 16'sd41;
            // atan(1/256) = 0.223811 deg
            9:  atan_const = 16'sd20;
            10: atan_const = 16'sd10;
            11: atan_const = 16'sd5;
            12: atan_const = 16'sd3;
            13: atan_const = 16'sd1;
            14: atan_const = 16'sd1;
            default:
                atan_const = 16'sd0;
        endcase
    end
endfunction
