module m (p, q, u, v);
  input [5:2] p;
  input [6:9] q;
  output [3:0] u;
  output [0:3] v;

  assign u = p;
  MMI_INVA inv (.in(q[6]), .out(v[0]));
endmodule

module n (a, b, y, z);
  input [0:3] a, b;
  output [0:3] y, z;

  m u2 (.p(a), .q(b), .u(y), .v(z));
endmodule

module o (a, b, y, z);
  input [3:0] a, b;
  output [3:0] y, z;

  n u1 (.a(a), .b(b), .y(y), .z(z));
endmodule

