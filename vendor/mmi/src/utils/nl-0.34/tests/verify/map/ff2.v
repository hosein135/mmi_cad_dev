module m (clk, reset, d, q);
  input clk, reset, d;
  output q;

  always 
    q = MMI_FFB (clk, MMI_INOR2A (reset, d));

endmodule
