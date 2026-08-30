//	   Index parameters
// The parameters are based on 144 source
`define	N_FL_INDEX_SIZ			 10	//   8

module m (a, z);
  input [`N_FL_INDEX_SIZ:0] a;
  output [`N_FL_INDEX_SIZ:0] z;

  assign z = a;
endmodule
