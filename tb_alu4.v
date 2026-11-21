`timescale 1ns/1ps
module tb_alu4;
 reg [3:0] A,B; reg M,S1,S0;
 wire [3:0] L,BCD_TENS,BCD_ONES; wire [4:0] R; wire N;
 wire [6:0] SEG_TENS_N,SEG_ONES_N;
 integer errors, checks, a,b,op, expR, expL, expN;
 reg [3:0] et,eo;
 alu4 dut(.A(A),.B(B),.M(M),.S1(S1),.S0(S0),.L(L),.R(R),.N(N),
 .BCD_TENS(BCD_TENS),.BCD_ONES(BCD_ONES),.SEG_TENS_N(SEG_TENS_N),.SEG_ONES_N(SEG_ONES_N));
 function [6:0] seg;
 input [3:0] d;
 begin case(d)
 0:seg=7'b0000001;1:seg=7'b1001111;2:seg=7'b0010010;3:seg=7'b0000110;
 4:seg=7'b1001100;5:seg=7'b0100100;6:seg=7'b0100000;7:seg=7'b0001111;
 8:seg=7'b0000000;9:seg=7'b0000100;default:seg=7'b1111111;
 endcase end endfunction
 initial begin
  errors=0; checks=0;
  // Exhaust all eight control encodings and all 256 A/B pairs: 2048 vectors.
  for (op=0;op<8;op=op+1) begin
   for (a=0;a<16;a=a+1) begin
    for (b=0;b<16;b=b+1) begin
     M=op/4; S1=(op%4)/2; S0=op%2; A=a; B=b;
     expL=0; expR=0; expN=0;
     case(op)
      0:expL=(a&b); 1:expL=(a^b); 2:expL=(~(a&b))&15; 3:expL=(~(a^b))&15;
      4:expR=a+b;
      5:begin if(a<b) begin expR=b-a; expN=1; end else expR=a-b; end
      6:expR=a+b+1;
      7:expR=2*a;
     endcase
     et=expR/10; eo=expR%10;
     #1; checks=checks+1;
     if(L!==expL[3:0] || R!==expR[4:0] || N!==expN[0] ||
        BCD_TENS!==et || BCD_ONES!==eo || SEG_TENS_N!==seg(et) || SEG_ONES_N!==seg(eo)) begin
       errors=errors+1;
       $display("FAIL op=%0d A=%0d B=%0d | L=%b R=%0d N=%b BCD=%0d%0d",op,a,b,L,R,N,BCD_TENS,BCD_ONES);
     end
    end
   end
  end
  if(errors==0) $display("PASS: %0d vectors checked; ALU, mode suppression, BCD and 7-segment outputs match reference.",checks);
  else $display("FAIL: %0d mismatches across %0d vectors.",errors,checks);
  $finish;
 end
endmodule
