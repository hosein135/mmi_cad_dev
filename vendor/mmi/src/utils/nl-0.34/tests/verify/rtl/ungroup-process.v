module sub (p, q);
  input [3:0] p;
  output [1:4] q;

  reg [1:4] q;
  reg [7:4] s;

  wire r;

  assign r = p[3];
 
  always @(r or p) begin
    case ( r )
      1'b0: s = ~p;
      1'b1: s = p;
    endcase
    q = q ^ s;
  end

endmodule

module m (a, z);
  input [0:3] a;
  input [10:7] z;

  wire [2:5] x = a;

  sub sub (.p(a), .q(z));

endmodule
