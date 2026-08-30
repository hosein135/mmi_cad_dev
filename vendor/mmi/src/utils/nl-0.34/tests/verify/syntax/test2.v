module m (.foo({bar}), z);
  input [1:0] bar;
  output z;

  m1 u1 (bar[1], bar[0], z);
endmodule
