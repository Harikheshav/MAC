package multiplier_float_tb; 

import multiplier_float :: *;
import float_point::*;
(* synthesize *)

module mkMultiplierFloatTb (Empty);
    Ifc_multiplier_float#(8,7,8,24) multiplier_float <- mkMultiplierFloat;
    rule rl_add;
        let num1 = extract_fields_bf16('h4000);
        let num2 = extract_fields_bf16('h3fc0 );
	    multiplier_float.inp(num1,num2);
    endrule
    rule rl_sum;
    	let op <- multiplier_float.op;
        $display("Product:%h",pack_fields_bf16_fp32(op));
    	$finish;
    endrule
endmodule

endpackage
