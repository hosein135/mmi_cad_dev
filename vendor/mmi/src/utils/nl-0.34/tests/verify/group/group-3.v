module sub (a, b, z);
  input [3:0] a;
  input [0:3] b;
  output [1:4] z;

  wire [9:6] t;
  wire [3:0] s;

  MMI_AND2B u1 (.in0(a[0]), .in1(b[0]), .out(t[6]));
  MMI_AND2B u2 (.in0(a[1]), .in1(b[1]), .out(t[7]));
  MMI_AND2B u3 (.in0(a[2]), .in1(b[2]), .out(t[8]));
  MMI_AND2B u4 (.in0(a[3]), .in1(b[3]), .out(t[9]));

  assign s = t;

  MMI_INVB u5 (.in(s[0]), .out(z[1]));
  MMI_INVB u6 (.in(s[1]), .out(z[2]));
  MMI_INVB u7 (.in(s[2]), .out(z[3]));
  MMI_INVB u8 (.in(s[3]), .out(z[4]));

endmodule

module m (a, b, z);
  input [3:0] a, b;
  output [3:0] z;

  sub sub (.a(a), .b(b), .z(z));

endmodule
