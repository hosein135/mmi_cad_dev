module m (clk, reset, d, q);
  input clk, reset, d;
  output q;

  wire a, b;

  always @(posedge clk)
    if ( reset )
      q = a & b;
    else
      q = d;

endmodule
