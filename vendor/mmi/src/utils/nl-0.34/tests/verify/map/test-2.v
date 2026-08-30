module m (a, z);
  input a;
  output [3:0] z;

  reg [3:0] z;

  always
    if ( a )
      z = 4'b0;
    else
      z = z + 4'b3;

endmodule

     