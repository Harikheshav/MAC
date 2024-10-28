package adder_subractor; 

import full_adder_subractor :: *;
import Vector :: * ;

typedef struct 
{
    Bit#(width) ip1;
    Bit#(width) ip2;
} Input#(numeric type width) deriving (Bits, Eq);

typedef struct 
{
  Bit#(1) carry_burrow;
  Bit#(width) sum_difference;
} Output#(numeric type width) deriving (Bits, Eq);

interface Ifc_adder_subractor #(numeric type width);
    method Action inp(Bit#(width) a,Bit#(width) b,Bit #(1) sub);
    method ActionValue #(Output#(TAdd#(width,1))) op;
endinterface

module mkAdderSubractor (Ifc_adder_subractor#(width)); //Based on ripple carry adder_subractor
    Reg #(Bit#(1)) rg_sub <- mkReg(0);
    Reg #(Input#(width)) rg_ip <- mkReg(Input{ip1:0,ip2:0});
    Wire #(Output#((TAdd#(width,1)))) rg_op <- mkWire;
    Reg #(Bool) got_ip <- mkReg(False);
    // Reg #(Bool) opReady <- mkReg(False);
    Vector#(width, Ifc_fullAdderSubractor) fas <-  replicateM(mkfullAdderSubractor());
    let width_val = valueOf(width);

    rule rl_sum(got_ip );
        let ip = rg_ip;
        Bit#(TAdd#(width,1)) carry_burrow = extend(rg_sub);
        Bit#(width) sum_difference = 0;
        for(Integer i=0; i<=width_val-1; i = i+1)
        begin
            //$display($time);
            if(rg_sub == 1)
            begin
            carry_burrow[i+1] = fas[i].borrow(ip.ip1[i],  ip.ip2[i] ,carry_burrow[i]);
            sum_difference[i] = fas[i].difference(ip.ip1[i],ip.ip2[i],carry_burrow[i]);
            end
            else
            begin
            carry_burrow[i+1] = fas[i].carry(ip.ip1[i],  ip.ip2[i] ,carry_burrow[i]);
            sum_difference[i] = fas[i].sum(ip.ip1[i],ip.ip2[i],carry_burrow[i]);
            end
            //$display($time);
        end
        rg_op <= Output {carry_burrow: (rg_sub == 1 && ip.ip1 > ip.ip2) ? ~carry_burrow[width_val]:carry_burrow[width_val] , sum_difference: extend(sum_difference)};
    endrule
    method Action inp(Bit#(width) a,Bit#(width) b,Bit #(1) sub) if(!got_ip);
        rg_ip <= Input{ip1:a,ip2:b};
        got_ip <= True;
        rg_sub <= sub;
    endmethod
    method ActionValue #(Output#((TAdd#(width,1)))) op;
            got_ip  <= False;
            //$display($time,"ADD_OP %d",got_ip);
            return rg_op; 
    endmethod
endmodule

endpackage
