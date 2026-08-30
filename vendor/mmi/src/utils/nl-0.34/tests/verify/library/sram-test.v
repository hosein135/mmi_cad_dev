module m (a, wd, rd, ck, we, me);
  input [0:6] a;
  input [0:63] wd;
  output [0:255] rd;
  input ck, we, me;

  MMI_SRAM32X256 u1 (.a(a), .wdata(wd), .rdata(rd),
                     .clk(ck), .wenable(we), .memenable(me));
endmodule

