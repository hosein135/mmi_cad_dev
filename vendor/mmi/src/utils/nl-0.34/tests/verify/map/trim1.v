module m (a, b, c, z);
  input [2:0] a;
  input [2:0] b;
  input [3:0] c;
  output [5:0] z;

  assign z = { a & b, c};

endmodule
