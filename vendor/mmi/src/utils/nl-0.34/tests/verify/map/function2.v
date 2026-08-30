module m (a, b, c, p, z);
  input [0:0] a;
  input [1:0] b;
  input [3:0] c;
  input p;
  output [3:0] z;

  function [2:0] fun;
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
    if ( p ) begin :foo
      z = fun (a, ~b, c);
    end
    else begin
      z = fun (c, b, ~a);
    end

endmodule
