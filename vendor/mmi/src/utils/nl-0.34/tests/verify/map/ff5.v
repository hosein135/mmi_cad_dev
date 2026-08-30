module m (clk, reset, d, q);
  input clk, reset, d;
  output q;

  always @(posedge clk or negedge reset)
    if ( !reset )
      d = 1'b0;
    else
      d = q;

endmodule
