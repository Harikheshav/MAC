package adder_float_tb; 

import adder_float :: *;
import float_point::*;
(* synthesize *)

module mkAdderFloatTb (Empty);
    Ifc_adder_float#(8,24) adder_float <- mkAdderFloat;
    rule rl_add; 
        // // 40200000
        let num1a = extract_fields('h3f800000);
        let num2a = extract_fields('h3fc00000);

        // // 40200000
        let num1b = extract_fields('h3fc00000);
        let num2b = extract_fields('h3f800000);

        // // 40400000
        let num1c = extract_fields('h3fc00000);
        let num2c = extract_fields('h3fc00000);

        // 40600000
        let num1d = extract_fields('h40000000);
        let num2d = extract_fields('h3fc00000);

        // // 40c00000
        let num1e = extract_fields('h40800000);
        let num2e = extract_fields('h40000000);

        // // 42d00000
        let num1f = extract_fields('h42c80000);
        let num2f = extract_fields('h40800000);

        // // 42ca0000
        let num1g = extract_fields('h3f800000);
        let num2g = extract_fields('h42c80000);

        // // 42ca0000
        let num1h = extract_fields('h42c80000);
        let num2h = extract_fields('h3f800000);

        // // 42c80000
        let num1i = extract_fields('h00000000);
        let num2i = extract_fields('h42c80000);

        // // 4e6e6b28
        let num1j = extract_fields('h4e6e6b28);
        let num2j = extract_fields('h00000000);

        // // 4e6e6b28 4e6e6b28
        let num1k = extract_fields('h3f800000);
        let num2k = extract_fields('h4e6e6b28);

        // // 4e6e6b28 4e6e6b28
        let num1l = extract_fields('h4e6e6b28);
        let num2l = extract_fields('h3f800000);

        // // 4e6e7142 4e6e7142
        let num1m = extract_fields('h47c35000);
        let num2m = extract_fields('h4e6e6b28);

        // // 4b3de548 4b3de548
        let num1n = extract_fields('h4b3c5ea8);
        let num2n = extract_fields('h47c35000);

        // // 4b3c5eaa 4b3c5eaa
        let num1o = extract_fields('h40000000);
        let num2o = extract_fields('h4b3c5ea8);

        // // 40a00000 40a00000
        let num1p = extract_fields('h40400000);
        let num2p = extract_fields('h40000000);

        // // 40400003 40400003
        let num1q = extract_fields('h353be7a2);
        let num2q = extract_fields('h40400000);

        // // 3540bc95 3540bc95
        let num1r = extract_fields('h329a9e6b);
        let num2r = extract_fields('h353be7a2);

        // // 329a9e6b 329a9e6b
        let num1s = extract_fields('h00000000);
        let num2s = extract_fields('h329a9e6b);

        // // 00000000 bug 
        let num1t = extract_fields('h00000000);
        let num2t = extract_fields('h00000000);

        // // 3f800000 3f800000
        let num1u = extract_fields('h3f800000);
        let num2u = extract_fields('h00000000);

        // // 43800000  43800000
        let num1v = extract_fields('h437f0000);
        let num2v = extract_fields('h3f800000);

        // // 437f0000 437f0000
        let num1w = extract_fields('h00000000);
        let num2w = extract_fields('h437f0000);

        // // c0400000 c0400000
        let num1x = extract_fields('hc0400000);
        let num2x = extract_fields('h00000000);

        // // c0000000 c0000000
        let num1y = extract_fields('h3f800000);
        let num2y = extract_fields('hc0400000);

        // // c0000000          c0000000
        let num1z = extract_fields('hc0400000);
        let num2z = extract_fields('h3f800000);

        // // c0a00000 c0a00000
        let num1aa = extract_fields('hc0000000);
        let num2aa = extract_fields('hc0400000);

        // // c0000000 c0000000
        let num1ab = extract_fields('h00000000);
        let num2ab = extract_fields('hc0000000);

        // // c2000000 c2000000
        let num1ac = extract_fields('hc2000000);
        let num2ac = extract_fields('h00000000);

        // // bf000000 bf000000
        let num1ad = extract_fields('h41fc0000);
        let num2ad = extract_fields('hc2000000);

        // // 38380000 38380000
        let num1ae = extract_fields('hc1fbffe9);
        let num2ae = extract_fields('h41fc0000);

        // // c1fbffe9 c1fbffe9
        let num1af = extract_fields('h00000000);
        let num2af = extract_fields('hc1fbffe9);

        // // 3fffffff 3fffffff
        let num1ag = extract_fields('h3fffffff);
        let num2ag = extract_fields('h00000000);

        // // 409fffff 409fffff
        let num1ah = extract_fields('h403fffff);
        let num2ah = extract_fields('h3fffffff);

        // // 40400000 40400000
        let num1ai = extract_fields('h3456bf95);
        let num2ai = extract_fields('h403fffff);

        // // 40400001 40400001
        let num1aj = extract_fields('h40400000);
        let num2aj = extract_fields('h3456bf95);
	    adder_float.inp(num1t,num2t);
    endrule
    rule rl_sum;
    	let op <- adder_float.op;
        $display("Sum:%h",pack_fields(op));
    	$finish;
    endrule
endmodule

endpackage
