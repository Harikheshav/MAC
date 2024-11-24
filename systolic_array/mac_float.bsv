package mac_float;

import multiplier_float ::* ;
import adder_float ::* ;
import float_point::*;

interface Ifc_mac_float;    
    method Action a(Bit#(16) x);
    method Action b(Bit#(16) x);
    method Action c(Bit#(32) x);
    method ActionValue#(Bit#(32)) mac_op;
endinterface
module mkMacFloat (Ifc_mac_float);
    Ifc_adder_float#(8,24) adder_float <- mkAdderFloat;
    Ifc_multiplier_float#(8,7,8,24) multiplier_float <- mkMultiplierFloat;
    Reg #(Bit#(16)) rg_a <- mkReg(0);
    Reg #(Bit#(16)) rg_b <- mkReg(0);
    Reg #(Bit#(32)) rg_c <- mkReg(0);
    Reg #(Bool) got_a <- mkReg(False);
    Reg #(Bool) got_b <- mkReg(False);
    rule rl_mul(got_a && got_b);
        multiplier_float.inp(extract_fields_bf16(rg_a),extract_fields_bf16(rg_b));
    endrule
    rule rl_add;
        let mulop <- multiplier_float.op;
        adder_float.inp(extract_fields(pack_fields_bf16_fp32(mulop)),extract_fields(rg_c));
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
    endmethod
    method ActionValue#(Bit#(32)) mac_op;
         got_a <= False;
         got_b <= False;
         let add_op <- adder_float.op;
        return pack_fields(add_op);
    endmethod
endmodule
endpackage
