package systolic_array;
import mac :: *;
import Vector :: *;
interface Ifc_sys_array;    
    method Action a(Bit#(16) x);
    method Action b(Bit#(16) x);
    method Vector#(16, Reg#(Bit#(32))) op;
endinterface

//Change meaningful var names, add comments for condition , change size (if any), remove display statements, create seperate Testbench.
(*synthesize*)
module mkSystolicArray(Ifc_sys_array);
    Vector#(16, Ifc_mac) sys_array <-  replicateM(mkMac);
    Reg #(Bit#(16)) rg_a <- mkReg(0);
    Reg #(Bit#(16)) rg_b <- mkReg(0);
    Reg #(Bit#(5)) count_a <- mkReg(3); //0-2 <=> 0
    Reg #(Bit#(4)) count_b <- mkReg(0);
    Reg #(Bool) got_a <- mkReg(False);
    Reg #(Bool) got_b <- mkReg(False);
    Reg#(Bit#(2)) row_idx <- mkReg(0);
    Vector#(24, Reg#(Bit#(16))) vrg_a <-  replicateM(mkReg(0));
    Vector#(16, Reg#(Bit#(16))) vrg_b <-  replicateM(mkReg(0));
    Vector#(16, Reg#(Bit#(32))) vrg_c <-  replicateM(mkReg(0));
    Vector#(16, Reg#(Bit#(32))) vrg_op <-  replicateM(mkReg(0));
    Reg#(Bool) ipReady <- mkReg(False);
    Reg#(Bool) get_pop <- mkReg(False);
    Reg#(Bool) got_op <- mkReg(True);
    Reg#(Bool) rg_reset <- mkReg(False);
    Reg#(Bool) opReady <- mkReg(False);
    Reg#(int) a_idx <- mkReg(0);
    Reg#(int) a_init_idx <- mkReg(2);
    Reg#(int) op_idx <- mkReg(0);
    Reg#(int) b_idx <- mkReg(0);
    Reg#(int) b_init_idx <- mkReg(0);
    Reg#(int) mac_idx <- mkReg(0);
    rule ip_a(got_a && count_a < 16 && !opReady);
        //$display("ip_a:%d count:%d",rg_a,count_a);
        vrg_a[count_a] <= rg_a;
        if(count_a % 5 == 0) 
            count_a <= count_a + 3;
        else
            count_a <= count_a + 1;
        got_a <= False;
   endrule
    rule ip_b(got_b && count_b < 11 && !opReady); 
        if((count_b+1)%4 == 0) //3,7 <=> 0
        begin
            //$display("ip_b:%d count:%d",rg_b,count_b);
            vrg_b[count_b+1] <= rg_b;
            count_b <= count_b  + 2;
        end
        else 
        begin
            //$display("ip_b:%d count:%d",rg_b,count_b);
            vrg_b[count_b] <= rg_b;
            count_b <= count_b  + 1;
        end        
        got_b <= False;
    endrule
    rule got_ips(count_a >= 16 && count_b >= 11 && !ipReady && !opReady); 
        ipReady <= True;
        for(int i=0; i<24; i=i+1)
        begin
            //$display("a%d:",i,vrg_a[i]);
        end
        for(int i=0; i<16; i=i+1)
        begin
            //$display("b%d:",i,vrg_b[i]);
        end
    endrule
    rule start_row(ipReady && !rg_reset && !opReady);
        //$display("reset");
        if(mac_idx >=9) //or 9 depends upon our constraint
        begin
            for(int i = 0; i<9;i=i+1)
            begin
                //$display("op:%d %d",i,vrg_op[i]);
            end
            mac_idx <= 0;
            b_idx <= b_init_idx + 4;
            b_init_idx <=b_init_idx + 4;
            a_idx <= 3;
            a_init_idx <=3;
        end  
        else
        begin
            b_idx <= b_init_idx;
            a_idx <= a_init_idx + 1;
            a_init_idx <= a_init_idx + 1;
        end
        row_idx <= 0;
        rg_reset <= True;
        for(int i=0; i<16; i=i+1)
        begin
            vrg_c[i] <= 0;
        end
        if(op_idx == 9)
            opReady <= True;
    endrule
    rule put_ips(ipReady && row_idx < 3 && !get_pop && got_op && rg_reset && !opReady);
        sys_array[mac_idx].a(vrg_a[a_idx]);
        sys_array[mac_idx].b(vrg_b[b_idx]);
        sys_array[mac_idx].c(vrg_c[b_idx]);
        a_idx <= a_idx+5; 
        //$display("a_idx:%d b_idx:%d putting a:%d,b:%d c:%d in mac:%d row_idx:%d",a_idx,b_idx,vrg_a[a_idx],vrg_b[b_idx],vrg_c[b_idx],mac_idx,row_idx);
        get_pop <= True;
        got_op <= False;
    endrule
    rule put_op(ipReady && row_idx < 3 && get_pop && !got_op && rg_reset && !opReady);
        let op <- sys_array[mac_idx].mac_op;
        //$display("Putting op:%d in pos:%d",op,b_idx+1);
        vrg_c[b_idx+1] <= op;
        mac_idx <= mac_idx+1;
        b_idx <= b_idx + 1;
        get_pop <= False;
        got_op <= True;
        if(row_idx == 2)
        begin
            rg_reset <= False;
            vrg_op[op_idx] <= op;
            op_idx <= op_idx + 1;
        end
        else
        begin
            row_idx <= row_idx + 1;
        end      
endrule
    method Action a(Bit#(16) x) if(!got_a);
        //$display("a",x);
        rg_a <= x;
        got_a <= True;
    endmethod
    method Action b(Bit#(16) x) if(!got_b);
        //$display("b",x);
        rg_b <= x;
        got_b <= True;
    endmethod
    method Vector#(16, Reg#(Bit#(32))) op if(opReady);
        return vrg_op;
    endmethod
endmodule

endpackage
