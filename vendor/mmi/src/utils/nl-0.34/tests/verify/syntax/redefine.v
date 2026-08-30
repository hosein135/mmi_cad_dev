`define FOO mod1
`define FOO mod2

module `FOO (a, z);
  input a;
  output z;

  assign z = a;
endmodule
