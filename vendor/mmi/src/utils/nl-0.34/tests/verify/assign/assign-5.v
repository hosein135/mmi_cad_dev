module m (a, b, z);
  input [4:7] a;
  input [4:1] b;
  output [0:3] z;

  wire [3:0] p = a;
  wire [0:3] q = b;
  wire [9:12] r;

  sub sub (.u(p), .v(q), .w(r));

  assign z = r;

endmodule
