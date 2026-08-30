module n (a, z);
  input a;
  output z;

  MMI_AND2B u3 (.in0(a), .out(z));
  MMI_NOR2B u4 (.in0(a));

endmodule


module m (a, b, z);
  input a, b;
  output z;

  MMI_AND2B u1 (.in0(a), .in1(b), .out(z));
  MMI_NOR2B u2 (.in0(a));
  n u0 (.a(a), .z(z));

endmodule
