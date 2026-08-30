module m (a, z);
  input [3:0] a;
  output [3:0] z;

  reg [3:0] z;

  always @(a)
    case (a)
      4'h0: z = 0;
      4'h1,
      4'h2,
      4'h4,
      4'h8: z = 1;
      4'h3,
      4'h5,
      4'h6,
      4'h9,
      4'ha,
      4'hc: z = 2;
      4'h7,
      4'hb,
      4'hd,
      4'he: z = 3;
      4'hf: z = 4;
    endcase

endmodule
