module sub1 (p, r);
  input p;
  output r;

  wire n;

  assign n = 1'b1;

  MMI_XOR2B u1 (.in0(p), .in1(n), .out(r));

endmodule


module sub2 (p, q);
  input p;
  output q;

  assign q = 1'b1;

endmodule


module top (a, z);
  input a;
  output z;

  wire c, x;

  sub1 s (.p(a), .r(x));
  sub2 t (.p(c), .q(y));
  MMI_AND2B u2 (.in0(x), .in1(y), .out(z));

endmodule
