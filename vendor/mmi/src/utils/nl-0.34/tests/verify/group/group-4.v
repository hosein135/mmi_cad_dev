module m (a, b, c, d, z);
  input [3:0] a;
  input [0:3] b;
  input [3:6] c;
  input [8:5] d;

  output [3:0] z;

  wire [2:5] p;
  wire [7:4] q;

  and2_4 u1 (.in0(a), .in1(b), .out(p));
  and2_4 u2 (.in0(c), .in1(d), .out(q));
  and2_4 u3 (.in0(p), .in1(q), .out(z));

endmodule
