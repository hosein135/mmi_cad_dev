module m (a, b, z);
  input a, b;
  output z;

  MMI_AND2B u1 (.in0(\a ),.in1(b),.out(\z ));
endmodule
