module sub (p, q, r, s, t);
  input p, q, s;
  output r, t;

  wire x;
  wire o;

  assign x = p;
  assign y = x;
  assign t = s;

  MMI_AND2B U2 (.in0(y), .in1(q), .out(o));
  MMI_INVB  U3 (.in(o), .out(r));

endmodule


module m (a, b, c, y, z);
  input a, b, c;
  output y, z;

  wire s, t, u, v, w;

  assign v = c;
  assign z = w;

  sub sub_1 (.p(u), .q(b), .r(t), .s(s), .t(y));
  sub sub_2 (.p(c), .q(a), .r(s), .s(a), .t(u));
  MMI_OR2B U1 (.in0(v), .in1(t), .out(w));

endmodule

  