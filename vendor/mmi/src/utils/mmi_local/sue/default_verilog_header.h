// ************************************************************************

// default verilog header file

// units of time and time resolution for this run
`timescale 1ps / 1ps

// this must be the very first module for interactive probing to work
module test;

// reg		a;
// wire		b;

// needed for interactive verilog probing.
   integer         tmp_channel;

// instantiate main verilog module
// NOTE: the name of the module must be the same as its type

	&file& &file&();

    initial
      begin
//    	$dumpfile();
//	$dumpvars;

//	a = 0;

// #1000 	a = 1; 

// #2000 	a = 0; 

//	$finish;
      end

endmodule

// include files
// `include "foo.v"

// ************************************************************************
