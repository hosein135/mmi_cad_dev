module m (a, b, y, z);
  input [15:0] a, b;
  output [3:0] y, z;

  assign y = a >> 2;
//  assign z = (a + b) >> (1 + 2);

endmodule
