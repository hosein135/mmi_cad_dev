module m (a, b, c, d, e, w, x, y, z);
  input a, b;
  input [1:0] c;
  input [2:0] d;
  output [0:6] z;

  function [0:6] fun;
    input a, b;
    input [1:0] c;
    input e;

    begin    
      fun[0] = a && b;
      fun[1] = a || b;
      fun[2] = !a;
      fun[3] = a && c;
      fun[4] = c || b;
      fun[5] = !c;
      fun[6] = !d;
    end
  endfunction

  assign z[0] = a && b;
  assign z[1] = a || b;
  assign z[2] = !a;
  assign z[3] = a && c;
  assign z[4] = c || b;
  assign z[5] = !c;
  assign z[6] = !d;

endmodule
