module foo (a, z);
  input a;
  output z;

  mod #(1, 2, 3) m (.a(a), .z(z));
endmodule
