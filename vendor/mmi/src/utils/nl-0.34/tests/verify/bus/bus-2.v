module sub (p, q);
  input [3:0] p;
  output [3:0] q;
endmodule

module m (a, b, c, d, e, v, w, x, y, z);
  input [3:0] a, b, c, d, e;
  output [3:0] v, w, x, y, z;

  assign x = c;
  assign w[3:0] = d;
  assign v = e[3:0];

  sub zz1 (.p(a[3:0]), .q({y[0], y[1:1], y[2], y[3:3]})),
      zz2 (.q(z), .p(b));
endmodule

