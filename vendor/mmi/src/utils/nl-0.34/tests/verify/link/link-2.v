module m (ins, outs, inouts);
  input [5:2] ins;
  output [6:9] outs;
  inout [0:0] inouts;
  
endmodule

module n (a, b, c);
  input [0:3] a;
  output [0:3] b;
  inout c;

  m u1 (.ins(a), .outs(b), .inouts(c));
endmodule
