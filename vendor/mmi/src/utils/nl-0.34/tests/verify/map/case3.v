module m (sel, a, b, c, d, z);
  input [1:0] sel;
  input [3:0] a, b, c, d;
  output [3:0] z;

  reg [3:0] z;

  always @(sel or a or b or c or d) begin
    z = d;
    case (sel)
      2'b10: z[3:2] = c[3:2];
      2'b00: z[0] = a[0];
      2'b01: z[1] = b[1];
    endcase
  end

endmodule

