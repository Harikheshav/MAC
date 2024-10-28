package float_point; 

typedef Bit#(2)  FP_RS ;
typedef struct 
{
    Bit#(1) sign;
    Bit#(exp_bits) exp;
    Bit#(mant_bits) mant;
    FP_RS      rs ; //round and sticky bit
} Float#(numeric type exp_bits,numeric type mant_bits) deriving (Bits, Eq);


function Bit#(m) pad_zeroes(Bit#(n) value)
    provisos(Add#(a__, n, m));

    Bit#(m) resp = 0;
    resp[valueOf(m)-1:valueOf(m)-valueOf(n)] = value;
    return resp;
endfunction

// extract out the fields from a 32 bit FP.
function Float#(8,24)
   extract_fields(Bit#(32) din ) ;
   begin
     Bit#(1)      sign   = din[31];
      Bit#(8)      exp    = din[30:23] ;
      Bit#(1)      hidden = exp != 0  ? 1'b1 : 1'b0 ;
      Bit#(24)     mant    = {hidden, din[22:0] } ;

      return Float{ sign:sign, exp:exp, mant:mant, rs:2'b00 } ;
   end
endfunction

// extract out the fields from a 32 bit FP.
function Float#(8,7)
   extract_fields_bf16(Bit#(16) din ) ;
   begin
     Bit#(1)      sign   = din[15] ;
      Bit#(8)      exp    = din[14:7] ;
      Bit#(1)      hidden = exp != 0  ? 1'b1 : 1'b0 ;
      Bit#(7)      mant    = {hidden, din[5:0] } ;

      return Float{ sign:sign, exp:exp, mant:mant, rs:2'b00 } ;
   end
endfunction

// Take the structure and pack it into a IEEE FP format
function Bit#(32)
   pack_fields( Float#(8,24)  din ) ;
   begin
      return { pack(din.sign), pack(din.exp), pack( truncate( din.mant ))  } ;
   end
endfunction


// Take the structure and pack it into a IEEE FP format
function Bit#(32)
   pack_fields_bf16_fp32( Float#(8,7)  din ) ;
   begin
      return { pack(din.sign), pack(din.exp), pack( pad_zeroes( din.mant ))  } ;
   end
endfunction


endpackage