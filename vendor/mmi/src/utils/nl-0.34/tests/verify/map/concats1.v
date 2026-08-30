module m (a, b, c, d, e, f, g, h, p, w, x, y, z);
  input a, b, c, d, e, f, g, h;
  input [7:0] p;
  output [7:0] w, x, y, z;

  assign w = p & {a, b, {c}};
  assign x = p & {a, b, {{c}, d}, e, f};
  assign y = p & {a, {{b}, c}, {d, {e, {f}}}};
  assign z = p & {{{a}, b}, {{c}, d}, {{{e, f}}}};

endmodule

