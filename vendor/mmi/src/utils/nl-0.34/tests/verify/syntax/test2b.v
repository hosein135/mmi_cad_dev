module m (bar[1], z, bar[0]);
  input [1:0] bar;
  output z;

  m1 u1 (bar[1], bar[0], z);
endmodule
