module m (v, w, x, y, z);
  output [0:63] z;
  output [0:33] y;
  output [0:11] x;
  output [0:35] w;
  output [0:31] v;

  assign z = 64
     'b
     _02_0011_000111_00001111_0000011111_;

endmodule
