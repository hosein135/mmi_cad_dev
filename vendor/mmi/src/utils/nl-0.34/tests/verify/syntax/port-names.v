module m (.a({x[0], x[2:1]}), .b({y[0], y[1], y[2]}));
  input [3:0] x;
  output [3:0] y;

  assign y[3] = x[3];
  assign y[2:0] = x[2:0];
endmodule
