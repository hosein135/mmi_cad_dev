module m (a, z);
  input [3:0] a;
  output [3:0] z;

  reg [3:0] z;

  integer i;
  integer j;

  always @(a) begin
    z = {a[0], a[1], a[2], a[3]};
    {z[3], z[2], z[1], z[0]} = {z[3], z[2], z[1]} + {z[3], ~z[2], z[1:0]};
    for ( i = 0; i < 4; i = i + 1 ) 
      for ( j = i; {j[3], j[2], j[1], j[0]} < 4; j = j + 1 )
        z[i] = z[i] ^ a[j];
  end

endmodule
