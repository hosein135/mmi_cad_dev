module gray2bin_width4_2 ( bin, gray );
output [3:0] bin;
input  [3:0] gray;
    wire \gray[3] , n19;
    assign bin[3] = \gray[3] ;
    assign \gray[3]  = gray[3];
    XNOR2_H U7 ( .Z(bin[1]), .A(n19), .B(gray[1]) );
    XOR2_E U8 ( .Z(bin[0]), .A(gray[0]), .B(bin[1]) );
    XNOR2_H U9 ( .Z(n19), .A(\gray[3] ), .B(gray[2]) );
    INVERT_H U10 ( .Z(bin[2]), .A(n19) );
endmodule
