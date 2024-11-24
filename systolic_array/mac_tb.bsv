package mac_tb; 

import mac :: *;

(* synthesize *)

module mkMacTb (Empty);
    Ifc_mac mac_unit <- mkMac;
    Reg #(Bool) put_a <- mkReg(False);
    Reg #(Bool) put_b <- mkReg(False);
    Reg #(Bool) put_c <- mkReg(False);
    Reg #(Bit#(32)) rg_op <- mkReg(0);
    (* descending_urgency = "rl_mac_val1, rl_op" *)
    
    rule rl_mac_val1;
        mac_unit.a(-113);
        put_a <= True;
    endrule
    rule rl_mac_val2;
        mac_unit.b(-14);
        put_b <= True;
    endrule
    rule rl_mac_val3;
        mac_unit.c(-306);
        put_c <= True;
    endrule
    rule rl_op(put_a && put_b && put_c);
    	let op <- mac_unit.mac_op;
    	$display($time," MAC Output:%d %b",op,op);
    	$finish;
    endrule
endmodule

endpackage
