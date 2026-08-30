module orientations (a, b, c, d, z);
  input [7:0] a;
  output [7:0] z;

  MMI_BUFB u0 (.in(a[0]), .out(z[0]));
  MMI_BUFC u1 (.in(a[1]), .out(z[1]));
  MMI_BUFD u2 (.in(a[2]), .out(z[2]));
  MMI_BUFE u3 (.in(a[3]), .out(z[3]));
  MMI_INVA u4 (.in(a[4]), .out(z[4]));
  MMI_INVB u5 (.in(a[5]), .out(z[5]));
  MMI_INVC u6 (.in(a[6]), .out(z[6]));
  MMI_INVD u7 (.in(a[7]), .out(z[7]));

endmodule
