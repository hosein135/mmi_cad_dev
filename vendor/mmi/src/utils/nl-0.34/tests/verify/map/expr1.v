module m (a, b, z);
  input [3:0] a, b;
  output [3:0] z;

  assign z = ~(a & ~b);
endmodule
