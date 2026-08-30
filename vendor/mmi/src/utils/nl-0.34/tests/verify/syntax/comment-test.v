module m (a, z);
  input a;
  output z;

  assign z = a;

/* synopsys translate_off */
/* verilint translate off */
// `
/* ` */

rkdp_multicyc_delay rd_req_dly (.dout (rrksac_snd_rdreq_x), 
                                .din (rrksac_snd_rdreq),
                                .clk  (clk_2x) );

rkdp_multicyc_delay pa_req_dly (.dout (rrksac_snd_pareq_x), 
                                .din (rrksac_snd_pareq),
                                .clk  (clk_2x) );

// 
/* verilint translate on */
/* synopsys translate_on */

endmodule
