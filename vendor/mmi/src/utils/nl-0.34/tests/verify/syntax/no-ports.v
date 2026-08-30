module m1;
endmodule

module m2;
  MMI_NAND2B u1 (.in0(a), .in1(b), .out(z));
endmodule

module m3;
  wire a, z;
  assign z = a;
endmodule

module m4;
  assign z = a;
endmodule
