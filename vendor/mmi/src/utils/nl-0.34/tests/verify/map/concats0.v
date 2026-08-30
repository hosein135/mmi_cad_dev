module m (a, b, c, d, e, f, g, h, w, x, y, z);
  input a, b, c, d, e, f, g, h;
  output [7:0] w, x, y, z;

  assign w = {a, b, {c}};
  assign x = {a, b, {{c}, d}, e, f};
  assign y = {a, {{b}, c}, {d, {d, {f}}}};
  assign z = {{{a}, b}, {{c}, d}, {{{e, f}}}};

endmodule

