module m (a, b, z);
  input a, b;
  output z;

  wire u = a;
  wire v = b;
  wire w = ~u & v, x = u & ~v;
  assign z = w | x;

endmodule
