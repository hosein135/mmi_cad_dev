module subsub (a, b, c, x, y, z);
  input a, b, c;
  output x, y, z;
 
  MMI_NAND2B u1 (.in0(a), .in1(b), .out(t));
  MMI_NOR2B u2 (.in0(b), .in1(c), .out(u));
  assign x = a;
  assign y = u;
  MMI_INVB u3 (.in(t), .out(z));

endmodule

module sub (d, e, u, v, w);
  input d, e;
  output u, v, w;

  subsub ss (.a(d), .b(e), .c(1'b1), .x(u), .y(v), .z(w)); 

endmodule


module m (p, q);
  input [4:0] p;
  output [5:0] q;

  assign q[5] = h;
  sub sub (.d(p[0]), .e(p[1]), .u(q[0]), .v(q[1]), .w(q[2]));
  subsub sub2 (.a(p[2]), .b(p[3]), .c(p[4]), .x(q[3]), .y(q[4]), .z(h));

endmodule
