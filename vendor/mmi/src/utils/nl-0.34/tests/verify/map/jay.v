module m (ck ,d ,q ,r);

  input ck;
  input [1:0] d;
  output [1:0] q;
  input r;

  // JNPR_FF_R
  always @(posedge ck)
    q[0] = d[0];

  // JNPR_FF_RCR
  always @(posedge ck or posedge r)
    if ( r )
      q[1] = 1'b0;
    else
      q[1] = d[1];
endmodule
