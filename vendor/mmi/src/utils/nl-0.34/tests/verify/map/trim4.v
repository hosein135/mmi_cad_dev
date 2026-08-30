module m (a, b, c, z);
  input [2:0] a;
  input [2:0] b;
  input [5:0] c;
  output [3:0] z;

  assign z = { c, a , b} + 20;

endmodule
