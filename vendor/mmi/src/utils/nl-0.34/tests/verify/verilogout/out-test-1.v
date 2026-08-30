module m (a, b, c, z);
  input [9:6] a;
  input [1:5] b;
  input c;
  output [0:0] z;

  m1 u1 (.a(a),
         .b(b),
         .c({a[9:8], c}),
         .d({c, b[3], b[2]}),
         .e(c),
         .f({a[9], a[7]}),
         .g(z[0]),
         .h({z[0], z[0]}),
         .i({b[1], b[5]}),
         .j({a[9], b[2], a[7]}),
	 .k(a));

endmodule
