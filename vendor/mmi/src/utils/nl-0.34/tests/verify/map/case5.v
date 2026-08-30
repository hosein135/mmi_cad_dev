module m (s, d, z);
  input [1:0] s;
  input [3:0] d;
  output z;

  reg z;

  always @(s or d)
    case (s)
      2'b00: z = d[0];
      2'b01: z = d[1];
      2'b10: z = d[2];
      2'b11: z = d[3];
      default: z = 1'b0;
    endcase
endmodule
