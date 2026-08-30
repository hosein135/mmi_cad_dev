module m (clk, reset, d, q);
  input clk, reset, d;
  output q;

  always @(negedge clk)
    q = d;

endmodule
