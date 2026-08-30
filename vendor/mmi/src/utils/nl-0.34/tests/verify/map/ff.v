module m (clk, r, d, q, p, s);
  input clk, r;
  input [4:0] d;
  output [5:0] p, q, s;

  always @(posedge clk)
    q[5:4] = {1'b1, d[4]};

  always @(posedge clk)
    if ( r )
      q[3:0] = {2'b10, d[1:0]};
    else
      {q[2], q[3], q[1:0]} = {d[2], 3'b001}; 

  always @(posedge clk or negedge r)
    if ( !r )
      p[0] = 1'b0;
    else
      p[0] = d[0];

  always @(negedge clk or posedge r)
    if ( r )
      p[1] = 1'b0;
    else
      p[1] = d[1];

  always @(negedge clk or posedge r)
    if ( ~r )
      p[2] = d[2];
    else
      p[2] = 1'b0;

  always @(posedge clk or negedge r)
    if ( r )
      p[3] = d[3];
    else
      p[3] = 1'b1;

  always @(negedge clk or negedge r)
    if ( !r )
      p[4] = 1'b1;
    else
      p[4] = d[4];

  always @(negedge clk) begin :foo
    s[3] <= #1 d[0];
    s[0] = #2 d[0];
    s[2:1] = d[2:1];
    s[3] = d[3];
  end    

endmodule
