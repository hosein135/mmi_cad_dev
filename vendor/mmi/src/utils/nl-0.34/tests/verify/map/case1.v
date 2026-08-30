module m (sel, a, b, c, d, z);
  input [1:0] sel;
  input [3:0] a, b, c, d;
  output [3:0] z;

  reg [3:0] z;

  always @(sel or a or b or c or d)
    case (sel) // synopsys full_case
      2'b00: z = a;
      2'b01: z = b;
      2'b10: z = c;
      2'b11: z = d;
    endcase

endmodule

