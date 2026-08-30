module m (a, b, c, z);
  input [0:0] a;
  input [1:0] b;
  input [3:0] c;
  output [3:0] z;

  function [2:0] fun;
    // synopsys map_to_module FOO
    input [2:0] u, v, w;
    
    reg [2:0] s;
    reg [2:0] t;

    begin
      t = u & v;
      t = t | w;
      fun = t;
    end
  endfunction

  reg [3:0] z;

  always
    z = fun (a, ~b, c);

endmodule
