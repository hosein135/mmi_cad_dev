module sub (a, b, c, z);
  input [3:0] a;
  input b;
  input [1:0] c;
  output [1:0] z;

  assign z = a;

  // synopsys translate_off
  initial #1 $display ("a = %b, b = %b", a, b);
  // synopsys translate_on

endmodule

module m (p, q, r, x, y, z);
  input p, q, r;
  input [1:0] x;
  output [2:0] y;
  output z;

  assign x = 2'b11;
  assign p = 1'b1;

  sub u1 (.a(x), .z(y));
  sub u2 (.a(p), .b(q), .c(r), .z(z));
endmodule
