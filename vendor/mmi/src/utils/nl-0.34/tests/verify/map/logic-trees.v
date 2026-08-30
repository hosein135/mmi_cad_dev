module m (a, b, c, d, w, x, y, z);
  input [3:0] a, b, c, d;
  output [3:0] w, x, y, z;

  assign w = a ^ (b ^ c) ^ d;
  assign x = a & b & c & d;
  assign y[3] = !(a[3] & b[3] & c[3] & d[3]);
  assign y[2:0] = ~(a[2] & {b[2], 2'b01});
  assign z[3] = !((a[3] | b[3]) | (c[3] | d[3]));
  assign z[2:0] = ~(a[2] | {b[2], 2'b01});
  

endmodule
