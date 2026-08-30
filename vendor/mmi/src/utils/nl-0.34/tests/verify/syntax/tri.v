module m (a, b, z);
  input a, b;
  output z;

  tri q;

  MMI_NAND2B u1 (.in0(a), .in1(b), .out(q));
  MMI_INVB   u2 (.in(q), .out(z));
endmodule
