module m (a, z);
  input a;
  output z;

 /* synopsys dc_script_begin

set_dont_touch find(cell, "mulnhp_addr_adder0");

*/

 // synopsys dc_script_end

 assign z = a;

 // synopsys dc_script_begin
 // foreach c list_cells() {
 //   set_map_only c
 // }
 /* synopsys dc_script_end */

endmodule
