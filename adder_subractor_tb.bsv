package adder_subractor_tb; 

import adder_subractor :: *;

(* synthesize *)

module mkAdderSubractorTb (Empty);
    Ifc_adder_subractor#(16) adder1 <- mkAdderSubractor;
    Ifc_adder_subractor#(16) subtractor1 <- mkAdderSubractor;
    Ifc_adder_subractor#(16) subtractor2 <- mkAdderSubractor;
    Reg #(Output#(17)) rg_op1 <- mkReg(Output{carry_burrow:0,sum_difference:0});
    Reg #(Output#(17)) rg_op2 <- mkReg(Output{carry_burrow:0,sum_difference:0});
    Reg #(Output#(17)) rg_op3 <- mkReg(Output{carry_burrow:0,sum_difference:0});
    Reg#(Bool) opDone <- mkReg(False);
    Reg#(Bit#(32))  counter <- mkReg(0);

    rule inc_counter;
        counter <= counter + 1;
    endrule
    rule rl_add;
    $display("time :%t Input cycle : %d", $time, counter);
	adder1.inp(unpack(11),unpack(9),0);
    subtractor1.inp(unpack(11),unpack(9),1);
    subtractor2.inp(unpack(9),unpack(11),1);
    endrule
    rule rl_sum;
        $display("time :%t Got out cycle : %d",$time, counter);
    	let op1 <- adder1.op;
        rg_op1 <= op1;
        let op2 <- subtractor1.op;
        rg_op2 <= op2;
        let op3 <- subtractor2.op;
        rg_op3 <= op3;
        opDone <= True;
    endrule
    rule rl_disp(opDone);
        $display("time :%t cycle : %d", $time, counter);
    	$display("Output1:%b:%d",rg_op1,rg_op1);
        $display("Output2:%b:%d",rg_op2,rg_op2);
        $display("Output3:%b:%d",rg_op3,rg_op3);
    	$finish;
    endrule
endmodule

endpackage
