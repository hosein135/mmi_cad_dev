module m (.a({a, b}), z);
  input [2:0] a;
  input [1:0] b;
  output z;

  m1 u1 (b[1], b[0], z);
  m1 u2 (b[1], b[0], a[2]);
  m2 u3 (b[0], a[0], a[1]);
endmodule
