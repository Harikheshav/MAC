package multiplier_tb; 

import multiplier :: *;



module mkMultiplierTb (Empty);
    Ifc_multiplier multiplier <- mkMultiplier;
    Reg#(Bit#(32)) rg_op <- mkReg(0);
    Reg#(Bool) opDone <- mkReg(False);
    Reg#(Bit#(32))  counter <- mkReg(0);

    rule inc_counter;
        counter <= counter + 1;
    endrule
    (* descending_urgency = "rl_mul, rl_product" *)
    rule rl_mul;
        $display("time :%t Input cycle : %d", $time, counter);
	    multiplier.inp(unpack(127),unpack(-360));
    endrule
    rule rl_product;
        $display("time :%t Output cycle : %d", $time, counter);
    	let op <- multiplier.op;
        rg_op <= op;
        opDone <= True;
    endrule
    rule rl_op(opDone);
    	$display("Product:%d %b",rg_op,rg_op);
    	$finish;
    endrule
endmodule

endpackage
