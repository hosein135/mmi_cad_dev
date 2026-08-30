module m (a, b, z);
  input a, b;
  output [0:3] z;

  wire [3:0] o;

  assign z = {o[0], o[3:1]};
  assign o = {{2{a}}, b, o[3]};

endmodule
