module foo;
 
	wire		bar;
	wire		net_3;
	wire		uc_net_1;
	wire		uc_net_2;
 
	MMI_BUFB MMI_BUFB (.in(uc_net_1), .out(bar));
	MMI_BUFB MMI_BUFB_1 (.in(net_3), .out(uc_net_2));
	MMI_BUFB foo (.in(bar), .out(net_3));

endmodule	

