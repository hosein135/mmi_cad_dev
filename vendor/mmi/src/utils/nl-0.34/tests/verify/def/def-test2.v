module m (a, z);
  input a;
  output z;

  MMI_INVA u1 (.in(a), .out(z));
endmodule
