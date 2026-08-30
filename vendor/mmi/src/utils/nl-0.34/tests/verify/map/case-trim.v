module m (sel, mux0, mux1, mux2out);
  input sel, mux0, mux1;
  output mux2out;

  reg mux2out;

    always @(sel or mux0 or mux1) 
        case (sel)
            0: mux2out = mux0;
            1: mux2out = mux1;
        endcase

endmodule
