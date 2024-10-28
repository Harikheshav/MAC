package adder_float; 

import float_point::*;
import adder_subractor::*;

typedef struct 
{
    Float#(exp_bits,mant_bits) ip1;
    Float#(exp_bits,mant_bits) ip2;
} Input#(numeric type exp_bits,numeric type mant_bits) deriving (Bits, Eq);

interface Ifc_adder_float #(numeric type exp_bits,numeric type mant_bits);
    method Action inp(Float#(exp_bits,mant_bits) a,Float#(exp_bits,mant_bits) b);
    method ActionValue #(Float#(exp_bits,mant_bits)) op;
endinterface

// Count bits.
function Integer getBitLen (Bit#(a) n);
   return valueOf(a);
endfunction

(* descending_urgency = "adder_subractor_expcomp_rl_sum,rl_shiftex_mant " *)
(* descending_urgency = "adder_subractor_expinc_rl_sum,rl_normalize1exp " *)
module mkAdderFloat (Ifc_adder_float#(exp_bits,mant_bits))
    provisos(Add#(1, a__, mant_bits),
    Add#(exp_bits, b__, 32),
    Add#(c__, TAdd#(1, TAdd#(exp_bits, 1)), 32),
    Add#(d__, TAdd#(mant_bits, 1), 32),
    Add#(mant_bits, e__, 33),
    Add#(f__, exp_bits, 34),
    Add#(g__, mant_bits, 32));

    Reg #(Bit#(3)) stage <- mkReg(0);
    Reg #(Bit#(2)) rg_exp_stage <- mkReg(0);
    Reg #(Input#(exp_bits,mant_bits)) rg_ip <- mkReg(unpack(0));
    Reg #(Float#(exp_bits,TAdd#(mant_bits,1))) rg_stage1 <- mkReg(unpack(0));
    Reg #(Bit#(mant_bits)) rg_manta <- mkReg(unpack(0));
    Reg #(Bit#(mant_bits)) rg_mantb <- mkReg(unpack(0));
    Reg #(Bit#(mant_bits)) rg_mantout <- mkReg(unpack(0));
    Reg #(Bit#(TAdd#(mant_bits,1)))  rg_round_bit <- mkReg(0);
    Reg #(Maybe#(Bit#(32))) rg_diffamt <- mkReg(tagged Invalid);
    Reg #(Float#(exp_bits,TAdd#(mant_bits,1))) rg_stage2 <- mkReg(unpack(0));
    Reg #(Float#(exp_bits,mant_bits)) rg_stage3 <- mkReg(unpack(0));
    Reg #(Float#(exp_bits,TAdd#(mant_bits,1))) rg_stage4 <- mkReg(unpack(0));
    Reg #(Float#(exp_bits,mant_bits)) rg_sum <- mkReg(unpack(0));
    Reg#(FP_RS) rg_rsout <- mkReg(unpack(0));
    Reg#(Bit#(exp_bits)) rg_expout <- mkReg(0);
    Reg#(Bit#(32)) rg_sftamt <- mkReg(0);
    Reg#(Bit#(32)) rg_vectorSize <- mkReg(0);
    Reg#(Bit#(32)) rg_msb <- mkReg(0);
    Reg #(Bool) got_ip <- mkReg(False);
    Reg #(Bool) got_mant_sum <- mkReg(False);
    Reg #(Bool) got_mant_inc <- mkReg(False);
    Reg #(Bool) got_exp_inc <- mkReg(False);
    Reg #(Bool) done_add_sub <- mkReg(False);
    Reg #(Bool) opReady <- mkReg(False);
    Reg #(Bool) is_msb_notzero <- mkReg(False);
    
    Ifc_adder_subractor#(32) adder_subractor_expcomp <-  mkAdderSubractor();
    Ifc_adder_subractor#(32) adder_subractor_mant <-  mkAdderSubractor();
    Ifc_adder_subractor#(32) adder_subractor_round <-  mkAdderSubractor();
    Ifc_adder_subractor#(32) adder_subractor_mantinc <-  mkAdderSubractor();
    Ifc_adder_subractor#(32) adder_subractor_expinc <-  mkAdderSubractor();
    Ifc_adder_subractor#(32) adder_subractor_expshift1 <-  mkAdderSubractor();
    Ifc_adder_subractor#(32) adder_subractor_expshift2 <-  mkAdderSubractor();
    Ifc_adder_subractor#(32) adder_subractor_expshift3 <-  mkAdderSubractor();



    
    // normalize the significands based on the exponent difference.
    // and add
    rule rl_add_exp(stage==0 && got_ip);
        Bit#(exp_bits) outexp = 0 ;
        Bit#(1) outsign ;
        FP_RS   rsa ;
        //$display("%h %h %h %h ",rg_ip.ip1.exp , rg_ip.ip2.exp , rg_ip.ip1.mant , rg_ip.ip2.mant);
        if ( rg_ip.ip1.exp > rg_ip.ip2.exp )           // A > B
        begin
            rg_manta    <= rg_ip.ip1.mant ;
            rg_mantb    <= rg_ip.ip2.mant ;
            adder_subractor_expcomp.inp( extend(rg_ip.ip1.exp) , extend(rg_ip.ip2.exp) , 1);
            outsign = rg_ip.ip1.sign ;
            outexp  = rg_ip.ip1.exp ;
            rsa     = rg_ip.ip1.rs ;
            //$display("rl_add_exp-if");
        end
        else if ( rg_ip.ip2.exp > rg_ip.ip1.exp )       // B > A
        begin
            rg_manta    <= rg_ip.ip2.mant ;
            rg_mantb    <= rg_ip.ip1.mant ;
            adder_subractor_expcomp.inp( extend(rg_ip.ip2.exp) , extend(rg_ip.ip1.exp) , 1);
            outsign = rg_ip.ip2.sign ;
            outexp  = rg_ip.ip2.exp ;
            rsa     = rg_ip.ip2.rs ;
            //$display("rl_add_exp-else if1");
        end
        else if ( rg_ip.ip1.mant > rg_ip.ip2.mant )     // A > B
        begin
            rg_manta    <= rg_ip.ip1.mant ;
            rg_mantb    <= rg_ip.ip2.mant ;
            rg_diffamt <= tagged Valid 0 ;
            outsign = rg_ip.ip1.sign ;
            outexp  = rg_ip.ip1.exp ;
            rsa     = rg_ip.ip2.rs ;
            //$display("rl_add_exp-else if2");
        end
        else
        begin
            rg_manta    <= rg_ip.ip2.mant ;
            rg_mantb    <= rg_ip.ip1.mant ;
            rg_diffamt <= tagged Valid 0 ;
            outsign = rg_ip.ip2.sign ;
            outexp  = rg_ip.ip1.exp ;
            rsa     = rg_ip.ip1.rs ;
            //$display("rl_add_exp-else");
        end
        stage <= 1;
        let stage1 = Float{ sign:outsign, exp:outexp, mant:0, rs:rsa }  ;
        rg_stage1 <= stage1;
    endrule

    rule rl_shiftex_mant(stage==1 && got_ip && !got_mant_sum);
        // Shifting and extending
        Bit#(32) diffamt = 0;
        if(rg_diffamt matches tagged Invalid)
        begin
            let diff <- adder_subractor_expcomp.op;
            diffamt = truncate(pack(diff)); 
            //$display("rl_shiftex_mant-if1");
        end
        let emantb = rg_mantb >> diffamt ;

        // generate round and sticky
        let vectorsize = fromInteger(valueOf(mant_bits)) ;
        let rev_shift = (diffamt <= vectorsize) ? ( vectorsize - diffamt ) : 0;
        Bit#(mant_bits)  mant1 = rg_mantb << rev_shift ; 
  
        Bit#(TAdd#(mant_bits,1)) sv =  { mant1[vectorsize-2:0] , 1'b0 } ;  
        // Avoid X generation when off the array.
        FP_RS rsb = { (diffamt <= vectorsize) ? mant1[vectorsize-1] : 1'b0 , | sv } ;
        //$display("sv%b",sv);
        //$display("rsb%b",rsb);
        // now do the addition or subtractions on the normalized significand
        Bit#(TAdd#(mant_bits,1)) mantv = 0;
        FP_RS    rsout ;
        if (rg_ip.ip2.sign == rg_ip.ip1.sign)
        begin
            rg_round_bit <= unpack(rg_stage1.rs[1] & rsb[1]) ? 1 : 0 ;
            adder_subractor_mant.inp(extend(rg_manta),extend(emantb),0);
            //$display("rl_shiftex_mant-if2");
        end
        else
        begin
            rg_round_bit <= unpack(rg_stage1.rs[1] &  ~rsb[1]) ? 1 : 0 ;
            adder_subractor_mant.inp(extend(rg_manta),extend(emantb),1);
            //$display("rl_shiftex_mant-else ");
        end
        rsout = { rg_stage1.rs[1] ^ rsb[1], rg_stage1.rs[0] | rsb[0] } ;
        //$display("outa:%h,eoutb:%h",rg_manta,emantb);
        //$display("rsout:%h",rsout);
        let stage2 = Float{ sign:rg_stage1.sign, exp:rg_stage1.exp, mant:0, rs:rsout }  ;
        rg_stage2 <= stage2;
        got_mant_sum <= True;
    endrule
    rule rl_addroundBits(stage==1 && got_ip && got_mant_sum);
        Bit#(TAdd#(mant_bits,1)) mantv = 0;
        let mant <- adder_subractor_mant.op;
        mantv = truncate(pack(mant));
        //$display("outv:%h rg_round_bit:%h",mantv,rg_round_bit);
        adder_subractor_round.inp(extend(mantv),extend(rg_round_bit),0);
        stage <= 2;
        got_mant_sum <= False;
    endrule
    rule rl_normalize_and_truncate(stage==2 && got_ip && !opReady && rg_exp_stage == 0 && !is_msb_notzero);
        Bit#(32) msb = 0 ;
        let mant <- adder_subractor_round.op;
        Bit#(TAdd#(mant_bits,1)) mant_round = truncate(pack(mant));
        Integer mantSize = getBitLen(mant_round);
        //$display("mant_round:%h",mant_round);
        //$display("mantSize%d",mantSize);
        rg_stage2.mant <= mant_round;
        for( Integer i = 0 ; i < mantSize  ;i = i + 1)
        begin
           Bit#(32) idx = fromInteger( i )  ;
           if ( mant_round[idx] == 1'b1 )  msb = fromInteger( i + 1 ) ;  else msb = msb ;
           //$display("Res:%b",msb);
        end
        // Default conditions are set for 0 result.
        if ( msb != 0 )
        begin
            Bit#(32) vectorSize = fromInteger(getBitLen(mant_round));
            rg_vectorSize <= vectorSize;
            rg_msb <= msb;
            //let sftamt = vectorSize - msb ; //# Add adder_subractor_expshift2
            adder_subractor_expshift2.inp(vectorSize,msb,1);
            //$display("v%b m%b",vectorSize,msb);
            is_msb_notzero <= True;
        end
        else
        begin
            //$display("rl_normalize_and_truncate else");
            rg_exp_stage <= 0;
            let stage3 = Float{ sign:rg_stage2.sign, exp:0, mant:0, rs:0 } ;
            stage<=3;
            rg_stage3 <= stage3;
        end
    endrule
    rule rl_getrnd_stky(stage==2 && got_ip && !opReady && rg_exp_stage == 0 && is_msb_notzero);
        Bit#(mant_bits) mantout = 0 ;
        Bit#(exp_bits) expout = 0 ;
        FP_RS    rsout = 0 ;
        Bit#(1) rndbit = rg_stage2.rs[1] ;
        Bit#(1) stkybit = rg_stage2.rs[0] ;
        Bit#(2) rest = 0 ;
        //$display("Vectorsize:%b",rg_vectorSize);
        //$display("MSB:%b",rg_msb);
        let sft <- adder_subractor_expshift2.op;
        Bit#(32) sftamt = truncate(pack(sft));
        //$display("%b %b %b",rg_stage2.mant, rndbit , sftamt);
        Bit#(TAdd#(mant_bits,2)) mantfull = { rg_stage2.mant, rndbit } << sftamt ;
        //$display("mantfull:%b",mantfull);
        mantout = truncate(mantfull >> 2);
        //$display("mantout:%b",mantout);
        rest = mantfull[1:0];
        // Calculate the round and sticky bits
        Bit#(1) rnd = rest[1];
        Bit#(1) stky = rest[0];
        rg_rsout <= { rnd, (| stky) | stkybit  } ;
        //$display("rsout:%b",{ rnd, (| stky) | stkybit  });
        rg_sftamt <= truncate(sftamt);
        //$display("mant b4:%b",sftamt);
        // Adjust exponent -- taking into account where the binary point was
        //$display("b4 inc expout:%b",rg_stage2.exp);
        adder_subractor_expshift1.inp(1,extend(rg_stage2.exp),0);
        rg_exp_stage <= 1;
        rg_mantout <= mantout;
        //$display("rl_normalize_and_truncate if");
        is_msb_notzero <= False;
    endrule
    rule rl_exp_shift(stage==2 && got_ip && !opReady && rg_exp_stage == 1 );
        //$display("inside exp shit rule");
        //$display("mant after:%b",rg_sftamt);
        let exp_op <- adder_subractor_expshift1.op;
        Bit#(exp_bits) expout = truncate(pack(exp_op));
        //$display("after inc expout:%b",expout);
        adder_subractor_expshift3.inp(extend(expout),rg_sftamt,1);
        // 1 + exp - mant
        rg_exp_stage <= 2;
    endrule

    rule rl_exp_shiftop(stage==2 && got_ip && !opReady && rg_exp_stage == 2);
        let op <- adder_subractor_expshift3.op;
        Bit#(exp_bits) exp_out = truncate(pack(op));
        rg_expout <= exp_out;
        rg_exp_stage <=  3;
        let stage3 = Float{ sign:rg_stage2.sign, exp:exp_out, mant:rg_mantout, rs:rg_rsout } ;
        stage<=3;
        rg_stage3 <= stage3;
    endrule
    rule rl_round(stage==3 && got_ip && !opReady && !got_mant_inc);
        //$display("Stage:3%b",pack(rg_stage3));
        //$display("stage:3-exp%b",rg_stage3.exp);
        //$display("stage:3-%b",rg_stage3.mant);
        Bit#(3) rbits = { rg_stage3.mant[0] , rg_stage3.rs } ;
        Bit#(TAdd#(mant_bits,1)) mantout = zeroExtend( rg_stage3.mant ) ;
        FP_RS rsout = rg_stage3.rs ;
        //$display("rsout:%b",rsout);
        rg_exp_stage <= 0;
        //$display("rbits:%b",rbits);
        if (( rbits == 3 && rg_stage3.mant[0] ==1 ) || ( rbits > 5 )) // round up at 3,6,7
        begin
            adder_subractor_mantinc.inp(zeroExtend( rg_stage3.mant ) , 1 ,0);
            //$display("round b4:%h",rg_stage3.mant);
            rsout = { 1'b0, rg_stage3.rs[0] }  ;
            rg_stage3.rs <= rsout;
            got_mant_inc <= True;
            //$display("rl_round if");
        end
        else
        begin
            let stage4 = Float{ sign:rg_stage3.sign, exp:rg_stage3.exp, mant:mantout, rs:rsout } ;
            stage<=4;
            rg_stage4 <= stage4;
            //$display("rl_round else");
        end
    endrule

    rule rl_mant_inc(stage==3 && got_ip && !opReady && got_mant_inc);
        let op <- adder_subractor_mantinc.op;
        Bit#(TAdd#(mant_bits,1)) mantout = truncate(pack(op));
        //$display("round after:%h",mantout);
        let stage4 = Float{ sign:rg_stage3.sign, exp:rg_stage3.exp, mant:mantout, rs:rg_stage3.rs } ;
        //$display("stage4:%h",stage4.mant);
        stage<=4;
        rg_stage4 <= stage4;
        got_mant_inc <= False;
    endrule

    rule rl_normalize1(stage==4 && got_ip && !opReady && !got_exp_inc);
        FP_RS   rsout = 0;
        Bit#(2) carrymsb = rg_stage4.mant[valueOf(mant_bits): valueOf(TSub#(mant_bits,1))]; 
        //$display("stage4:%h",rg_stage4.mant);
        if ( 1 == carrymsb[1] )
        begin
            // TODO overflow can occur here
            adder_subractor_expinc.inp(extend(rg_stage4.exp) , 1,0);
            rg_mantout <= truncate( rg_stage4.mant >> 1) ;
            rg_rsout <= {rg_stage4.mant[0], pack(rg_stage4.rs != 0) } ;
            done_add_sub <= True;
            //$display("rl_normalize1 if");
        end
        else if ( rg_stage4.exp == 0 )      // Denormalized case -- do not modify
        begin
            rg_expout <= rg_stage4.exp;
            rg_mantout <= truncate ( rg_stage4.mant );
            rg_rsout  <= 2'b00 ;
            //$display("rl_normalize1 else if1");
        end
        else if ( 1 == carrymsb[0] ) // The sum is in normalized form
        begin
            rg_expout <= rg_stage4.exp;
            rg_mantout <= truncate ( rg_stage4.mant );
            rg_rsout  <= 2'b00 ;
            //$display("rl_normalize1 else if2");
        end
        else
        begin                  // left shift by 1
            adder_subractor_expinc.inp(extend(rg_stage4.exp) , 1 ,1);
            let vectorsize = fromInteger(valueOf(exp_bits)) ;
            rg_mantout <= {rg_stage4.mant[vectorsize-3:0] ,  rg_stage4.rs[0] } ;
            rg_rsout  <= {1'b0, rg_stage4.rs[0] };
            done_add_sub <= True;
            //$display("rl_normalize1 else");
        end
        got_exp_inc <= True;
    endrule

    rule rl_normalize1exp(stage==4 && got_ip && !opReady && got_exp_inc);
        if(done_add_sub)
        begin
            let expop <- adder_subractor_expinc.op;
            rg_expout <= truncate(pack(expop));
            //$display("rl_normalize1exp if");
        end
        let op = Float{ sign:rg_stage4.sign, exp:rg_expout, mant:rg_mantout, rs:rg_rsout } ;
        opReady<=True;
        got_exp_inc <= False;
        rg_sum <= op;
    endrule

    method Action inp(Float#(exp_bits,mant_bits) a,Float#(exp_bits,mant_bits) b) if(!got_ip);
        rg_ip <= Input{ip1:a,ip2:b};
        got_ip <= True;
    endmethod
    method ActionValue #(Float#(exp_bits,mant_bits)) op if(opReady);
            opReady <= False;
            got_ip  <= False;
            done_add_sub <= False;
            stage<=0;
            return rg_sum; 
    endmethod
endmodule

endpackage
