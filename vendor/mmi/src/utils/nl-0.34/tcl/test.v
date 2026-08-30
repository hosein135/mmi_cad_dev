module n (p, q);
  input p;
  output q;

  MMI_NAND2B u1 (.in0(p), .in1(), .out(q));
  MMI_NAND2B u2 (.in0(p), .in1(), .out());
endmodule

module m (a, b, c, x, y, z);
  input a, b;
  output x, y, z;

  n sub1 (.p(a), .q(x));
  n sub2 (.p(b), .q(y));
  n sub3 (.p(c), .q(z));
  MMI_NAND2B u3 (.in0(a), .in1(), .out());

endmodule
