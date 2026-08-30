module m (a, z);
  input a;
  output z;

  MMI_INVB u1 (.in0(a), .out(z));
endmodule
