module m (a, b, z);
  input a, b;
  output [0:3] z;

  wire [3:0] o;

  assign z = o;
  assign o = {a, b, a, b};

endmodule
