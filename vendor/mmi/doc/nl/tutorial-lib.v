module MMI_AND2B (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_AND2C (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_AND3B (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_AND3C (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_AND4B (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_AND4C (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_AO21B (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_AO21C (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_AO22B (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_AO22C (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_AO31B (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_AO31C (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_AOI21A (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_AOI21B (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_AOI21C (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_AOI22A (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_AOI22B (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_AOI31A (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_AOI31B (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_BUFB (in, out);
  input in;
  output out;
endmodule

module MMI_BUFC (in, out);
  input in;
  output out;
endmodule

module MMI_BUFD (in, out);
  input in;
  output out;
endmodule

module MMI_BUFE (in, out);
  input in;
  output out;
endmodule

module MMI_FILL_1;
  wire dummy;
endmodule

module MMI_FILL_2;
  wire dummy;
endmodule

module MMI_FILL_4;
  wire dummy;
endmodule

module MMI_FILL_8;
  wire dummy;
endmodule

module MMI_FFB (d, clk, q);
  input d, clk;
  output q;
endmodule

module MMI_FFCB (d, clk, clrb, q);
  input d, clk, clrb;
  output q;
endmodule

module MMI_FFNCB (d, clk, clrb, q);
  input d, clk, clrb;
  output q;
endmodule

module MMI_FFHB (d, clk, hold, q);
  input d, clk, hold;
  output q;
endmodule

module MMI_FFMB (d0, d1, clk, sel, q);
  input d0, d1, clk, sel;
  output q;
endmodule

module MMI_FFSB (d, clk, setb, q);
  input d, clk, setb;
  output q;
endmodule

module MMI_INAND2A (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_INAND2B (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_INAND2C (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_INOR2A (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_INOR2B (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_INOR2C (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_INVA (in, out);
  input in;
  output out;
endmodule

module MMI_INVB (in, out);
  input in;
  output out;
endmodule

module MMI_INVC (in, out);
  input in;
  output out;
endmodule

module MMI_INVD (in, out);
  input in;
  output out;
endmodule

module MMI_INVE (in, out);
  input in;
  output out;
endmodule

module MMI_KEEPW (in);
  input in;
endmodule

module MMI_LLACB (d, clk, clrb, q);
  input d, clk, clrb;
  output q;
endmodule

module MMI_LLCB (d, clk, clrb, q);
  input d, clk, clrb;
  output q;
endmodule

module MMI_LTCHNB (d, clk, q);
  input d, clk;
  output q;
endmodule

module MMI_LTCHPB (d, clk, q);
  input d, clk;
  output q;
endmodule

module MMI_MUX2A (in0, in1, sel, out);
  input in0, in1, sel;
  output out;
endmodule

module MMI_MUX2B (in0, in1, sel, out);
  input in0, in1, sel;
  output out;
endmodule

module MMI_MUX2C (in0, in1, sel, out);
  input in0, in1, sel;
  output out;
endmodule

module MMI_MUX2D (in0, in1, sel, out);
  input in0, in1, sel;
  output out;
endmodule

module MMI_MUX3B (in0, in1, in2, sel0, sel1, out);
  input in0, in1, in2, sel0, sel1;
  output out;
endmodule

module MMI_MUX3C (in0, in1, in2, sel0, sel1, out);
  input in0, in1, in2, sel0, sel1;
  output out;
endmodule

module MMI_MUX4B (in0, in1, in2, in3, sel0, sel1, out);
  input in0, in1, in2, in3, sel0, sel1;
  output out;
endmodule

module MMI_MUX4C (in0, in1, in2, in3, sel0, sel1, out);
  input in0, in1, in2, in3, sel0, sel1;
  output out;
endmodule

module MMI_MUXI2A (in0, in1, sel, out);
  input in0, in1, sel;
  output out;
endmodule

module MMI_MUXI2B (in0, in1, sel, out);
  input in0, in1, sel;
  output out;
endmodule

module MMI_MUXI2C (in0, in1, sel, out);
  input in0, in1, sel;
  output out;
endmodule

module MMI_MUXI3B (in0, in1, in2, sel0, sel1, out);
  input in0, in1, in2, sel0, sel1;
  output out;
endmodule

module MMI_MUXI3C (in0, in1, in2, sel0, sel1, out);
  input in0, in1, in2, sel0, sel1;
  output out;
endmodule

module MMI_MUXI4B (in0, in1, in2, in3, sel0, sel1, out);
  input in0, in1, in2, in3, sel0, sel1;
  output out;
endmodule

module MMI_MUXI4C (in0, in1, in2, in3, sel0, sel1, out);
  input in0, in1, in2, in3, sel0, sel1;
  output out;
endmodule

module MMI_NAND2A (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_NAND2B (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_NAND2C (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_NAND2D (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_NAND3A (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_NAND3B (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_NAND3C (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_NAND4A (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_NAND4B (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_NAND4C (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_NOR2A (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_NOR2B (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_NOR2C (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_NOR2D (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_NOR3A (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_NOR3B (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_OA21B (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_OA21C (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_OA22B (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_OA22C (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_OA31B (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_OA31C (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_OAI21A (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_OAI21B (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_OAI21C (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_OAI22A (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_OAI22B (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_OAI31A (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_OAI31B (in0, in1, in2, in3, out);
  input in0, in1, in2, in3;
  output out;
endmodule

module MMI_OR2B (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_OR2C (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_OR3B (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_OR3C (in0, in1, in2, out);
  input in0, in1, in2;
  output out;
endmodule

module MMI_RPTRF (in, out);
  input in;
  output out;
endmodule

module MMI_SFFB (d, clk, s_in, s_en, q, s_out);
  input d, clk, s_in, s_en;
  output q, s_out;
endmodule

module MMI_SFFCB (d, clk, clrb, s_in, s_en, q, s_out);
  input d, clk, clrb, s_in, s_en;
  output q, s_out;
endmodule

module MMI_SFFHB (d, clk, hold, s_in, s_en, q, s_out);
  input d, clk, hold, s_in, s_en;
  output q, s_out;
endmodule

module MMI_SFFMB (d0, d1, clk, sel, s_in, s_en, q, s_out);
  input d0, d1, clk, sel, s_in, s_en;
  output q, s_out;
endmodule

module MMI_SFFPB (d, clk, setb, s_in, s_en, q);
  input d, clk, setb, s_in, s_en;
  output q;
endmodule

module MMI_SFFRB (d, clk, clrb, s_in, s_en, q);
  input d, clk, clrb, s_in, s_en;
  output q;
endmodule

module MMI_SFFSB (d, clk, setb, s_in, s_en, q, s_out);
  input d, clk, setb, s_in, s_en;
  output q, s_out;
endmodule

module MMI_TSBUFC (in, en, enb, out);
  input in, en, enb;
  output out;
endmodule

module MMI_TSBUFE (in, en, enb, out);
  input in, en, enb;
  output out;
endmodule

module MMI_XNOR2A (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_XNOR2B (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_XNOR2C (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_XOR2A (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_XOR2B (in0, in1, out);
  input in0, in1;
  output out;
endmodule

module MMI_XOR2C (in0, in1, out);
  input in0, in1;
  output out;
endmodule

