package full_adder_subractor ;

interface Ifc_fullAdderSubractor;

method Bit#(1) sum (Bit#(1) a, Bit#(1) b, Bit #(1) cin);
method Bit#(1) carry (Bit#(1) a, Bit#(1) b, Bit #(1) cin);
method Bit#(1) difference (Bit#(1) a, Bit#(1) b, Bit #(1) bin);
method Bit#(1) borrow (Bit#(1) a, Bit#(1) b, Bit #(1) bin);

endinterface

(* synthesize *)

module mkfullAdderSubractor (Ifc_fullAdderSubractor);

method Bit#(1) sum (Bit#(1) a, Bit#(1) b, Bit #(1) cin);

    return a ^ b ^ cin;

endmethod

method Bit#(1) carry (Bit#(1) a, Bit#(1) b, Bit #(1) cin);

    
    return (a & b)|(b & cin)|(cin & a);

endmethod

method Bit#(1) difference(Bit#(1) a, Bit#(1) b, Bit #(1) bin);

    return a ^ ~b ^ bin;

endmethod

method Bit#(1) borrow(Bit#(1) a, Bit#(1) b, Bit #(1) bin);
        return (a & ~b) | (bin & a) | (bin & ~b);
endmethod
endmodule

endpackage
