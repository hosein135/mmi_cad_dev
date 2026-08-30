module m (a, b, y, z);
  input [7:0] a, b;
  output y, z;

  assign y = ^ ((a <= b) ? a + b : a & b);
  assign z = & ((a > b) ? a - b : b - a);
endmodule
