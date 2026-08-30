module m (clk, reset, d, q);
  input clk, reset;
  input [3:0] d;
  output [3:0] q;

  always @(posedge clk or negedge reset)
    if ( !reset )
      d = 6'o25;
    else
      d = q;

endmodule
