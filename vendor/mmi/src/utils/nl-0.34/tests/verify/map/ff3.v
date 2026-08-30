module m (clk, reset, d, q);
  input clk, reset, d;
  output q;

  always @(posedge clk)
    q = d;

endmodule
