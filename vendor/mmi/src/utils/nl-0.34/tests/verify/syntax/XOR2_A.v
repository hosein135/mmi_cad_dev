`ifdef VCS
`else
`delay_mode_path
`endif
`timescale 1 ns / 10 ps

`celldefine

module XOR2_A (Z,A,B);

  output  Z;
  input  A;
  input  B;

  XOR2  i0 (Z,A,B);

specify

if(A)
  (posedge A => (Z:A) ) = (0.0:0.0:0.0, 0.0:0.0:0.0);
if(!A)
  (negedge A => (Z:A) ) = (0.0:0.0:0.0, 0.0:0.0:0.0);
if(B)
  (posedge B => (Z:B) ) = (0.0:0.0:0.0, 0.0:0.0:0.0);
if(!B)
  (negedge B => (Z:B) ) = (0.0:0.0:0.0, 0.0:0.0:0.0);
endspecify

endmodule
`endcelldefine
