`include "l.h"

module m (write_bits_en_cmp, i_exec_cmp, write_en_cmp);

input                           [31:0] write_bits_en_cmp;
input  [(`LIN_IMEM_SUBINST_WIDTH-1):0]  i_exec_cmp; 
output        [(`LIN_NTFREG_SIZE+31):0] write_en_cmp;

assign write_en_cmp =
       {{(`LIN_NTFREG_SIZE-2){1'b0}},write_bits_en_cmp,1'b0}
    << i_exec_cmp[`LIN_INST_IDATA_WR_EX_BP];

endmodule
