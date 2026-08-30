module m (v, w, x, y, z);
  output [0:63] z;
  output [0:33] y;
  output [0:11] x;
  output [0:35] w;
  output [0:31] v;

  assign z = 64
     'b
     _01_0011_000111_00001111_0000011111_;

  assign y = 34  'O0_1_2_3_4_5_6_7___;

  assign x = 12'd259;

  assign w = 36'h	fdb97531;

  assign v = ___5_1_4;

endmodule
