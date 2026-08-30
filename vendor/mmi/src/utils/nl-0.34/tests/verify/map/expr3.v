module m (a, b, c, z);
  input [3:0] a, b, c;
  output [4:0] z;

  assign z = a + b - c;
endmodule
