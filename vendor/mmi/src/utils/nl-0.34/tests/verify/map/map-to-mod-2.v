module m (a1, a2, b1, b2, y, z);
  input [3:0] a1, a2;
  input [7:0] b1, b2;
  output [3:0] y, z;

  function [3:0] foo;
    // synopsys map_to_module MMI_FOOBAR
    // synopsys return_port_name Z
    input [4:1] A;
    input [3:10] B;
    
    foo = 4'b0;
  endfunction

  assign y = foo (a1, b1);
  assign z = foo (a2, b2);

endmodule
