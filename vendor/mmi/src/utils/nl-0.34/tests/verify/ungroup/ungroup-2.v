module sub1 (p, q);
  input [3:0] p;
  output [3:0] q;

  reg [3:0] q;

  always @(p)
    q = ~p;

endmodule

module sub2 (p, q);
  input [2:0] p;
  output q;

  reg q;

  always @(p)
    q = &p;

endmodule

module m (a, y, z);
  input [3:0] a;
  output [3:0] y;
  output z;

  sub1 sub1 (.p(a), .q(y));
  sub2 sub2 (.p(a[2:0]), .q(z));

endmodule
