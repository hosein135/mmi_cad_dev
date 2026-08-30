module m (sel, a, b, c, d, z);
  input [3:0] sel;
  input [3:0] a, b;
  output [3:0] z;

  reg [3:0] z;

  always @(sel or a or b)
    if ( sel ) 
      z = a;
    else
      z = b;

endmodule

