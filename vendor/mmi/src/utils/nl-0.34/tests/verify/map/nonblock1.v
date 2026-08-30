module m (a, b, c, y, z);
  input a, b;
  output y, z;

  always begin
    z <= a & b;
    y <= z;
    z <= a | b;
  end

endmodule
