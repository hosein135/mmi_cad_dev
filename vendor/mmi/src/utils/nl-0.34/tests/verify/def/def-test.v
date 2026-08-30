module A (a, y, z);
  input a;
  output y, z;

  wire n;
  assign n = a;

  MMI_INVA inva (.in(x), .out(z));

  assign y = 1'b0;

endmodule


module B (b, w, x);
  input b;
  output w, x;

  MMI_INVB invb (.in(b), .out(m));

  assign w = m;

  assign x = 1'b1;

endmodule


module F (in, out);
  input in;
  output out;

  assign out = in;

endmodule


module AB (d, e, f, o, p, q, r, s, t, u, v);
  input d, e, f;
  output o, p, q, r, s, t, u, v;

  wire c;
  wire g;
  wire j, k;
 
  assign c = 1'b1;

  A a1 (.a(c), .y(p), .z(q));
  A a2 (.a(d), .y(j), .z(k));
  B b1 (.b(e), .w(t), .x(u));
  B b2 (.b(1'b0), .w(h), .x(i));

  assign {r, s} = {j, k};

  MMI_AND2B and2 (.in0(h), .in1(i), .out(g));

  assign v = g;

  F f1 (.in(f), .out(o));

endmodule
