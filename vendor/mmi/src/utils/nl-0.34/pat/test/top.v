
module sub2 (foo);
	inout foo;

	MMI_BUFD MMI_BUFD_1 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_2 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_3 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_4 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_5 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_6 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_7 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_8 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_9 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_10 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_11 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_12 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_13 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_14 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_15 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_16 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_17 (.in(foo), .out(foo));
	MMI_BUFD MMI_BUFD_18 (.in(foo), .out(foo));
 

endmodule

module sub1 (foo);
	inout foo;
 
	sub2 b_1 (.foo(foo));
	sub2 b_2 (.foo(foo));
	sub2 b_3 (.foo(foo));
	sub2 b_4 (.foo(foo));
	sub2 b_5 (.foo(foo));
	sub2 b_6 (.foo(foo));
	sub2 b_7 (.foo(foo));
	sub2 b_8 (.foo(foo));
	sub2 b_9 (.foo(foo));
	sub2 b_10 (.foo(foo));
	sub2 b_11 (.foo(foo));
	sub2 b_12 (.foo(foo));
	sub2 b_13 (.foo(foo));
	sub2 b_14 (.foo(foo));
	sub2 b_15 (.foo(foo));
	sub2 b_16 (.foo(foo));
	sub2 b_17 (.foo(foo));
	sub2 b_18 (.foo(foo));

endmodule

module top (foo);
 
	inout foo;
	sub1 a_1 (.foo(foo));
	sub1 a_2 (.foo(foo));
	sub1 a_3 (.foo(foo));
	sub1 a_4 (.foo(foo));
	sub1 a_5 (.foo(foo));
	sub1 a_6 (.foo(foo));
	sub1 a_7 (.foo(foo));
	sub1 a_8 (.foo(foo));
	sub1 a_9 (.foo(foo));
	sub1 a_10 (.foo(foo));
	sub1 a_11 (.foo(foo));
	sub1 a_12 (.foo(foo));
	sub1 a_13 (.foo(foo));
	sub1 a_14 (.foo(foo));
	sub1 a_15 (.foo(foo));
	sub1 a_16 (.foo(foo));
	sub1 a_17 (.foo(foo));
	sub1 a_19 (.foo(foo));

endmodule

