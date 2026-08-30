module m (a, z);
  input [3:0] a;
  output [3:0] z;

  foo u1 (.in(a), .out(z));
endmodule
