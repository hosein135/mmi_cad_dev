module m (a, b, c, d, e, w, x, y, z);
  input a;
  input [1:0] b;
  input [2:0] c;
  input [3:0] d;
  input e;
  output [0:4] w, x, y, z;

  function [0:19] fun;
    input a;
    input [1:0] b;
    input [2:0] c;
    input [3:0] d;
    input e;

    begin    
      fun[0] = & a;
      fun[1] = & b;
      fun[2] = & c;
      fun[3] = & { a, e };
      fun[4] = & { a, b };

      fun[5] = | a;
      fun[6] = | b;
      fun[7] = | c;
      fun[8] = | { a, e };
      fun[9] = | { a, b };

      fun[10] = ^ a;
      fun[11] = ^ b;
      fun[12] = ^ c;
      fun[13] = ^ { a, e };
      fun[14] = ^ { a, b };

      fun[15] = ~^ a;
      fun[16] = ~^ b;
      fun[17] = ~^ c;
      fun[18] = ~^ { a, e };
      fun[19] = ~^ { a, b };
    end
  endfunction

  assign w[0] = & a;
  assign w[1] = & b;
  assign w[2] = & c;
  assign w[3] = & { a, e };
  assign w[4] = & { a, b };

  assign x[0] = | a;
  assign x[1] = | b;
  assign x[2] = | c;
  assign x[3] = | { a, e };
  assign x[4] = | { a, b };

  assign y[0] = ^ a;
  assign y[1] = ^ b;
  assign y[2] = ^ c;
  assign y[3] = ^ { a, e };
  assign y[4] = ^ { a, b };

  assign z[0] = ~^ a;
  assign z[1] = ~^ b;
  assign z[2] = ~^ c;
  assign z[3] = ~^ { a, e };
  assign z[4] = ~^ { a, b };

endmodule
