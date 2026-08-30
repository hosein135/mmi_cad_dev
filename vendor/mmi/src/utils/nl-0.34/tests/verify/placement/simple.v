module simple (a, b, c, d, z);
  input a, b, c, d;
  output z;

  MMI_NAND2A u1 (.in0(a), .in1(b), .out(s));
  MMI_NAND2B u2 (.in0(c), .in1(d), .out(t));
  MMI_NAND2C u3 (.in0(s), .in1(t), .out(z));

endmodule
