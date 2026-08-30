module m (a, b, c, z);
  input [3:0] a, b, c;
  output [3:0] z;

  m1 u1 (.x({a[1], a[2]}), .y(4'd10), .z({3{z[0]}}));

endmodule
