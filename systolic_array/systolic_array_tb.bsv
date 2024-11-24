package systolic_array_tb;
import systolic_array :: *;
import Vector :: *;
(* synthesize *)

module mkSystolicArrayTb (Empty);
    Ifc_sys_array sys_unit <- mkSystolicArray;
    Reg #(Bit#(4)) count_a <- mkReg(0);
    Reg #(Bit#(4)) count_b <- mkReg(0);
    Reg #(Bit#(32)) rg_op <- mkReg(0);
    rule rl_sys_val1(count_a <9);
        Bit#(16) a = extend(count_a)/*+100*/;
        sys_unit.a(10000+a);
        count_a <= count_a + 1;
    endrule
    rule rl_sys_val2(count_b <9);
        Bit#(16) b = extend(count_b)/*+200*/;
        sys_unit.b(10000+b);
        count_b <= count_b + 1;
    endrule
    rule rl_mat_op(count_a == 9 && count_b == 9);
        let op = sys_unit.op;
        $display("------------------------");
        for(int i = 0; i<9;i=i+1)
        begin
            $display($time,"op:%d %d",i,op[i]);
        end
        $finish;
    endrule
endmodule

endpackage
