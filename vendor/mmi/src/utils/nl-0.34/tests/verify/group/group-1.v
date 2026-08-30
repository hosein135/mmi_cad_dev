module m1 (in, out, io);
  input in;
  output out;
  inout io;

endmodule

           

module m (a, b, p, q, y, z);
  input a, b;
  inout p, q;
  output y, z;

  m1 ext1  (.out(in1));
  m1 int1  (.in(in1));
  
  m1 ext2  (.in(in2), .out(in2));
  m1 int2  (.in(in2));

  m1 ext3  (.io(in3));
  m1 int3  (.in(in3));

  u1 ext4  (.unk(in4));
  m1 int4  (.in(in4));

  u1 ext5a (.unk(in5));
  m1 ext5b (.out(in5));
  m1 int5  (.in(in5));


  m1 ext6  (.in(out6));
  m1 int6  (.in(out6), .out(out6));

  m1 ext7  (.out(in7));
  m1 int7  (.in(in7), .out(in7));

  m1 ext8  (.in(io8), .out(io8));
  m1 int8  (.in(io8), .out(io8));

  m1 ext9  (.io(io9));
  m1 int9  (.in(io9), .out(io9));

  u1 ext10 (.unk(unk10));
  m1 int10 (.in(unk10), .out(unk10));

  u1 ext11a (.unk(unk11));
  u1 ext11b (.in(unk11));
  m1 int11 (.in(unk11), .out(unk11));


  u1 ext12a (.unk(unk12));
  u1 ext12b (.out(unk12));
  m1 int12 (.in(unk12), .out(unk12));

  m1 ext13 (.in(out13));
  m1 int13 (.out(out13));

  m1 ext14 (.out(out14));
  m1 int14 (.out(out14));

  m1 ext15 (.io(out15));
  m1 int15 (.out(out15));

  m1 ext16 (.in(out16), .out(out16));
  m1 int16 (.out(out16));

  u1 ext17 (.unk(out17));
  m1 int17 (.out(out17));

  m1 ext18a (.in(out18));
  u1 ext18b (.unk(out18));
  m1 int18 (.out(out18));

  m1 ext19a (.out(out19));
  u1 ext19b (.unk(out19));
  m1 int19 (.out(out19));

  m1 ext20a (.io(out20));
  u1 ext20b (.unk(out20));
  m1 int20 (.out(out20));

  m1 int21a (.in(a), .out(n21a));
  m1 int21b (.in(n21a), .out(n21b));
  m1 int21c (.in(n21b), .out(z));

endmodule
