module m (clk, r, d, q, p, s);
  input clk, r;
  input [4:0] d;
  output [5:0] p, q, s;

  always @(negedge clk) begin :foo
    s[3] = #1 d[0];
    s[0] = #2 d[0];
    s[2:1] = d[2:1];
    s[3] = d[3];
  end    

endmodule
