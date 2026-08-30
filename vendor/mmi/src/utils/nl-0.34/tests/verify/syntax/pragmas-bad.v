module m (ck, a, z);
  input ck;
  input [3:0] a;
  output [3:0] z;
  reg [3:0] z;

  always @(posedge ck) begin
    case (a[1:0]) // synopsys infer_mux parallel_foobar
      2'b01: z[0] = a[2] | a[3];
      2'b10: z[0] = a[2] &~ a[3];
      2'b11: begin
          z[0] = a[2] |~ a[3];
	  z[1] = ~a[2];
        end
      default: begin
          z[0] = 1'b0;
          z[1] = 1'b1;
        end
    endcase
    z[1] = ~z[1];
  end

endmodule
	
 
    