module m (clk, r, d, q);
  input clk;
  input r;
  input [3:0] d;
  output [3:0] q;
  reg [3:0] q;

  // juniper cell attribute foo boolean;

  // juniper begin attribute foo;

  always @(posedge clk)
    if ( r )
      q = d;

  // juniper end attribute foo;

endmodule
