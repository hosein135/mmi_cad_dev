module m (sel, a, b, c, d, z);
  input [1:0] sel;
  input [3:0] a, b, c, d;
  output [3:0] z;

  reg [3:0] z;

  always @(sel or a or b or c or d) begin

    case (sel)
      2'h3: z = d;
      2'b00, 2'd2: begin
        z[1:0] = a[1:0]; 
        z[3:2] = c[3:2];
      end
      default: z = b;
    endcase

  end

endmodule
