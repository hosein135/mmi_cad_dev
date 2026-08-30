module MMI_FFCB (D,Q,clearn,clk,scan_en,scan_in);
	input	D;
	output	Q;
	input	clearn;
	input	clk;
	input	scan_en;
	input	scan_in;

	reg	Q;

	always @(posedge clk or negedge clearn)
		if (clearn == 0)
			Q <= #1 1'b0;
		else
			Q <= #1 D;

endmodule



