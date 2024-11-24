package mac_float_tb; 

import mac_float :: *;
import float_point::*;


(* synthesize *)

module mkMacFloatTb (Empty);
    Ifc_mac_float mac_unit <- mkMacFloat;
    Reg #(Bool) put_a <- mkReg(False);
    Reg #(Bool) put_b <- mkReg(False);
    Reg #(Bool) put_c <- mkReg(False);
    Reg #(Bit#(32)) rg_op <- mkReg(0);
    (* descending_urgency = "rl_mac_val1, rl_op" *)
    (* execution_order = "mac_unit_rl_mul, rl_op" *)
    rule rl_mac_val1;
        mac_unit.a('h4080);
        put_a <= True;
    endrule
    rule rl_mac_val2;
        mac_unit.b('h4000);
        put_b <= True;
    endrule
    rule rl_mac_val3;
        mac_unit.c('h3fc00000);
        put_c <= True;
    endrule
    rule rl_op(put_a && put_b && put_c);
    	let op <- mac_unit.mac_op;
    	$display("MAC Output: %h",op);
    	$finish;
    endrule
endmodule

endpackage
