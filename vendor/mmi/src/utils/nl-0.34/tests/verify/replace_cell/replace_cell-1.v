module m (a, z);
  input [1:0] a;
  output [1:0] z;

  MMI_INVA INVA (.in(a[0]), .out(z[0]));
  MMI_INVB INVB (.in(a[1]), .out(z[1]));

endmodule
