module m (a, b, z);
  input [3:0] a, b;
  output [3:0] z;

  reg [3:0] z;
  reg [3:0] t1, t2;

  always @(a or b) begin
    t1 = a & ~b;
    t2 = ~a & b;
    z = t1 | t2;
  end    

endmodule
