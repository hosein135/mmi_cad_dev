module m (a, b, z);
  input a, b;
  output z;

  MMI_NAND3B u1 (.in0(a), .in1(b), .in2(), .out(z));

endmodule
