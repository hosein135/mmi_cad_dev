module m (a, z);
  input a;
  output z;

  MMI_INVB u1 (.in(a), .out(z));
endmodule
