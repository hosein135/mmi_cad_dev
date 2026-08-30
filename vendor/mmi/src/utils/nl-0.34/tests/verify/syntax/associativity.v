module m (a, z);
  input [3-2+1:0] a;
  output [6-2-2:0] z;

  assign z = a;
endmodule
