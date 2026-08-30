module m (a, b, y, z);
  input [3:0] a, b;
  output [3:0] y, z;

  assign y[3] = !(a[3] & b[3]);
  assign y[2:0] = ~(a[2] & {b[2], 2'b01});
  assign z[3] = !(a[3] | b[3]);
  assign z[2:0] = ~(a[2] | {b[2], 2'b01});
  

endmodule
