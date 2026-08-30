`define	LIN_NTFREG_STRPOF_WIDTH        6
`define	LIN_SOF_WIDTH         6

module test (strpof_cmp, l3sof_cmp, strpof_plus_sof_cmp);
 
input  [(`LIN_NTFREG_STRPOF_WIDTH-1):0] strpof_cmp;
input          [(`LIN_SOF_WIDTH-1):0]  l3sof_cmp; 
output                         [ 6:0] strpof_plus_sof_cmp;

assign strpof_plus_sof_cmp = {1'b0,strpof_cmp} + {1'b0,l3sof_cmp};

endmodule
