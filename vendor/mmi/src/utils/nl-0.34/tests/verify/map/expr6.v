module m (a, b, cin, sum, cout);
  input [7:0] a, b;
  input cin;
  output [7:0] sum;
  output cout;

  wire dummy;

  assign {cout, sum} = a + b;

endmodule
