module m (a, b, c, d, z);
  input a, b, c, d;
  output z;

  reg z;
  reg t;

  always @(a or b or c or d) begin
    t = ~t | c;
    t = t ^ d;
    z = t;
    t = a & b;
  end    

endmodule
