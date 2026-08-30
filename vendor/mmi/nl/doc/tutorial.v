module full_adder (a, b, cin, cout, sum);
  input a, b, cin;
  output cout, sum;

  wire n1, n2, n3, n4;

  MMI_XOR2B  u1 (.in0(a), .in1(b), .out(n1));
  MMI_XOR2A  u2 (.in0(n1), .in1(cin), .out(sum));
  MMI_NAND2A u3 (.in0(a), .in1(b), .out(n2));
  MMI_NAND2A u4 (.in0(a), .in1(cin), .out(n3));
  MMI_NAND2A u5 (.in0(b), .in1(cin), .out(n4));
  MMI_NAND3B u6 (.in0(n2), .in1(n3), .in2(n4), .out(cout));

endmodule


module add4 (x, y, cin, z, cout);
  input [0:3] x, y;
  input cin;
  output [0:3] z;
  output cout;

  wire [2:0] carry;

  full_adder
    fa1 (.a(x[0]), .b(y[0]), .cin(cin),      .cout(carry[0]), .sum(z[0]));
  full_adder
    fa2 (.a(x[1]), .b(y[1]), .cin(carry[0]), .cout(carry[1]), .sum(z[1]));
  full_adder
    fa3 (.a(x[2]), .b(y[2]), .cin(carry[1]), .cout(carry[2]), .sum(z[2]));
  full_adder
    fa4 (.a(x[3]), .b(y[3]), .cin(carry[2]), .cout(cout),     .sum(z[3]));

endmodule
