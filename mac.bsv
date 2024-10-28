package mac;

import multiplier ::* ;
import adder_subractor ::* ;

interface Ifc_mac;    
    method Action a(Bit#(16) x);
    method Action b(Bit#(16) x);
    method Action c(Bit#(32) x);
    method ActionValue#(Bit#(32)) mac_op;
endinterface
(*synthesize*)
module mkMac (Ifc_mac);
    Ifc_adder_subractor#(32) adder_subractor <- mkAdderSubractor;
    Ifc_multiplier multiplier <- mkMultiplier;
    Reg #(Bit#(16)) rg_a <- mkReg(0);
    Reg #(Bit#(16)) rg_b <- mkReg(0);
    Reg #(Bit#(32)) rg_c <- mkReg(0);
    Reg #(Bool) got_a <- mkReg(False);
    Reg #(Bool) got_b <- mkReg(False);
    Reg #(Bool) got_c <- mkReg(False);
    rule rl_mul(got_a && got_b);
        multiplier.inp(rg_a,rg_b);
    endrule
    rule rl_add;
        let mulop <- multiplier.op;
        
        adder_subractor.inp(extend(pack(mulop)),rg_c,0);
    endrule
    method Action a(Bit#(16) x);
        rg_a <= x;
        got_a <= True;
    endmethod
    method Action b(Bit#(16) x);
        rg_b <= x;
        got_b <= True;
    endmethod
    method Action c(Bit#(32) x);
        rg_c <= x;
        got_c <= True;
    endmethod
    method ActionValue#(Bit#(32)) mac_op if(got_a && got_b && got_c);
         got_a <= False;
         got_b <= False;
         got_c <= False;
         let add_op <- adder_subractor.op;
        
        return truncate(pack(add_op));
        
    endmethod
endmodule
endpackage
