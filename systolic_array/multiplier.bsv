package multiplier;
import adder_subractor :: *;
interface Ifc_multiplier;
    method Action inp(Bit#(16) a,Bit#(16) b);
    method ActionValue #(Bit#(32)) op;
endinterface: Ifc_multiplier
    
typedef struct
    {
        Bit#(32) ip1;
        Bit#(32) ip2;
    }Input  deriving (Bits,Eq);
    
(* synthesize *)
(* descending_urgency = "rl_prod, adder_subractor_rl_sum" *)
module mkMultiplier (Ifc_multiplier);   
    
    Reg#(Input) rg_ip <- mkReg(Input{ip1:0,ip2:0});
    Reg#(Bit#(32)) rg_op <- mkReg (0);
    Reg#(Bool) got_ip <- mkReg (False);
    Reg#(Bool) got_partop <- mkReg (False);
    Ifc_adder_subractor#(32) adder_subractor <- mkAdderSubractor();
    Reg#(Bit#(7)) counter <- mkReg(0);
   
rule rl_ip(counter != 32 &&  got_ip && !got_partop);
    if (rg_ip.ip1[0] == 1)
    begin
        adder_subractor.inp(rg_op , signExtend(rg_ip.ip2),0);
    end
    got_partop <= True;
endrule
rule rl_prod( counter != 32  &&  got_ip && got_partop);
    if (rg_ip.ip1[0] == 1)
    begin
        let op <- adder_subractor.op;
        rg_op <= truncate(pack(op));
    end
    rg_ip <= Input { ip1:rg_ip.ip1 >> 1 , ip2: rg_ip.ip2 << 1};
    got_partop <= False;
    counter <= counter + 1;
endrule

method Action inp(Bit#(16) a,Bit#(16) b) if(!got_ip);
    rg_ip <= Input{ip1:signExtend(a),ip2:signExtend(b)};
    rg_op <= 0;
    got_ip <= True;
    counter <= 0;
endmethod

method ActionValue #(Bit#(32)) op  if (counter == 32 && got_ip && !got_partop);
    got_ip <= False;
    counter <= 0;
    //$display("MUL_OP_:%d ",rg_op);
    return rg_op; 
endmethod

endmodule: mkMultiplier

endpackage: multiplier
