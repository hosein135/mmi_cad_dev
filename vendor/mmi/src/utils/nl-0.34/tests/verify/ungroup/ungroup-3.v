
module sub1 (a, z);
  input a;
  output z;

  m1 u1 (.p(a), .q(a), .r(z));
endmodule

module sub2 (a, z);
  input a;
  output z;

  m1 u1 (.p(a), .r(z));
endmodule

module top (a, z);
  input a;
  output z;

  sub1 s1 (.a(a), .z(z));
  sub2 s2 (.a(a), .z(z));
endmodule
