module m (a, b, z);
  input [5:2] a;
  input [1:4] b;
  output [6:9] z;

  MMI_INVB u1 (.in(a & b), .out(z));
endmodule
