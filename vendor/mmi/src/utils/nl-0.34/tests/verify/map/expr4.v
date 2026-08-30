module m (a, b, z);
  input [7:0] a, b;
  output [7:0] z;

  assign z = (a > b) ? a - b : b - a;
endmodule
