module m (a, b, c, d, z);
  input [2:0] a;
  input [1:0] b;
  input [5:0] c;
  input [3:0] d;
  output [3:0] z;

  assign z = {2{a}} + {3{c}} + {4{b}} + {5{d}};

endmodule
