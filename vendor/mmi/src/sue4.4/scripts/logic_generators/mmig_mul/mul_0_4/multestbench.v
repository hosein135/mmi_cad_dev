// This module tests the multiplier for correctness.  It can be used to test
// ONLY the following configurations:
// NBITS_A = 4
// NBITS_B = 4
// UseMulCin = Y,N
// AddExtraCSA = N
// IncludePPG = Y
// A = Both
// B = Both
// IncludeCPA = Y
// HalfHeight = Y,N
// bitslice = Y,N

module multestbench;

  reg [3:0]  A_H;
  reg [3:0]  B_H;
  reg        ASigned;
  reg        BSigned;
  reg        ACin_H;

  wire       ACout_H;
  wire [7:0] RES_H;

  // signed values
  integer    ai;
  integer    bi;
  integer    resulti;

  integer    err;

  // unsigned values
  reg [4:0]        ar;
  reg [4:0]       br;
  reg [8:0]       resultr;

  mmm mmm(
      .ACin_H(ACin_H),
      .ACout_H(ACout_H),
      .A_H(A_H[3:0]),
      .B_H(B_H[3:0]),
      .ASigned_H(ASigned),
      .BSigned_H(BSigned),
      .RES_H(RES_H[7:0])
  );

  initial
    begin
      // not being used here
      force mmm.ACin_H = 0;
      
      // test unsigned * unsigned
      $display("Testing unsigned * unsigned...");
      assign err = 0;
      force mmm.ASigned_H = 0;
      force mmm.BSigned_H = 0;

      for (ar = 0; ar < 16; ar = ar + 1)
        begin
	  force mmm.A_H = ar[3:0];
          for (br = 0; br < 16; br = br + 1)
            begin
              force mmm.B_H = br[3:0];
              #10;
              assign resultr = ar * br;
              if (resultr !== mmm.RES_H)
                begin
                  $display("A=%d, B=%d, result=%d, resultr=%d ***ERROR", ar, br, mmm.RES_H, resultr);	
                  assign err = 1;
                end
              else
                begin
//                $display("A=%d, B=%d, result=%d, resultr=%d OK", ar, br, mmm.RES_H, resultr);	
                end
              release mmm.B_H;
            end
          release mmm.A_H;
        end

      release mmm.ASigned_H;
      release mmm.BSigned_H;
      if (err == 0)
        $display("...OK");


      // test signed * signed
      $display("Testing signed * signed...");
      assign err = 0;
      force mmm.ASigned_H = 1;
      force mmm.BSigned_H = 1;

      for (ai = -8; ai < 8; ai = ai + 1)
        begin
	  force mmm.A_H = ai[3:0];
          for (bi = -8; bi < 8; bi = bi + 1)
            begin
              force mmm.B_H = bi[3:0];
              #10;
              assign resulti = ai * bi;
              if (resulti[7:0]!== mmm.RES_H)
                begin
                  $display("A=%d, B=%d, result=%d, resulti=%d ***ERROR", ai, bi, mmm.RES_H, resulti);	
                  assign err = 1;
                end
              else
                begin
//                  $display("A=%d, B=%d, result=%d, resulti=%d OK", ai, bi, mmm.RES_H, resulti);	
                end
              release mmm.B_H;
            end
          release mmm.A_H;
        end

      release mmm.ASigned_H;
      release mmm.BSigned_H;
      if (err == 0)
        $display("...OK");


      // test unsigned * signed
      $display("Testing unsigned * signed...");
      assign err = 0;
      force mmm.ASigned_H = 0;
      force mmm.BSigned_H = 1;

      for (ai = 0; ai < 16; ai = ai + 1)
        begin
	  force mmm.A_H = ai[3:0];
          for (bi = -8; bi < 8; bi = bi + 1)
            begin
              force mmm.B_H = bi[3:0];
              #10;
              assign resulti = ai * bi;
              if (resulti[7:0]!== mmm.RES_H)
                begin
                  $display("A=%d, B=%d, result=%d, resulti=%d ***ERROR", ai, bi, mmm.RES_H, resulti);	
                  assign err = 1;
                end
              else
                begin
//                  $display("A=%d, B=%d, result=%d, resulti=%d OK", ai, bi, mmm.RES_H, resulti);	
                end
              release mmm.B_H;
            end
          release mmm.A_H;
        end

      release mmm.ASigned_H;
      release mmm.BSigned_H;
      if (err == 0)
        $display("...OK");


      // test signed * unsigned
      $display("Testing signed * unsigned...");
      assign err = 0;
      force mmm.ASigned_H = 1;
      force mmm.BSigned_H = 0;

      for (ai = -8; ai < 8; ai = ai + 1)
        begin
	  force mmm.A_H = ai[3:0];
          for (bi = 0; bi < 16; bi = bi + 1)
            begin
              force mmm.B_H = bi[3:0];
              #10;
              assign resulti = ai * bi;
              if (resulti[7:0]!== mmm.RES_H)
                begin
                  $display("A=%d, B=%d, result=%d, resulti=%d ***ERROR", ai, bi, mmm.RES_H, resulti);	
                  assign err = 1;
                end
              else
                begin
//                  $display("A=%d, B=%d, result=%d, resulti=%d OK", ai, bi, mmm.RES_H, resulti);	
                end
              release mmm.B_H;
            end
          release mmm.A_H;
        end

      release mmm.ASigned_H;
      release mmm.BSigned_H;
      if (err == 0)
        $display("...OK");

    end
endmodule