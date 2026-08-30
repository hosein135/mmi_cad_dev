module m (a, b, z);
  input a, b;
  output [1:0] z;

  wire u = a;
  wire v = b;
  wire w = a, x = b;
  assign z = {w, x};

endmodule
