module m (a, b, u);
  input a, b;
  output [3:0] u;

  wire [3:0] s;
  wire [3:0] t;

  assign t[1] = a;
  assign t[3] = b;

  m2 u1 (.w(s[0]), .x(t[2]), .y(t[0]), .z(u[0]));
  m3 u2 (          .x(t[0]), .y(t[3]), .z(u[3]));
  m4 u3 (          .x(t[2]), .y(t[1]), .z(u[1]));
  m5 u4 (.w(s[2]), .x(t[2]), .y(t[1]), .z(u[2]));

endmodule
