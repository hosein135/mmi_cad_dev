module m (a, b, y, z);
  input a, b;
  output y, z;

  function nand2b;
    // synopsys map_to_module MMI_NAND2B
    // synopsys return_port_name out
    input in1;
    input in0;
    
    nand2b = ~(in0 & in1);
  endfunction

  assign z = nand2b (b, a);

endmodule
