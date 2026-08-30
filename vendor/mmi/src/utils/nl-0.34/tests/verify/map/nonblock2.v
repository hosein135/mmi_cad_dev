module m (a, b, c, w, x, y, z);
  input a, b, c;
  output w, x, y, z;

  always begin
    z <= a ^ b;
    y <= z;
    x = a ^~ b;
    if ( c ) begin
      z <= a & b;
      x = ~(a & b);
    end
    else begin
      z <= a | b;
      x = ~(a | b);
    end
    w <= x;
    x = ~a;
  end

endmodule
