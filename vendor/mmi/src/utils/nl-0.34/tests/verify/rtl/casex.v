module m (a, b, z);
  input [2:0] a;
  input [3:0] b;
  output [3:0] z;

  /* synopsys sync_set_reset "reset" */

  reg [3:0] z;

  always @(a or b)
    casex (a)
      3'b00x: z = b + 4'h0;
      3'b01x: z = b + 4'h1;
      3'b1?0: z = b + 4'h2;
      3'b1?1: z = b + 4'h3;
    endcase

endmodule
