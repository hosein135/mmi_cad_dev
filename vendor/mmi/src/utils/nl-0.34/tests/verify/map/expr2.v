module m (a, b, c, z);
  input [3:0] a, b;
  input c;
  output [4:0] z;

  assign z[3:0] = c ? a : b;
  assign z[4] = c ? a[1] : a[2];
endmodule
