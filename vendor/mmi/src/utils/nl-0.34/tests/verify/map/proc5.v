module m (a, b, z);
  input a, b;
  output z;

  reg z;

  always @(a or b) begin
    if ( a ) 
      z = b;
  end    

endmodule
