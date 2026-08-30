module m1 (a, z);
  input a;
  output z;

  MMI_INVA INVA (.in(a), .out(z));
endmodule

module m2 (a, b, y, z);
  input a, b;
  output y, z;

  m1 u1 (.a(a), .z(z));
  MMI_INVA INVA_1 (.in(b), .out(y));
endmodule

module m3 (a, b, y, z);
  input a, b;
  output y, z;

  m1 u1 (.a(a), .z(z));
  MMI_INVA INVA_2 (.in(b), .out(y));
endmodule

module top (a, b, c, d, e, f, u, v, w, x, y, z);
  input a, b, c, d, e, f;
  input u, v, w, x, y, z;

  m2 u2a (.a(a), .b(b), .y(y), .z(z));
  m2 u2b (.a(e), .b(f), .y(u), .z(v));
  m3 u3 (.a(c), .b(d), .y(w), .z(x));
endmodule
