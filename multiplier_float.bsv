package multiplier_float; 

import float_point::*;
import multiplier :: *;
import adder_subractor :: *;

typedef struct 
{
    Float#(exp_bits,mant_bits) ip1;
    Float#(exp_bits,mant_bits) ip2;
} Input#(numeric type exp_bits,numeric type mant_bits) deriving (Bits, Eq);

interface Ifc_multiplier_float #(numeric type ip_exp_bits,numeric type ip_mant_bits,numeric type op_exp_bits,numeric type op_mant_bits);
    method Action inp(Float#(ip_exp_bits,ip_mant_bits) a,Float#(ip_exp_bits,ip_mant_bits) b);
    method ActionValue #(Float#(ip_exp_bits,ip_mant_bits)) op;
endinterface

module mkMultiplierFloat (Ifc_multiplier_float#(ip_exp_bits, ip_mant_bits,op_exp_bits,op_mant_bits))
                     provisos(Add#(1, a__, ip_mant_bits),
                     Add#(b__, 2, ip_mant_bits),
                     Add#(c__, 3, ip_mant_bits),
                     Add#(d__, ip_exp_bits, 34),
                     Add#(e__, ip_exp_bits, 32),
                     Add#(f__, TAdd#(ip_mant_bits, ip_mant_bits), 32),
                     Add#(g__, ip_mant_bits, 16));
    Reg #(Input#(ip_exp_bits,ip_mant_bits)) rg_ip <- mkReg(unpack(0));
    Reg #(Float#(ip_exp_bits,TAdd#(ip_mant_bits,1))) rg_stage1 <- mkReg(unpack(0));
    Reg #(Float#(ip_exp_bits,ip_mant_bits)) rg_prod <- mkReg(unpack(0));
    Reg#(FP_RS) rg_rsout <- mkReg(unpack(0));
    Reg#(Bit#(ip_exp_bits)) rg_expout <- mkReg(0);
    Reg #(Bit#(ip_mant_bits)) rg_mantout <- mkReg(unpack(0));
    Reg #(Bool) got_ip <- mkReg(False);
    Reg #(Bool) got_exp_out <- mkReg(False);
    Reg #(Bool) got_mul_out <- mkReg(False);
    Reg #(Bool) got_mant_out <- mkReg(False);
    Reg #(Bool) got_exp_inc <- mkReg(False);
    Reg #(Bool) done_add_sub <- mkReg(False);
    Reg #(Bool) exp_add <- mkReg(False);
    Reg #(Bool) opReady <- mkReg(False);
    let expSize =  valueOf(ip_exp_bits);
    Bit#(1) signout = rg_ip.ip1.sign != rg_ip.ip2.sign ? 1 : 0;
    Integer opSize = valueOf(ip_mant_bits) ;
    //Ifc_adder_subractor adder_subractor <-  mkAdderSubractor();
    Ifc_adder_subractor#(32) adder_subractor_expadd <-  mkAdderSubractor();
    Ifc_adder_subractor#(32) adder_subractor_expinc <-  mkAdderSubractor();
    Ifc_multiplier multiplier <- mkMultiplier;
    
    (* descending_urgency="rl_normalize1exp , adder_subractor_expinc_rl_sum" *)
    (* descending_urgency="rl_multmantout , rl_add_expop" *)
    rule rl_add_exp( got_ip && !got_exp_out);
      if((rg_ip.ip1.exp != 0) && (rg_ip.ip2.exp != 0 ))
      begin 
         adder_subractor_expadd.inp(extend(rg_ip.ip1.exp),extend(rg_ip.ip2.exp),0);
         exp_add <= True;
      end
      else
         rg_expout <= 0;
      got_exp_out <= True;
    endrule
    rule rl_add_expop( got_ip && got_exp_out && exp_add);
      let bias = (1 << (expSize - 1))-1; //Stage-1
      let exp_op <- adder_subractor_expadd.op;
      Bit#(ip_exp_bits) expout = truncate(pack(exp_op)) - bias; 
      rg_expout <= expout;
      exp_add <= False;
    endrule
    rule rl_multmant( got_ip && got_exp_out && !got_mul_out);
         multiplier.inp(extend(rg_ip.ip1.mant), extend(rg_ip.ip2.mant));
         got_mul_out <= True;
    endrule
    rule rl_multmantout( got_ip && got_exp_out && got_mul_out);
      let mul_op <- multiplier.op;
      Bit#(TAdd#(ip_mant_bits,ip_mant_bits)) multout = truncate(pack(mul_op));
      Bit#(TAdd#(ip_mant_bits,1)) mantout   = multout[(opSize+opSize)-1:opSize-1] ; 
      Bit#(TAdd#(ip_mant_bits,2)) stickies = multout[opSize-3:0] ;
      Bit#(1)  sticky   = (stickies != 0) ? 1'b1 : 1'b0  ;
      FP_RS    rsout    = {multout[opSize-2], sticky } ;
      let stage1 = Float{ sign:signout, exp:rg_expout, mant:mantout, rs:rsout };   
      rg_stage1 <= stage1;
      got_exp_out <= False;
      got_mul_out <= False;
      got_mant_out <= True;
    endrule
    rule rl_normalize1(got_mant_out && got_ip && !got_exp_out && !got_mul_out && !opReady && !got_exp_inc);
        FP_RS   rsout = 0;
        Bit#(2) carrymsb = rg_stage1.mant[valueOf(ip_mant_bits): valueOf(TSub#(ip_mant_bits,1))]; 
        //$display("stage1:%h",rg_stage1.mant);
        if ( 1 == carrymsb[1] )
        begin
            // TODO overflow can occur here
            adder_subractor_expinc.inp(extend(rg_stage1.exp) , 1,0);
            rg_mantout <= truncate( rg_stage1.mant >> 1) ;
            rg_rsout <= {rg_stage1.mant[0], pack(rg_stage1.rs != 0) } ;
            done_add_sub <= True;
            //$display("rl_normalize1 if");
        end
        else if ( rg_stage1.exp == 0 )      // Denormalized case -- do not modify
        begin
            rg_expout <= rg_stage1.exp;
            rg_mantout <= truncate ( rg_stage1.mant );
            rg_rsout  <= 2'b00 ;
            //$display("rl_normalize1 else if1");
        end
        else if ( 1 == carrymsb[0] ) // The sum is in normalized form
        begin
            rg_expout <= rg_stage1.exp;
            rg_mantout <= truncate ( rg_stage1.mant );
            rg_rsout  <= 2'b00 ;
            //$display("rl_normalize1 else if2");
        end
        else
        begin                  // left shift by 1
            adder_subractor_expinc.inp(extend(rg_stage1.exp) , 1 ,1);
            let vectorsize = fromInteger(valueOf(ip_exp_bits)) ;
            rg_mantout <= {rg_stage1.mant[vectorsize-3:0] ,  rg_stage1.rs[0] } ;
            rg_rsout  <= {1'b0, rg_stage1.rs[0] };
            done_add_sub <= True;
            //$display("rl_normalize1 else");
        end
        got_exp_inc <= True;
    endrule

    rule rl_normalize1exp(got_mant_out && got_ip && !got_exp_out && !got_mul_out && !opReady && got_exp_inc);
        if(done_add_sub)
        begin
            let expop <- adder_subractor_expinc.op;
            rg_expout <= truncate(pack(expop));
            //$display("rl_normalize1exp if");
        end
       let prod = Float{ sign:rg_stage1.sign, exp:rg_expout, mant:rg_mantout, rs:rg_rsout };
       opReady<=True;
       rg_prod <= prod;
       got_exp_inc <= False;
       got_mant_out <= False;
    endrule

    method Action inp(Float#(ip_exp_bits,ip_mant_bits) a,Float#(ip_exp_bits,ip_mant_bits) b) if(!got_ip);
        rg_ip <= Input{ip1:a,ip2:b};
        got_ip <= True;
    endmethod
    method ActionValue #(Float#(ip_exp_bits,ip_mant_bits)) op if(opReady);
            opReady <= False;
            got_ip  <= False;
            return rg_prod; 
    endmethod
endmodule

endpackage
