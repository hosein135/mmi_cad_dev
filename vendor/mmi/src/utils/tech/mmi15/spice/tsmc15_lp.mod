*  **********************************************
*  *             TSMC SPICE MODEL               *
*  **********************************************
*  
*    PROCESS :  TSMC 0.15um LOGIC 1P7M SALICIDE 1.5V/3.3V  LOW POWER
*    DOC. NO.:  T-015-LO-SP-008
*    VERSION :  1.0 
*    DATE    :  June 15, 2000
*    HSPICE VERSION : For H98.2, H98.4
*
******************************************************************************
*       IN THIS MODEL LIB CONTAINS :                                         *  
*                                                                            *
*       1.LIB TT                                                             *
*             SS                                                             *
*             FF                                                             *
*             SF                                                             *
*             FS                                                             *
*        ( 1.5V Normal devices with different geometric and corner models)   *
*                                                                            *
*       2.LIB TT_3V                                                          *
*             SS_3V                                                          *
*             FF_3V                                                          *
*             SF_3V                                                          *
*             FS_3V                                                          *
*        ( 3.3V normal devices & 3.3V NMOS with ESD implant with different   *
*          geometric and corner models)                                      *
*                                                                            *
*       3.LIB BIP                                                            *
*        ( P+/NW/PSUB 10x10,5x5 and 2x2 vertical PNP bipolar )               *
*                                                                            *
*       4.LIB BIP3                                                           *
*        ( P+/NW/PSUB 10x10,5x5 and 2x2 vertical PNP bipolar )               *
*                                                                            *
*       5.LIB DIO                                                            *
*        ( P+/NW ,N+/PW & NW/PSUB diode )                                    *
*                                                                            *
*       6.LIB DIO3                                                           *
*        ( P+/NW ,N+/PW diode )                                              *
*                                                                            *
*       7.LIB RES                                                            *
*        ( POLY,METAL,CONTACT resistance )                                   *
*                                                                            *
******************************************************************************
******************************************************************************
*                                                                            *
* 1)To use these models directly by programming in this style:               *
*                                                                            *
*     .lib 'lib_path/lib_name' model_name                                    *
*                                                                            *
*                                                                            *
*    EX: .lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15_lp.mod' TT                            *
*        for typical 1.5V N,PMOS                                             *
*        .lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15_lp.mod' TT_3V                         *
*        for typical 3.3V N,PMOS                                             *
*  note:                                                                     *
*      corner_name                                                           *
*       TT : typical model for 1.5V devices                                  *
*       SS : Slow NMOS Slow PMOS model for 1.5V devices                      *
*       FF : Fast NMOS Fast PMOS model for 1.5V devices                      *
*       SF : Slow NMOS Fast PMOS model for 1.5V devices                      *
*       FS : Fast NMOS Slow PMOS model for 1.5V devices                      *
*                                                                            *
*       TT_3V : typical model for 3.3V devices                               *
*       SS_3V : Slow NMOS Slow PMOS model for 3.3V devices                   *
*       FF_3V : Fast NMOS Fast PMOS model for 3.3V devices                   *
*       SF_3V : Slow NMOS Fast PMOS model for 3.3V devices                   *
*       FS_3V : Fast NMOS Slow PMOS model for 3.3V devices                   *
*                                                                            *
* 2)HDIF is the half of distance from spacer edge to OD edge.                *
*   The value listed here is TSMC minimum-rule value. you can change it      *
*   according to your layout by change the parameters .                      *
*                                                                            *
*                                                                            *
******************************************************************************
***************************************************************
*                                                             *
*                    1.5V DEVICES LIB                         *
*                                                             *
***************************************************************
***************** CORNER_LIB OF TYPICAL MODEL ****************************
.LIB TT
.param toxn = 3.49e-09 toxp = 3.68e-09
+dxl = 0 dxw = 0
+dvthn = 0 dvthp = 0
+cjn = 0.00120389 cjp = 0.00110416
+cjswn = 2.08947e-10 cjswp = 1.84991e-10
+cjgaten = 4.08535e-10 cjgatep = 7.08617e-10
+cgon = 3.7e-10 cgop = 2.5e-10
+hdifn = 1.7e-07 hdifp = 1.7e-07
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15_lp.mod' MOS
.ENDL TT
***************** CORNER_LIB OF SNSP MODEL ****************************
.LIB SS
.param toxn = 3.5833e-09 toxp = 3.7733e-09
+dxl = 8.667e-09 dxw = -1.2e-08
+dvthn = 0.06 dvthp = -0.05
+cjn = 0.00126409 cjp = 0.00115936
+cjswn = 2.19395e-10 cjswp = 1.94241e-10
+cjgaten = 4.28962e-10 cjgatep = 7.44048e-10
+cgon = 3.515e-10 cgop = 2.375e-10
+hdifn = 1.7e-07 hdifp = 1.7e-07
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15_lp.mod' MOS
.ENDL SS
***************** CORNER_LIB OF FNFP MODEL ****************************
.LIB FF
.param toxn = 3.3967e-09 toxp = 3.5867e-09
+dxl = -8.667e-09 dxw = 1.2e-08
+dvthn = -0.06 dvthp = 0.05
+cjn = 0.0011437 cjp = 0.00104895
+cjswn = 1.985e-10 cjswp = 1.75741e-10
+cjgaten = 3.88109e-10 cjgatep = 6.73186e-10
+cgon = 3.885e-10 cgop = 2.625e-10
+hdifn = 1.7e-07 hdifp = 1.7e-07
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15_lp.mod' MOS
.ENDL FF
***************** CORNER_LIB OF SNFP MODEL ****************************
.LIB SF
.param toxn = 3.49e-09 toxp = 3.68e-09
+dxl = 0 dxw = 0
+dvthn = 0.06 dvthp = 0.05
+cjn = 0.00126409 cjp = 0.00104895
+cjswn = 2.19395e-10 cjswp = 1.75741e-10
+cjgaten = 4.28962e-10 cjgatep = 6.73186e-10
+cgon = 3.7e-10 cgop = 2.5e-10
+hdifn = 1.7e-07 hdifp = 1.7e-07
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15_lp.mod' MOS
.ENDL SF
***************** CORNER_LIB OF FNSP MODEL ****************************
.LIB FS
.param toxn = 3.49e-09 toxp = 3.68e-09
+dxl = 0 dxw = 0
+dvthn = -0.06 dvthp = -0.05
+cjn = 0.0011437 cjp = 0.00115936
+cjswn = 1.985e-10 cjswp = 1.94241e-10
+cjgaten = 3.88109e-10 cjgatep = 7.44048e-10
+cgon = 3.7e-10 cgop = 2.5e-10
+hdifn = 1.7e-07 hdifp = 1.7e-07
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15_lp.mod' MOS
.ENDL FS
***********************************************************************
***************************************************************
*                                                             *
*                3.3V NORMAL DEVICES LIB                      *
*                                                             *
***************************************************************
**************** CORNER_LIB OF TYPICAL MODEL ****************************
.LIB TT_3V
.param toxn3 = 7.19E-09  toxp3 = 7.06E-09  toxe3= 7.19e-9
+dxl3 = 0 dxw3 = 0
+dvthn3 = 0              dvthp3 = 0    dvthe3 = 0.0
+cjn3 = 8.91153E-4       cjp3 = 0.00123885    cje3 = 1E-3      
+cjswn3 = 1.48665E-10    cjswp3 = 1.78516E-10  cjswe3 = 2.048062E-10  
+cjgaten3 = 1.70610E-10  cjgatep3 = 2.619152E-10  cjgatee3 = 2.712155E-10
+cgon3 = 2.66716E-10     cgop3 = 2.4926E-10   cgoe3= 4.15E-10  
+hdifn3 = 2E-07          hdifp3 = 2E-07    hdife3 = 7.7e-07
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15_lp.mod' MOS_3V
.ENDL TT_3V
**************** CORNER_LIB OF SNSP MODEL ****************************
.LIB SS_3V
.param toxn3 = 7.66E-09  toxp3 = 7.53E-09  toxe3= 7.66e-09
+dxl3 = 1.0E-08 dxw3 = -1.47E-08 
+dvthn3 = 0.10           dvthp3 = -0.10  dvthe3= 0.1   
+cjn3 = 9.35711E-04      cjp3 = 1.30079E-03   cje3 = 1.05E-3  
+cjswn3 = 1.56098E-10    cjswp3 = 1.87442E-10  cjswe3 = 2.15047E-10   
+cjgaten3 = 1.79141E-10  cjgatep3 = 2.75011E-10  cjgatee3 = 2.84776E-10  
+cgon3 = 2.53380E-10     cgop3 = 2.36797E-10    cgoe3= 3.9425E-10
+hdifn3 = 2E-07          hdifp3 = 2E-07     hdife3 = 7.7e-07
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15_lp.mod' MOS_3V
.ENDL SS_3V
**************** CORNER_LIB OF FNFP MODEL ****************************
.LIB FF_3V
.param toxn3 = 6.72E-09 toxp3 = 6.59E-09  toxe3= 6.72e-09 
+dxl3 = -1.0E-08 dxw3 = 1.47E-08
+dvthn3 = -0.10          dvthp3 = 0.10    dvthe3= -0.1
+cjn3 = 8.46595E-04      cjp3 = 1.17691E-03   cje3 = 0.95E-3
+cjswn3 = 1.41232E-10    cjswp3 = 1.69590E-10  cjswe3 = 1.9456E-10   
+cjgaten3 = 1.62080E-10  cjgatep3 = 2.48819E-10    cjgatee3 = 2.5765E-10 
+cgon3 = 2.80052E-10     cgop3 = 2.61723E-10    cgoe3= 4.3575E-10 
+hdifn3 = 2E-07          hdifp3 = 2E-07   hdife3 = 7.7e-07
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15_lp.mod' MOS_3V
.ENDL FF_3V
**************** CORNER_LIB OF SNFP MODEL ****************************
.LIB SF_3V
.param toxn3 = 7.19E-09  toxp3 = 7.06E-09   toxe3= 7.19e-09
+dxl3 = 0 dxw3 = 0
+dvthn3 = 0.10           dvthp3 = 0.10    dvthe3= 0.1
+cjn3 = 9.35711E-04      cjp3 = 1.17691E-03    cje3 = 1.05E-3 
+cjswn3 = 1.56098E-10    cjswp3 = 1.69590E-10  cjswe3 = 2.15047E-10
+cjgaten3 = 1.79141E-10  cjgatep3 = 2.48819E-10   cjgatee3 = 2.84776E-10 
+cgon3 = 2.66716E-10     cgop3 = 2.49260E-10    cgoe3= 4.15E-10 
+hdifn3 = 2E-07          hdifp3 = 2E-07   hdife3 = 7.7e-07
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15_lp.mod' MOS_3V
.ENDL SF_3V
**************** CORNER_LIB OF FNSP MODEL ****************************
.LIB FS_3V
.param toxn3 = 7.19E-09  toxp3 = 7.06E-09   toxe3= 7.19e-09
+dxl3 = 0 dxw3 = 0
+dvthn3 = -0.10          dvthp3 = -0.10    dvthe3= -0.1
+cjn3 = 8.46595E-04      cjp3 = 1.30079E-03    cje3 = 0.95E-3
+cjswn3 = 1.41232E-10    cjswp3 = 1.87442E-10   cjswe3 = 1.9456E-10
+cjgaten3 = 1.62080E-10  cjgatep3 = 2.75011E-10  cjgatee3 = 2.5765E-10
+cgon3 = 2.66716E-10     cgop3 = 2.49260E-10   cgoe3= 4.15E-10
+hdifn3 = 2E-07          hdifp3 = 2E-07  hdife3 = 7.7e-07
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15_lp.mod' MOS_3V
.ENDL FS_3V
*
***************************************************************
*                                                             *
*               1.5V NMOS DEVICES MODEL                       *
*                                                             *
***************************************************************
.LIB MOS
.MODEL  n.1 NMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '1.2E-06-dxl'  LMAX     = 2.1E-05        
+WMIN     = '1.008E-05-dxw'  WMAX     = 0.000201     XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxn           
+XJ       = 1.5E-07        NCH      = 1.7E+17        LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 1.5E-09        WINT     = 1.42E-08       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '0.5446514+dvthn' LVTH0 = 6.00491E-08    WVTH0    = -6.704496E-08  
+K1       = 0.783283       K2       = -0.0918207     K3       = 0              
+DVT0     = 0              DVT1     = 0              DVT2     = 0              
+DVT0W    = 0              DVT1W    = 0              DVT2W    = 0              
+NLX      = 0              W0       = 0              K3B      = 0              
+VSAT     = 101485         UA       = 2.17E-12       UB       = 2.141356E-18   
+LUB      = -1.57195E-25   UC       = 1.382363E-10   LUC      = -1.22451E-16   
+RDSW     = 94             PRWB     = 0              PRWG     = 0              
+WR       = 1              U0       = 0.0486392      LU0      = 8.080605E-11   
+WU0      = -2.271522E-09  PU0      = 2.266297E-14   A0       = 0.5014815      
+LA0      = 4.285635E-08   KETA     = 0.027408       LKETA    = -4.102552E-08  
+A1       = 0              A2       = 0.99           AGS      = 0              
+B0       = 0              B1       = 0              VOFF     = -0.1537264     
+LVOFF    = 1.208664E-08   WVOFF    = 2.412205E-08   PVOFF    = -2.40666E-13   
+NFACTOR  = 2.8696358      CIT      = -0.0001585095  CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = 0.000110904    
+ETAB     = -3.44E-06      DSUB     = 0              PCLM     = 0.2791423      
+LPCLM    = 2.161887E-07   PDIBLC1  = 0              PDIBLC2  = 0.000920619    
+LPDIBLC2 = 4.183166E-09   PDIBLCB  = 0.2775065      DROUT    = 0              
+PSCBE1   = 6.665679E+08   PSCBE2   = 1E-20          PVAG     = 0              
+DELTA    = 0.01           ALPHA0   = 2.71E-09       BETA0    = 7.222          
+KT1      = -0.236825      KT2      = -0.0229        AT       = 26400          
+UTE      = -1.969619      UA1      = 6.495E-10      UB1      = -1.96528E-18   
+LUB1     = 2.84735E-25    WUB1     = 2.868641E-25   PUB1     = -2.86204E-30   
+UC1      = -1.19327E-10   LUC1     = 6.684032E-17   WUC1     = 6.734014E-17   
+PUC1     = -6.71852E-22   KT1L     = 0              PRT      = 0              
+HDIF     = hdifn          LDIF     = 6.5E-08        RSH      = 6              
+RS       = 0              RD       = 0              RSC      = 0              
+RDC      = 0              CJ       = cjn            MJ       = 0.440821       
+PB       = 0.7802155      CJSW     = cjswn          MJSW     = 0.4439558      
+PBSW     = 0.7802155      CJSWG    = cjgaten        MJSWG    = 0.4439558      
+PBSWG    = 0.7802155      CTA      = 0.00101709     CTP      = 0.0007730462   
+PTA      = 0.001464986    PTP      = 0.001464986    CGDO     = cgon           
+CGSO     = cgon           ACM      = 12             CAPMOD   = 0              
+NQSMOD   = 0              XTI      = 3              N        = 1              
+XPART    = 1              CF       = 0              TLEV     = 1              
+TLEVC    = 1              JS       = 7.15E-06       JSW      = 3E-11          
+DLC      = 1.85E-08       AF       = 0.973          KF       = 4.478E-24   )
*
.MODEL  n.2 NMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '5E-07-dxl'    LMAX     = '1.2E-06-dxl'   
+WMIN     = '1.008E-05-dxw' WMAX     = 0.000201      XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxn           
+XJ       = 1.5E-07        NCH      = 1.7E+17        LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 1.5E-09        WINT     = 1.42E-08       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '0.5745255+dvthn' LVTH0 = 2.488722E-08   WVTH0    = -1.127326E-07  
+PVTH0    = 5.377344E-14   K1       = 0.783283       K2       = -0.0918207     
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 93913.45       LVSAT    = 0.008911712    
+WVSAT    = 0.0761062      PVSAT    = -8.957695E-08  UA       = 2.17E-12       
+UB       = 1.877353E-18   LUB      = 1.535364E-25   WUB      = 1.311204E-24   
+PUB      = -1.54329E-30   UC       = 1.864571E-11   LUC      = 1.83074E-17    
+RDSW     = 94             PRWB     = 0              PRWG     = 0              
+WR       = 1              U0       = 0.0494654      LU0      = -8.9162E-10    
+WU0      = 9.368895E-09   PU0      = 8.962204E-15   A0       = 0.4120838      
+LA0      = 1.480774E-07   WA0      = -5.502262E-07  PA0      = 6.476161E-13   
+KETA     = -0.004542385   LKETA    = -3.419907E-09  A1       = 0              
+A2       = 0.99           AGS      = 0              B0       = 0              
+B1       = 0              VOFF     = -0.1495707     LVOFF    = 7.195356E-09   
+WVOFF    = -1.189032E-07  PVOFF    = -7.23248E-14   NFACTOR  = 2.8696358      
+CIT      = -0.0001585095  CDSC     = 0              CDSCB    = 0              
+CDSCD    = 0              ETA0     = 0.000110904    ETAB     = -3.44E-06      
+DSUB     = 0              PCLM     = 0.2526128      LPCLM    = 2.474138E-07   
+PDIBLC1  = 0              PDIBLC2  = 0.004474711    PDIBLCB  = 0.2775065      
+DROUT    = 0              PSCBE1   = 6.665679E+08   PSCBE2   = 1E-20          
+PVAG     = 0              DELTA    = 0.01           ALPHA0   = 2.71E-09       
+BETA0    = 7.222          KT1      = -0.236825      KT2      = -0.0229        
+AT       = 26400          UTE      = -1.969619      UA1      = 6.495E-10      
+UB1      = -1.28202E-18   LUB1     = -5.19456E-25   WUB1     = -6.58094E-24   
+PUB1     = 5.221365E-30   UC1      = -2.84055E-11   LUC1     = -4.01737E-17   
+WUC1     = -8.46561E-16   PUC1     = 4.038097E-22   KT1L     = 0              
+PRT      = 0              HDIF     = hdifn          LDIF     = 6.5E-08        
+RSH      = 6              RS       = 0              RD       = 0              
+RSC      = 0              RDC      = 0              CJ       = cjn            
+MJ       = 0.440821       PB       = 0.7802155      CJSW     = cjswn          
+MJSW     = 0.4439558      PBSW     = 0.7802155      CJSWG    = cjgaten        
+MJSWG    = 0.4439558      PBSWG    = 0.7802155      CTA      = 0.00101709     
+CTP      = 0.0007730462   PTA      = 0.001464986    PTP      = 0.001464986    
+CGDO     = cgon           CGSO     = cgon           ACM      = 12             
+CAPMOD   = 0              NQSMOD   = 0              XTI      = 3              
+N        = 1              XPART    = 1              CF       = 0              
+TLEV     = 1              TLEVC    = 1              JS       = 7.15E-06       
+JSW      = 3E-11          AF       = 0.973          KF       = 4.478E-24
+DLC      = 1.85E-08       )
*
.MODEL  n.3 NMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = 1.5E-07        LMAX     = '5E-07-dxl'     
+WMIN     = '1.008E-05-dxw' WMAX     = 0.000201      XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxn           
+XJ       = 1.5E-07        NCH      = 1.7E+17        LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 1.5E-09        WINT     = 1.42E-08       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '0.6260629+dvthn' LVTH0 = 3.038894E-10   WVTH0    = -6.92983E-08   
+PVTH0    = 3.305529E-14   K1       = 0.7832754      WK1      = 7.648625E-11   
+PK1      = -3.64839E-17   K2       = -0.0918207     K3       = 0              
+DVT0     = 0              DVT1     = 0              DVT2     = 0              
+DVT0W    = 0              DVT1W    = 0              DVT2W    = 0              
+NLX      = 0              W0       = 0              K3B      = 0              
+VSAT     = 116877.9       LVSAT    = -0.002042334   WVSAT    = -0.137122      
+PVSAT    = 1.213286E-08   UA       = 2.17E-12       UB       = 2.292012E-18   
+LUB      = -4.42562E-26   WUB      = -1.5653E-24    PUB      = -1.71194E-31   
+UC       = 4.728253E-12   LUC      = 2.494602E-17   WUC      = 7.321206E-17   
+PUC      = -3.49221E-23   RDSW     = 94             PRWB     = 0              
+PRWG     = 0              WR       = 1              U0       = 0.0477597      
+LU0      = -7.7976E-11    WU0      = 1.714879E-08   PU0      = 5.251194E-15   
+A0       = 0.3226632      LA0      = 1.90731E-07    WA0      = 1.731905E-06   
+PA0      = -4.4096E-13    KETA     = -0.0394688     LKETA    = 1.324E-08      
+WKETA    = 3.924695E-08   PKETA    = -1.87208E-14   A1       = 0              
+A2       = 0.99           AGS      = 0              B0       = 0              
+B1       = 0              VOFF     = -0.1303463     LVOFF    = -1.974705E-09  
+WVOFF    = -3.340663E-07  PVOFF    = 3.030799E-14   NFACTOR  = 2.8696358      
+CIT      = -0.0001585095  CDSC     = 0              CDSCB    = 0              
+CDSCD    = 0              ETA0     = -0.000566342   LETA0    = 3.230464E-10   
+WETA0    = -1.05036E-08   PETA0    = 5.01022E-15    ETAB     = 0.001419926    
+LETAB    = -6.78946E-10   WETAB    = 9.962563E-09   PETAB    = -4.75214E-15   
+DSUB     = 0              PCLM     = 0.608917       LPCLM    = 7.74567E-08    
+WPCLM    = 2.295695E-07   PPCLM    = -1.09505E-13   PDIBLC1  = 0              
+PDIBLC2  = 0.001874547    LPDIBLC2 = 1.240278E-09   WPDIBLC2 = -1.910629E-08  
+PPDIBLC2 = 9.113704E-15   PDIBLCB  = 0.2775065      DROUT    = 0              
+PSCBE1   = 6.663743E+08   LPSCBE1  = 0.0923324      WPSCBE1  = 1.9456773      
+PPSCBE1  = -9.28088E-07   PSCBE2   = 1E-20          PVAG     = 0              
+DELTA    = 0.01           ALPHA0   = 2.71E-09       BETA0    = 7.222          
+KT1      = -0.2414111     LKT1     = 2.187551E-09   WKT1     = 6.307816E-09   
+PKT1     = -3.00883E-15   KT2      = -0.0229        AT       = 26400          
+UTE      = -1.9694633     LUTE     = -7.42766E-11   WUTE     = -2.19959E-10   
+PUTE     = 1.049204E-16   UA1      = 6.49276E-10    LUA1     = 1.068321E-19   
+WUA1     = 2.251224E-18   PUA1     = -1.07383E-24   UB1      = -2.20133E-18   
+LUB1     = -8.09482E-26   WUB1     = 5.63281E-24    PUB1     = -6.04595E-31   
+UC1      = -1.1246E-10    LUC1     = -7.96764E-20   WUC1     = -1.67898E-18   
+PUC1     = 8.008748E-25   KT1L     = 0              PRT      = 0              
+HDIF     = hdifn          LDIF     = 6.5E-08        RSH      = 6              
+RS       = 0              RD       = 0              RSC      = 0              
+RDC      = 0              CJ       = cjn            MJ       = 0.440821       
+PB       = 0.7802155      CJSW     = cjswn          MJSW     = 0.4439558      
+PBSW     = 0.7802155      CJSWG    = cjgaten        MJSWG    = 0.4439558      
+PBSWG    = 0.7802155      CTA      = 0.00101709     CTP      = 0.0007730462   
+PTA      = 0.001464986    PTP      = 0.001464986    CGDO     = cgon           
+CGSO     = cgon           ACM      = 12             CAPMOD   = 0              
+NQSMOD   = 0              XTI      = 3              N        = 1              
+XPART    = 1              CF       = 0              TLEV     = 1              
+TLEVC    = 1              JS       = 7.15E-06       JSW      = 3E-11          
+DLC      = 1.85E-08       AF       = 0.973          KF       = 4.478E-24    )
*
.MODEL  n.4 NMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '1.2E-06-dxl'  LMAX     = 2.1E-05        
+WMIN     = '1.28E-06-dxw' WMAX     = '1.008E-05-dxw' XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxn           
+XJ       = 1.5E-07        NCH      = 1.7E+17        LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 1.5E-09        WINT     = 1.42E-08       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '0.5384932+dvthn' LVTH0 = 6.061838E-08   WVTH0    = -5.144836E-09  
+PVTH0    = -5.72305E-15   K1       = 0.7900817      LK1      = 3.804725E-09   
+WK1      = -6.833789E-08  PK1      = -3.82436E-14   K2       = -0.0918207     
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 101485         UA       = 2.17E-12       
+UB       = 2.148765E-18   LUB      = -1.09368E-25   WUB      = -7.44758E-26   
+PUB      = -4.80742E-31   UC       = 1.553794E-10   LUC      = -1.22252E-16   
+WUC      = -1.72315E-16   PUC      = -1.99741E-24   RDSW     = 94             
+PRWB     = 0              PRWG     = 0              WR       = 1              
+U0       = 0.0487096      LU0      = 2.830328E-09   WU0      = -2.978786E-09  
+PU0      = -4.97412E-15   A0       = 0.5014815      LA0      = 4.285634E-08   
+KETA     = 0.0280443      LKETA    = -4.737365E-08  WKETA    = -6.395613E-09  
+PKETA    = 6.380899E-14   A1       = 0              A2       = 0.99           
+AGS      = 0              B0       = 0              B1       = 0              
+VOFF     = -0.1474891     LVOFF    = -1.096948E-08  WVOFF    = -3.857378E-08  
+PVOFF    = -8.9147E-15    NFACTOR  = 2.8696358      CIT      = -0.0001585095  
+CDSC     = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0     = 0.000110904    ETAB     = -3.44E-06      DSUB     = 0              
+PCLM     = 0.2791423      LPCLM    = 2.161886E-07   PDIBLC1  = 0              
+PDIBLC2  = 0.0009291279   LPDIBLC2 = 4.098275E-09   WPDIBLC2 = -8.55267E-11   
+PPDIBLC2 = 8.532968E-16   PDIBLCB  = 0.2775065      DROUT    = 0              
+PSCBE1   = 6.665679E+08   PSCBE2   = 1E-20          PVAG     = 0              
+DELTA    = 0.01           ALPHA0   = 2.71E-09       BETA0    = 7.222          
+KT1      = -0.236825      KT2      = -0.0229        AT       = 26400          
+UTE      = -1.969619      UA1      = 6.495E-10      UB1      = -1.93309E-18   
+LUB1     = -3.64285E-26   WUB1     = -3.67009E-26   PUB1     = 3.661654E-31   
+UC1      = -1.10914E-10   LUC1     = -1.70949E-17   WUC1     = -1.72227E-17   
+PUC1     = 1.718312E-22   KT1L     = 0              PRT      = 0              
+HDIF     = hdifn          LDIF     = 6.5E-08        RSH      = 6              
+RS       = 0              RD       = 0              RSC      = 0              
+RDC      = 0              CJ       = cjn            MJ       = 0.440821       
+PB       = 0.7802155      CJSW     = cjswn          MJSW     = 0.4439558      
+PBSW     = 0.7802155      CJSWG    = cjgaten        MJSWG    = 0.4439558      
+PBSWG    = 0.7802155      CTA      = 0.00101709     CTP      = 0.0007730462   
+PTA      = 0.001464986    PTP      = 0.001464986    CGDO     = cgon           
+CGSO     = cgon           ACM      = 12             CAPMOD   = 0              
+NQSMOD   = 0              XTI      = 3              N        = 1              
+XPART    = 1              CF       = 0              TLEV     = 1              
+TLEVC    = 1              JS       = 7.15E-06       JSW      = 3E-11          
+DLC      = 1.85E-08       AF       = 0.973          KF       = 4.478E-24    )
*
.MODEL  n.5 NMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '5E-07-dxl'    LMAX     = '1.2E-06-dxl'   
+WMIN     = '1.28E-06-dxw' WMAX     = '1.008E-05-dxw' XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxn           
+XJ       = 1.5E-07        NCH      = 1.7E+17        LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 1.5E-09        WINT     = 1.42E-08       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '0.5633656+dvthn' LVTH0 = 3.134346E-08   WVTH0    = -5.57709E-10   
+PVTH0    = -1.11221E-14   K1       = 0.7951699      LK1      = -2.184121E-09  
+WK1      = -1.194828E-07  PK1      = 2.195394E-14   K2       = -0.0918207     
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 101485         UA       = 2.202952E-12   
+LUA      = -3.87845E-20   WUA      = -3.3122E-19    PUA      = 3.898466E-25   
+UB       = 2.051299E-18   LUB      = 5.349968E-27   WUB      = -4.37234E-25   
+PUB      = -5.37758E-32   UC       = 3.562607E-11   LUC      = 1.869763E-17   
+WUC      = -1.7068E-16    PUC      = -3.92252E-24   RDSW     = 94             
+PRWB     = 0              PRWG     = 0              WR       = 1              
+U0       = 0.0511143      WU0      = -7.204888E-09  A0       = 0.3573437      
+LA0      = 2.125065E-07   KETA     = -0.009375198   LKETA    = -3.330931E-09  
+WKETA    = 4.85775E-08    PKETA    = -8.94349E-16   A1       = 0              
+A2       = 0.99           AGS      = 0              B0       = 0              
+B1       = 0              VOFF     = -0.157591      LVOFF    = 9.205607E-10   
+WVOFF    = -3.828625E-08  PVOFF    = -9.25311E-15   NFACTOR  = 2.8696358      
+CIT      = -0.0001585095  CDSC     = 0              CDSCB    = 0              
+CDSCD    = 0              ETA0     = 0.000110904    ETAB     = -3.44E-06      
+DSUB     = 0              PCLM     = 0.2526129      LPCLM    = 2.474138E-07   
+PDIBLC1  = 0              PDIBLC2  = 0.0045194      LPDIBLC2 = -1.27475E-10   
+WPDIBLC2 = -4.49194E-10   PPDIBLC2 = 1.281334E-15   PDIBLCB  = 0.2775065      
+DROUT    = 0              PSCBE1   = 6.665679E+08   PSCBE2   = 1E-20          
+PVAG     = 0              DELTA    = 0.01           ALPHA0   = 2.71E-09       
+BETA0    = 7.222          KT1      = -0.236825      KT2      = -0.0229        
+AT       = 26400          UTE      = -1.969619      UA1      = 6.495E-10      
+UB1      = -1.98264E-18   LUB1     = 2.189499E-26   WUB1     = 4.613834E-25   
+PUB1     = -2.2008E-31    UC1      = -1.34167E-10   LUC1     = 1.027471E-17   
+WUC1     = 2.165144E-16   PUC1     = -1.03277E-22   KT1L     = 0              
+PRT      = 0              HDIF     = hdifn          LDIF     = 6.5E-08        
+RSH      = 6              RS       = 0              RD       = 0              
+RSC      = 0              RDC      = 0              CJ       = cjn            
+MJ       = 0.440821       PB       = 0.7802155      CJSW     = cjswn          
+MJSW     = 0.4439558      PBSW     = 0.7802155      CJSWG    = cjgaten        
+MJSWG    = 0.4439558      PBSWG    = 0.7802155      CTA      = 0.00101709     
+CTP      = 0.0007730462   PTA      = 0.001464986    PTP      = 0.001464986    
+CGDO     = cgon           CGSO     = cgon           ACM      = 12             
+CAPMOD   = 0              NQSMOD   = 0              XTI      = 3              
+N        = 1              XPART    = 1              CF       = 0              
+TLEV     = 1              TLEVC    = 1              JS       = 7.15E-06       
+JSW      = 3E-11          DLC      = 1.85E-08       AF       = 0.973          
+KF       = 4.478E-24     )
*
.MODEL  n.6 NMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = 1.5E-07        LMAX     = '5E-07-dxl'     
+WMIN     = '1.28E-06-dxw' WMAX     = '1.008E-05-dxw' XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxn           
+XJ       = 1.5E-07        NCH      = 1.7E+17        LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 1.5E-09        WINT     = 1.42E-08       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '0.6238367+dvthn' LVTH0 = 2.498743E-09   WVTH0    = -4.692166E-08  
+PVTH0    = 1.099351E-14   K1       = 0.7917383      LK1      = -5.47223E-10   
+WK1      = -8.498915E-08  PK1      = 5.500468E-15   K2       = -0.0918207     
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 103199.5       LVSAT    = -0.0008178038  
+WVSAT    = 0.0003682061   PVSAT    = -1.75634E-10   UA       = 2.102158E-12   
+LUA      = 9.294409E-21   WUA      = 6.819245E-19   PUA      = -9.34237E-26   
+UB       = 2.179516E-18   LUB      = -5.58098E-26   WUB      = -4.34537E-25   
+PUB      = -5.50623E-32   UC       = 2.32823E-11    LUC      = 2.458561E-17   
+WUC      = -1.13286E-16   PUC      = -3.12994E-23   RDSW     = 94             
+PRWB     = 0              PRWG     = 0              WR       = 1              
+U0       = 0.0501868      LU0      = 4.424012E-10   WU0      = -7.248015E-09  
+PU0      = 2.057107E-17   A0       = 0.5033313      LA0      = 1.428704E-07   
+WA0      = -8.409794E-08  PA0      = 4.011472E-14   KETA     = -0.0415838     
+LKETA    = 1.203255E-08   WKETA    = 6.050551E-08   PKETA    = -6.58401E-15   
+A1       = 0              A2       = 0.99           AGS      = 0              
+B0       = 0              B1       = 0              VOFF     = -0.1593097     
+LVOFF    = 1.740343E-09   WVOFF    = -4.29381E-08   PVOFF    = -7.03418E-15   
+NFACTOR  = 2.8696358      CIT      = -0.0001585095  CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = -0.001856882   
+LETA0    = 9.386337E-10   WETA0    = 2.468379E-09   PETA0    = -1.17742E-15   
+ETAB     = 0.002557531    LETAB    = -1.221583E-09  WETAB    = -1.472181E-09  
+PETAB    = 7.022304E-16   DSUB     = 0              PCLM     = 0.6494077      
+LPCLM    = 5.814263E-08   WPCLM    = -1.77427E-07   PPCLM    = 8.463267E-14   
+PDIBLC1  = 0              PDIBLC2  = 5.454963E-05   LPDIBLC2 = 2.002258E-09   
+WPDIBLC2 = -8.12431E-10   PPDIBLC2 = 1.454599E-15   PDIBLCB  = 0.2775065      
+DROUT    = 0              PSCBE1   = 6.665679E+08   PSCBE2   = 1E-20          
+PVAG     = 0              DELTA    = 0.01           ALPHA0   = 2.71E-09       
+BETA0    = 7.222          KT1      = -0.2407007     LKT1     = 1.848713E-09   
+WKT1     = -8.3236E-10    PKT1     = 3.970358E-16   KT2      = -0.0229        
+AT       = 26400          UTE      = -1.969488      LUTE     = -6.2503E-11    
+PUTE     = -1.34234E-17   UA1      = 6.495E-10      UB1      = -1.6233E-18    
+LUB1     = -1.49513E-25   WUB1     = -1.77334E-25   PUB1     = 8.458852E-32   
+UC1      = -1.12627E-10   KT1L     = 0              PRT      = 0              
+HDIF     = hdifn          LDIF     = 6.5E-08        RSH      = 6              
+RS       = 0              RD       = 0              RSC      = 0              
+RDC      = 0              CJ       = cjn            MJ       = 0.440821       
+PB       = 0.7802155      CJSW     = cjswn          MJSW     = 0.4439558      
+PBSW     = 0.7802155      CJSWG    = cjgaten        MJSWG    = 0.4439558      
+PBSWG    = 0.7802155      CTA      = 0.00101709     CTP      = 0.0007730462   
+PTA      = 0.001464986    PTP      = 0.001464986    CGDO     = cgon           
+CGSO     = cgon           ACM      = 12             CAPMOD   = 0              
+NQSMOD   = 0              XTI      = 3              N        = 1              
+XPART    = 1              CF       = 0              TLEV     = 1              
+TLEVC    = 1              JS       = 7.15E-06       JSW      = 3E-11          
+DLC      = 1.85E-08       AF       = 0.973          KF       = 4.478E-24     )
*
.MODEL  n.7 NMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '1.2E-06-dxl'  LMAX     = 2.1E-05        
+WMIN     = '5.8E-07-dxw'  WMAX     = '1.28E-06-dxw' XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxn           
+XJ       = 1.5E-07        NCH      = 1.7E+17        LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 1.5E-09        WINT     = 1.42E-08       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '0.5475126+dvthn' LVTH0 = 6.656104E-08   WVTH0    = -1.643358E-08  
+PVTH0    = -1.31609E-14   K1       = 0.7647846      LK1      = -6.124112E-08  
+WK1      = -3.66761E-08   PK1      = 4.316777E-14   K2       = -0.0918207     
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 101485         UA       = 2.17E-12       
+UB       = 2.139029E-18   LUB      = -3.20178E-25   WUB      = -6.22903E-26   
+PUB      = -2.16892E-31   UC       = 4.083067E-11   LUC      = -1.65983E-16   
+WUC      = -2.89461E-17   PUC      = 5.273574E-23   RDSW     = 94             
+PRWB     = 0              PRWG     = 0              WR       = 1              
+U0       = 0.0472277      LU0      = -2.200992E-09  WU0      = -1.124111E-09  
+PU0      = 1.323078E-15   A0       = 0.4963747      LA0      = 9.380697E-08   
+WA0      = 6.391683E-09   PA0      = -6.37698E-14   KETA     = 0.0134         
+LKETA    = 1.483016E-08   WKETA    = 1.193315E-08   PKETA    = -1.40453E-14   
+A1       = 0              A2       = 0.99           AGS      = 0              
+B0       = 0              B1       = 0              VOFF     = -0.1688635     
+LVOFF    = -6.663266E-08  WVOFF    = -1.18215E-08   PVOFF    = 6.075334E-14   
+NFACTOR  = 2.8696358      CIT      = -0.0001585095  CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = 0.0001206456   
+LETA0    = -1.14658E-11   WETA0    = -1.21926E-11   PETA0    = 1.435065E-17   
+ETAB     = -3.44E-06      DSUB     = 0              PCLM     = 0.2791423      
+LPCLM    = 2.161886E-07   PDIBLC1  = 0              PDIBLC2  = 0.0009079062   
+LPDIBLC2 = 4.310007E-09   WPDIBLC2 = -5.89648E-11   PPDIBLC2 = 5.88292E-16    
+PDIBLCB  = 0.2775065      DROUT    = 0              PSCBE1   = 6.665679E+08   
+PSCBE2   = 1E-20          PVAG     = 0              DELTA    = 0.01           
+ALPHA0   = 2.71E-09       BETA0    = 7.222          KT1      = -0.236825      
+KT2      = -0.0229        AT       = 26400          UTE      = -1.969619      
+UA1      = 6.495E-10      UB1      = -1.96241E-18   LUB1     = 2.561293E-25   
+UC1      = -1.24674E-10   LUC1     = 1.201943E-16   KT1L     = 0              
+PRT      = 0              HDIF     = hdifn          LDIF     = 6.5E-08        
+RSH      = 6              RS       = 0              RD       = 0              
+RSC      = 0              RDC      = 0              CJ       = cjn            
+MJ       = 0.440821       PB       = 0.7802155      CJSW     = cjswn          
+MJSW     = 0.4439558      PBSW     = 0.7802155      CJSWG    = cjgaten        
+MJSWG    = 0.4439558      PBSWG    = 0.7802155      CTA      = 0.00101709     
+CTP      = 0.0007730462   PTA      = 0.001464986    PTP      = 0.001464986    
+CGDO     = cgon           CGSO     = cgon           ACM      = 12             
+CAPMOD   = 0              NQSMOD   = 0              XTI      = 3              
+N        = 1              XPART    = 1              CF       = 0              
+TLEV     = 1              TLEVC    = 1              JS       = 7.15E-06       
+JSW      = 3E-11          DLC      = 1.85E-08       AF       = 0.973     
+KF       = 4.478E-24    )
*
.MODEL  n.8 NMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '5E-07-dxl'    LMAX     = '1.2E-06-dxl'   
+WMIN     = '5.8E-07-dxw'  WMAX     = '1.28E-06-dxw' XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxn           
+XJ       = 1.5E-07        NCH      = 1.7E+17        LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 1.5E-09        WINT     = 1.42E-08       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '0.5903537+dvthn' LVTH0 = 1.613708E-08   WVTH0    = -3.433595E-08  
+PVTH0    = 7.910213E-15   K1       = 0.6997059      LK1      = 1.535657E-08   
+K2       = -0.0918207     K3       = 0              DVT0     = 0              
+DVT1     = 0              DVT2     = 0              DVT0W    = 0              
+DVT1W    = 0              DVT2W    = 0              NLX      = 0              
+W0       = 0              K3B      = 0              VSAT     = 101485         
+UA       = 1.938314E-12   LUA      = 2.726941E-19   UB       = 1.762248E-18   
+LUB      = 1.232938E-25   WUB      = -7.54571E-26   PUB      = -2.01394E-31   
+UC       = -1.22049E-10   LUC      = 2.572633E-17   WUC      = 2.666591E-17   
+PUC      = -1.27196E-23   RDSW     = 94             PRWB     = 0              
+PRWG     = 0              WR       = 1              U0       = 0.0453578      
+A0       = 0.3827418      LA0      = 2.275528E-07   WA0      = -3.178835E-08  
+PA0      = -1.88319E-14   KETA     = 0.0181909      LKETA    = 9.191294E-09   
+WKETA    = 1.407576E-08   PKETA    = -1.65672E-14   A1       = 0              
+A2       = 0.99           AGS      = 0              B0       = 0              
+B1       = 0              VOFF     = -0.22691       LVOFF    = 1.688031E-09   
+WVOFF    = 4.847335E-08   PVOFF    = -1.02137E-14   NFACTOR  = 2.8696358      
+CIT      = -0.0001585095  CDSC     = 0              CDSCB    = 0              
+CDSCD    = 0              ETA0     = 0.000110904    ETAB     = -3.44E-06      
+DSUB     = 0              PCLM     = 0.2526129      LPCLM    = 2.474138E-07   
+PDIBLC1  = 0              PDIBLC2  = 0.003832271    LPDIBLC2 = 8.680301E-10   
+WPDIBLC2 = 4.108169E-10   PPDIBLC2 = 3.535886E-17   PDIBLCB  = 0.2775065      
+DROUT    = 0              PSCBE1   = 6.665679E+08   PSCBE2   = 1E-20          
+PVAG     = 0              DELTA    = 0.01           ALPHA0   = 2.71E-09       
+BETA0    = 7.222          KT1      = -0.236825      KT2      = -0.0229        
+AT       = 26400          UTE      = -1.969619      UA1      = 6.495E-10      
+UB1      = -1.61401E-18   LUB1     = -1.53944E-25   UC1      = 3.882271E-11   
+LUC1     = -7.22416E-17   KT1L     = 0              PRT      = 0              
+HDIF     = hdifn          LDIF     = 6.5E-08        RSH      = 6              
+RS       = 0              RD       = 0              RSC      = 0              
+RDC      = 0              CJ       = cjn            MJ       = 0.440821       
+PB       = 0.7802155      CJSW     = cjswn          MJSW     = 0.4439558      
+PBSW     = 0.7802155      CJSWG    = cjgaten        MJSWG    = 0.4439558      
+PBSWG    = 0.7802155      CTA      = 0.00101709     CTP      = 0.0007730462   
+PTA      = 0.001464986    PTP      = 0.001464986    CGDO     = cgon           
+CGSO     = cgon           ACM      = 12             CAPMOD   = 0              
+NQSMOD   = 0              XTI      = 3              N        = 1              
+XPART    = 1              CF       = 0              TLEV     = 1              
+TLEVC    = 1              JS       = 7.15E-06       JSW      = 3E-11          
+DLC      = 1.85E-08       AF       = 0.973          KF       = 4.478E-24    )
*
.MODEL  n.9 NMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = 1.5E-07        LMAX     = '5E-07-dxl'     
+WMIN     = '5.8E-07-dxw'  WMAX     = '1.28E-06-dxw' XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxn           
+XJ       = 1.5E-07        NCH      = 1.7E+17        LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 1.5E-09        WINT     = 1.42E-08       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '0.597926 +dvthn' LVTH0 = 1.252509E-08   WVTH0    = -1.449175E-08  
+PVTH0    = -1.55547E-15   K1       = 0.7211186      LK1      = 5.142715E-09   
+WK1      = 3.398446E-09   PK1      = -1.62106E-15   K2       = -0.0918207     
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 103411.4       LVSAT    = -0.0009188967  
+WVSAT    = 0.0001029486   PVSAT    = -4.91065E-11   UA       = 2.64139E-12    
+LUA      = -6.2673E-20    WUA      = 7.021565E-21   PUA      = -3.34929E-27   
+UB       = 2.266067E-18   LUB      = -1.17028E-25   WUB      = -5.42863E-25   
+PUB      = 2.155837E-32   UC       = -1.03504E-10   LUC      = 1.688073E-17   
+WUC      = 4.540032E-17   PUC      = -2.16559E-23   RDSW     = 94             
+PRWB     = 0              PRWG     = 0              WR       = 1              
+U0       = 0.0444352      LU0      = 4.400479E-10   WU0      = -4.93008E-11   
+PU0      = 2.351649E-17   A0       = 0.5041878      LA0      = 1.69623E-07    
+WA0      = -8.517011E-08  PA0      = 6.631215E-15   KETA     = 0.0308397      
+LKETA    = 3.157829E-09   WKETA    = -3.013967E-08  PKETA    = 4.523593E-15   
+A1       = 0              A2       = 0.99           AGS      = 0              
+B0       = 0              B1       = 0              VOFF     = -0.2059227     
+LVOFF    = -8.322923E-09  WVOFF    = 1.540274E-08   PVOFF    = 5.561E-15      
+NFACTOR  = 2.8696358      CIT      = -0.0001585095  CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = 0.0001151178   
+LETA0    = -2.00996E-12   WETA0    = 2.251858E-13   PETA0    = -1.07414E-19   
+ETAB     = 0.001324588    LETAB    = -6.33469E-10   WETAB    = 7.097067E-11   
+PETAB    = -3.38531E-17   DSUB     = 0              PCLM     = 0.5184439      
+LPCLM    = 1.206123E-07   WPCLM    = -1.351279E-08  PPCLM    = 6.445613E-15   
+PDIBLC1  = 0              PDIBLC2  = -0.002495256   LPDIBLC2 = 3.886259E-09   
+WPDIBLC2 = 2.378903E-09   PPDIBLC2 = -9.03418E-16   PDIBLCB  = 0.2775065      
+DROUT    = 0              PSCBE1   = 6.665679E+08   PSCBE2   = 1E-20          
+PVAG     = 0              DELTA    = 0.01           ALPHA0   = 2.71E-09       
+BETA0    = 7.222          KT1      = -0.2411798     LKT1     = 2.077242E-09   
+WKT1     = -2.32724E-10   PKT1     = 1.110093E-16   KT2      = -0.0229        
+AT       = 26400          UTE      = -1.9694718     LUTE     = -7.02293E-11   
+UA1      = 6.495E-10      UB1      = -1.66059E-18   LUB1     = -1.31725E-25   
+WUB1     = -1.30661E-25   PUB1     = 6.23252E-32    UC1      = -5.99651E-11   
+LUC1     = -2.51198E-17   WUC1     = -6.59117E-17   PUC1     = 3.143988E-23   
+KT1L     = 0              PRT      = 0              HDIF     = hdifn          
+LDIF     = 6.5E-08        RSH      = 6              RS       = 0              
+RD       = 0              RSC      = 0              RDC      = 0              
+CJ       = cjn            MJ       = 0.440821       PB       = 0.7802155      
+CJSW     = cjswn          MJSW     = 0.4439558      PBSW     = 0.7802155      
+CJSWG    = cjgaten        MJSWG    = 0.4439558      PBSWG    = 0.7802155      
+CTA      = 0.00101709     CTP      = 0.0007730462   PTA      = 0.001464986    
+PTP      = 0.001464986    CGDO     = cgon           CGSO     = cgon           
+ACM      = 12             CAPMOD   = 0              NQSMOD   = 0              
+XTI      = 3              N        = 1              XPART    = 1              
+CF       = 0              TLEV     = 1              TLEVC    = 1              
+JS       = 7.15E-06       JSW      = 3E-11          DLC      = 1.85E-08  
+AF       = 0.973          KF       = 4.478E-24        )
*
.MODEL n.10 NMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '1.2E-06-dxl'  LMAX     = 2.1E-05        
+WMIN     = 1.8E-07        WMAX     = '5.8E-07-dxw'  XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxn           
+XJ       = 1.5E-07        NCH      = 1.7E+17        LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 1.5E-09        WINT     = 1.42E-08       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '0.5426953+dvthn' LVTH0 = 6.936723E-08   WVTH0    = -1.377637E-08  
+PVTH0    = -1.47088E-14   K1       = 0.6982943      LK1      = 1.701808E-08   
+K2       = -0.0918207     K3       = 0              DVT0     = 0              
+DVT1     = 0              DVT2     = 0              DVT0W    = 0              
+DVT1W    = 0              DVT2W    = 0              NLX      = 0              
+W0       = 0              K3B      = 0              VSAT     = 101472.2       
+LVSAT    = 0.0001274974   WVSAT    = 7.048968E-06   PVSAT    = -7.03275E-11   
+UA       = 2.17E-12       UB       = 2.071803E-18   LUB      = -8.26316E-25   
+WUB      = -2.52085E-26   PUB      = 6.229407E-32   UC       = -2.6614E-11    
+LUC      = -1.26373E-16   WUC      = 8.256348E-18   PUC      = 3.088726E-23   
+RDSW     = 94             PRWB     = 0              PRWG     = 0              
+WR       = 1              U0       = 0.0450181      LU0      = 1.911106E-09   
+WU0      = 9.473342E-11   PU0      = -9.45155E-16   A0       = 0.5293949      
+LA0      = 5.49023E-08    WA0      = -1.182229E-08  PA0      = -4.231E-14     
+KETA     = 0.0412351      LKETA    = 1.560771E-09   WKETA    = -3.420654E-09  
+PKETA    = -6.72591E-15   A1       = 0              A2       = 0.99           
+AGS      = 0              B0       = 0              B1       = 0              
+VOFF     = -0.203258      LVOFF    = 4.473488E-08   WVOFF    = 7.150506E-09   
+PVOFF    = -6.76989E-16   NFACTOR  = 2.8696358      CIT      = -0.0001585095  
+CDSC     = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0     = 9.854159E-05   LETA0    = 1.455056E-11   ETAB     = -3.44E-06      
+DSUB     = 0              PCLM     = 0.2791423      LPCLM    = 2.161887E-07   
+PDIBLC1  = 0              PDIBLC2  = 0.000801008    LPDIBLC2 = 5.376526E-09   
+PDIBLCB  = 0.2775065      DROUT    = 0              PSCBE1   = 6.665679E+08   
+PSCBE2   = 1E-20          PVAG     = 0              DELTA    = 0.01           
+ALPHA0   = 2.71E-09       BETA0    = 7.222          KT1      = -0.2379434     
+LKT1     = 1.115838E-08   WKT1     = 6.169151E-10   PKT1     = -6.15496E-15   
+KT2      = -0.0229        AT       = 26400          UTE      = -1.969619      
+UA1      = 6.495E-10      UB1      = -1.53207E-18   LUB1     = -1.18334E-25   
+WUB1     = -2.37377E-25   PUB1     = 2.06554E-31    UC1      = -1.24674E-10   
+LUC1     = 1.201943E-16   KT1L     = 0              PRT      = 0              
+HDIF     = hdifn          LDIF     = 6.5E-08        RSH      = 6              
+RS       = 0              RD       = 0              RSC      = 0              
+RDC      = 0              CJ       = cjn            MJ       = 0.440821       
+PB       = 0.7802155      CJSW     = cjswn          MJSW     = 0.4439558      
+PBSW     = 0.7802155      CJSWG    = cjgaten        MJSWG    = 0.4439558      
+PBSWG    = 0.7802155      CTA      = 0.00101709     CTP      = 0.0007730462   
+PTA      = 0.001464986    PTP      = 0.001464986    CGDO     = cgon           
+CGSO     = cgon           ACM      = 12             CAPMOD   = 0              
+NQSMOD   = 0              XTI      = 3              N        = 1              
+XPART    = 1              CF       = 0              TLEV     = 1              
+TLEVC    = 1              JS       = 7.15E-06       JSW      = 3E-11          
+DLC      = 1.85E-08       AF       = 0.973          KF       = 4.478E-24     )
*
.MODEL n.11 NMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '5E-07-dxl'    LMAX     = '1.2E-06-dxl'  
+WMIN     = 1.8E-07        WMAX     = '5.8E-07-dxw'  XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxn           
+XJ       = 1.5E-07        NCH      = 1.7E+17        LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 1.5E-09        WINT     = 1.42E-08       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '0.5825376+dvthn' LVTH0 = 2.247283E-08   WVTH0    = -3.002462E-08  
+PVTH0    = 4.415408E-15   K1       = 0.6831658      LK1      = 3.482428E-08   
+WK1      = 9.123521E-09   PK1      = -1.07384E-14   K2       = -0.0918207     
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 101645.6       LVSAT    = -7.663099E-05  
+WVSAT    = -8.86156E-05   PVSAT    = 4.226965E-11   UA       = 1.938314E-12   
+LUA      = 2.726941E-19   UB       = 1.555926E-18   LUB      = -2.19128E-25   
+WUB      = 3.834996E-26   PUB      = -1.25142E-32   UC       = -1.78867E-10   
+LUC      = 5.282888E-17   WUC      = 5.800713E-17   PUC      = -2.76694E-23   
+RDSW     = 94             PRWB     = 0              PRWG     = 0              
+WR       = 1              U0       = 0.0493259      LU0      = -3.159167E-09  
+WU0      = -2.188828E-09  PU0      = 1.742596E-15   A0       = 0.4325806      
+LA0      = 1.688527E-07   WA0      = -5.927941E-08  PA0      = 1.354704E-14   
+KETA     = 0.0715553      LKETA    = -3.412616E-08  WKETA    = -1.536004E-08  
+PKETA    = 7.326738E-15   A1       = 0              A2       = 0.99           
+AGS      = 0              B0       = 0              B1       = 0              
+VOFF     = -0.1506405     LVOFF    = -1.71959E-08   WVOFF    = 6.40311E-09    
+PVOFF    = 2.026965E-16   NFACTOR  = 2.8696358      CIT      = -0.0001585095  
+CDSC     = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0     = 0.0001109496   LETA0    = -5.36834E-14   WETA0    = -2.51587E-14   
+PETA0    = 2.961177E-20   ETAB     = -3.44E-06      DSUB     = 0              
+PCLM     = 0.4452271      LPCLM    = 2.070689E-08   WPCLM    = -1.06246E-07   
+PPCLM    = 1.250515E-13   PDIBLC1  = 0              PDIBLC2  = 0.006316813    
+LPDIBLC2 = -1.115576E-09  WPDIBLC2 = -9.59657E-10   PPDIBLC2 = 1.129516E-15   
+PDIBLCB  = 0.2775065      DROUT    = 0              PSCBE1   = 6.665679E+08   
+PSCBE2   = 1E-20          PVAG     = 0              DELTA    = 0.01           
+ALPHA0   = 2.71E-09       BETA0    = 7.222          KT1      = -0.222765      
+LKT1     = -6.706629E-09  WKT1     = -7.755504E-09  PKT1     = 3.699376E-15   
+KT2      = -0.0229        AT       = 26400          UTE      = -1.969619      
+UA1      = 6.495E-10      UB1      = -1.47257E-18   LUB1     = -1.88363E-25   
+WUB1     = -7.80149E-26   PUB1     = 1.898544E-32   UC1      = 3.882272E-11   
+LUC1     = -7.22416E-17   KT1L     = 0              PRT      = 0              
+HDIF     = hdifn          LDIF     = 6.5E-08        RSH      = 6              
+RS       = 0              RD       = 0              RSC      = 0              
+RDC      = 0              CJ       = cjn            MJ       = 0.440821       
+PB       = 0.7802155      CJSW     = cjswn          MJSW     = 0.4439558      
+PBSW     = 0.7802155      CJSWG    = cjgaten        MJSWG    = 0.4439558      
+PBSWG    = 0.7802155      CTA      = 0.00101709     CTP      = 0.0007730462   
+PTA      = 0.001464986    PTP      = 0.001464986    CGDO     = cgon           
+CGSO     = cgon           ACM      = 12             CAPMOD   = 0              
+NQSMOD   = 0              XTI      = 3              N        = 1              
+XPART    = 1              CF       = 0              TLEV     = 1              
+TLEVC    = 1              JS       = 7.15E-06       JSW      = 3E-11          
+DLC      = 1.85E-08       AF       = 0.973          KF       = 4.478E-24    )
*
.MODEL n.12 NMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = 1.5E-07        LMAX     = '5E-07-dxl'     
+WMIN     = 1.8E-07        WMAX     = '5.8E-07-dxw'  XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxn           
+XJ       = 1.5E-07        NCH      = 1.7E+17        LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 1.5E-09        WINT     = 1.42E-08       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '0.6035432+dvthn' LVTH0 = 1.245315E-08   WVTH0    = -1.759025E-08  
+PVTH0    = -1.51579E-15   K1       = 0.7293954      LK1      = 1.277274E-08   
+WK1      = -1.16705E-09   PK1      = -5.82978E-15   K2       = -0.0918207     
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 106332.2       LVSAT    = -0.00231213    
+WVSAT    = -0.001508178   PVSAT    = 7.194007E-10   UA       = 5.141443E-12   
+LUA      = -1.2552E-18    WUA      = -1.37201E-18   PUA      = 6.544476E-25   
+UB       = 1.312649E-18   LUB      = -1.03085E-25   WUB      = -1.69577E-26   
+PUB      = 1.386752E-32   UC       = 2.194595E-12   LUC      = -3.35377E-17   
+WUC      = -1.29032E-17   PUC      = 6.154834E-24   RDSW     = 94             
+PRWB     = 0              PRWG     = 0              WR       = 1              
+U0       = 0.0422182      LU0      = 2.31181E-10    WU0      = 1.173581E-09   
+PU0      = 1.387274E-16   A0       = -0.018346      LA0      = 3.839446E-07   
+WA0      = 2.030594E-07   PA0      = -1.11589E-13   KETA     = -0.0473323     
+LKETA    = 2.258324E-08   WKETA    = 1.298001E-08   PKETA    = -6.19146E-15   
+A1       = 0              A2       = 0.99           AGS      = 0              
+B0       = 0              B1       = 0              VOFF     = -0.2035349     
+LVOFF    = 8.03472E-09    WVOFF    = 1.408565E-08   PVOFF    = -3.46187E-15   
+NFACTOR  = 2.8696358      CIT      = -0.0001585095  CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = 0.0001169449   
+LETA0    = -2.91344E-12   WETA0    = -7.82671E-13   PETA0    = 3.909451E-19   
+ETAB     = 0.002569147    LETAB    = -1.227123E-09  WETAB    = -6.15528E-10   
+PETAB    = 2.936066E-16   DSUB     = 0              PCLM     = 0.132327       
+LPCLM    = 1.699602E-07   WPCLM    = 1.994693E-07   PPCLM    = -2.07747E-14   
+PDIBLC1  = 0              PDIBLC2  = -0.0006724232  LPDIBLC2 = 2.21829E-09    
+WPDIBLC2 = 1.37343E-09    PPDIBLC2 = 1.663367E-17   PDIBLCB  = 0.2775065      
+DROUT    = 0              PSCBE1   = 6.667642E+08   LPSCBE1  = -0.0936704     
+WPSCBE1  = -0.1083199     PPSCBE1  = 5.16686E-08    PSCBE2   = 1E-20          
+PVAG     = 0              DELTA    = 0.01           ALPHA0   = 2.71E-09       
+BETA0    = 7.222          KT1      = -0.2431798     LKT1     = 3.031225E-09   
+WKT1     = 8.704574E-10   PKT1     = -4.15208E-16   KT2      = -0.0229        
+AT       = 26400          UTE      = -1.9694048     LUTE     = -1.0216E-10    
+PUTE     = 1.385986E-17   UA1      = 6.497272E-10   LUA1     = -1.0838E-19    
+WUA1     = -1.2533E-19    PUA1     = 5.978258E-26   UB1      = -1.79313E-18   
+LUB1     = -3.54555E-26   WUB1     = -5.75487E-26   PUB1     = 9.223047E-33   
+UC1      = -2.01271E-10   LUC1     = 4.228334E-17   WUC1     = 1.203283E-17   
+PUC1     = -5.73966E-24   KT1L     = 0              PRT      = 0              
+HDIF     = hdifn          LDIF     = 6.5E-08        RSH      = 6              
+RS       = 0              RD       = 0              RSC      = 0              
+RDC      = 0              CJ       = cjn            MJ       = 0.440821       
+PB       = 0.7802155      CJSW     = cjswn          MJSW     = 0.4439558      
+PBSW     = 0.7802155      CJSWG    = cjgaten        MJSWG    = 0.4439558      
+PBSWG    = 0.7802155      CTA      = 0.00101709     CTP      = 0.0007730462   
+PTA      = 0.001464986    PTP      = 0.001464986    CGDO     = cgon           
+CGSO     = cgon           ACM      = 12             CAPMOD   = 0              
+NQSMOD   = 0              XTI      = 3              N        = 1              
+XPART    = 1              CF       = 0              TLEV     = 1              
+TLEVC    = 1              JS       = 7.15E-06       JSW      = 3E-11          
+DLC      = 1.85E-08       AF       = 0.973          KF       = 4.478E-24   )
***************************************************************
*                                                             *
*                 1.5V PMOS DEVICES MODEL                     *
*                                                             *
***************************************************************
.MODEL  p.1 PMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '1.206E-06-dxl' LMAX     = 2.1E-05        
+WMIN     = '1.008E-05-dxw' WMAX     = 0.000201       XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxp           
+XJ       = 1.5E-07        NCH      = 9.3846E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 7.85E-09       WINT     = 1.08E-10       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '-0.4839865+dvthp' LVTH0= -2.62567E-08   WVTH0    = 1.080625E-07   
+PVTH0    = 4.012703E-14   K1       = 0.626688       K2       = 0.009141911    
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 113000         UA       = 3.81E-11       
+UB       = 9.796012E-19   LUB      = 4.013621E-25   WUB      = 7.938221E-25   
+PUB      = -1.78493E-30   UC       = -1.9194E-10    RDSW     = 735.8          
+PRWB     = 0              PRWG     = 0              WR       = 1              
+U0       = 0.008974799    LU0      = -1.4755E-10    A0       = 1.067116       
+KETA     = 0.024          A1       = 0              A2       = 0.4            
+AGS      = 0              B0       = 0              B1       = 0              
+VOFF     = -0.0961487     LVOFF    = -1.32379E-11   NFACTOR  = 1.3429912      
+CIT      = 0.0005002944   CDSC     = 0              CDSCB    = 0              
+CDSCD    = 0              ETA0     = 0.000208       ETAB     = -0.0001553004  
+LETAB    = -1.57527E-10   DSUB     = 0              PCLM     = 0.164512       
+LPCLM    = 3.538262E-07   PDIBLC1  = 0              PDIBLC2  = 0.0002762747   
+LPDIBLC2 = 2.245367E-09   PDIBLCB  = 0.3330078      DROUT    = 0              
+PSCBE1   = 7.37E+08       PSCBE2   = 1E-20          PVAG     = 0              
+DELTA    = 0.015          ALPHA0   = 1.54E-07       BETA0    = 20             
+KT1      = -0.240505      LKT1     = -1.913327E-08  KT2      = -0.0286        
+AT       = 10000          UTE      = -1.04          UA1      = 3.99E-10       
+UB1      = -8.91485E-19   LUB1     = -5.09956E-26   UC1      = -1.01E-12      
+KT1L     = 0              PRT      = 0              HDIF     = hdifp          
+LDIF     = 6.5E-08        RSH      = 6.4            RS       = 0              
+RD       = 0              RSC      = 0              RDC      = 0              
+CJ       = cjp            MJ       = 0.40377        PB       = 0.82245        
+CJSW     = cjswp          MJSW     = 0.3932347      PBSW     = 0.82245        
+CJSWG    = cjgatep        MJSWG    = 0.3932347      PBSWG    = 0.82245        
+CTA      = 0.0009560416   CTP      = 0.0006629025   PTA      = 0.001925529    
+PTP      = 0.001925529    CGDO     = cgop           CGSO     = cgop           
+ACM      = 12             CAPMOD   = 0              NQSMOD   = 0              
+XTI      = 3              N        = 1              XPART    = 1              
+CF       = 0              TLEV     = 1              TLEVC    = 1              
+JS       = 1.42E-06       JSW      = 1E-11    
+AF       = 1.12           KF       = 5.965E-24      )
*
.MODEL  p.2 PMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '5.06E-07-dxl' LMAX     = '1.206E-06-dxl'
+WMIN     = '1.008E-05-dxw' WMAX     = 0.000201      XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxp           
+XJ       = 1.5E-07        NCH      = 9.3846E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 7.85E-09       WINT     = 1.08E-10       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '-0.4963295+dvthp' LVTH0= -1.181172E-08  WVTH0    = 1.408442E-07   
+PVTH0    = 1.762652E-15   K1       = 0.6091444      LK1      = 2.053121E-08   
+K2       = 0.009141911    K3       = 0              DVT0     = 0              
+DVT1     = 0              DVT2     = 0              DVT0W    = 0              
+DVT1W    = 0              DVT2W    = 0              NLX      = 0              
+W0       = 0              K3B      = 0              VSAT     = 113000         
+UA       = 3.81E-11       UB       = 1.294429E-18   LUB      = 3.291877E-26   
+WUB      = -4.47838E-25   PUB      = -3.31814E-31   UC       = -2.4926E-10    
+LUC      = 6.708169E-17   WUC      = 3.614708E-16   PUC      = -4.23029E-22   
+RDSW     = 735.8          PRWB     = 0              PRWG     = 0              
+WR       = 1              U0       = 0.00903469     LU0      = -2.17641E-10   
+A0       = 1.1157365      LA0      = -5.690049E-08  WA0      = -8.425889E-07  
+PA0      = 9.860818E-13   KETA     = 0.0233281      LKETA    = 7.862745E-10   
+A1       = 0              A2       = 0.4            AGS      = 0              
+B0       = 0              B1       = 0              VOFF     = -0.0969681     
+LVOFF    = 9.457742E-10   WVOFF    = 8.087918E-08   PVOFF    = -9.46529E-14   
+NFACTOR  = 1.3429912      CIT      = 0.0005002944   CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = 0.000208       
+ETAB     = -0.0001201822  LETAB    = -1.98625E-10   DSUB     = 0              
+PCLM     = 0.3884779      LPCLM    = 9.171892E-08   PDIBLC1  = 0              
+PDIBLC2  = 0.001147811    LPDIBLC2 = 1.225409E-09   PDIBLCB  = 0.3330078      
+DROUT    = 0              PSCBE1   = 7.37E+08       PSCBE2   = 1E-20          
+PVAG     = 0              DELTA    = 0.015          ALPHA0   = 1.54E-07       
+BETA0    = 20             KT1      = -0.256854      KT2      = -0.0286        
+AT       = 10000          UTE      = -1.04          UA1      = 3.99E-10       
+UB1      = -1.00182E-18   LUB1     = 7.812745E-26   WUB1     = -2.48511E-25   
+PUB1     = 2.908327E-31   UC1      = -1.01E-12      KT1L     = 0              
+PRT      = 0              HDIF     = hdifp          LDIF     = 6.5E-08        
+RSH      = 6.4            RS       = 0              RD       = 0              
+RSC      = 0              RDC      = 0              CJ       = cjp            
+MJ       = 0.40377        PB       = 0.82245        CJSW     = cjswp          
+MJSW     = 0.3932347      PBSW     = 0.82245        CJSWG    = cjgatep        
+MJSWG    = 0.3932347      PBSWG    = 0.82245        CTA      = 0.0009560416   
+CTP      = 0.0006629025   PTA      = 0.001925529    PTP      = 0.001925529    
+CGDO     = cgop           CGSO     = cgop           ACM      = 12             
+CAPMOD   = 0              NQSMOD   = 0              XTI      = 3              
+N        = 1              XPART    = 1              CF       = 0              
+TLEV     = 1              TLEVC    = 1              JS       = 1.42E-06       
+JSW      = 1E-11          AF       = 1.12           KF       = 5.965E-24    )
*
.MODEL  p.3 PMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = 1.5E-07        LMAX     = '5.06E-07-dxl'
+WMIN     = '1.008E-05-dxw' WMAX     = 0.000201      XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxp           
+XJ       = 1.5E-07        NCH      = 9.3846E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 7.85E-09       WINT     = 1.08E-10       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '-0.5023987+dvthp' LVTH0= -8.95735E-09   WVTH0    = 1.561749E-07   
+PVTH0    = -5.44737E-15   K1       = 0.6421866      LK1      = 4.991472E-09   
+WK1      = 1.895352E-08   PK1      = -8.91384E-15   K2       = 0.009141911    
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 110475         LVSAT    = 0.001187497    
+WVSAT    = 0.0254512      PVSAT    = -1.196972E-08  UA       = 3.797084E-11   
+LUA      = 6.074232E-20   WUA      = 2.306496E-19   PUA      = -1.08474E-25   
+UB       = 1.385193E-18   LUB      = -9.76735E-27   WUB      = 5.951106E-25   
+PUB      = -8.22313E-31   UC       = -1.13508E-10   LUC      = 3.237494E-18   
+WUC      = -4.69649E-16   PUC      = -3.21538E-23   RDSW     = 735.8          
+PRWB     = 0              PRWG     = 0              WR       = 1              
+U0       = 0.008489518    LU0      = 3.875369E-11   WU0      = 1.471548E-10   
+PU0      = -6.92069E-17   A0       = 1.0095304      LA0      = -6.951822E-09  
+WA0      = 1.06301E-06    PA0      = 8.987884E-14   KETA     = 0.025          
+A1       = 0              A2       = 0.4            AGS      = 0              
+B0       = 0              B1       = 0              VOFF     = -0.0908168     
+LVOFF    = -1.947181E-09  WVOFF    = -1.657363E-07  PVOFF    = 2.133032E-14   
+NFACTOR  = 1.3429912      CIT      = 0.0005002944   CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = -0.0001867992  
+LETA0    = 1.85674E-10    WETA0    = 7.798996E-10   PETA0    = -3.66787E-16   
+ETAB     = -0.0002780858  LETAB    = -1.24363E-10   WETAB    = 3.374223E-09   
+PETAB    = -1.5869E-15    DSUB     = 0              PCLM     = 0.4310875      
+LPCLM    = 7.16796E-08    WPCLM    = -7.150356E-08  PPCLM    = 3.362815E-14   
+PDIBLC1  = 0              PDIBLC2  = 0.003639701    LPDIBLC2 = 5.347249E-11   
+WPDIBLC2 = -1.624369E-08  PPDIBLC2 = 7.63941E-15    PDIBLCB  = 0.3330078      
+DROUT    = 0              PSCBE1   = 7.37E+08       PSCBE2   = 1E-20          
+PVAG     = 0              DELTA    = 0.015          ALPHA0   = 1.54E-07       
+BETA0    = 20             KT1      = -0.244448      LKT1     = -5.834522E-09  
+WKT1     = -2.215475E-08  PKT1     = 1.041937E-14   KT2      = -0.0286        
+AT       = 10000          UTE      = -1.04          UA1      = 3.99E-10       
+UB1      = -8.36805E-19   LUB1     = 5.213991E-28   WUB1     = 4.885065E-25   
+PUB1     = -5.57867E-32   UC1      = -1.01E-12      KT1L     = 0              
+PRT      = 0              HDIF     = hdifp          LDIF     = 6.5E-08        
+RSH      = 6.4            RS       = 0              RD       = 0              
+RSC      = 0              RDC      = 0              CJ       = cjp            
+MJ       = 0.40377        PB       = 0.82245        CJSW     = cjswp          
+MJSW     = 0.3932347      PBSW     = 0.82245        CJSWG    = cjgatep        
+MJSWG    = 0.3932347      PBSWG    = 0.82245        CTA      = 0.0009560416   
+CTP      = 0.0006629025   PTA      = 0.001925529    PTP      = 0.001925529    
+CGDO     = cgop           CGSO     = cgop           ACM      = 12             
+CAPMOD   = 0              NQSMOD   = 0              XTI      = 3              
+N        = 1              XPART    = 1              CF       = 0              
+TLEV     = 1              TLEVC    = 1              JS       = 1.42E-06       
+JSW      = 1E-11          AF       = 1.12           KF       = 5.965E-24  )
*
.MODEL  p.4 PMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '1.206E-06-dxl' LMAX     = 2.1E-05        
+WMIN     = '1.28E-06-dxw' WMAX     = '1.008E-05-dxw' XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxp           
+XJ       = 1.5E-07        NCH      = 9.3846E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 7.85E-09       WINT     = 1.08E-10       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '-0.4744246+dvthp' LVTH0= -2.304709E-08  WVTH0    = 1.168034E-08   
+PVTH0    = 7.774852E-15   K1       = 0.6281341      LK1      = 5.57475E-09    
+WK1      = -1.457588E-08  PK1      = -5.61923E-14   K2       = 0.009141911    
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 113114.6       LVSAT    = -0.001142523   
+WVSAT    = -0.00115507    PVSAT    = 1.151639E-08   UA       = 3.81E-11       
+UB       = 1.03912E-18    LUB      = 2.399593E-25   WUB      = 1.938831E-25   
+PUB      = -1.58022E-31   UC       = -1.93538E-10   LUC      = 1.593169E-17   
+WUC      = 1.610665E-17   PUC      = -1.60588E-22   RDSW     = 735.8          
+PRWB     = 0              PRWG     = 0              WR       = 1              
+U0       = 0.009015605    LU0      = -8.48938E-11   WU0      = -4.11301E-10   
+PU0      = -6.31564E-16   A0       = 1.0695933      LA0      = -2.469894E-08  
+WA0      = -2.497018E-08  PA0      = 2.4896E-13     KETA     = 0.024          
+A1       = 0              A2       = 0.4            AGS      = 0              
+B0       = 0              B1       = 0              VOFF     = -0.0925341     
+LVOFF    = -2.609507E-09  WVOFF    = -3.643436E-08  PVOFF    = 2.616986E-14   
+NFACTOR  = 1.3429912      CIT      = 0.0005002944   CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = 0.000224477    
+LETA0    = -1.92831E-11   WETA0    = -1.66085E-10   PETA0    = 1.943694E-16   
+ETAB     = -0.0001806751  LETAB    = -1.27831E-10   WETAB    = 2.557711E-10   
+PETAB    = -2.99329E-16   DSUB     = 0              PCLM     = 0.1607041      
+LPCLM    = 2.930717E-07   WPCLM    = 3.838288E-08   PPCLM    = 6.123921E-13   
+PDIBLC1  = 0              PDIBLC2  = 0.0002762747   LPDIBLC2 = 2.245367E-09   
+PDIBLCB  = 0.3330078      DROUT    = 0              PSCBE1   = 7.37E+08       
+PSCBE2   = 1E-20          PVAG     = 0              DELTA    = 0.015          
+ALPHA0   = 1.54E-07       BETA0    = 20             KT1      = -0.2416623     
+LKT1     = -1.777883E-08  WKT1     = 1.16658E-08    PKT1     = -1.36525E-14   
+KT2      = -0.0286        AT       = 10000          UTE      = -1.04          
+UA1      = 3.99E-10       UB1      = -9.05636E-19   LUB1     = -1.08212E-26   
+WUB1     = 1.426424E-25   PUB1     = -4.04949E-31   UC1      = -1.16907E-12   
+LUC1     = 2.73732E-19    WUC1     = 1.60338E-18    PUC1     = -2.75916E-24   
+KT1L     = 0              PRT      = 0              HDIF     = hdifp          
+LDIF     = 6.5E-08        RSH      = 6.4            RS       = 0              
+RD       = 0              RSC      = 0              RDC      = 0              
+CJ       = cjp            MJ       = 0.40377        PB       = 0.82245        
+CJSW     = cjswp          MJSW     = 0.3932347      PBSW     = 0.82245        
+CJSWG    = cjgatep        MJSWG    = 0.3932347      PBSWG    = 0.82245        
+CTA      = 0.0009560416   CTP      = 0.0006629025   PTA      = 0.001925529    
+PTP      = 0.001925529    CGDO     = cgop           CGSO     = cgop           
+ACM      = 12             CAPMOD   = 0              NQSMOD   = 0              
+XTI      = 3              N        = 1              XPART    = 1              
+CF       = 0              TLEV     = 1              TLEVC    = 1              
+JS       = 1.42E-06       JSW      = 1E-11      
+AF       = 1.12           KF       = 5.965E-24          )
*
.MODEL  p.5 PMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '5.06E-07-dxl' LMAX     = '1.206E-06-dxl'
+WMIN     = '1.28E-06-dxw' WMAX     = '1.008E-05-dxw' XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxp           
+XJ       = 1.5E-07        NCH      = 9.3846E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 7.85E-09       WINT     = 1.08E-10       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '-0.4849658+dvthp' LVTH0= -1.071063E-08  WVTH0    = 2.630132E-08   
+PVTH0    = -9.33608E-15   K1       = 0.6124128      LK1      = 2.397331E-08   
+WK1      = -3.294437E-08  PK1      = -3.46956E-14   K2       = 0.009141911    
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 112138.3       WVSAT    = 0.008685474    
+UA       = 3.81E-11       UB       = 1.25591E-18    LUB      = -1.37503E-26   
+WUB      = -5.95755E-26   PUB      = 1.386004E-31   UC       = -2.06057E-10   
+LUC      = 3.058286E-17   WUC      = -7.40063E-17   PUC      = -5.51289E-23   
+RDSW     = 735.8          PRWB     = 0              PRWG     = 0              
+WR       = 1              U0       = 0.009151195    LU0      = -2.43575E-10   
+WU0      = -1.174332E-09  PU0      = 2.614107E-16   A0       = 1.0272503      
+LA0      = 2.485512E-08   WA0      = 4.933321E-08   PA0      = 1.620028E-13   
+KETA     = 0.0245495      LKETA    = -6.43075E-10   WKETA    = -1.231097E-08  
+PKETA    = 1.440753E-14   A1       = 0              A2       = 0.4            
+AGS      = 0              B0       = 0              B1       = 0              
+VOFF     = -0.088172      LVOFF    = -7.714485E-09  WVOFF    = -7.784255E-09  
+PVOFF    = -7.35935E-15   NFACTOR  = 1.3429912      CIT      = 0.0005002944   
+CDSC     = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0     = 0.000208       ETAB     = -0.0001201822  LETAB    = -1.98625E-10   
+DSUB     = 0              PCLM     = 0.3214837      LPCLM    = 1.049115E-07   
+WPCLM    = 6.752879E-07   PPCLM    = -1.32978E-13   PDIBLC1  = 0              
+PDIBLC2  = 0.001147811    LPDIBLC2 = 1.225409E-09   PDIBLCB  = 0.3330078      
+DROUT    = 0              PSCBE1   = 7.37E+08       PSCBE2   = 1E-20          
+PVAG     = 0              DELTA    = 0.015          ALPHA0   = 1.54E-07       
+BETA0    = 20             KT1      = -0.256854      KT2      = -0.0286        
+AT       = 10000          UTE      = -1.04          UA1      = 3.99E-10       
+UB1      = -1.05752E-18   LUB1     = 1.669286E-25   WUB1     = 3.129523E-25   
+PUB1     = -6.04263E-31   UC1      = -8.84895E-13   LUC1     = -5.88372E-20   
+WUC1     = -1.26104E-18   PUC1     = 5.930656E-25   KT1L     = 0              
+PRT      = 0              HDIF     = hdifp          LDIF     = 6.5E-08        
+RSH      = 6.4            RS       = 0              RD       = 0              
+RSC      = 0              RDC      = 0              CJ       = cjp            
+MJ       = 0.40377        PB       = 0.82245        CJSW     = cjswp          
+MJSW     = 0.3932347      PBSW     = 0.82245        CJSWG    = cjgatep        
+MJSWG    = 0.3932347      PBSWG    = 0.82245        CTA      = 0.0009560416   
+CTP      = 0.0006629025   PTA      = 0.001925529    PTP      = 0.001925529    
+CGDO     = cgop           CGSO     = cgop           ACM      = 12             
+CAPMOD   = 0              NQSMOD   = 0              XTI      = 3              
+N        = 1              XPART    = 1              CF       = 0              
+TLEV     = 1              TLEVC    = 1              JS       = 1.42E-06       
+JSW      = 1E-11          AF       = 1.12           KF       = 5.965E-24  )
*
.MODEL  p.6 PMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = 1.5E-07        LMAX     = '5.06E-07-dxl'
+WMIN     = '1.28E-06-dxw' WMAX     = '1.008E-05-dxw' XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxp           
+XJ       = 1.5E-07        NCH      = 9.3846E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 7.85E-09       WINT     = 1.08E-10       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '-0.4878719+dvthp' LVTH0= -9.343925E-09  WVTH0    = 9.747416E-09   
+PVTH0    = -1.55078E-15   K1       = 0.6553237      LK1      = 3.792312E-09   
+WK1      = -1.134655E-07  PK1      = 3.173432E-15   K2       = 0.009141911    
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 112138.3       WVSAT    = 0.008685474    
+UA       = 3.797677E-11   LUA      = 5.795469E-20   WUA      = 1.709033E-19   
+PUA      = -8.03758E-26   UB       = 1.432698E-18   LUB      = -9.68934E-26   
+WUB      = 1.162722E-25   PUB      = 5.589922E-32   UC       = -1.39314E-10   
+LUC      = -8.06403E-19   WUC      = -2.0953E-16    PUC      = 8.607808E-24   
+RDSW     = 735.8          PRWB     = 0              PRWG     = 0              
+WR       = 1              U0       = 0.008559504    LU0      = 3.469694E-11   
+WU0      = -5.58286E-10   PU0      = -2.83158E-17   A0       = 1.0709949      
+LA0      = 4.282009E-09   WA0      = 4.434615E-07   PA0      = -2.33558E-14   
+KETA     = 0.0225573      LKETA    = 2.938575E-10   WKETA    = 2.462195E-08   
+PKETA    = -2.96202E-15   A1       = 0              A2       = 0.4            
+AGS      = 0              B0       = 0              B1       = 0              
+VOFF     = -0.1044927     LVOFF    = -3.88424E-11   WVOFF    = -2.788638E-08  
+PVOFF    = 2.094676E-15   NFACTOR  = 1.3429912      CIT      = 0.0005002944   
+CDSC     = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0     = -0.00015499    LETA0    = 1.707142E-10   WETA0    = 4.592703E-10   
+PETA0    = -2.15995E-16   ETAB     = 0.0001388577   LETAB    = -3.20452E-10   
+WETAB    = -8.28477E-10   PETAB    = 3.896326E-16   DSUB     = 0              
+PCLM     = 0.3763033      LPCLM    = 7.912976E-08   WPCLM    = 4.807099E-07   
+PPCLM    = -4.14679E-14   PDIBLC1  = 0              PDIBLC2  = 0.00174654     
+LPDIBLC2 = 9.438262E-10   WPDIBLC2 = 2.838962E-09   PPDIBLC2 = -1.33516E-15   
+PDIBLCB  = 0.3330078      DROUT    = 0              PSCBE1   = 7.37E+08       
+PSCBE2   = 1E-20          PVAG     = 0              DELTA    = 0.015          
+ALPHA0   = 1.54E-07       BETA0    = 20             KT1      = -0.2467507     
+LKT1     = -4.751585E-09  WKT1     = 1.055499E-09   PKT1     = -4.96402E-16   
+KT2      = -0.0286        AT       = 10000          UTE      = -1.04          
+UA1      = 3.99E-10       UB1      = -6.73103E-19   LUB1     = -1.3863E-26    
+WUB1     = -1.16157E-24   PUB1     = 8.920469E-32   UC1      = -1.01E-12      
+KT1L     = 0              PRT      = 0              HDIF     = hdifp          
+LDIF     = 6.5E-08        RSH      = 6.4            RS       = 0              
+RD       = 0              RSC      = 0              RDC      = 0              
+CJ       = cjp            MJ       = 0.40377        PB       = 0.82245        
+CJSW     = cjswp          MJSW     = 0.3932347      PBSW     = 0.82245        
+CJSWG    = cjgatep        MJSWG    = 0.3932347      PBSWG    = 0.82245        
+CTA      = 0.0009560416   CTP      = 0.0006629025   PTA      = 0.001925529    
+PTP      = 0.001925529    CGDO     = cgop           CGSO     = cgop           
+ACM      = 12             CAPMOD   = 0              NQSMOD   = 0              
+XTI      = 3              N        = 1              XPART    = 1              
+CF       = 0              TLEV     = 1              TLEVC    = 1              
+JS       = 1.42E-06       JSW      = 1E-11      
+AF       = 1.12           KF       = 5.965E-24          )
*
.MODEL  p.7 PMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '1.206E-06-dxl' LMAX     = 2.1E-05        
+WMIN     = '5.8E-07-dxw'  WMAX     = '1.28E-06-dxw' XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxp           
+XJ       = 1.5E-07        NCH      = 9.3846E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 7.85E-09       WINT     = 1.08E-10       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '-0.4728989+dvthp' LVTH0= -8.076343E-09  WVTH0    = 9.72782E-09    
+PVTH0    = -1.13845E-14   K1       = 0.6744139      LK1      = -1.058231E-07  
+WK1      = -7.38041E-08   PK1      = 8.637294E-14   K2       = 0.009141911    
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 112220.3       LVSAT    = 0.007773808    
+WVSAT    = -1.057254E-05  PVSAT    = 1.054117E-10   UA       = 3.81E-11       
+UB       = 1.22305E-18    LUB      = 3.113084E-25   WUB      = -4.15072E-26   
+PUB      = -2.49334E-31   UC       = -1.20089E-10   LUC      = -2.00251E-16   
+WUC      = -7.78924E-17   PUC      = 1.160794E-22   RDSW     = 735.8          
+PRWB     = 0              PRWG     = 0              WR       = 1              
+U0       = 0.008672191    LU0      = -3.58742E-10   WU0      = 2.819351E-11   
+PU0      = -2.81098E-16   A0       = 1.0635068      LA0      = 3.598451E-08   
+WA0      = -1.718085E-08  PA0      = 1.712983E-13   KETA     = 0.0104869      
+LKETA    = 1.581442E-08   WKETA    = 1.72939E-08    PKETA    = -2.0239E-14    
+A1       = 0              A2       = 0.4            AGS      = 0              
+B0       = 0              B1       = 0              VOFF     = -0.1326685     
+LVOFF    = 4.684982E-08   WVOFF    = 1.492903E-08   PVOFF    = -3.71274E-14   
+NFACTOR  = 1.3429912      CIT      = 0.0005002944   CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = 9.470114E-05   
+LETA0    = 1.325936E-10   ETAB     = 1.917981E-05   LETAB    = -3.61721E-10   
+DSUB     = 0              PCLM     = 0.1873913      LPCLM    = 8.045305E-07   
+WPCLM    = 4.229005E-09   PPCLM    = -4.21647E-14   PDIBLC1  = 0              
+PDIBLC2  = 0.0004764943   LPDIBLC2 = 2.613377E-10   WPDIBLC2 = -2.56238E-10   
+PPDIBLC2 = 2.539129E-15   PDIBLCB  = 0.3330078      DROUT    = 0              
+PSCBE1   = 7.37E+08       PSCBE2   = 1E-20          PVAG     = 0              
+DELTA    = 0.015          ALPHA0   = 1.54E-07       BETA0    = 20             
+KT1      = -0.242205      LKT1     = -1.71437E-08   WKT1     = 1.236034E-08   
+PKT1     = -1.44653E-14   KT2      = -0.0286        AT       = 10000          
+UTE      = -1.04          UA1      = 3.99E-10       UB1      = -7.73702E-19   
+LUB1     = -3.51205E-25   WUB1     = -2.62051E-26   PUB1     = 3.066784E-32   
+UC1      = 9.330466E-13   LUC1     = -2.87612E-18   WUC1     = -1.08687E-18   
+PUC1     = 1.271968E-24   KT1L     = 0              PRT      = 0              
+HDIF     = hdifp          LDIF     = 6.5E-08        RSH      = 6.4            
+RS       = 0              RD       = 0              RSC      = 0              
+RDC      = 0              CJ       = cjp            MJ       = 0.40377        
+PB       = 0.82245        CJSW     = cjswp          MJSW     = 0.3932347      
+PBSW     = 0.82245        CJSWG    = cjgatep        MJSWG    = 0.3932347      
+PBSWG    = 0.82245        CTA      = 0.0009560416   CTP      = 0.0006629025   
+PTA      = 0.001925529    PTP      = 0.001925529    CGDO     = cgop           
+CGSO     = cgop           ACM      = 12             CAPMOD   = 0              
+NQSMOD   = 0              XTI      = 3              N        = 1              
+XPART    = 1              CF       = 0              TLEV     = 1              
+TLEVC    = 1              JS       = 1.42E-06       JSW      = 1E-11
+AF       = 1.12           KF       = 5.965E-24                )
*
.MODEL  p.8 PMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '5.06E-07-dxl' LMAX     = '1.206E-06-dxl' 
+WMIN     = '5.8E-07-dxw'  WMAX     = '1.28E-06-dxw' XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxp           
+XJ       = 1.5E-07        NCH      = 9.3846E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 7.85E-09       WINT     = 1.08E-10       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '-0.4644145+dvthp' LVTH0= -1.800567E-08  K1       = 0.5866707      
+LK1      = -3.137231E-09  K2       = 0.009141911    K3       = 0              
+DVT0     = 0              DVT1     = 0              DVT2     = 0              
+DVT0W    = 0              DVT1W    = 0              DVT2W    = 0              
+NLX      = 0              W0       = 0              K3B      = 0              
+VSAT     = 118821.1       LVSAT    = 4.884314E-05   WVSAT    = 0.0001329123   
+PVSAT    = -6.25087E-11   UA       = 3.81E-11       UB       = 1.278552E-18   
+LUB      = 2.46354E-25    WUB      = -8.85522E-26   PUB      = -1.94277E-31   
+UC       = -3.10818E-10   LUC      = 2.295972E-17   WUC      = 6.006573E-17   
+PUC      = -4.5373E-23    RDSW     = 735.8          PRWB     = 0              
+PRWG     = 0              WR       = 1              U0       = 0.00842707     
+LU0      = -7.18758E-11   WU0      = -2.47608E-10   PU0      = 4.167244E-17   
+A0       = 0.9177257      LA0      = 2.065921E-07   WA0      = 1.895009E-07   
+PA0      = -7.05814E-14   KETA     = 0.0149299      LKETA    = 1.061471E-08   
+A1       = 0              A2       = 0.4            AGS      = 0              
+B0       = 0              B1       = 0              VOFF     = -0.063418      
+LVOFF    = -3.419398E-08  WVOFF    = -3.946394E-08  PVOFF    = 2.652868E-14   
+NFACTOR  = 1.3429912      CIT      = 0.0005002944   CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = 0.000208       
+ETAB     = -0.0001201821  LETAB    = -1.98626E-10   DSUB     = 0              
+PCLM     = 0.9034018      LPCLM    = -3.341655E-08  WPCLM    = -6.944155E-08  
+PPCLM    = 4.405195E-14   PDIBLC1  = 0              PDIBLC2  = -0.001114386   
+LPDIBLC2 = 2.123145E-09   WPDIBLC2 = 2.895124E-09   PPDIBLC2 = -1.14891E-15   
+PDIBLCB  = 0.3330078      DROUT    = 0              PSCBE1   = 7.37E+08       
+PSCBE2   = 1E-20          PVAG     = 0              DELTA    = 0.015          
+ALPHA0   = 1.54E-07       BETA0    = 20             KT1      = -0.256854      
+KT2      = -0.0286        AT       = 10000          UTE      = -1.04          
+UA1      = 3.99E-10       UB1      = -6.41591E-19   LUB1     = -5.05814E-25   
+WUB1     = -2.19347E-25   PUB1     = 2.567023E-31   UC1      = -1.87025E-12   
+LUC1     = 4.045736E-19   KT1L     = 0              PRT      = 0              
+HDIF     = hdifp          LDIF     = 6.5E-08        RSH      = 6.4            
+RS       = 0              RD       = 0              RSC      = 0              
+RDC      = 0              CJ       = cjp            MJ       = 0.40377        
+PB       = 0.82245        CJSW     = cjswp          MJSW     = 0.3932347      
+PBSW     = 0.82245        CJSWG    = cjgatep        MJSWG    = 0.3932347      
+PBSWG    = 0.82245        CTA      = 0.0009560416   CTP      = 0.0006629025   
+PTA      = 0.001925529    PTP      = 0.001925529    CGDO     = cgop           
+CGSO     = cgop           ACM      = 12             CAPMOD   = 0              
+NQSMOD   = 0              XTI      = 3              N        = 1              
+XPART    = 1              CF       = 0              TLEV     = 1              
+TLEVC    = 1              JS       = 1.42E-06       JSW      = 1E-11         
+AF       = 1.12           KF       = 5.965E-24       )
*
.MODEL  p.9 PMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = 1.5E-07        LMAX     = '5.06E-07-dxl'  
+WMIN     = '5.8E-07-dxw'  WMAX     = '1.28E-06-dxw' XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxp           
+XJ       = 1.5E-07        NCH      = 9.3846E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 7.85E-09       WINT     = 1.08E-10       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '-0.4717148+dvthp' LVTH0= -1.457231E-08  WVTH0    = -1.09301E-08   
+PVTH0    = 5.140426E-15   K1       = 0.5666639      LK1      = 6.271974E-09   
+K2       = 0.009141911    K3       = 0              DVT0     = 0              
+DVT1     = 0              DVT2     = 0              DVT0W    = 0              
+DVT1W    = 0              DVT2W    = 0              NLX      = 0              
+W0       = 0              K3B      = 0              VSAT     = 117238.2       
+LVSAT    = 0.0007932847   WVSAT    = 0.002158693    PVSAT    = -1.015233E-09  
+UA       = 3.811031E-11   LUA      = -4.84951E-21   UB       = 1.986569E-18   
+LUB      = -8.66265E-26   WUB      = -5.92564E-25   PUB      = 4.275972E-32   
+UC       = -2.64807E-10   LUC      = 1.320539E-18   WUC      = -4.89259E-17   
+PUC      = 5.885781E-24   RDSW     = 735.8          PRWB     = 0              
+PRWG     = 0              WR       = 1              U0       = 0.008238199    
+LU0      = 1.694974E-11   WU0      = -1.47085E-10   PU0      = -5.60325E-18   
+A0       = 1.3761147      LA0      = -8.988189E-09  WA0      = 5.297397E-08   
+PA0      = -6.37277E-15   KETA     = 0.0417964      LKETA    = -2.020612E-09  
+A1       = 0              A2       = 0.4            AGS      = 0              
+B0       = 0              B1       = 0              VOFF     = -0.1404963     
+LVOFF    = 2.055931E-09   WVOFF    = 1.819046E-08   PVOFF    = -5.86181E-16   
+NFACTOR  = 1.3429912      CIT      = 0.0005002944   CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = 0.00025553     
+LETA0    = -2.23533E-11   WETA0    = -6.61066E-11   PETA0    = 3.108995E-17   
+ETAB     = -0.0005084992  LETAB    = -1.6E-11       DSUB     = 0              
+PCLM     = 0.747884       LPCLM    = 3.972342E-08   WPCLM    = 5.166692E-09   
+PPCLM    = 8.963698E-15   PDIBLC1  = 0              PDIBLC2  = 0.003490069    
+LPDIBLC2 = -4.23298E-11   WPDIBLC2 = 6.076211E-10   PPDIBLC2 = -7.30968E-17   
+PDIBLCB  = 0.3330078      DROUT    = 0              PSCBE1   = 7.37E+08       
+PSCBE2   = 1E-20          PVAG     = 0              DELTA    = 0.015          
+ALPHA0   = 1.54E-07       BETA0    = 20             KT1      = -0.2409952     
+LKT1     = -7.458401E-09  WKT1     = -6.310306E-09  PKT1     = 2.967737E-15   
+KT2      = -0.0286        AT       = 10000          UTE      = -1.04          
+UA1      = 3.99E-10       UB1      = -1.92352E-18   LUB1     = 9.707736E-26   
+WUB1     = 4.386947E-25   PUB1     = -5.2775E-32    UC1      = -1.01E-12      
+KT1L     = 0              PRT      = 0              HDIF     = hdifp          
+LDIF     = 6.5E-08        RSH      = 6.4            RS       = 0              
+RD       = 0              RSC      = 0              RDC      = 0              
+CJ       = cjp            MJ       = 0.40377        PB       = 0.82245        
+CJSW     = cjswp          MJSW     = 0.3932347      PBSW     = 0.82245        
+CJSWG    = cjgatep        MJSWG    = 0.3932347      PBSWG    = 0.82245        
+CTA      = 0.0009560416   CTP      = 0.0006629025   PTA      = 0.001925529    
+PTP      = 0.001925529    CGDO     = cgop           CGSO     = cgop           
+ACM      = 12             CAPMOD   = 0              NQSMOD   = 0              
+XTI      = 3              N        = 1              XPART    = 1              
+CF       = 0              TLEV     = 1              TLEVC    = 1              
+JS       = 1.42E-06       JSW      = 1E-11  
+AF       = 1.12           KF       = 5.965E-24              )
*
.MODEL p.10 PMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '1.206E-06-dxl' LMAX     = 2.1E-05        
+WMIN     = 1.8E-07        WMAX     = '5.8E-07-dxw'  XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxp           
+XJ       = 1.5E-07        NCH      = 9.3846E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 7.85E-09       WINT     = 1.08E-10       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '-0.4616587+dvthp' LVTH0= -3.337038E-08  WVTH0    = 3.21094E-09    
+PVTH0    = 3.280609E-15   K1       = 0.5855891      LK1      = 2.055622E-08   
+WK1      = -2.230487E-08  PK1      = 1.310022E-14   K2       = 0.009141911    
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 112195.5       LVSAT    = 0.008020908    
+WVSAT    = 3.79659E-06    PVSAT    = -3.78531E-11   UA       = 3.81E-11       
+UB       = 1.497352E-18   LUB      = -2.12361E-25   WUB      = -2.00543E-25   
+PUB      = 5.428137E-32   UC       = -2.165E-10     LUC      = -6.07406E-17   
+WUC      = -2.19948E-17   PUC      = 3.519333E-23   RDSW     = 735.8          
+PRWB     = 0              PRWG     = 0              WR       = 1              
+U0       = 0.008609013    LU0      = -8.80993E-10   WU0      = 6.482313E-11   
+PU0      = 2.169478E-17   A0       = 0.9544736      LA0      = 4.243582E-07   
+WA0      = 4.603485E-08   PA0      = -5.38746E-14   KETA     = 0.0528829      
+LKETA    = -3.380165E-08  WKETA    = -7.286643E-09  PKETA    = 8.527558E-15   
+A1       = 0              A2       = 0.4            AGS      = 0              
+B0       = 0              B1       = 0              VOFF     = -0.0958712     
+LVOFF    = -2.767994E-08  WVOFF    = -6.40548E-09   PVOFF    = 6.08376E-15    
+NFACTOR  = 1.3429912      CIT      = 0.0005002944   CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = 9.470114E-05   
+LETA0    = 1.325937E-10   ETAB     = 1.917983E-05   LETAB    = -3.61721E-10   
+DSUB     = 0              PCLM     = 0.1946854      LPCLM    = 7.318056E-07   
+PDIBLC1  = 0              PDIBLC2  = 3.453979E-05   LPDIBLC2 = 4.640778E-09   
+PDIBLCB  = 0.3330078      DROUT    = 0              PSCBE1   = 7.37E+08       
+PSCBE2   = 1E-20          PVAG     = 0              DELTA    = 0.015          
+ALPHA0   = 1.54E-07       BETA0    = 20             KT1      = -0.2368054     
+LKT1     = -4.517828E-08  WKT1     = 9.229715E-09   PKT1     = 1.788689E-15   
+KT2      = -0.0286        AT       = 10000          UTE      = -1.04          
+UA1      = 3.99E-10       UB1      = -8.189E-19     LUB1     = -2.98309E-25   
+UC1      = 8.795243E-12   LUC1     = -1.20772E-17   WUC1     = -5.64525E-18   
+PUC1     = 6.606636E-24   KT1L     = 0              PRT      = 0              
+HDIF     = hdifp          LDIF     = 6.5E-08        RSH      = 6.4            
+RS       = 0              RD       = 0              RSC      = 0              
+RDC      = 0              CJ       = cjp            MJ       = 0.40377        
+PB       = 0.82245        CJSW     = cjswp          MJSW     = 0.3932347      
+PBSW     = 0.82245        CJSWG    = cjgatep        MJSWG    = 0.3932347      
+PBSWG    = 0.82245        CTA      = 0.0009560416   CTP      = 0.0006629025   
+PTA      = 0.001925529    PTP      = 0.001925529    CGDO     = cgop           
+CGSO     = cgop           ACM      = 12             CAPMOD   = 0              
+NQSMOD   = 0              XTI      = 3              N        = 1              
+XPART    = 1              CF       = 0              TLEV     = 1              
+TLEVC    = 1              JS       = 1.42E-06       JSW      = 1E-11   
+AF       = 1.12           KF       = 5.965E-24             )
*
.MODEL p.11 PMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = '5.06E-07-dxl' LMAX     = '1.206E-06-dxl' 
+WMIN     = 1.8E-07        WMAX     = '5.8E-07-dxw'  XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxp           
+XJ       = 1.5E-07        NCH      = 9.3846E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 7.85E-09       WINT     = 1.08E-10       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '-0.4648413+dvthp' LVTH0= -2.964582E-08  WVTH0    = 2.474565E-10   
+PVTH0    = 6.748774E-15   K1       = 0.6049692      LK1      = -2.124381E-09  
+WK1      = -1.060919E-08  PK1      = -5.87234E-16   K2       = 0.009141911    
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 119132.7       LVSAT    = -9.768629E-05  
+WVSAT    = -4.772856E-05  PVSAT    = 2.244674E-11   UA       = 3.81E-11       
+UB       = 1.370495E-18   LUB      = -6.39003E-26   WUB      = -1.41859E-25   
+PUB      = -1.43965E-32   UC       = -2.14968E-10   LUC      = -6.25329E-17   
+WUC      = 4.493312E-18   PUC      = 4.194279E-24   RDSW     = 735.8          
+PRWB     = 0              PRWG     = 0              WR       = 1              
+U0       = 0.007759621    LU0      = 1.1305E-10     WU0      = 1.393676E-10   
+PU0      = -6.55446E-17   A0       = 1.28011        LA0      = 4.326599E-08   
+WA0      = -2.06037E-08   PA0      = 2.411251E-14   KETA     = 0.002229981    
+LKETA    = 2.547745E-08   WKETA    = 7.363222E-09   PKETA    = -8.61718E-15   
+A1       = 0              A2       = 0.4            AGS      = 0              
+B0       = 0              B1       = 0              VOFF     = -0.1280041     
+LVOFF    = 9.925268E-09   WVOFF    = -2.017962E-09  PVOFF    = 9.490475E-16   
+NFACTOR  = 1.3429912      CIT      = 0.0005002944   CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = 0.000208       
+ETAB     = -1.820601E-06  LETAB    = -3.37144E-10   WETAB    = -6.86241E-11   
+PETAB    = 8.031082E-17   DSUB     = 0              PCLM     = 0.7565356      
+LPCLM    = 7.427236E-08   WPCLM    = 1.570909E-08   PPCLM    = -1.83843E-14   
+PDIBLC1  = 0              PDIBLC2  = 0.003879066    LPDIBLC2 = 1.415294E-10   
+PDIBLCB  = 0.3330078      DROUT    = 0              PSCBE1   = 7.37E+08       
+PSCBE2   = 1E-20          PVAG     = 0              DELTA    = 0.015          
+ALPHA0   = 1.54E-07       BETA0    = 20             KT1      = -0.2744843     
+LKT1     = -1.082707E-09  WKT1     = 1.022173E-08   PKT1     = 6.277364E-16   
+KT2      = -0.0286        AT       = 10000          UTE      = -1.04          
+UA1      = 3.99E-10       UB1      = -8.83456E-19   LUB1     = -2.2276E-25    
+WUB1     = -7.91183E-26   PUB1     = 9.259213E-32   UC1      = -2.11405E-12   
+LUC1     = 6.898978E-19   WUC1     = 1.413539E-19   PUC1     = -1.65426E-25   
+KT1L     = 0              PRT      = 0              HDIF     = hdifp          
+LDIF     = 6.5E-08        RSH      = 6.4            RS       = 0              
+RD       = 0              RSC      = 0              RDC      = 0              
+CJ       = cjp            MJ       = 0.40377        PB       = 0.82245        
+CJSW     = cjswp          MJSW     = 0.3932347      PBSW     = 0.82245        
+CJSWG    = cjgatep        MJSWG    = 0.3932347      PBSWG    = 0.82245        
+CTA      = 0.0009560416   CTP      = 0.0006629025   PTA      = 0.001925529    
+PTP      = 0.001925529    CGDO     = cgop           CGSO     = cgop           
+ACM      = 12             CAPMOD   = 0              NQSMOD   = 0              
+XTI      = 3              N        = 1              XPART    = 1              
+CF       = 0              TLEV     = 1              TLEVC    = 1              
+JS       = 1.42E-06       JSW      = 1E-11      
+AF       = 1.12           KF       = 5.965E-24          )
*
.MODEL p.12 PMOS (       LEVEL    = 49             
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1              
+VERSION  = 3.1            LMIN     = 1.5E-07        LMAX     = '5.06E-07-dxl' 
+WMIN     = 1.8E-07        WMAX     = '5.8E-07-dxw'  XL       = '-2E-8+dxl'    
+XW       = '0+dxw'        TNOM     = 25             TOX      = toxp           
+XJ       = 1.5E-07        NCH      = 9.3846E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 7.85E-09       WINT     = 1.08E-10       MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = '-0.5237184+dvthp' LVTH0= -1.955907E-09  WVTH0    = 1.922075E-08   
+PVTH0    = -2.17436E-15   K1       = 0.5779728      LK1      = 1.057206E-08   
+WK1      = -6.556705E-09  PK1      = -2.49312E-15   K2       = 0.009141911    
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 124058.6       LVSAT    = -0.002414345   
+WVSAT    = -0.001795661   PVSAT    = 8.444991E-10   UA       = 3.811031E-11   
+LUA      = -4.84951E-21   UB       = 1.165926E-18   LUB      = 3.230846E-26   
+WUB      = -1.16768E-25   PUB      = -2.61968E-32   UC       = -4.32146E-10   
+LUC      = 3.960576E-17   WUC      = 4.809453E-17   PUC      = -1.63114E-23   
+RDSW     = 735.8          PRWB     = 0              PRWG     = 0              
+WR       = 1              U0       = 0.007889003    LU0      = 5.220185E-11   
+WU0      = 5.537287E-11   PU0      = -2.60419E-17   A0       = 1.5120552      
+LA0      = -6.581781E-08  WA0      = -2.584211E-08  PA0      = 2.657614E-14   
+KETA     = 0.0671963      LKETA    = -5.076218E-09  WKETA    = -1.472645E-08  
+PKETA    = 1.771591E-15   A1       = 0              A2       = 0.4            
+AGS      = 0              B0       = 0              B1       = 0              
+VOFF     = -0.1091186     LVOFF    = 1.043421E-09   PVOFF    = 8.559256E-19   
+NFACTOR  = 1.3429912      CIT      = 0.0005002944   CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = 0.0001415105   
+LETA0    = 3.127E-11      ETAB     = -0.0007452223  LETAB    = 1.24778E-11    
+WETAB    = 1.372483E-10   PETAB    = -1.6511E-17    DSUB     = 0              
+PCLM     = 0.8444108      LPCLM    = 3.294464E-08   WPCLM    = -5.079799E-08  
+PPCLM    = 1.289393E-14   PDIBLC1  = 0              PDIBLC2  = 0.004604676    
+LPDIBLC2 = -1.99725E-10   WPDIBLC2 = -3.86105E-11   PPDIBLC2 = 1.815852E-17   
+PDIBLCB  = 0.3330078      DROUT    = 0              PSCBE1   = 7.37E+08       
+PSCBE2   = 1E-20          PVAG     = 0              DELTA    = 0.015          
+ALPHA0   = 1.54E-07       BETA0    = 20             KT1      = -0.268747      
+LKT1     = -3.780911E-09  WKT1     = 9.779773E-09   PKT1     = 8.355876E-16   
+KT2      = -0.0286        AT       = 10000          UTE      = -1.04          
+UA1      = 3.99E-10       UB1      = -1.43979E-18   LUB1     = 3.88848E-26    
+WUB1     = 1.582366E-25   PUB1     = -1.90359E-32   UC1      = -5.22391E-13   
+LUC1     = -5.86593E-20   WUC1     = -2.82708E-19   PUC1     = 3.400975E-26   
+KT1L     = 0              PRT      = 0              HDIF     = hdifp          
+LDIF     = 6.5E-08        RSH      = 6.4            RS       = 0              
+RD       = 0              RSC      = 0              RDC      = 0              
+CJ       = cjp            MJ       = 0.40377        PB       = 0.82245        
+CJSW     = cjswp          MJSW     = 0.3932347      PBSW     = 0.82245        
+CJSWG    = cjgatep        MJSWG    = 0.3932347      PBSWG    = 0.82245        
+CTA      = 0.0009560416   CTP      = 0.0006629025   PTA      = 0.001925529    
+PTP      = 0.001925529    CGDO     = cgop           CGSO     = cgop           
+ACM      = 12             CAPMOD   = 0              NQSMOD   = 0              
+XTI      = 3              N        = 1              XPART    = 1              
+CF       = 0              TLEV     = 1              TLEVC    = 1              
+JS       = 1.42E-06       JSW      = 1E-11       
+AF       = 1.12           KF       = 5.965E-24         )
*
.ENDL MOS

***************************************************************
*                                                             *
*                 3.3V DEVICES MODEL                          *
*                                                             *
***************************************************************
*
.LIB MOS_3V
*
***************************************************************
*               3.3V NMOS DEVICES MODEL                       *
***************************************************************
*
.MODEL nch3.1           NMOS   (                    LMIN     = '1.2E-06-dxl3'  
+LMAX    = 21E-05         WMIN     = '1.0076E-05-dxw3'   WMAX     = 0.000201
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn3          XJ       = 1.6E-07        NCH      = 2.97E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 9.45E-09       LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.15E-08       
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifn3         
+RSH     = 6.8            RD       = 0              RS       = 0              
+VTH0    = '0.5891622+dvthn3' LVTH0    = 7.38249E-08    WVTH0    = -7.938074E-07  
+PVTH0   = 2.719448E-13   K1       = 0.8279679      LK1      = -5.015063E-09  
+WK1     = 5.017706E-07   PK1      = -4.837188E-13  K2       = -0.04046488    
+LK2     = -2.150319E-08  WK2      = -1.488408E-07  PK2      = 2.157415E-13   
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 100000         UA       = -8.397954E-10  
+LUA     = -2.224685E-17  WUA      = -1.917094E-15  PUA      = 2.22542E-21    
+UB      = 2.849445E-18   LUB      = 7.845232E-25   WUB      = -7.347713E-24  
+PUB     = -5.431645E-30  UC       = 1.10577E-10    LUC      = 6.535553E-17   
+WUC     = -7.340631E-16  PUC      = -1.094535E-22  RDSW     = 393            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.03979599     LU0      = 6.13097E-09    WU0      = -9.831601E-08  
+PU0     = 2.391358E-14   A0       = 0.3586054      LA0      = 2.93176E-08    
+WA0     = 1.152327E-05   PA0      = -2.932734E-12  KETA     = -0.003677651   
+LKETA   = -2.676358E-08  WKETA    = -3.520183E-07  PKETA    = 2.68519E-13    
+A1      = 0              A2       = 1              AGS      = 0.1261305      
+LAGS    = 1.004065E-07   WAGS     = 1.440745E-06   PAGS     = 1.689856E-14   
+B0      = 0              B1       = 0              VOFF     = -0.06419823    
+LVOFF   = -6.801697E-08  WVOFF    = 6.118346E-08   PVOFF    = 6.824144E-13   
+NFACTOR = 0.5111478      WNFACTOR = -1.115146E-06  CIT      = 0.001716296    
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = 9.208927E-05   LETA0    = -1.104727E-12  WETA0    = 2.41152E-10    
+PETA0   = 1.105089E-16   ETAB     = -3.5E-06       DSUB     = 0              
+PCLM    = 0.2210362      LPCLM    = 1.937685E-07   WPCLM    = -1.778336E-06  
+PPCLM   = 1.760549E-12   PDIBLC1  = 0              PDIBLC2  = 3.240661E-06   
+LPDIBLC2= 6.365217E-09   WPDIBLC2 = 1.384538E-08   PPDIBLC2 = -1.956181E-14  
+PDIBLCB = -0.1387533     DROUT    = 0              PSCBE1   = 3.615613E+08   
+PSCBE2  = 2.282738E-06   PVAG     = 0              DELTA    = 0.01           
+ALPHA0  = 1.84E-06       BETA0    = 22.4112        KT1      = -0.295         
+KT2     = -0.02722041    AT       = 35000          UTE      = -1.17          
+UA1     = 1.75E-09       UB1      = -7.799954E-19  UC1      = 9.971474E-11   
+KT1L    = 0              PRT      = 0             
+CJ       = cjn3  
+MJ       = 0.3436375      PB       = 0.854555       CJSW     = cjswn3
+MJSW     = 0.01           PBSW     = 0.854555       CJSWG    = cjgaten3
+MJSWG    = 0.1275785      PBSWG    = 0.854555       CTA      = 8.83679E-4
+CTP      = 1.20092E-4     PTA      = 1.83078E-3     PTP      = 1.83078E-3
+CGDO     = cgon3          CGSO     = cgon3          JS       = 1E-05 
+JSW      = 5.3E-11        NLEV     = 3              AF       = 1.1     
+KF       = 2E-23          CAPMOD   = 0              XTI      = 3     
+N        = 1              NQSMOD   = 0              XPART    = 1     
+CF       = 0              TLEV     = 1              TLEVC    = 1    
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     )

.MODEL nch3.2           NMOS   (                    LMIN     = '5.0E-07-dxl3'  
+LMAX    = '1.2E-06-dxl3' WMIN     = '1.0076E-05-dxw3'   WMAX     = 0.000201
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn3          XJ       = 1.6E-07        NCH      = 2.97E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 9.45E-09       LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.15E-08       
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifn3         
+RSH     = 6.8            RD       = 0              RS       = 0              
+VTH0    = '0.6327373+dvthn3' LVTH0    = 2.322986E-08   WVTH0    = -6.90231E-07   
+PVTH0   = 1.516824E-13   K1       = 0.8258397      LK1      = -2.54402E-09   
+WK1     = -1.340101E-07  PK1      = 2.544861E-13   K2       = -0.04111454    
+LK2     = -2.074887E-08  WK2      = 1.424869E-07   PK2      = -1.225191E-13  
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 100000         UA       = -9.259452E-10  
+LUA     = 7.778166E-17   WUA      = -9.402445E-16  PUA      = 1.0912E-21     
+UB      = 3.376049E-18   LUB      = 1.730832E-25   WUB      = -1.223646E-23  
+PUB     = 2.446824E-31   UC       = 1.456645E-10   LUC      = 2.461543E-17   
+WUC     = -9.295381E-16  PUC      = 1.175126E-22   RDSW     = 393            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.04575227     LU0      = -7.848577E-10  WU0      = -1.453388E-07  
+PU0     = 7.851168E-14   A0       = 0.3485903      LA0      = 4.094617E-08   
+WA0     = 1.25251E-05    PA0      = -4.095969E-12  KETA     = -0.02476404    
+LKETA   = -2.280168E-09  WKETA    = -3.172005E-07  PKETA    = 2.28092E-13    
+A1      = 0              A2       = 1              AGS      = 0.2512295      
+LAGS    = -4.484595E-08  WAGS     = 3.354407E-06   PAGS     = -2.205055E-12  
+B0      = 0              B1       = 0              VOFF     = -0.124913      
+LVOFF   = 2.478989E-09   WVOFF    = 8.624884E-07   PVOFF    = -2.479807E-13  
+NFACTOR = 0.5111478      WNFACTOR = -1.115146E-06  CIT      = 0.001716296    
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = 2.543871E-05   LETA0    = 7.628324E-11   WETA0    = 1.194811E-09   
+PETA0   = -9.967848E-16  ETAB     = 0.0002374408   LETAB    = -2.797564E-10  
+WETAB   = -1.270058E-09  PETAB    = 1.474665E-15   DSUB     = 0              
+PCLM    = 0.2850711      LPCLM    = 1.194175E-07   WPCLM    = -2.668119E-06  
+PPCLM   = 2.793675E-12   PDIBLC1  = 0              PDIBLC2  = 0.0010189      
+LPDIBLC2= 5.185935E-09   WPDIBLC2 = 5.943696E-09   PPDIBLC2 = -1.038716E-14  
+PDIBLCB = -0.1387533     DROUT    = 0              PSCBE1   = 3.615613E+08   
+PSCBE2  = 2.282738E-06   PVAG     = 0              DELTA    = 0.01           
+ALPHA0  = 1.84E-06       BETA0    = 22.4112        KT1      = -0.295         
+KT2     = -0.02722041    AT       = 50534.37       LAT      = -0.01803696    
+WAT     = 0.009365655    PAT      = -1.087448E-08  UTE      = -1.17          
+UA1     = 1.419656E-09   LUA1     = 3.835629E-16   WUA1     = 3.314346E-15   
+PUA1    = -3.848287E-21  UB1      = 2.167518E-19   LUB1     = -1.157323E-24  
+WUB1    = -1.000037E-23  PUB1     = 1.161143E-29   UC1      = 1.361864E-10   
+LUC1    = -4.234726E-17  WUC1     = -3.659204E-16  PUC1     = 4.248701E-22   
+KT1L    = 0              PRT      = 0              
+CJ       = cjn3  
+MJ       = 0.3436375      PB       = 0.854555       CJSW     = cjswn3
+MJSW     = 0.01           PBSW     = 0.854555       CJSWG    = cjgaten3
+MJSWG    = 0.1275785      PBSWG    = 0.854555       CTA      = 8.83679E-4
+CTP      = 1.20092E-4     PTA      = 1.83078E-3     PTP      = 1.83078E-3
+CGDO     = cgon3          CGSO     = cgon3          JS       = 1E-05 
+JSW      = 5.3E-11        NLEV     = 3              AF       = 1.1     
+KF       = 2E-23          CAPMOD   = 0              XTI      = 3     
+N        = 1              NQSMOD   = 0              XPART    = 1     
+CF       = 0              TLEV     = 1              TLEVC    = 1    
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     )

.MODEL nch3.3           NMOS   (                    LMIN     = 3.5E-07    
+LMAX    = '5.0E-07-dxl3' WMIN     = '1.0076E-05-dxw3'   WMAX     = 0.000201
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn3          XJ       = 1.6E-07        NCH      = 2.97E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 9.45E-09       LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.15E-08       
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifn3         
+RSH     = 6.8            RD       = 0              RS       = 0              
+VTH0    = '0.7662141+dvthn3' LVTH0    = -3.831627E-08  WVTH0    = -1.952418E-06  
+PVTH0   = 7.336765E-13   K1       = 0.9671541      LK1      = -6.770409E-08  
+WK1     = 1.284627E-06   PK1      = -3.996475E-13  K2       = -0.03548093    
+LK2     = -2.334652E-08  WK2      = -3.787894E-07  PK2      = 1.178414E-13   
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 98843.98       LVSAT    = 0.0005330428   
+WVSAT   = 0.1156406      PVSAT    = -5.332189E-08  UA       = -1.286773E-09  
+LUA     = 2.441594E-16   WUA      = 3.080459E-15   PUA      = -7.627461E-22  
+UB      = 2.531035E-18   LUB      = 5.627193E-25   WUB      = -7.471733E-25  
+PUB     = -5.053029E-30  UC       = 2.412852E-10   LUC      = -1.947527E-17  
+WUC     = -5.959578E-18  PUC      = -3.083495E-22  RDSW     = 393            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.03410441     LU0      = 4.585969E-09   WU0      = 1.053909E-07   
+PU0     = -3.709979E-14  A0       = 0.4373914      WA0      = 3.642066E-06   
+KETA    = 0.004868983    LKETA    = -1.594395E-08  WKETA    = -1.694532E-07  
+PKETA   = 1.599657E-13   A1       = 0              A2       = 1              
+AGS     = -0.5534782     LAGS     = 3.262048E-07   WAGS     = 5.670081E-06   
+PAGS    = -3.272812E-12  B0       = 0              B1       = 0              
+VOFF    = -0.1262686     LVOFF    = 3.104016E-09   WVOFF    = 9.980844E-07   
+PVOFF   = -3.105041E-13  NFACTOR  = 0.5342683      LNFACTOR = -1.066085E-08  
+WNFACTOR= -3.427958E-06  PNFACTOR = 1.066438E-12   CIT      = 0.001716296    
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = 0.0001947677   LETA0    = -1.794379E-12  WETA0    = -2.972383E-09  
+PETA0   = 9.247083E-16   ETAB     = 0.0002846642   LETAB    = -3.015311E-10  
+WETAB   = 9.306697E-09   PETAB    = -3.402277E-15  DSUB     = 0              
+PCLM    = 0.1680058      LPCLM    = 1.733963E-07   WPCLM    = 1.045407E-06   
+PPCLM   = 1.081369E-12   PDIBLC1  = 0              PDIBLC2  = -0.01338962    
+LPDIBLC2= 1.18297E-08    WPDIBLC2 = 3.362581E-08   PPDIBLC2 = -2.315139E-14  
+PDIBLCB = -0.1387533     DROUT    = 0              PSCBE1   = 3.615613E+08   
+PSCBE2  = 2.282738E-06   PVAG     = 0              DELTA    = 0.01           
+ALPHA0  = 1.84E-06       BETA0    = 22.4112        KT1      = -0.295         
+KT2     = -0.02722041    AT       = -42117.84      LAT      = 0.02468498     
+WAT     = 0.418856       PAT      = -1.996905E-07  UTE      = -1.17          
+UA1     = 3.291608E-09   LUA1     = -4.795941E-16  WUA1     = -1.546695E-14  
+PUA1    = 4.811768E-21   UB1      = -5.431484E-18  LUB1     = 1.447078E-24   
+WUB1    = 4.666838E-23   PUB1     = -1.451854E-29  UC1      = -7.048645E-11  
+LUC1    = 5.294959E-17   WUC1     = 1.707629E-15   PUC1     = -5.312433E-22  
+KT1L    = 0              PRT      = 0             
+CJ       = cjn3  
+MJ       = 0.3436375      PB       = 0.854555       CJSW     = cjswn3
+MJSW     = 0.01           PBSW     = 0.854555       CJSWG    = cjgaten3
+MJSWG    = 0.1275785      PBSWG    = 0.854555       CTA      = 8.83679E-4
+CTP      = 1.20092E-4     PTA      = 1.83078E-3     PTP      = 1.83078E-3
+CGDO     = cgon3          CGSO     = cgon3          JS       = 1E-05 
+JSW      = 5.3E-11        NLEV     = 3              AF       = 1.1     
+KF       = 2E-23          CAPMOD   = 0              XTI      = 3     
+N        = 1              NQSMOD   = 0              XPART    = 1     
+CF       = 0              TLEV     = 1              TLEVC    = 1    
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     )

.MODEL nch3.4           NMOS   (                    LMIN     = '1.2E-06-dxl3'   
+LMAX    = 21E-06        WMIN     = '1.3E-06-dxw3' WMAX     = '1.0076E-05-dxw3' 
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn3          XJ       = 1.6E-07        NCH      = 2.97E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 9.45E-09       LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.15E-08       
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifn3         
+RSH     = 6.8            RD       = 0              RS       = 0              
+VTH0    = '0.5121657+dvthn3' LVTH0    = 9.128267E-08   WVTH0    = -2.130088E-08  
+PVTH0   = 9.679093E-14   K1       = 0.8906361      LK1      = -6.085175E-08  
+WK1     = -1.269797E-07  PK1      = 7.649065E-14   K2       = -0.05640073    
+WK2     = 1.104367E-08   K3       = 0              DVT0     = 0              
+DVT1    = 0              DVT2     = 0              DVT0W    = 0              
+DVT1W   = 0              DVT2W    = 0              NLX      = 0              
+W0      = 0              K3B      = 0              VSAT     = 100000         
+UA      = -1.065353E-09  LUA      = 1.859222E-16   WUA      = 3.459198E-16   
+PUA     = 1.368602E-22   UB       = 1.883102E-18   LUB      = 4.948721E-25   
+WUB     = 2.347602E-24   PUB      = -2.525574E-30  UC       = 2.910442E-11   
+LUC     = 5.85549E-17    WUC      = 8.335103E-17   PUC      = -4.122286E-23  
+RDSW    = 393            PRWB     = 0              PRWG     = 0              
+WR      = 1              U0       = 0.02814049     LU0      = 9.734002E-09   
+WU0     = 1.862366E-08   PU0      = -1.223564E-14  A0       = 1.596905       
+LA0     = -3.006598E-07  WA0      = -9.005968E-07  PA0      = 3.779294E-13   
+KETA    = -0.03910942    WKETA    = 3.468585E-09   A1       = 0              
+A2      = 1              AGS      = 0.3038035      LAGS     = 6.362774E-08   
+WAGS    = -3.418488E-07  PAGS     = 3.858998E-13   B0       = 0              
+B1      = 0              VOFF     = -0.04976521    WVOFF    = -8.362291E-08  
+NFACTOR = 0.3856768      WNFACTOR = 1.437042E-07   CIT      = 0.001716296    
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = 0.0001300509   LETA0    = 1.132922E-11   WETA0    = -1.397166E-10  
+PETA0   = -1.424083E-17  ETAB     = -3.067441E-06  WETAB    = -4.339867E-12  
+DSUB    = 0              PCLM     = 0.01767791     LPCLM    = 2.565218E-07   
+WPCLM   = 2.619569E-07   PPCLM    = 1.130944E-12   PDIBLC1  = 0              
+PDIBLC2 = 0.001117276    LPDIBLC2 = 5.047906E-09   WPDIBLC2 = 2.668264E-09   
+PPDIBLC2= -6.345217E-15  PDIBLCB  = -0.1585278     WPDIBLCB = 1.98397E-07    
+DROUT   = 0              PSCBE1   = 3.615613E+08   PSCBE2   = 2.282738E-06   
+PVAG    = 0              DELTA    = 0.01           ALPHA0   = 1.84E-06       
+BETA0   = 22.4112        KT1      = -0.295         KT2      = -0.02722041    
+AT      = 35000          UTE      = -1.17          UA1      = 1.75E-09       
+UB1     = -7.872184E-19  LUB1     = 7.194969E-26   WUB1     = 7.246903E-26   
+PUB1    = -7.218711E-31  UC1      = 9.971447E-11   LUC1     = 2.775762E-21   
+WUC1    = 2.795797E-21   PUC1     = -2.784921E-26  KT1L     = 0              
+PRT     = 0            
+CJ       = cjn3  
+MJ       = 0.3436375      PB       = 0.854555       CJSW     = cjswn3
+MJSW     = 0.01           PBSW     = 0.854555       CJSWG    = cjgaten3
+MJSWG    = 0.1275785      PBSWG    = 0.854555       CTA      = 8.83679E-4
+CTP      = 1.20092E-4     PTA      = 1.83078E-3     PTP      = 1.83078E-3
+CGDO     = cgon3          CGSO     = cgon3          JS       = 1E-05 
+JSW      = 5.3E-11        NLEV     = 3              AF       = 1.1     
+KF       = 2E-23          CAPMOD   = 0              XTI      = 3     
+N        = 1              NQSMOD   = 0              XPART    = 1     
+CF       = 0              TLEV     = 1              TLEVC    = 1    
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     )

.MODEL nch3.5           NMOS   (                    LMIN     = '5.0E-07-dxl3'   
+LMAX    = '1.2E-06-dxl3' WMIN     = '1.3E-06-dxw3' WMAX     = '1.0076E-05-dxw3' 
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn3          XJ       = 1.6E-07        NCH      = 2.97E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 9.45E-09       LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.15E-08       
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifn3         
+RSH     = 6.8            RD       = 0              RS       = 0              
+VTH0    = '0.553025+dvthn3' LVTH0    = 4.384087E-08   WVTH0    = 1.095224E-07   
+PVTH0   = -5.510798E-14  K1       = 0.8187082      LK1      = 2.266376E-08   
+WK1     = -6.245966E-08  PK1      = 1.576399E-15   K2       = -0.0277705     
+LK2     = -3.324257E-08  WK2      = 8.606178E-09   PK2      = 2.830174E-15   
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 100000         UA       = -1.099253E-09  
+LUA     = 2.252834E-16   WUA      = 7.985467E-16   PUA      = -3.886847E-22  
+UB      = 2.124079E-18   LUB      = 2.150741E-25   WUB      = 3.245525E-25   
+PUB     = -1.766121E-31  UC       = 4.397742E-11   LUC      = 4.128586E-17   
+WUC     = 9.068802E-17   PUC      = -4.974184E-23  RDSW     = 393            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.02959178     LU0      = 8.048906E-09   WU0      = 1.679939E-08   
+PU0     = -1.011748E-14  A0       = 1.742404       LA0      = -4.695985E-07  
+WA0     = -1.45903E-06   PA0      = 1.026326E-12   KETA     = -0.0606186     
+LKETA   = 2.497431E-08   WKETA    = 4.252825E-08   PKETA    = -4.535216E-14  
+A1      = 0              A2       = 1              AGS      = 0.6403223      
+LAGS    = -3.271041E-07  WAGS     = -5.493606E-07  PAGS     = 6.268417E-13   
+B0      = 0              B1       = 0              VOFF     = -0.0278699     
+LVOFF   = -2.542264E-08  WVOFF    = -1.111453E-07  PVOFF    = 3.195625E-14   
+NFACTOR = 0.3856769      WNFACTOR = 1.437042E-07   CIT      = 0.001716296    
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = 0.0002290774   LETA0    = -1.036505E-10  WETA0    = -8.482952E-10  
+PETA0   = 8.084896E-16   ETAB     = 0.0001094329   LETAB    = -1.306242E-10  
+WETAB   = 1.424567E-11   PETAB    = -2.157968E-17  DSUB     = 0              
+PCLM    = -0.1387256     LPCLM    = 4.38122E-07    WPCLM    = 1.583833E-06   
+PPCLM   = -4.038854E-13  PDIBLC1  = 0              PDIBLC2  = 0.001683584    
+LPDIBLC2= 4.390365E-09   WPDIBLC2 = -7.25075E-10   PPDIBLC2 = -2.40521E-15   
+PDIBLCB = -0.1715535     LPDIBLCB = 1.512415E-08   WPDIBLCB = 3.290839E-07   
+PPDIBLCB= -1.517406E-13  DROUT    = 0              PSCBE1   = 3.615613E+08   
+PSCBE2  = 2.282738E-06   PVAG     = 0              DELTA    = 0.01           
+ALPHA0  = 1.84E-06       BETA0    = 22.4112        KT1      = -0.295         
+KT2     = -0.02722041    AT       = 52340.58       LAT      = -0.02013415    
+WAT     = -0.008756055   PAT      = 1.016665E-08   UTE      = -1.17          
+UA1     = 1.75E-09       UB1      = -7.481217E-19  LUB1     = 2.655448E-26   
+WUB1    = -3.197883E-25  PUB1     = -2.664211E-31  UC1      = 9.280157E-11   
+LUC1    = 8.02934E-18    WUC1     = 6.935988E-17   PUC1     = -8.055834E-23  
+KT1L    = 0              PRT      = 0               
+CJ       = cjn3  
+MJ       = 0.3436375      PB       = 0.854555       CJSW     = cjswn3
+MJSW     = 0.01           PBSW     = 0.854555       CJSWG    = cjgaten3
+MJSWG    = 0.1275785      PBSWG    = 0.854555       CTA      = 8.83679E-4
+CTP      = 1.20092E-4     PTA      = 1.83078E-3     PTP      = 1.83078E-3
+CGDO     = cgon3          CGSO     = cgon3          JS       = 1E-05 
+JSW      = 5.3E-11        NLEV     = 3              AF       = 1.1     
+KF       = 2E-23          CAPMOD   = 0              XTI      = 3     
+N        = 1              NQSMOD   = 0              XPART    = 1     
+CF       = 0              TLEV     = 1              TLEVC    = 1    
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     )

.MODEL nch3.6           NMOS   (                    LMIN     = 3.5E-07   
+LMAX    = '5.0E-07-dxl3' WMIN     = '1.3E-06-dxw3' WMAX     = '1.0076E-05-dxw3'
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn3          XJ       = 1.6E-07        NCH      = 2.97E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 9.45E-09       LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.15E-08       
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifn3         
+RSH     = 6.8            RD       = 0              RS       = 0              
+VTH0    = '0.5718063+dvthn3' LVTH0    = 3.518086E-08   WVTH0    = -1.923733E-09  
+PVTH0   = -3.720166E-15  K1       = 1.12288        LK1      = -1.1759E-07    
+WK1     = -2.777743E-07  PK1      = 1.00858E-13    K2       = -0.07805391    
+LK2     = -1.005688E-08  WK2      = 4.834535E-08   PK2      = -1.549356E-14  
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 111855.3       LVSAT    = -0.005466484   
+WVSAT   = -0.01490212    PVSAT    = 6.87137E-09    UA       = -8.934787E-10  
+LUA     = 1.304011E-16   WUA      = -8.654668E-16  PUA      = 3.785918E-22   
+UB      = 2.341702E-18   LUB      = 1.147282E-25   WUB      = 1.152407E-24   
+PUB     = -5.583356E-31  UC       = 2.502055E-10   LUC      = -5.38059E-17   
+WUC     = -9.545744E-17  PUC      = 3.608982E-23   RDSW     = 393            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.04561116     LU0      = 6.623729E-10   WU0      = -1.005625E-08  
+PU0     = 2.265656E-15   A0       = 0.7239732      WA0      = 7.667912E-07   
+KETA    = -0.004658913   LKETA    = -8.287002E-10  WKETA    = -7.38598E-08   
+PKETA   = 8.31436E-15    A1       = 0              A2       = 1              
+AGS     = -0.0802956     LAGS     = 5.172733E-09   WAGS     = 9.226408E-07   
+PAGS    = -5.18981E-14   B0       = 0              B1       = 0              
+VOFF    = -0.01396882    LVOFF    = -3.183243E-08  WVOFF    = -1.28619E-07   
+PVOFF   = 4.001337E-14   NFACTOR  = 0.1485707      LNFACTOR = 1.093297E-07   
+WNFACTOR= 4.417467E-07   PNFACTOR = -1.374274E-13  CIT      = 0.001716296    
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = 0.0006443943   LETA0    = -2.951534E-10  WETA0    = -7.483504E-09  
+PETA0   = 3.867985E-15   ETAB     = 0.001117313    LETAB    = -5.953578E-10  
+WETAB   = 9.527317E-10   PETAB    = -4.543157E-16  DSUB     = 0              
+PCLM    = 0.1596573      LPCLM    = 3.005376E-07   WPCLM    = 1.129168E-06   
+PPCLM   = -1.942397E-13  PDIBLC1  = 0              PDIBLC2  = -0.0124038     
+LPDIBLC2= 1.088606E-08   WPDIBLC2 = 2.373504E-08   PPDIBLC2 = -1.368377E-14  
+PDIBLCB = -0.1387533     DROUT    = 0              PSCBE1   = 3.615613E+08   
+PSCBE2  = 2.282738E-06   PVAG     = 0              DELTA    = 0.01           
+ALPHA0  = 1.84E-06       BETA0    = 22.4112        KT1      = -0.295         
+KT2     = -0.02722041    AT       = -2140.485      LAT      = 0.004987071    
+WAT     = 0.01776327     PAT      = -2.061411E-09  UTE      = -1.17          
+UA1     = 1.75E-09       UB1      = -6.705104E-19  LUB1     = -9.232127E-27  
+WUB1    = -1.098464E-24  PUB1     = 9.262609E-32   UC1      = 1.246285E-10   
+LUC1    = -6.646036E-18  WUC1     = -2.499594E-16  PUC1     = 6.667977E-23   
+KT1L    = 0              PRT      = 0             
+CJ       = cjn3  
+MJ       = 0.3436375      PB       = 0.854555       CJSW     = cjswn3
+MJSW     = 0.01           PBSW     = 0.854555       CJSWG    = cjgaten3
+MJSWG    = 0.1275785      PBSWG    = 0.854555       CTA      = 8.83679E-4
+CTP      = 1.20092E-4     PTA      = 1.83078E-3     PTP      = 1.83078E-3
+CGDO     = cgon3          CGSO     = cgon3          JS       = 1E-05 
+JSW      = 5.3E-11        NLEV     = 3              AF       = 1.1     
+KF       = 2E-23          CAPMOD   = 0              XTI      = 3     
+N        = 1              NQSMOD   = 0              XPART    = 1     
+CF       = 0              TLEV     = 1              TLEVC    = 1    
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     )

.MODEL nch3.7           NMOS   (                    LMIN     = '1.2E-06-dxl3'   
+LMAX    = 21E-06         WMIN     = '5.8E-07-dxw3'   WMAX     = '1.3E-06-dxw3'  
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn3          XJ       = 1.6E-07        NCH      = 2.97E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 9.45E-09       LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.15E-08       
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifn3         
+RSH     = 6.8            RD       = 0              RS       = 0              
+VTH0    = '0.4457419+dvthn3' LVTH0    = 2.556566E-07   WVTH0    = 6.219383E-08   
+PVTH0   = -1.098271E-13  K1       = 0.7425936      LK1      = 2.951743E-08   
+WK1     = 5.910967E-08   PK1      = -3.710341E-14  K2       = -0.04165952    
+WK2     = -7.486037E-09  K3       = 0              DVT0     = 0              
+DVT1    = 0              DVT2     = 0              DVT0W    = 0              
+DVT1W   = 0              DVT2W    = 0              NLX      = 0              
+W0      = 0              K3B      = 0              VSAT     = 100000         
+UA      = -1.45618E-09   LUA      = 6.921075E-16   WUA      = 8.3719E-16     
+PUA     = -4.994147E-22  UB       = 5.398793E-18   LUB      = -2.80199E-24   
+WUB     = -2.071622E-24  PUB      = 1.618581E-30   UC       = 1.096797E-10   
+LUC     = 3.4955E-17     WUC      = -1.793215E-17  PUC      = -1.155778E-23  
+RDSW    = 393            PRWB     = 0              PRWG     = 0              
+WR      = 1              U0       = 0.04103415     WU0      = 2.416326E-09   
+A0      = 0.5421673      WA0      = 4.252088E-07   KETA     = -0.05592195    
+LKETA   = 3.267951E-08   WKETA    = 2.460194E-08   PKETA    = -4.107814E-14  
+A1      = 0              A2       = 1              AGS      = -0.1465015     
+LAGS    = 5.11444E-07    WAGS     = 2.241846E-07   PAGS     = -1.770051E-13  
+B0      = 0              B1       = 0              VOFF     = -0.1213842     
+LVOFF   = -5.810913E-09  WVOFF    = 6.402123E-09   PVOFF    = 7.304317E-15   
+NFACTOR = 0.4269702      LNFACTOR = -2.940744E-07  WNFACTOR = 9.179846E-08   
+PNFACTOR= 3.696515E-13   CIT      = 0.001716296    CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = 1.9422E-05     
+WETA0   = -6.561563E-13  ETAB     = -3.924501E-06  WETAB    = -3.262543E-12  
+DSUB    = 0              PCLM     = 0.3328769      LPCLM    = 1.485773E-06   
+WPCLM   = -1.34248E-07   PPCLM    = -4.142243E-13  PDIBLC1  = 0              
+PDIBLC2 = 0.00554455     LPDIBLC2 = -5.480312E-09  WPDIBLC2 = -2.89682E-09   
+PPDIBLC2= 6.888753E-15   PDIBLCB  = 0.1022752      WPDIBLCB = -1.294323E-07  
+DROUT   = 0              PSCBE1   = 3.615613E+08   PSCBE2   = 2.282738E-06   
+PVAG    = 0              DELTA    = 0.01           ALPHA0   = 1.84E-06       
+BETA0   = 22.4112        KT1      = -0.295         KT2      = -0.02722041    
+AT      = 44136.46       WAT      = -0.01148453    UTE      = -1.17          
+UA1     = 1.75E-09       UB1      = -4.246815E-19  LUB1     = -8.769866E-25  
+WUB1    = -3.8324E-25    PUB1     = 4.709418E-31   UC1      = 1.433417E-10   
+LUC1    = -3.381752E-20  WUC1     = -5.483668E-17  PUC1     = 1.816001E-26   
+KT1L    = 0              PRT      = 0             
+CJ       = cjn3  
+MJ       = 0.3436375      PB       = 0.854555       CJSW     = cjswn3
+MJSW     = 0.01           PBSW     = 0.854555       CJSWG    = cjgaten3
+MJSWG    = 0.1275785      PBSWG    = 0.854555       CTA      = 8.83679E-4
+CTP      = 1.20092E-4     PTA      = 1.83078E-3     PTP      = 1.83078E-3
+CGDO     = cgon3          CGSO     = cgon3          JS       = 1E-05 
+JSW      = 5.3E-11        NLEV     = 3              AF       = 1.1     
+KF       = 2E-23          CAPMOD   = 0              XTI      = 3     
+N        = 1              NQSMOD   = 0              XPART    = 1     
+CF       = 0              TLEV     = 1              TLEVC    = 1    
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     )

.MODEL nch3.8           NMOS   (                    LMIN     = '5.0E-07-dxl3'   
+LMAX    = '1.2E-06-dxl3' WMIN     = '5.8E-07-dxw3'   WMAX     = '1.3E-06-dxw3' 
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn3          XJ       = 1.6E-07        NCH      = 2.97E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 9.45E-09       LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.15E-08       
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifn3         
+RSH     = 6.8            RD       = 0              RS       = 0              
+VTH0    = '0.6693704+dvthn3' LVTH0    = -3.998384E-09  WVTH0    = -3.672366E-08  
+PVTH0   = 5.025971E-15   K1       = 0.6782444      LK1      = 1.042334E-07   
+WK1     = 1.141034E-07   PK1      = -1.009566E-13  K2       = 0.004938684    
+LK2     = -5.410518E-08  WK2      = -3.250927E-08  PK2      = 2.905448E-14   
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 100000         UA       = -1.047682E-09  
+LUA     = 2.178004E-16   WUA      = 7.337225E-16   PUA      = -3.792786E-22  
+UB      = 2.919924E-18   LUB      = 7.622548E-26   WUB      = -6.758245E-25  
+PUB     = -2.079369E-33  UC       = 1.246159E-10   LUC      = 1.761267E-17   
+WUC     = -1.067449E-17  PUC      = -1.998464E-23  RDSW     = 393            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.04103415     WU0      = 2.416326E-09   A0       = 0.02058254     
+LA0     = 6.056122E-07   WA0      = 7.052998E-07   PA0      = -3.252137E-13  
+KETA    = -0.004570436   LKETA    = -2.694473E-08  WKETA    = -2.79243E-08   
+PKETA   = 1.991007E-14   A1       = 0              A2       = 1              
+AGS     = 0.1058854      LAGS     = 2.183976E-07   WAGS     = 1.224266E-07   
+PAGS    = -5.885401E-14  B0       = 0              B1       = 0              
+VOFF    = -0.1152247     LVOFF    = -1.296263E-08  WVOFF    = -1.340288E-09  
+PVOFF   = 1.629403E-14   NFACTOR  = -0.05843703    LNFACTOR = 2.695319E-07   
+WNFACTOR= 7.019555E-07   PNFACTOR = -3.388017E-13  CIT      = 0.001716296    
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = -0.0006595949  LETA0    = 7.884066E-10   WETA0    = 2.687661E-10   
+PETA0   = -3.128262E-16  ETAB     = -7.156606E-05  LETAB    = 7.853864E-11   
+WETAB   = 2.417614E-10   PETAB    = -2.844973E-16  DSUB     = 0              
+PCLM    = 2.078731       LPCLM    = -5.413389E-07  WPCLM    = -1.203511E-06  
+PPCLM   = 8.27297E-13    PDIBLC1  = 0              PDIBLC2  = -0.002899674   
+LPDIBLC2= 4.324276E-09   WPDIBLC2 = 5.036079E-09   PPDIBLC2 = -2.322136E-15  
+PDIBLCB = 0.2610441      LPDIBLCB = -1.843466E-07  WPDIBLCB = -2.146912E-07  
+PPDIBLCB= 9.899411E-14   DROUT    = 0              PSCBE1   = 3.615613E+08   
+PSCBE2  = 2.282738E-06   PVAG     = 0              DELTA    = 0.01           
+ALPHA0  = 1.84E-06       BETA0    = 22.4112        KT1      = -0.295         
+KT2     = -0.02722041    AT       = 62249.04       LAT      = -0.02103052    
+WAT     = -0.02121099    PAT      = 1.129339E-08   UTE      = -1.17          
+UA1     = 1.75E-09       UB1      = -9.01227E-19   LUB1     = -3.236696E-25  
+WUB1    = -1.273351E-25  PUB1     = 1.738106E-31   UC1      = 2.276022E-10   
+LUC1    = -9.786869E-17  WUC1     = -1.000846E-16  PUC1     = 5.255549E-23   
+KT1L    = 0              PRT      = 0             
+CJ       = cjn3  
+MJ       = 0.3436375      PB       = 0.854555       CJSW     = cjswn3
+MJSW     = 0.01           PBSW     = 0.854555       CJSWG    = cjgaten3
+MJSWG    = 0.1275785      PBSWG    = 0.854555       CTA      = 8.83679E-4
+CTP      = 1.20092E-4     PTA      = 1.83078E-3     PTP      = 1.83078E-3
+CGDO     = cgon3          CGSO     = cgon3          JS       = 1E-05 
+JSW      = 5.3E-11        NLEV     = 3              AF       = 1.1     
+KF       = 2E-23          CAPMOD   = 0              XTI      = 3     
+N        = 1              NQSMOD   = 0              XPART    = 1     
+CF       = 0              TLEV     = 1              TLEVC    = 1    
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     )

.MODEL nch3.9           NMOS   (                    LMIN     = 3.5E-07    
+LMAX    = '5.0E-07-dxl3' WMIN     = '5.8E-07-dxw3'   WMAX     = '1.3E-06-dxw3'  
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn3          XJ       = 1.6E-07        NCH      = 2.97E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 9.45E-09       LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.15E-08       
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifn3         
+RSH     = 6.8            RD       = 0              RS       = 0              
+VTH0    = '0.5355518+dvthn3' LVTH0    = 5.770536E-08   WVTH0    = 4.364814E-08   
+PVTH0   = -3.203346E-14  K1       = 1.068396       LK1      = -7.566534E-08  
+WK1     = -2.09287E-07   PK1      = 4.815868E-14   K2       = -0.1137058     
+LK2     = 6.0177E-10     WK2      = 9.315972E-08   PK2      = -2.889149E-14  
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 100000         UA       = -2.313606E-09  
+LUA     = 8.015183E-16   WUA      = 9.196342E-16   PUA      = -4.650025E-22  
+UB      = 4.314261E-18   LUB      = -5.667033E-25  WUB      = -1.3271E-24    
+PUB     = 2.982239E-31   UC       = 2.200211E-10   LUC      = -2.637869E-17  
+WUC     = -5.751564E-17  PUC      = 1.613812E-24   RDSW     = 393            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.02888444     LU0      = 5.602233E-09   WU0      = 1.096924E-08   
+PU0     = -3.943749E-15  A0       = 1.33399        KETA     = -0.04918694    
+LKETA   = -6.372062E-09  WKETA    = -1.788808E-08  PKETA    = 1.528237E-14   
+A1      = 0              A2       = 1              AGS      = 0.7996131      
+LAGS    = -1.014802E-07  WAGS     = -1.834045E-07  PAGS     = 8.21647E-14    
+B0      = 0              B1       = 0              VOFF     = -0.1723825     
+LVOFF   = 1.339282E-08   WVOFF    = 7.050705E-08   PVOFF    = -1.683478E-14  
+NFACTOR = 0.9669587      LNFACTOR = -2.032781E-07  WNFACTOR = -5.869672E-07  
+PNFACTOR= 2.555205E-13   CIT      = 0.001716296    CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = -0.004307223   
+LETA0   = 2.470328E-09   WETA0    = -1.259321E-09  PETA0    = 3.917749E-16   
+ETAB    = 0.002792895    LETAB    = -1.242264E-09  WETAB    = -1.153474E-09  
+PETAB   = 3.588459E-16   DSUB     = 0              PCLM     = 0.2041805      
+LPCLM   = 3.230165E-07   WPCLM    = 1.073203E-06   PPCLM    = -2.224957E-13  
+PDIBLC1 = 0              PDIBLC2  = 0.0064785      PDIBLCB  = -0.1387533     
+DROUT   = 0              PSCBE1   = 3.615613E+08   PSCBE2   = 2.282738E-06   
+PVAG    = 0              DELTA    = 0.01           ALPHA0   = 1.84E-06       
+BETA0   = 22.4112        KT1      = -0.295         KT2      = -0.02722041    
+AT      = 3966.579       LAT      = 0.005843522    WAT      = 0.0100867      
+PAT     = -3.137972E-09  UTE      = -1.17          UA1      = 1.75E-09       
+UB1     = -1.847224E-18  LUB1     = 1.125296E-25   WUB1     = 3.806653E-25   
+PUB1    = -6.042839E-32  UC1      = -1.603323E-10  LUC1     = 8.100791E-17   
+WUC1    = 1.082363E-16   PUC1     = -4.350125E-23  KT1L     = 0              
+PRT     = 0             
+CJ       = cjn3  
+MJ       = 0.3436375      PB       = 0.854555       CJSW     = cjswn3
+MJSW     = 0.01           PBSW     = 0.854555       CJSWG    = cjgaten3
+MJSWG    = 0.1275785      PBSWG    = 0.854555       CTA      = 8.83679E-4
+CTP      = 1.20092E-4     PTA      = 1.83078E-3     PTP      = 1.83078E-3
+CGDO     = cgon3          CGSO     = cgon3          JS       = 1E-05 
+JSW      = 5.3E-11        NLEV     = 3              AF       = 1.1     
+KF       = 2E-23          CAPMOD   = 0              XTI      = 3     
+N        = 1              NQSMOD   = 0              XPART    = 1     
+CF       = 0              TLEV     = 1              TLEVC    = 1    
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     )

.MODEL nch3.10          NMOS   (                    LMIN     = '1.2E-06-dxl3'  
+LMAX    = 21E-06         WMIN     = 1.8E-07        WMAX     = '5.8E-07-dxw3'  
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn3          XJ       = 1.6E-07        NCH      = 2.97E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 9.45E-09       LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.15E-08       
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifn3         
+RSH     = 6.8            RD       = 0              RS       = 0              
+VTH0    = '0.5760282+dvthn3' LVTH0    = 7.142075E-08   WVTH0    = -7.769922E-09  
+PVTH0   = -1.089247E-14  K1       = 0.8662176      LK1      = 1.369726E-08   
+WK1     = -7.276387E-09  PK1      = -2.860798E-14  K2       = -0.05394444    
+LK2     = -1.649125E-08  WK2      = -8.89038E-10   PK2      = 8.855804E-15   
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 100000         UA       = -5.624329E-11  
+LUA     = 2.292046E-16   WUA      = 8.542401E-17   PUA      = -2.508359E-22  
+UB      = 1.650869E-18   LUB      = 8.458743E-26   WUB      = -5.898645E-26  
+PUB     = 6.848915E-32   UC       = 7.469917E-11   LUC      = 2.924416E-17   
+WUC     = 8.524212E-19   PUC      = -8.491058E-24  RDSW     = 393            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.04553383     A0       = 1.33399        KETA     = -0.01010828    
+LKETA   = -4.38161E-08   A1       = 0              A2       = 1              
+AGS     = 0.2662211      LAGS     = 1.852886E-07   WAGS     = 2.552529E-09   
+PAGS    = -1.859721E-15  B0       = 0              B1       = 0              
+VOFF    = -0.1165444     LVOFF    = 1.170754E-08   WVOFF    = 3.803137E-09   
+PVOFF   = -2.103093E-15  NFACTOR  = 0.3843988      LNFACTOR = 8.351834E-07   
+WNFACTOR= 1.146593E-07   PNFACTOR = -2.3676E-13    CIT      = 0.001716296    
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = 1.820011E-05   ETAB     = -1E-05         DSUB     = 0              
+PCLM    = 0.08288045     LPCLM    = 7.144056E-07   PDIBLC1  = 0              
+PDIBLC2 = 0.0001500998   LPDIBLC2 = 7.347905E-09   PDIBLCB  = -0.1387533     
+DROUT   = 0              PSCBE1   = 3.615613E+08   PSCBE2   = 2.282738E-06   
+PVAG    = 0              DELTA    = 0.01           ALPHA0   = 1.84E-06       
+BETA0   = 22.4112        KT1      = -0.295         KT2      = -0.02722041    
+AT      = 22750          UTE      = -1.17          UA1      = 1.75E-09       
+UB1     = -1.13835E-18   UC1      = 4.1225E-11     KT1L     = 0              
+PRT     = 0             
+CJ       = cjn3  
+MJ       = 0.3436375      PB       = 0.854555       CJSW     = cjswn3
+MJSW     = 0.01           PBSW     = 0.854555       CJSWG    = cjgaten3
+MJSWG    = 0.1275785      PBSWG    = 0.854555       CTA      = 8.83679E-4
+CTP      = 1.20092E-4     PTA      = 1.83078E-3     PTP      = 1.83078E-3
+CGDO     = cgon3          CGSO     = cgon3          JS       = 1E-05 
+JSW      = 5.3E-11        NLEV     = 3              AF       = 1.1     
+KF       = 2E-23          CAPMOD   = 0              XTI      = 3     
+N        = 1              NQSMOD   = 0              XPART    = 1     
+CF       = 0              TLEV     = 1              TLEVC    = 1    
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     )

.MODEL nch3.11          NMOS   (                    LMIN     = '5.0E-07-dxl3'  
+LMAX    = '1.2E-06-dxl3' WMIN     = 1.8E-07        WMAX     = '5.8E-07-dxw3'
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn3          XJ       = 1.6E-07        NCH      = 2.97E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 9.45E-09       LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.15E-08       
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifn3         
+RSH     = 6.8            RD       = 0              RS       = 0              
+VTH0    = '0.6120653+dvthn3' LVTH0    = 2.95781E-08    WVTH0    = -5.950841E-09  
+PVTH0   = -1.30046E-14   K1       = 1.004244       LK1      = -1.465651E-07  
+WK1     = -6.095835E-08  PK1      = 3.372214E-14   K2       = -0.08325001    
+LK2     = 1.753545E-08   WK2      = 1.484805E-08   PK2      = -9.416534E-15  
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 100000         UA       = 5.129243E-10   
+LUA     = -4.316561E-16  WUA      = -1.043231E-16  PUA      = -3.052048E-23  
+UB      = 1.629372E-18   LUB      = 1.095475E-25   WUB      = 1.720203E-26   
+PUB     = -1.997327E-32  UC       = 1.095671E-10   LUC      = -1.124103E-17  
+WUC     = -2.593326E-18  PUC      = -4.490202E-24  RDSW     = 393            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.04553383     A0       = 1.33399        KETA     = -0.0597155     
+LKETA   = 1.378284E-08   WKETA    = 1.688606E-09   PKETA    = -1.96064E-15   
+A1      = 0              A2       = 1              AGS      = 0.3360209      
+LAGS    = 1.042441E-07   WAGS     = -1.156145E-09  PAGS     = 2.44642E-15    
+B0      = 0              B1       = 0              VOFF     = -0.1131616     
+LVOFF   = 7.779822E-09   WVOFF    = -2.4482E-09    PVOFF    = 5.155333E-15   
+NFACTOR = 1.59355        LNFACTOR = -5.687618E-07  WNFACTOR = -1.851616E-07  
+PNFACTOR= 1.113621E-13   CIT      = 0.001716296    CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = -0.0001590994  
+LETA0   = 2.058625E-10   ETAB     = 0.0003251254   LETAB    = -3.89114E-10   
+WETAB   = 2.873814E-11   PETAB    = -3.336785E-17  DSUB     = 0              
+PCLM    = -0.09688425    LPCLM    = 9.231305E-07   WPCLM    = -3.520537E-08  
+PPCLM   = 4.087694E-14   PDIBLC1  = 0              PDIBLC2  = 0.0064785      
+PDIBLCB = -0.1387533     DROUT    = 0              PSCBE1   = 3.615613E+08   
+PSCBE2  = 2.282738E-06   PVAG     = 0              DELTA    = 0.01           
+ALPHA0  = 1.84E-06       BETA0    = 22.4112        KT1      = -0.295         
+KT2     = -0.02722041    AT       = 19780.45       LAT      = 0.003447942    
+WAT     = 0.001594647    PAT      = -1.851545E-09  UTE      = -1.17          
+UA1     = 1.75E-09       UB1      = -1.189577E-18  LUB1     = 5.947941E-26   
+WUB1    = 2.750878E-26   PUB1     = -3.194044E-32  UC1      = 4.1225E-11     
+KT1L    = 0              PRT      = 0              
+CJ       = cjn3  
+MJ       = 0.3436375      PB       = 0.854555       CJSW     = cjswn3
+MJSW     = 0.01           PBSW     = 0.854555       CJSWG    = cjgaten3
+MJSWG    = 0.1275785      PBSWG    = 0.854555       CTA      = 8.83679E-4
+CTP      = 1.20092E-4     PTA      = 1.83078E-3     PTP      = 1.83078E-3
+CGDO     = cgon3          CGSO     = cgon3          JS       = 1E-05 
+JSW      = 5.3E-11        NLEV     = 3              AF       = 1.1     
+KF       = 2E-23          CAPMOD   = 0              XTI      = 3     
+N        = 1              NQSMOD   = 0              XPART    = 1     
+CF       = 0              TLEV     = 1              TLEVC    = 1    
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     )

.MODEL nch3.12          NMOS   (                    LMIN     = 3.5E-07   
+LMAX    = '5.0E-07-dxl3' WMIN     = 1.8E-07        WMAX     = '5.8E-07-dxw3'
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn3          XJ       = 1.6E-07        NCH      = 2.97E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 9.45E-09       LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.15E-08       
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifn3         
+RSH     = 6.8            RD       = 0              RS       = 0              
+VTH0    = '0.6803751+dvthn3' LVTH0    = -1.919552E-09  WVTH0    = -3.412198E-08  
+PVTH0   = -1.488861E-17  K1       = 0.7461514      LK1      = -2.755866E-08  
+WK1     = -3.624191E-08  PK1      = 2.232539E-14   K2       = 0.03238772     
+LK2     = -3.578511E-08  WK2      = 1.470752E-08   PK2      = -9.35173E-15   
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 100000         UA       = -1.543905E-10  
+LUA     = -1.239572E-16  WUA      = -2.398648E-16  PUA      = 3.197781E-23   
+UB      = 1.620117E-18   LUB      = 1.138147E-25   WUB      = 1.196549E-25   
+PUB     = -6.721428E-32  UC       = 1.250444E-10   LUC      = -1.83776E-17   
+WUC     = -6.513137E-18  PUC      = -2.682777E-24  RDSW     = 393            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.05173212     LU0      = -2.858028E-09  WU0      = -1.299961E-09  
+PU0     = 5.994119E-16   A0       = 1.33399        KETA     = -0.0620048     
+LKETA   = 1.483844E-08   WKETA    = -1.100489E-08  PKETA    = 3.892329E-15   
+A1      = 0              A2       = 1              AGS      = 0.3015822      
+LAGS    = 1.201237E-07   WAGS     = 8.403808E-08   PAGS     = -3.683664E-14  
+B0      = 0              B1       = 0              VOFF     = -0.03683854    
+LVOFF   = -2.741273E-08  WVOFF    = -2.280065E-09  PVOFF    = 5.077805E-15   
+NFACTOR = -0.4486732     LNFACTOR = 3.729072E-07   WNFACTOR = 1.732271E-07   
+PNFACTOR= -5.389096E-14  CIT      = 0.001716296    CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = -0.007036602   
+LETA0   = 3.377079E-09   WETA0    = 2.063546E-10   PETA0    = -9.515013E-17  
+ETAB    = 0.0008946396   LETAB    = -6.517171E-10  WETAB    = -1.341113E-10  
+PETAB   = 4.172203E-17   DSUB     = 0              PCLM     = 3.108956       
+LPCLM   = -5.550823E-07  WPCLM    = -4.866616E-07  PPCLM    = 2.490433E-13   
+PDIBLC1 = 0              PDIBLC2  = 0.0064785      PDIBLCB  = -0.1387533     
+DROUT   = 0              PSCBE1   = 3.615613E+08   PSCBE2   = 2.282738E-06   
+PVAG    = 0              DELTA    = 0.01           ALPHA0   = 1.84E-06       
+BETA0   = 22.4112        KT1      = -0.295         KT2      = -0.02722041    
+AT      = 36607.9        LAT      = -0.004311191   WAT      = -0.007441689   
+PAT     = 2.315109E-09   UTE      = -1.17          UA1      = 1.75E-09       
+UB1     = -8.992916E-19  LUB1     = -7.437106E-26  WUB1     = -1.283743E-25  
+PUB1    = 3.993725E-32   UC1      = 4.1225E-11     KT1L     = 0              
+PRT     = 0             
+CJ       = cjn3  
+MJ       = 0.3436375      PB       = 0.854555       CJSW     = cjswn3
+MJSW     = 0.01           PBSW     = 0.854555       CJSWG    = cjgaten3
+MJSWG    = 0.1275785      PBSWG    = 0.854555       CTA      = 8.83679E-4
+CTP      = 1.20092E-4     PTA      = 1.83078E-3     PTP      = 1.83078E-3
+CGDO     = cgon3          CGSO     = cgon3          JS       = 1E-05 
+JSW      = 5.3E-11        NLEV     = 3              AF       = 1.1     
+KF       = 2E-23          CAPMOD   = 0              XTI      = 3     
+N        = 1              NQSMOD   = 0              XPART    = 1     
+CF       = 0              TLEV     = 1              TLEVC    = 1    
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     )
*
*
***************************************************************
*               3.3V PMOS DEVICES MODEL                       *
***************************************************************
*
*
.MODEL pch3.1           PMOS   (                    LMIN     = '1.2E-06-dxl3' 
+LMAX    = 21E-06         WMIN     = '1.0E-05-dxw3'   WMAX     = 0.000201 
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxp3          XJ       = 1.8E-07        NCH      = 4.15E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.8E-08        LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.5E-09        
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifp3        
+RSH     = 8.2            RD       = 0              RS       = 0              
+VTH0    = 'dvthp3-0.5783178' LVTH0    = -2.709245E-08  K1       = 0.895          
+K2      = -0.01116511    K3       = 0              DVT0     = 0              
+DVT1    = 0              DVT2     = 0              DVT0W    = 0              
+DVT1W   = 0              DVT2W    = 0              NLX      = 0              
+W0      = 0              K3B      = 0              VSAT     = 94000          
+UA      = 1.224742E-09   LUA      = -1.679105E-16  WUA      = 5.495818E-16   
+PUA     = -5.465044E-21  UB       = 3.384796E-19   LUB      = 3.48904E-25    
+WUB     = 1.517898E-24   PUB      = 6.715582E-30   UC       = -1.092533E-10  
+LUC     = 1.868113E-17   WUC      = 1.552391E-16   PUC      = 2.209409E-22   
+RDSW    = 1050           PRWB     = 0              PRWG     = 0              
+WR      = 1              U0       = 0.012365       LU0      = -6.46358E-10   
+A0      = 1              KETA     = 0.0026         LKETA    = -2.58544E-08   
+A1      = 0              A2       = 0.9            AGS      = 0.0972         
+LAGS    = 7.756321E-08   B0       = 0              B1       = 0              
+VOFF    = -0.07253496    LVOFF    = 2.622026E-09   WVOFF    = 2.654702E-08   
+PVOFF   = -2.639837E-13  NFACTOR  = 0.736016       LNFACTOR = 2.3253E-07     
+WNFACTOR= -7.529401E-07  PNFACTOR = 7.48724E-12    CIT      = 0.000175593    
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = 3.556902E-06   LETA0    = 9.049039E-11   ETAB     = -1.02627E-05   
+DSUB    = 0              PCLM     = 0.76332        LPCLM    = 3.878159E-07   
+PDIBLC1 = 0              PDIBLC2  = -8.499995E-06  LPDIBLC2 = 5.81724E-10    
+PDIBLCB = -0.001         DROUT    = 0              PSCBE1   = 2.972857E+08   
+LPSCBE1 = -3.437352      PSCBE2   = 2.29866E-06    LPSCBE2  = -1.657267E-12  
+PVAG    = 0.1            DELTA    = 0.01           ALPHA0   = 1.33E-06       
+BETA0   = 25.35          KT1      = -0.35          KT2      = -0.028         
+AT      = 0              UTE      = -0.998         LUTE     = -5.17088E-07   
+UA1     = 7.092015E-10   LUA1     = -1.51031E-15   UB1      = -1.2748E-18    
+LUB1    = -5.170889E-26  UC1      = 4.51E-11       KT1L     = 0              
+PRT     = 0             
+CJ      = cjp3            PB      = 0.7289734       
+MJ      = 0.3909346       CJSW    = cjswp3          PBSW    = 0.7289734       
+MJSW    = 0.2513909       CJSWG   = cjgatep3        PBSWG   = 0.7289734       
+MJSWG   = 0.5427887       CTA     = 7.836E-4        CTP     = 1.301E-4     
+PTA     = 1.739E-3        PTP     = 1.739E-3        CGDO    = cgop3           
+CGSO    = cgop3           JS      = 5.4E-6          JSW     = 1.60E-10        
+N       = 1               XTI     = 3               CAPMOD  = 0               
+NQSMOD  = 0               XPART   = 1               CF      = 0               
+TLEV    = 1               TLEVC   = 1               
+NLEV    = 3               AF      = 1.1             KF      = 2.0E-23        
+CALCACM = 1               SFVTFLAG= 0               VFBFLAG = 1              )

.MODEL pch3.2           PMOS   (                    LMIN     = '5.0E-07-dxl3' 
+LMAX    = '1.2E-06-dxl3' WMIN     = '1.0E-05-dxw3'   WMAX     = 0.000201 
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxp3          XJ       = 1.8E-07        NCH      = 4.15E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.8E-08        LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.5E-09        
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifp3        
+RSH     = 8.2            RD       = 0              RS       = 0              
+VTH0    = 'dvthp3-0.6035093' LVTH0    = 1.726659E-09   WVTH0    = -1.786855E-07  
+PVTH0   = 2.044162E-13   K1       = 0.9073895      LK1      = -1.41736E-08   
+WK1     = 1.29754E-07    PK1      = -1.484386E-13  K2       = -0.01510108    
+LK2     = 4.502753E-09   WK2      = 3.934005E-08   PK2      = -4.500502E-14  
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 94000          UA       = 9.935536E-10   
+LUA     = 9.656884E-17   WUA      = -6.910646E-15  PUA      = 3.069457E-21   
+UB      = 7.396585E-19   LUB      = -1.100446E-25  WUB      = 1.326503E-23   
+PUB     = -6.723134E-30  UC       = -1.323463E-10  LUC      = 4.509958E-17   
+WUC     = 1.091277E-15   PUC      = -8.498862E-22  RDSW     = 1050           
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.01167314     LU0      = 1.45124E-10    A0       = 1              
+KETA    = -0.01910336    LKETA    = -1.02576E-09   WKETA    = 3.719097E-08   
+PKETA   = -4.254647E-14  A1       = 0              A2       = 0.9            
+AGS     = 0.1513142      LAGS     = 1.565654E-08   WAGS     = 1.380574E-07   
+PAGS    = -1.579376E-13  B0       = 0              B1       = 0              
+VOFF    = -0.06916244    LVOFF    = -1.236151E-09  WVOFF    = -5.400094E-07  
+PVOFF   = 3.841568E-13   NFACTOR  = 0.8859756      LNFACTOR = 6.097629E-08   
+WNFACTOR= 8.641621E-06   PNFACTOR = -3.260138E-12  CIT      = 0.000175593    
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = -0.0001989103  LETA0    = 3.221128E-10   ETAB     = 0.0001117513   
+LETAB   = -1.39584E-10   DSUB     = 0              PCLM     = 1.10232        
+PDIBLC1 = 0              PDIBLC2  = 0.0001828571   LPDIBLC2 = 3.628115E-10   
+PDIBLCB = -0.001         DROUT    = 0              PSCBE1   = 2.815953E+08   
+LPSCBE1 = 14.51246       PSCBE2   = 9.768571E-07   LPSCBE2  = -1.451246E-13  
+PVAG    = 0.1            DELTA    = 0.01           ALPHA0   = 1.33E-06       
+BETA0   = 25.35          KT1      = -0.35          KT2      = -0.03180572    
+LKT2    = 4.353738E-09   AT       = 0              UTE      = -1.481714      
+LUTE    = 3.62812E-08    UA1      = -6.744285E-10  LUA1     = 7.256226E-17   
+UB1     = -1.256571E-18  LUB1     = -7.256224E-26  UC1      = 4.51E-11       
+KT1L    = 0              PRT      = 0              
+CJ      = cjp3            PB      = 0.7289734       
+MJ      = 0.3909346       CJSW    = cjswp3          PBSW    = 0.7289734       
+MJSW    = 0.2513909       CJSWG   = cjgatep3        PBSWG   = 0.7289734       
+MJSWG   = 0.5427887       CTA     = 7.836E-4        CTP     = 1.301E-4     
+PTA     = 1.739E-3        PTP     = 1.739E-3        CGDO    = cgop3           
+CGSO    = cgop3           JS      = 5.4E-6          JSW     = 1.60E-10        
+N       = 1               XTI     = 3               CAPMOD  = 0               
+NQSMOD  = 0               XPART   = 1               CF      = 0               
+TLEV    = 1               TLEVC   = 1               
+NLEV    = 3               AF      = 1.1             KF      = 2.0E-23        
+CALCACM = 1               SFVTFLAG= 0               VFBFLAG = 1              )

.MODEL pch3.3           PMOS   (                    LMIN     = 3.0E-07   
+LMAX    = '5.0E-07-dxl3' WMIN     = '1.0E-05-dxw3'   WMAX     = 0.000201   
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxp3          XJ       = 1.8E-07        NCH      = 4.15E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.8E-08        LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.5E-09        
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifp3        
+RSH     = 8.2            RD       = 0              RS       = 0              
+VTH0    = 'dvthp3-0.5884327' LVTH0    = -4.96736E-09   WVTH0    = 9.507745E-08   
+PVTH0   = 8.286545E-14   K1       = 0.9558175      LK1      = -3.567562E-08  
+WK1     = -9.771858E-07  PK1      = 3.430427E-13   K2       = 0.008251499    
+LK2     = -5.865792E-09  WK2      = -2.6509E-08    PK2      = -1.576803E-14  
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 91560          LVSAT    = 0.00108336     
+UA      = 1.45174E-09    LUA      = -1.06866E-16   WUA      = -2.749604E-15  
+PUA     = 1.221954E-21   UB       = -1.106546E-19  LUB      = 2.674945E-25   
+WUB     = 2.119555E-24   PUB      = -1.774544E-30  UC       = -3.627492E-11  
+LUC     = 2.443873E-18   WUC      = -1.516816E-15  PUC      = 3.08107E-22    
+RDSW    = 1050           PRWB     = 0              PRWG     = 0              
+WR      = 1              U0       = 0.01139        LU0      = 2.7084E-10     
+A0      = 1              KETA     = -0.01992326    LKETA    = -6.617231E-10  
+WKETA   = -2.076636E-07  PKETA    = 6.616894E-14   A1       = 0              
+A2      = 0.9            AGS      = 0.4142002      LAGS     = -1.010649E-07  
+WAGS    = -4.832009E-07  PAGS     = 1.17901E-13    B0       = 0              
+B1      = 0              VOFF     = -0.06084789    LVOFF    = -4.927807E-09  
+WVOFF   = 6.580502E-07   PVOFF    = -1.477816E-13  NFACTOR  = 0.7831898      
+LNFACTOR= 1.066132E-07   WNFACTOR = 5.246208E-06   PNFACTOR = -1.752574E-12  
+CIT     = 0.000175593    CDSC     = 0              CDSCB    = 0              
+CDSCD   = 0              ETA0     = -0.001595158   LETA0    = 9.420469E-10   
+ETAB    = 0.00202222     LETAB    = -9.878321E-10  DSUB     = 0              
+PCLM    = 0.98032        LPCLM    = 5.416801E-08   PDIBLC1  = 0              
+PDIBLC2 = 0.001          PDIBLCB  = -0.001         DROUT    = 0              
+PSCBE1  = 3.14281E+08    PSCBE2   = 6.5E-07        PVAG     = 0.1            
+DELTA   = 0.01           ALPHA0   = 1.33E-06       BETA0    = 25.35          
+KT1     = -0.411         LKT1     = 2.708399E-08   KT2      = -0.0342        
+LKT2    = 5.4168E-09     AT       = 0              UTE      = -1.6806        
+LUTE    = 1.245864E-07   UA1      = -6.213738E-10  LUA1     = 4.900596E-17   
+WUA1    = -1.162563E-15  PUA1     = 5.161778E-22   UB1      = -1.597882E-18  
+LUB1    = 7.897954E-26   WUB1     = -6.611474E-24  PUB1     = 2.935494E-30   
+UC1     = 4.51E-11       KT1L     = 0              PRT      = 0              
+CJ      = cjp3            PB      = 0.7289734       
+MJ      = 0.3909346       CJSW    = cjswp3          PBSW    = 0.7289734       
+MJSW    = 0.2513909       CJSWG   = cjgatep3        PBSWG   = 0.7289734       
+MJSWG   = 0.5427887       CTA     = 7.836E-4        CTP     = 1.301E-4     
+PTA     = 1.739E-3        PTP     = 1.739E-3        CGDO    = cgop3           
+CGSO    = cgop3           JS      = 5.4E-6          JSW     = 1.60E-10        
+N       = 1               XTI     = 3               CAPMOD  = 0               
+NQSMOD  = 0               XPART   = 1               CF      = 0               
+TLEV    = 1               TLEVC   = 1               
+NLEV    = 3               AF      = 1.1             KF      = 2.0E-23        
+CALCACM = 1               SFVTFLAG= 0               VFBFLAG = 1              )


.MODEL pch3.4           PMOS   (                    LMIN     = '1.2E-06-dxl3'   
+LMAX    = 21E-06         WMIN     = '1.2E-06-dxw3' WMAX     = '1.0E-05-dxw3'
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxp3          XJ       = 1.8E-07        NCH      = 4.15E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.8E-08        LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.5E-09        
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifp3        
+RSH     = 8.2            RD       = 0              RS       = 0              
+VTH0    = 'dvthp3-0.5788425' LVTH0    = -3.003418E-08  WVTH0    = 5.244249E-09   
+PVTH0   = 2.940262E-14   K1       = 0.8676301      LK1      = 3.131114E-08   
+WK1     = 2.73562E-07    PK1      = -3.129549E-13  K2       = 0.0004256394   
+LK2     = -1.325981E-08  WK2      = -1.158495E-07  PK2      = 1.325318E-13   
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 94000          UA       = 1.317331E-09   
+LUA     = -7.946852E-16  WUA      = -3.758472E-16  PUA      = 7.995696E-22   
+UB      = 4.424821E-19   LUB      = 1.148359E-24   WUB      = 4.783918E-25   
+PUB     = -1.274966E-30  UC       = -1.031857E-10  LUC      = 5.343807E-17   
+WUC     = 9.459322E-17   PUC      = -1.264548E-22  RDSW     = 1050           
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.01248368     LU0      = -6.112488E-10  WU0      = -1.186258E-09  
+PU0     = -3.509168E-16  A0       = 1              KETA     = -0.00121395    
+LKETA   = -2.195729E-08  WKETA    = 3.812044E-08   PKETA    = -3.895162E-14  
+A1      = 0              A2       = 0.9            AGS      = 0.08714183     
+LAGS    = 8.677056E-08   WAGS     = 1.005314E-07   PAGS     = -9.202759E-14  
+B0      = 0              B1       = 0              VOFF     = -0.06705506    
+LVOFF   = -2.702006E-08  WVOFF    = -2.822463E-08  PVOFF    = 3.228898E-14   
+NFACTOR = 0.5441627      LNFACTOR = 1.114929E-06   WNFACTOR = 1.164634E-06   
+PNFACTOR= -1.332341E-12  CIT      = 0.000175593    CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = 3.556902E-06   
+LETA0   = 9.049039E-11   ETAB     = -1.02627E-05   DSUB     = 0              
+PCLM    = 0.76332        LPCLM    = 3.878159E-07   PDIBLC1  = 0              
+PDIBLC2 = -8.499995E-06  LPDIBLC2 = 5.81724E-10    PDIBLCB  = -0.001         
+DROUT   = 0              PSCBE1   = 2.972857E+08   LPSCBE1  = -3.437352      
+PSCBE2  = 2.29866E-06    LPSCBE2  = -1.657267E-12  PVAG     = 0.1            
+DELTA   = 0.01           ALPHA0   = 1.33E-06       BETA0    = 25.35          
+KT1     = -0.35          KT2      = -0.028         AT       = 0              
+UTE     = -0.9768159     LUTE     = -5.521972E-07  WUTE     = -2.11735E-07   
+PUTE    = 3.509155E-13   UA1      = 7.164628E-10   LUA1     = -1.518617E-15  
+WUA1    = -7.257579E-17  PUA1     = 8.302666E-23   UB1      = -1.17951E-18   
+LUB1    = -1.296511E-25  WUB1     = -9.524275E-25  PUB1     = 7.790324E-31   
+UC1     = 4.51E-11       KT1L     = 0              PRT      = 0              
+CJ      = cjp3            PB      = 0.7289734       
+MJ      = 0.3909346       CJSW    = cjswp3          PBSW    = 0.7289734       
+MJSW    = 0.2513909       CJSWG   = cjgatep3        PBSWG   = 0.7289734       
+MJSWG   = 0.5427887       CTA     = 7.836E-4        CTP     = 1.301E-4     
+PTA     = 1.739E-3        PTP     = 1.739E-3        CGDO    = cgop3           
+CGSO    = cgop3           JS      = 5.4E-6          JSW     = 1.60E-10        
+N       = 1               XTI     = 3               CAPMOD  = 0               
+NQSMOD  = 0               XPART   = 1               CF      = 0               
+TLEV    = 1               TLEVC   = 1               
+NLEV    = 3               AF      = 1.1             KF      = 2.0E-23        
+CALCACM = 1               SFVTFLAG= 0               VFBFLAG = 1              )


.MODEL pch3.5           PMOS   (                    LMIN     = '5.0E-07-dxl3'   
+LMAX    = '1.2E-06-dxl3' WMIN     = '1.2E-06-dxw3' WMAX     = '1.0E-05-dxw3'
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxp3          XJ       = 1.8E-07        NCH      = 4.15E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.8E-08        LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.5E-09        
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifp3        
+RSH     = 8.2            RD       = 0              RS       = 0              
+VTH0    = 'dvthp3-0.6248794' LVTH0    = 2.263207E-08   WVTH0    = 3.490859E-08   
+PVTH0   = -4.533386E-15  K1       = 0.9227427      LK1      = -3.17376E-08   
+WK1     = -2.370066E-08  PK1      = 2.711356E-14   K2       = -0.01164184    
+LK2     = 5.453882E-10   WK2      = 4.764995E-09   PK2      = -5.451153E-15  
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 94000          UA       = 2.118788E-10   
+LUA     = 4.699521E-16   WUA      = 9.021931E-16   PUA      = -6.625083E-22  
+UB      = 2.223373E-18   LUB      = -8.889807E-25  WUB      = -1.564701E-24  
+PUB     = 1.062332E-30   UC       = -1.631214E-11  LUC      = -4.594522E-17  
+WUC     = -6.84849E-17   PUC      = 6.010649E-23   RDSW     = 1050           
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.011745       LU0      = 2.338067E-10   WU0      = -7.181924E-10  
+PU0     = -8.863833E-16  A0       = 1              KETA     = -0.01667523    
+LKETA   = -4.269582E-09  WKETA    = 1.292188E-08   PKETA    = -1.012446E-14  
+A1      = 0              A2       = 0.9            AGS      = 0.1712481      
+LAGS    = -9.446961E-09  WAGS     = -6.118135E-08  PAGS     = 9.297176E-14   
+B0      = 0              B1       = 0              VOFF     = -0.1258833     
+LVOFF   = 4.027945E-08   WVOFF    = 2.69157E-08    PVOFF    = -3.079156E-14  
+NFACTOR = 1.78205        LNFACTOR = -3.012137E-07  WNFACTOR = -3.14642E-07   
+PNFACTOR= 3.599504E-13   CIT      = 0.000175593    CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = -0.0001989102  
+LETA0   = 3.221128E-10   ETAB     = 0.0001117513   LETAB    = -1.39584E-10   
+DSUB    = 0              PCLM     = 1.10232        PDIBLC1  = 0              
+PDIBLC2 = 0.0001828571   LPDIBLC2 = 3.628115E-10   PDIBLCB  = -0.001         
+DROUT   = 0              PSCBE1   = 2.815953E+08   LPSCBE1  = 14.51246       
+PSCBE2  = 9.768571E-07   LPSCBE2  = -1.451246E-13  PVAG     = 0.1            
+DELTA   = 0.01           ALPHA0   = 1.33E-06       BETA0    = 25.35          
+KT1     = -0.3508613     LKT1     = 9.853657E-10   WKT1     = 8.609025E-09   
+PKT1    = -9.848724E-15  KT2      = -0.03180572    LKT2     = 4.353738E-09   
+AT      = 0              UTE      = -1.495527      LUTE     = 4.120803E-08   
+WUTE    = 1.380545E-07   PUTE     = -4.924359E-14  UA1      = -6.916551E-10  
+LUA1    = 9.226952E-17   WUA1     = 1.721801E-16   PUA1     = -1.96974E-22   
+UB1     = -1.203572E-18  LUB1     = -1.021231E-25  WUB1     = -5.297253E-25  
+PUB1    = 2.95461E-31    UC1      = 4.51E-11       KT1L     = 0              
+PRT     = 0              
+CJ      = cjp3            PB      = 0.7289734       
+MJ      = 0.3909346       CJSW    = cjswp3          PBSW    = 0.7289734       
+MJSW    = 0.2513909       CJSWG   = cjgatep3        PBSWG   = 0.7289734       
+MJSWG   = 0.5427887       CTA     = 7.836E-4        CTP     = 1.301E-4     
+PTA     = 1.739E-3        PTP     = 1.739E-3        CGDO    = cgop3           
+CGSO    = cgop3           JS      = 5.4E-6          JSW     = 1.60E-10        
+N       = 1               XTI     = 3               CAPMOD  = 0               
+NQSMOD  = 0               XPART   = 1               CF      = 0               
+TLEV    = 1               TLEVC   = 1               
+NLEV    = 3               AF      = 1.1             KF      = 2.0E-23        
+CALCACM = 1               SFVTFLAG= 0               VFBFLAG = 1              )

.MODEL pch3.6           PMOS   (                    LMIN     = 3.0E-07   
+LMAX    = '5.0E-07-dxl3' WMIN     = '1.2E-06-dxw3' WMAX     = '1.0E-05-dxw3' 
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxp3          XJ       = 1.8E-07        NCH      = 4.15E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.8E-08        LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.5E-09        
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifp3        
+RSH     = 8.2            RD       = 0              RS       = 0              
+VTH0    = 'dvthp3-0.5799206' LVTH0    = 2.670367E-09   WVTH0    = 9.999278E-09   
+PVTH0   = 6.526349E-15   K1       = 0.8434267      LK1      = 3.478685E-09   
+WK1     = 1.461601E-07   PK1      = -4.830464E-14  K2       = 0.008627413    
+LK2     = -8.454163E-09  WK2      = -3.026626E-08  PK2      = 1.010272E-14   
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 90897.32       LVSAT    = 0.001377591    
+WVSAT   = 0.006623506    PVSAT    = -2.940837E-09  UA       = 1.366113E-09   
+LUA     = -4.252801E-17  WUA      = -1.893761E-15  PUA      = 5.788953E-22   
+UB      = -1.73285E-19   LUB      = 1.751357E-25   WUB      = 2.745543E-24   
+PUB     = -8.514164E-31  UC       = -2.073167E-10  LUC      = 3.886081E-17   
+WUC     = 1.927466E-16   PUC      = -5.588027E-23  RDSW     = 1050           
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.01174443     LU0      = 2.340611E-10   WU0      = -3.542489E-09  
+PU0     = 3.676046E-16   A0       = 1              KETA     = -0.04133333    
+LKETA   = 6.678612E-09   WKETA    = 6.33007E-09    PKETA    = -7.197699E-15  
+A1      = 0              A2       = 0.9            AGS      = 0.4039673      
+LAGS    = -1.127743E-07  WAGS     = -3.80921E-07   PAGS     = 2.349361E-13   
+B0      = 0              B1       = 0              VOFF     = 0.0157619      
+LVOFF   = -2.261103E-08  WVOFF    = -1.076646E-07  PVOFF    = 2.89621E-14    
+NFACTOR = 1.279464       LNFACTOR = -7.806536E-08  WNFACTOR = 2.859487E-07   
+PNFACTOR= 9.328811E-14   CIT      = 0.000175593    CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = -0.001798788   
+LETA0   = 1.032458E-09   WETA0    = 2.035273E-09   PETA0    = -9.036609E-16  
+ETAB    = 0.002154757    LETAB    = -1.046679E-09  WETAB    = -1.324706E-09  
+PETAB   = 5.881691E-16   DSUB     = 0              PCLM     = 0.9803199      
+LPCLM   = 5.416801E-08   PDIBLC1  = 0              PDIBLC2  = 0.001          
+PDIBLCB = -0.001         DROUT    = 0              PSCBE1   = 3.14281E+08    
+PSCBE2  = 6.831341E-07   LPSCBE2  = -1.471156E-14  WPSCBE2  = -3.311753E-13  
+PPSCBE2 = 1.470418E-19   PVAG     = 0.1            DELTA    = 0.01           
+ALPHA0  = 1.33E-06       BETA0    = 25.35          KT1      = -0.4146121     
+LKT1    = 2.929072E-08   WKT1     = 3.610347E-08   PKT1     = -2.205625E-14  
+KT2     = -0.03635372    LKT2     = 6.373051E-09   WKT2     = 2.15264E-08    
+PKT2    = -9.557719E-15  AT       = 0              UTE      = -1.720082      
+LUTE    = 1.409103E-07   WUTE     = 3.946176E-07   PUTE     = -1.631576E-13  
+UA1     = -7.519153E-10  LUA1     = 1.19025E-16    WUA1     = 1.421995E-16   
+PUA1    = -1.836626E-22  UB1      = -2.466343E-18  LUB1     = 4.585471E-25   
+WUB1    = 2.068797E-24   PUB1     = -8.582831E-31  UC1      = 3.474558E-11   
+LUC1    = 4.597361E-18   WUC1     = 1.034923E-16   PUC1     = -4.595057E-23  
+KT1L    = 0              PRT      = 0              
+CJ      = cjp3            PB      = 0.7289734       
+MJ      = 0.3909346       CJSW    = cjswp3          PBSW    = 0.7289734       
+MJSW    = 0.2513909       CJSWG   = cjgatep3        PBSWG   = 0.7289734       
+MJSWG   = 0.5427887       CTA     = 7.836E-4        CTP     = 1.301E-4     
+PTA     = 1.739E-3        PTP     = 1.739E-3        CGDO    = cgop3           
+CGSO    = cgop3           JS      = 5.4E-6          JSW     = 1.60E-10        
+N       = 1               XTI     = 3               CAPMOD  = 0               
+NQSMOD  = 0               XPART   = 1               CF      = 0               
+TLEV    = 1               TLEVC   = 1               
+NLEV    = 3               AF      = 1.1             KF      = 2.0E-23        
+CALCACM = 1               SFVTFLAG= 0               VFBFLAG = 1              )

.MODEL pch3.7           PMOS   (                    LMIN     = '1.2E-06-dxl3' 
+LMAX    = 21E-06         WMIN     = '5.4E-07-dxw3'   WMAX     = '1.2E-06-dxw3' 
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxp3          XJ       = 1.8E-07        NCH      = 4.15E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.8E-08        LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.5E-09        
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifp3        
+RSH     = 8.2            RD       = 0              RS       = 0              
+VTH0    = 'dvthp3-0.5916921' LVTH0    = -1.178842E-08  WVTH0    = 2.059962E-08   
+PVTH0   = 7.598937E-15   K1       = 1.264666       LK1      = -4.101965E-07  
+WK1     = -2.008957E-07  PK1      = 2.146467E-13   K2       = -0.1656113     
+LK2     = 1.77179E-07    WK2      = 8.25646E-08    PK2      = -9.504266E-14  
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 94000          UA       = 1.320618E-09   
+LUA     = -1.908948E-16  WUA      = -3.797752E-16  PUA      = 7.804011E-23   
+UB      = 9.992215E-19   LUB      = 1.279448E-26   WUB      = -1.869118E-25  
+PUB     = 8.20331E-32    UC       = 3.557823E-11   LUC      = -1.032365E-16  
+WUC     = -7.122965E-17  PUC      = 6.077129E-23   RDSW     = 1050           
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.01301009     LU0      = -1.066276E-09  WU0      = -1.815315E-09  
+PU0     = 1.928406E-16   A0       = 1              KETA     = 0.05421707     
+LKETA   = -8.94474E-08   WKETA    = -2.811964E-08  PKETA    = 4.169908E-14   
+A1      = 0              A2       = 0.9            AGS      = 0.2391251      
+LAGS    = -4.231991E-08  WAGS     = -8.108869E-08  PAGS     = 6.223556E-14   
+B0      = 0              B1       = 0              VOFF     = -0.09888963    
+LVOFF   = 5.969338E-10   WVOFF    = 9.817678E-09   PVOFF    = -7.133371E-16  
+NFACTOR = 2.092189       LNFACTOR = 4.81594E-08    WNFACTOR = -6.852579E-07  
+PNFACTOR= -5.755043E-14  CIT      = 0.000175593    CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = 3.556902E-06   
+LETA0   = 9.049039E-11   ETAB     = -1.342406E-05  LETAB    = 3.14366E-11    
+WETAB   = 3.777827E-12   PETAB    = -3.756674E-17  DSUB     = 0              
+PCLM    = 0.7527822      LPCLM    = 4.926044E-07   WPCLM    = 1.259272E-08   
+PPCLM   = -1.252223E-13  PDIBLC1  = 0              PDIBLC2  = -8.499995E-06  
+LPDIBLC2= 5.81724E-10    PDIBLCB  = -0.001         DROUT    = 0              
+PSCBE1  = 2.972857E+08   LPSCBE1  = -3.437352      PSCBE2   = 2.29866E-06    
+LPSCBE2 = -1.657267E-12  PVAG     = 0.1            DELTA    = 0.01           
+ALPHA0  = 1.33E-06       BETA0    = 25.35          KT1      = -0.3468386     
+LKT1    = -3.14366E-08   WKT1     = -3.777827E-09  PKT1     = 3.756674E-14   
+KT2     = -0.028         AT       = 0              UTE      = -1.154         
+LUTE    = -2.58544E-07   UA1      = 5.641315E-10   LUA1     = -1.34435E-15   
+WUA1    = 1.094602E-16   PUA1     = -1.252225E-22  UB1      = -1.848541E-18  
+LUB1    = 2.346466E-26   WUB1     = -1.529344E-25  PUB1     = 5.96059E-31    
+UC1     = 6.552727E-11   LUC1     = -4.191546E-17  WUC1     = -2.441059E-17  
+PUC1    = 5.008898E-23   KT1L     = 0              PRT      = 0              
+CJ      = cjp3            PB      = 0.7289734       
+MJ      = 0.3909346       CJSW    = cjswp3          PBSW    = 0.7289734       
+MJSW    = 0.2513909       CJSWG   = cjgatep3        PBSWG   = 0.7289734       
+MJSWG   = 0.5427887       CTA     = 7.836E-4        CTP     = 1.301E-4     
+PTA     = 1.739E-3        PTP     = 1.739E-3        CGDO    = cgop3           
+CGSO    = cgop3           JS      = 5.4E-6          JSW     = 1.60E-10        
+N       = 1               XTI     = 3               CAPMOD  = 0               
+NQSMOD  = 0               XPART   = 1               CF      = 0               
+TLEV    = 1               TLEVC   = 1               
+NLEV    = 3               AF      = 1.1             KF      = 2.0E-23        
+CALCACM = 1               SFVTFLAG= 0               VFBFLAG = 1              )


.MODEL pch3.8           PMOS   (                    LMIN     = '5.0E-07-dxl3'   
+LMAX    = '1.2E-06-dxl3' WMIN     = '5.4E-07-dxw3'   WMAX     = '1.2E-06-dxw3'  
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxp3          XJ       = 1.8E-07        NCH      = 4.15E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.8E-08        LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.5E-09        
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifp3        
+RSH     = 8.2            RD       = 0              RS       = 0              
+VTH0    = 'dvthp3-0.6255528' LVTH0    = 2.694814E-08   WVTH0    = 3.571328E-08   
+PVTH0   = -9.69109E-15   K1       = 0.9250507      LK1      = -2.167683E-08  
+WK1     = -2.645882E-08  PK1      = 1.509094E-14   K2       = -0.01121804    
+LK2     = 5.532568E-10   WK2      = 4.258554E-09   PK2      = -5.460557E-15  
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 94000          UA       = 1.157738E-09   
+LUA     = -4.559712E-18  WUA      = -2.281084E-16  PUA      = -9.546668E-23  
+UB      = 1.017989E-18   LUB      = -8.67588E-27   WUB      = -1.242671E-25  
+PUB     = 1.036768E-32   UC       = -6.873176E-11  LUC      = 1.609412E-17   
+WUC     = -5.843453E-18  PUC      = -1.403052E-23  RDSW     = 1050           
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.01262487     LU0      = -6.255768E-10  WU0      = -1.769633E-09  
+PU0     = 1.4058E-16     A0       = 1              KETA     = -0.01577413    
+LKETA   = -9.377466E-09  WKETA    = 1.184506E-08   PKETA    = -4.020544E-15  
+A1      = 0              A2       = 0.9            AGS      = 0.1082169      
+LAGS    = 1.074392E-07   WAGS     = 1.414098E-08   PAGS     = -4.670718E-14  
+B0      = 0              B1       = 0              VOFF     = -0.1127164     
+LVOFF   = 1.641481E-08   WVOFF    = 1.11813E-08    PVOFF    = -2.273315E-15  
+NFACTOR = 2.134286       WNFACTOR = -7.355642E-07  CIT      = 0.000175593    
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = -0.0003017414  LETA0    = 4.397517E-10   WETA0    = 1.228832E-10   
+PETA0   = -1.405785E-16  ETAB     = 0.0001514941   LETAB    = -1.572298E-10  
+WETAB   = -4.749273E-11  PETAB    = 2.108677E-17   DSUB     = 0              
+PCLM    = 1.311919       LPCLM    = -1.470485E-07  WPCLM    = -2.504714E-07  
+PPCLM   = 1.75723E-13    PDIBLC1  = 0              PDIBLC2  = 0.0001828571   
+LPDIBLC2= 3.628115E-10   PDIBLCB  = -0.001         DROUT    = 0              
+PSCBE1  = 2.815953E+08   LPSCBE1  = 14.51246       PSCBE2   = 8.74026E-07    
+LPSCBE2 = -2.748573E-14  WPSCBE2  = 1.228833E-13   PPSCBE2  = -1.405785E-19  
+PVAG    = 0.1            DELTA    = 0.01           ALPHA0   = 1.33E-06       
+BETA0   = 25.35          KT1      = -0.3731169     LKT1     = -1.374307E-09  
+WKT1    = 3.520439E-08   PKT1     = -7.028915E-15  KT2      = -0.03180572    
+LKT2    = 4.353738E-09   AT       = 0              UTE      = -1.31316       
+LUTE    = -7.646524E-08  WUTE     = -7.987413E-08  PUTE     = 9.137598E-14   
+UA1     = -2.105422E-10  LUA1     = -4.581236E-16  WUA1     = -4.0275E-16    
+PUA1    = 4.607458E-22   UB1      = -2.336895E-18  LUB1     = 5.821409E-25   
+WUB1    = 8.245951E-25   PUB1     = -5.222346E-31  UC1      = 7.036251E-12   
+LUC1    = 2.499825E-17   WUC1     = 4.548619E-17   PUC1     = -2.987292E-23  
+KT1L    = 0              PRT      = 0             
+CJ      = cjp3            PB      = 0.7289734       
+MJ      = 0.3909346       CJSW    = cjswp3          PBSW    = 0.7289734       
+MJSW    = 0.2513909       CJSWG   = cjgatep3        PBSWG   = 0.7289734       
+MJSWG   = 0.5427887       CTA     = 7.836E-4        CTP     = 1.301E-4     
+PTA     = 1.739E-3        PTP     = 1.739E-3        CGDO    = cgop3           
+CGSO    = cgop3           JS      = 5.4E-6          JSW     = 1.60E-10        
+N       = 1               XTI     = 3               CAPMOD  = 0               
+NQSMOD  = 0               XPART   = 1               CF      = 0               
+TLEV    = 1               TLEVC   = 1               
+NLEV    = 3               AF      = 1.1             KF      = 2.0E-23        
+CALCACM = 1               SFVTFLAG= 0               VFBFLAG = 1              )

.MODEL pch3.9           PMOS   (                    LMIN     = 3.0E-07    
+LMAX    = '5.0E-07-dxl3' WMIN     = '5.4E-07-dxw3'   WMAX     = '1.2E-06-dxw3'  
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxp3          XJ       = 1.8E-07        NCH      = 4.15E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.8E-08        LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.5E-09        
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifp3        
+RSH     = 8.2            RD       = 0              RS       = 0              
+VTH0    = 'dvthp3-0.5990314' LVTH0    = 1.517265E-08   WVTH0    = 3.283669E-08   
+PVTH0   = -8.413884E-15  K1       = 1.040872       LK1      = -7.310135E-08  
+WK1     = -8.978672E-08  PK1      = 4.320853E-14   K2       = -0.03143194    
+LK2     = 9.52823E-09    WK2      = 1.760468E-08   PK2      = -1.138624E-14  
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 96440          LVSAT    = -0.00108336    
+UA      = -3.978582E-10  LUA      = 6.86125E-16    WUA      = 2.141852E-16   
+PUA     = -2.918451E-22  UB       = 2.854619E-18   LUB      = -8.241398E-25  
+WUB     = -8.728036E-25  PUB      = 3.427179E-31   UC       = -3.51195E-12   
+LUC     = -1.286348E-17  WUC      = -5.080017E-17  PUC      = 5.930264E-24   
+RDSW    = 1050           PRWB     = 0              PRWG     = 0              
+WR      = 1              U0       = 0.009343209    LU0      = 8.31479E-10    
+WU0     = -6.730336E-10  PU0      = -3.463099E-16  A0       = 1              
+KETA    = -0.04383463    LKETA    = 3.0814E-09     WKETA    = 9.319129E-09   
+PKETA   = -2.899031E-15  A1       = 0              A2       = 0.9            
+AGS     = 0.1003349      LAGS     = 1.109387E-07   WAGS     = -1.808028E-08  
+PAGS    = -3.240094E-14  B0       = 0              B1       = 0              
+VOFF    = -0.07883818    LVOFF    = 1.372863E-09   WVOFF    = 5.382498E-09   
+PVOFF   = 3.013506E-16   NFACTOR  = 2.339875       LNFACTOR = -9.128134E-08  
+WNFACTOR= -9.812426E-07  PNFACTOR = 1.090812E-13   CIT      = 0.000175593    
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = 0.0005897589   LETA0    = 4.392556E-11   WETA0    = -8.190409E-10  
+PETA0   = 2.776359E-16   ETAB     = 0.001046217    LETAB    = -5.544869E-10  
+DSUB    = 0              PCLM     = 0.759835       LPCLM    = 9.807692E-08   
+WPCLM   = 2.634795E-07   PPCLM    = -5.247116E-14  PDIBLC1  = 0              
+PDIBLC2 = 0.001          PDIBLCB  = -0.001         DROUT    = 0              
+PSCBE1  = 3.14281E+08    PSCBE2   = 3.703335E-07   LPSCBE2  = 1.961538E-13   
+WPSCBE2 = 4.26216E-14    PPSCBE2  = -1.049423E-19  PVAG     = 0.1            
+DELTA   = 0.01           ALPHA0   = 1.33E-06       BETA0    = 25.35          
+KT1     = -0.4401698     LKT1     = 2.839717E-08   WKT1     = 6.664482E-08   
+PKT1    = -2.098847E-14  KT2      = -0.01834       LKT2     = -1.62504E-09   
+AT      = 0              UTE      = -1.503227      LUTE     = 7.924619E-09   
+WUTE    = 1.354765E-07   PUTE     = -4.239671E-15  UA1      = -8.166602E-10  
+LUA1    = -1.890073E-16  WUA1     = 2.195695E-16   PUA1     = 1.844361E-22   
+UB1     = 1.702507E-18   LUB1     = -1.211354E-24  WUB1     = -2.91298E-24   
+PUB1    = 1.137249E-30   UC1      = 1.687623E-10   LUC1     = -4.680813E-17  
+WUC1    = -5.665775E-17  PUC1     = 1.547899E-23   KT1L     = 0              
+PRT     = 0               
+CJ      = cjp3            PB      = 0.7289734       
+MJ      = 0.3909346       CJSW    = cjswp3          PBSW    = 0.7289734       
+MJSW    = 0.2513909       CJSWG   = cjgatep3        PBSWG   = 0.7289734       
+MJSWG   = 0.5427887       CTA     = 7.836E-4        CTP     = 1.301E-4     
+PTA     = 1.739E-3        PTP     = 1.739E-3        CGDO    = cgop3           
+CGSO    = cgop3           JS      = 5.4E-6          JSW     = 1.60E-10        
+N       = 1               XTI     = 3               CAPMOD  = 0               
+NQSMOD  = 0               XPART   = 1               CF      = 0               
+TLEV    = 1               TLEVC   = 1               
+NLEV    = 3               AF      = 1.1             KF      = 2.0E-23        
+CALCACM = 1               SFVTFLAG= 0               VFBFLAG = 1              )

.MODEL pch3.10          PMOS   (                    LMIN     = '1.2E-06-dxl3'   
+LMAX    = 21E-06         WMIN     = 1.8E-07        WMAX     = '5.4E-07-dxw3'  
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxp3          XJ       = 1.8E-07        NCH      = 4.15E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.8E-08        LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.5E-09        
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifp3        
+RSH     = 8.2            RD       = 0              RS       = 0              
+VTH0    = 'dvthp3-0.551653' LVTH0    = 5.250639E-09   WVTH0    = -8.213405E-10  
+PVTH0   = -1.516961E-15  K1       = 0.8743964      LK1      = 8.116454E-08   
+WK1     = 7.898463E-09   PK1      = -4.823143E-14  K2       = -0.01199399    
+LK2     = 5.176319E-09   WK2      = 3.793641E-10   PK2      = -3.02119E-15   
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 94000          UA       = 5.688736E-10   
+LUA     = -1.575363E-16  WUA      = 2.240811E-17   PUA      = 6.019328E-23   
+UB      = 1.036072E-18   LUB      = 1.70296E-25    WUB      = -2.06627E-25   
+PUB     = -2.230208E-33  UC       = -5.784545E-11  LUC      = -3.599839E-17  
+WUC     = -2.124798E-17  PUC      = 2.47989E-23    RDSW     = 1050           
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.01074629     LU0      = -1.03128E-09   WU0      = -6.041833E-10  
+PU0     = 1.741177E-16   A0       = 1              KETA     = 0.09399208     
+LKETA   = -1.43565E-07   WKETA    = -4.939928E-08  PKETA    = 7.065201E-14   
+A1      = 0              A2       = 0.9            AGS      = 0.07972596     
+LAGS    = 1.875893E-07   WAGS     = 4.189879E-09   PAGS     = -6.076587E-14  
+B0      = 0              B1       = 0              VOFF     = -0.05965457    
+LVOFF   = -3.987672E-08  WVOFF    = -1.117308E-08  PVOFF    = 2.094007E-14   
+NFACTOR = 0.2136868      LNFACTOR = -1.09604E-07   WNFACTOR = 3.197408E-07   
+PNFACTOR= 2.685297E-14   CIT      = 0.000175593    CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = 3.556902E-06   
+LETA0   = 9.049039E-11   ETAB     = -6.362699E-06  LETAB    = -3.87816E-11   
+DSUB    = 0              PCLM     = 0.77632        LPCLM    = 2.585441E-07   
+PDIBLC1 = 0              PDIBLC2  = -8.499995E-06  LPDIBLC2 = 5.81724E-10    
+PDIBLCB = -0.001         DROUT    = 0              PSCBE1   = 2.972857E+08   
+LPSCBE1 = -3.437352      PSCBE2   = 2.29866E-06    LPSCBE2  = -1.657267E-12  
+PVAG    = 0.1            DELTA    = 0.01           ALPHA0   = 1.33E-06       
+BETA0   = 25.35          KT1      = -0.3539        LKT1     = 3.87816E-08    
+KT2     = -0.028         AT       = 0              UTE      = -1.247162      
+LUTE    = -4.225813E-07  WUTE     = 4.984192E-08   PUTE     = 8.775993E-14   
+UA1     = 5.048312E-10   LUA1     = -2.07096E-15   WUA1     = 1.411859E-16   
+PUA1    = 2.635135E-22   UB1      = -2.238652E-18  LUB1     = 1.334176E-24   
+WUB1    = 5.577478E-26   PUB1     = -1.051718E-31  UC1      = -4.684495E-12  
+LUC1    = 1.281576E-16   WUC1     = 1.31527E-17    PUC1     = -4.09001E-23   
+KT1L    = 0              PRT      = 0              
+CJ      = cjp3            PB      = 0.7289734       
+MJ      = 0.3909346       CJSW    = cjswp3          PBSW    = 0.7289734       
+MJSW    = 0.2513909       CJSWG   = cjgatep3        PBSWG   = 0.7289734       
+MJSWG   = 0.5427887       CTA     = 7.836E-4        CTP     = 1.301E-4     
+PTA     = 1.739E-3        PTP     = 1.739E-3        CGDO    = cgop3           
+CGSO    = cgop3           JS      = 5.4E-6          JSW     = 1.60E-10        
+N       = 1               XTI     = 3               CAPMOD  = 0               
+NQSMOD  = 0               XPART   = 1               CF      = 0               
+TLEV    = 1               TLEVC   = 1               
+NLEV    = 3               AF      = 1.1             KF      = 2.0E-23        
+CALCACM = 1               SFVTFLAG= 0               VFBFLAG = 1              )

.MODEL pch3.11          PMOS   (                    LMIN     = '5.0E-07-dxl3'   
+LMAX    = '1.2E-06-dxl3' WMIN     = 1.8E-07        WMAX     = '5.4E-07-dxw3'  
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxp3          XJ       = 1.8E-07        NCH      = 4.15E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.8E-08        LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.5E-09        
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifp3        
+RSH     = 8.2            RD       = 0              RS       = 0              
+VTH0    = 'dvthp3-0.560745' LVTH0    = 1.565191E-08   WVTH0    = 1.041114E-09   
+PVTH0   = -3.647609E-15  K1       = 1.04666        LK1      = -1.159054E-07  
+WK1     = -9.151994E-08  PK1      = 6.550323E-14   K2       = -0.03422381    
+LK2     = 3.060724E-08   WK2      = 1.656664E-08   PK2      = -2.153944E-14  
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 91856.55       LVSAT    = 0.002452105    
+WVSAT   = 0.001146745    PVSAT    = -1.311876E-09  UA       = 6.242341E-10   
+LUA     = -2.208687E-16  WUA      = 5.731601E-17   PUA      = 2.025864E-23   
+UB      = 1.1998E-18     LUB      = -1.700884E-26  WUB      = -2.215361E-25  
+PUB     = 1.482582E-32   UC       = -9.467202E-11  LUC      = 6.131201E-18   
+WUC     = 8.034591E-18   PUC      = -8.70036E-24   RDSW     = 1050           
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.0104299      LU0      = -6.693224E-10  WU0      = -5.95325E-10   
+PU0     = 1.63984E-16    A0       = 1              KETA     = -0.0154844     
+LKETA   = -1.832392E-08  WKETA    = 1.169006E-08   PKETA    = 7.658073E-16   
+A1      = 0              A2       = 0.9            AGS      = 0.2313247      
+LAGS    = 1.416027E-08   WAGS     = -5.172175E-08  PAGS     = 3.197039E-15   
+B0      = 0              B1       = 0              VOFF     = -0.1114322     
+LVOFF   = 1.935689E-08   WVOFF    = 1.049423E-08   PVOFF    = -3.847328E-15  
+NFACTOR = 0.1178793      WNFACTOR = 3.432137E-07   CIT      = 0.000175593    
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = -0.0001095634  LETA0    = 2.199E-10      WETA0    = 2.006803E-11   
+PETA0   = -2.295782E-17  ETAB     = -0.0002909462  LETAB    = 2.86782E-10    
+WETAB   = 1.892129E-10   PETAB    = -2.164596E-16  DSUB     = 0              
+PCLM    = 0.8437486      LPCLM    = 1.814057E-07   PDIBLC1  = 0              
+PDIBLC2 = 0.0001828571   LPDIBLC2 = 3.628115E-10   PDIBLCB  = -0.001         
+DROUT   = 0              PSCBE1   = 2.815953E+08   LPSCBE1  = 14.51246       
+PSCBE2  = 1.103714E-06   LPSCBE2  = -2.902491E-13  PVAG     = 0.1            
+DELTA   = 0.01           ALPHA0   = 1.33E-06       BETA0    = 25.35          
+KT1     = -0.3110653     LKT1     = -1.022128E-08  WKT1     = 2.006803E-09   
+PKT1    = -2.295783E-15  KT2      = -0.03126986    LKT2     = 3.740712E-09   
+WKT2    = -2.866863E-10  PKT2     = 3.279691E-16   AT       = 0              
+UTE     = -1.779388      LUTE     = 1.862848E-07   WUTE     = 1.695581E-07   
+PUTE    = -4.919534E-14  UA1      = -1.773808E-09  LUA1     = 5.358036E-16   
+WUA1    = 4.335974E-16   PUA1     = -7.100527E-23  UB1      = -8.014334E-19  
+LUB1    = -3.100015E-25  WUB1     = 3.123193E-27   PUB1     = -4.493841E-32  
+UC1     = 1.435153E-10   LUC1     = -4.138303E-17  WUC1     = -2.753014E-17  
+PUC1    = 5.641068E-24   KT1L     = 0              PRT      = 0             
+CJ      = cjp3            PB      = 0.7289734       
+MJ      = 0.3909346       CJSW    = cjswp3          PBSW    = 0.7289734       
+MJSW    = 0.2513909       CJSWG   = cjgatep3        PBSWG   = 0.7289734       
+MJSWG   = 0.5427887       CTA     = 7.836E-4        CTP     = 1.301E-4     
+PTA     = 1.739E-3        PTP     = 1.739E-3        CGDO    = cgop3           
+CGSO    = cgop3           JS      = 5.4E-6          JSW     = 1.60E-10        
+N       = 1               XTI     = 3               CAPMOD  = 0               
+NQSMOD  = 0               XPART   = 1               CF      = 0               
+TLEV    = 1               TLEVC   = 1               
+NLEV    = 3               AF      = 1.1             KF      = 2.0E-23        
+CALCACM = 1               SFVTFLAG= 0               VFBFLAG = 1              )


.MODEL pch3.12          PMOS   (                    LMIN     = 3.0E-07    
+LMAX    = '5.0E-07-dxl3' WMIN     = 1.8E-07        WMAX     = '5.4E-07-dxw3' 
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxp3          XJ       = 1.8E-07        NCH      = 4.15E+17       
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.8E-08        LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 2.5E-09        
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'   
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 9E-08          HDIF     = hdifp3        
+RSH     = 8.2            RD       = 0              RS       = 0              
+VTH0    = 'dvthp3-0.4872466' LVTH0    = -1.698137E-08  WVTH0    = -2.696818E-08  
+PVTH0   = 8.788521E-15   K1       = 0.6771492      LK1      = 4.815752E-08   
+WK1     = 1.048048E-07   PK1      = -2.166498E-14  K2       = 0.08919834     
+LK2     = -2.419219E-08  WK2      = -4.693251E-08  PK2      = 6.654187E-15   
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 92604.48       LVSAT    = 0.002120022    
+WVSAT   = 0.002052001    PVSAT    = -1.71381E-09   UA       = -1.112368E-09  
+LUA     = 5.501827E-16   WUA      = 5.96448E-16    PUA      = -2.19116E-22   
+UB      = 2.445857E-18   LUB      = -5.702579E-25  WUB      = -6.541156E-25  
+PUB     = 2.068911E-31   UC       = -4.652952E-11  LUC      = -1.524407E-17  
+WUC     = -2.778577E-17  PUC      = 7.203881E-24   RDSW     = 1050           
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.007794895    LU0      = 5.00619E-10    WU0      = 1.55314E-10    
+PU0     = -1.692998E-16  A0       = 1              KETA     = -0.054876      
+LKETA   = -8.340471E-10  WKETA    = 1.522626E-08   PKETA    = -8.042668E-16  
+A1      = 0              A2       = 0.9            AGS      = -0.030096      
+LAGS    = 1.302311E-07   WAGS     = 5.170028E-08   PAGS     = -4.272234E-14  
+B0      = 0              B1       = 0              VOFF     = -0.04488746    
+LVOFF   = -1.018898E-08  WVOFF    = -1.278114E-08  PVOFF    = 6.486937E-15   
+NFACTOR = -0.9604837     LNFACTOR = 4.787931E-07   WNFACTOR = 7.844494E-07   
+PNFACTOR= -1.959086E-13  CIT      = 0.000175593    CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = -0.001410445   
+LETA0   = 7.974914E-10   WETA0    = 2.510681E-10   PETA0    = -1.255219E-16  
+ETAB    = 0.0009441629   LETAB    = -2.616063E-10  WETAB    = 5.459932E-11   
+PETAB   = -1.566912E-16  DSUB     = 0              PCLM     = 1.702937       
+LPCLM   = -2.000741E-07  WPCLM    = -2.410803E-07  PPCLM    = 1.070397E-13   
+PDIBLC1 = 0              PDIBLC2  = 0.001          PDIBLCB  = -0.001         
+DROUT   = 0              PSCBE1   = 3.14281E+08    PSCBE2   = 4.5E-07        
+PVAG    = 0.1            DELTA    = 0.01           ALPHA0   = 1.33E-06       
+BETA0   = 25.35          KT1      = -0.4106731     LKT1     = 3.40046E-08    
+WKT1    = 5.086414E-08   PKT1     = -2.398844E-14  KT2      = -0.01609276    
+LKT2    = -2.997919E-09  WKT2     = -1.202274E-09  PKT2     = 7.344901E-16   
+AT      = 0              UTE      = -1.763858      LUTE     = 1.793894E-07   
+WUTE    = 2.749139E-07   PUTE     = -9.597335E-14  UA1      = -1.497555E-09  
+LUA1    = 4.131477E-16   WUA1     = 5.838486E-16   PUA1     = -1.377169E-22  
+UB1     = -4.809176E-18  LUB1     = 1.469436E-24   WUB1     = 5.707704E-25   
+PUB1    = -2.969738E-31  UC1      = 2.167823E-10   LUC1     = -7.391358E-17  
+WUC1    = -8.234847E-17  PUC1     = 2.998041E-23   KT1L     = 0              
+PRT     = 0           
+CJ      = cjp3            PB      = 0.7289734       
+MJ      = 0.3909346       CJSW    = cjswp3          PBSW    = 0.7289734       
+MJSW    = 0.2513909       CJSWG   = cjgatep3        PBSWG   = 0.7289734       
+MJSWG   = 0.5427887       CTA     = 7.836E-4        CTP     = 1.301E-4     
+PTA     = 1.739E-3        PTP     = 1.739E-3        CGDO    = cgop3           
+CGSO    = cgop3           JS      = 5.4E-6          JSW     = 1.60E-10        
+N       = 1               XTI     = 3               CAPMOD  = 0               
+NQSMOD  = 0               XPART   = 1               CF      = 0               
+TLEV    = 1               TLEVC   = 1               
+NLEV    = 3               AF      = 1.1             KF      = 2.0E-23        
+CALCACM = 1               SFVTFLAG= 0               VFBFLAG = 1              )
*
***************************************************************
*               3.3V NMOS DEVICES MODEL                       *
*                  WITH ESD IMPLANT                           *
***************************************************************
*
*
.MODEL ech3             NMOS   (                    LMIN     = 5E-07          
+LMAX    = 10E-06         WMIN     = 1E-05          WMAX     = 0.0002         
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxe3          XJ       = 3.3E-07        NCH      = 2E+17          
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.064E-08      LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 3.48E-08       
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-2E-08+dxl3'    
+XW      = '0+dxw3'       DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 6.5E-08        HDIF     = hdife3        
+RSH     = 35.52          RD       = 0              RS       = 0              
+RSC     = 0              RDC      = 0              CALCACM  = 1              
+VTH0    = 'dvthe3+0.619' LVTH0    = -2.767951E-08  WVTH0    = 4.111727E-07 
+PVTH0   = 2.865955E-13   K1       = 0.7562578      LK1      = -1.254282E-07  
+WK1     = -4.205232E-07  PK1      = 6.156349E-13   K2       = -0.02476029    
+LK2     = 7.304521E-09   WK2      = 5.674667E-08   PK2      = -1.541741E-13  
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 90000          UA       = -1.336087E-09  
+LUA     = -4.225306E-16  WUA      = 1.529425E-15   PUA      = 8.542471E-22   
+UB      = 2.450673E-18   LUB      = 5.572135E-25   WUB      = -2.86592E-24   
+PUB     = -2.191702E-30  UC       = 7.334567E-11   LUC      = 6.901632E-18   
+WUC     = -1.545609E-16  PUC      = 4.055683E-24   RDSW     = 166.3          
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.03           A0       = 0.2398930      LA0      = 3.455249E-07   
+WA0     = 5.675755E-06   PA0      = -6.269777E-12  KETA     = -0.035233      
+LKETA   = -1.080247E-08  WKETA    = 4.904361E-08   PKETA    = 1.16816E-13    
+A1      = 0              A2       = 0.9            AGS      = 0.381084       
+LAGS    = -1.748792E-07  WAGS     = 1.44393E-06    PAGS     = -6.540588E-13  
+B0      = 0              B1       = 0              VOFF     = -0.2222058     
+LVOFF   = 2.266585E-08   WVOFF    = 4.800931E-07   PVOFF    = -2.250809E-13  
+NFACTOR = 1.560235       CIT      = -0.0001245021  LCIT     = 2.038491E-11   
+WCIT    = 1.732069E-10   PCIT     = -2.024304E-16  CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = 0.0002618002   
+LETA0   = 2.512749E-10   WETA0    = 1.103425E-09   PETA0    = 7.074792E-16     
+ETAB    = 0.0002846984   LETAB    = -3.333496E-10  WETAB    = -8.080077E-10  
+PETAB   = 9.376649E-16   DSUB     = 0              PCLM     = 0.3885748      
+LPCLM   = 1.0443409E-07  WPCLM    = 1.0977581E-06  PPCLM    = 1.2943123E-12    
+PDIBLC1 = 0              PDIBLC2  = -8.837943E-05  LPDIBLC2 = 7.072224E-09   
+WPDIBLC2= 5.623145E-08   PPDIBLC2 = -2.63568E-14   PDIBLCB  = -0.001054183   
+LPDIBLCB= 6.954203E-11   WPDIBLCB = 6.706997E-10   PPDIBLCB = -7.527509E-16  
+DROUT   = 0              PSCBE1   = 2.515116E+08   LPSCBE1  = -8.373891      
+WPSCBE1 = -122.9806      PPSCBE1  = 3.643153E-05   PSCBE2   = 3.292502E-06   
+LPSCBE2 = 6.775879E-13   WPSCBE2  = 3.340624E-12   PPSCBE2  = -9.44022E-18   
+PVAG    = 0.1607327      LPVAG    = -6.980499E-08  WPVAG    = -3.048304E-06  
+PPVAG   = 3.511685E-12   DELTA    = 0.0162277      ALPHA0   = 3.6E-7          
+BETA0   = 16.725         KT1      = -0.3964404     LKT1     = 6.328926E-08   
+WKT1    = 9.595964E-07   PKT1     = -1.009529E-12  KT2      = -0.06825232    
+LKT2    = 3.836596E-09   WKT2     = -7.700292E-08  PKT2     = 2.265909E-13   
+AT      = 10000          UTE      = -1.93252       LUTE     = 2.457967E-07   
+WUTE    = 9.791324E-07   PUTE     = -8.866033E-13  UA1      = 9.177206E-11   
+LUA1    = 8.646131E-17   WUA1     = 2.598262E-15   PUA1     = -3.623213E-22  
+UB1     = -1.257597E-18  LUB1     = 5.013096E-25   WUB1     = -2.995331E-24  
+PUB1    = 6.811535E-31   UC1      = -9.948914E-12  LUC1     = 1.942767E-17   
+WUC1    = 1.454088E-16   PUC1     = -1.290213E-22  KT1L     = 0              
+PRT     = 0               CJ      = cje3            MJ      = 0.3697551       
+PB      = 0.8545          CJSW    = cjswe3          MJSW    = 0.01            
+PBSW    = 0.8545          CJSWG   = cjgatee3        MJSWG   = 0.2376          
+PBSWG   = 0.8545          CTA     = 9.5798E-4       CTP     = 1.596E-4        
+PTA     = 1.830E-3        PTP     = 1.830E-3        JS      = 9.5E-06         
+JSW     = 3.55E-11        N       = 1               XTI     = 3               
+CGDO    = cgoe3           CGSO    = cgoe3           CAPMOD  = 0               
+NQSMOD  = 0               XPART   = 1               CF      = 0               
+TLEV    = 1               TLEVC   = 1               SFVTFLAG= 0               
+VFBFLAG = 1            )
*
.ENDL MOS_3V
*
***************************************************************
*                                                             *
*  Vertical BIPOLAR MODELS for 1.5 device process             *
*                                                             *
***************************************************************
.LIB BIP
*
***************************************************************
*                                                             *
*        MODEL OF P+/NW/PSUB VERTICAL PNP10X10 BIPOLAR        *
*                                                             *
***************************************************************
.MODEL pnp10 PNP (                                  LEVEL  = 1                  
+ BF     = 2.775           NF     = 0.97            ISE    = 4.5E-18            
+ NE     = 1.23            IS     = 4.5E-18         RB     = 105                
+ IRB    = 1.806E-4        RE     = 2.717           IKF    = 1.268E-3           
+ NKF    = 0.47            VAF    = 125             BR     = 9.5E-3             
+ NR     = 0.945           ISC    = 4.5E-18         NC     = 1.6                
+ RC     = 21.08           IKR    = 1E-5            VAR    = 20                 
+ XTI    = 3               EG     = 1.18            XTB    = 0                  
+ TRB1   = 9.756E-4        TIRB1  = 1.052E-7        TRE1   = -1.826E-4          
+ TRM1   = 9.44E-6         TIKF1  = -3.845E-3       TIKR1  = -1.925E-3          
+ TRC1   = 1.509764E-4     TBF1   = 4.5E-3          TVAF1  = -4.5E-8            
+ TBR1   = 1.03398E-5      TNC1   = 1E-5            TNR1   = -5.63854E-4        
+ TNF1   = -2.205E-4       TNE1   = 1E-3            CJE    = 1.17815E-13        
+ VJE    = 0.82245         MJE    = 0.40377         FC     = 0                  
+ CJC    = 6.6929E-14      VJC    = 0.55            MJC    = 0.35            
+ TLEVC  = 1               CTE    = 8.5E-4          CTC    = 3.21E-3          
+ TVJE   = 1.9255E-3       TVJC   = 2.8E-3          TREF   = 25                 
+ SUBS   = 1               RBM    = 0.1            TLEV    = 0                  
+TBR2    = 1.035E-5       TBF2    = 5E-6           TVAR1   = -1.211E-3          
+TNF2    = -1E-7           )           
*
***************************************************************
*                                                             *
*       MODEL OF P+/NW/PSUB VERTICAL PNP5X5 BIPOLAR           *
*                                                             *
***************************************************************
.MODEL pnp5 PNP (                                  LEVEL  = 1                 
+ BF     = 2.78            NF     = 0.96            ISE    = 1E-18              
+ NE     = 1.23            IS     = 1E-18           RB     = 200                
+ IRB    = 7.806E-5        RE     = 3.717           IKF    = 8E-4               
+ NKF    = 0.47            VAF    = 140             BR     = 3.8E-3             
+ NR     = 0.935           ISC    = 1E-18           NC     = 1.161              
+ RC     = 21.08           IKR    = 1E-4            VAR    = 20                 
+ XTI    = 3               EG     = 1.18            XTB    = 0                  
+ TRB1   = 1E-3            TIRB1  = 1.052E-3        TRE1   = -5E-4              
+ TRM1   = 9.44E-6         TIKF1  = -3.845E-3       TIKR1  = -3.925E-3          
+ TRC1   = 0               TBF1   = 5.2E-3          TVAF1  = -1.95E-4           
+ TBR1   = 9E-5            TNC1   = 1.27841E-4      TNR1   = -1E-3              
+ TNF1   = -2.05E-4        TNE1   = 1E-3            CJE    = 3.1304E-14      
+ VJE    = 0.8224          MJE    = 0.40377         FC     = 0                  
+ CJC    = 3.9906E-14      VJC    = 0.55            MJC    = 0.35            
+ TLEVC  = 1               CTE    = 8.5E-4          CTC    = 3.21E-3          
+ TVJE   = 1.9255E-3       TVJC   = 2.8E-3          TREF   = 25                 
+ SUBS   = 1               RBM    = 0.1            TLEV    = 0                  
+TBR2    = 3E-5           TBF2    = 6E-6           TVAR1   = -1.225E-3          
+TNF2    = -5E-7           )      
                        
*                                                                               
***************************************************************
*                                                             *
*       MODEL OF P+/NW/PSUB VERTICAL PNP2X2 BIPOLAR           *
*                                                             *
***************************************************************
.MODEL pnp2 PNP (                                   LEVEL  = 1                  
+ BF     = 2.85            NF     = 0.965           ISE    = 2.5E-19            
+ NE     = 1.255           IS     = 2.5E-19         RB     = 300                
+ IRB    = 7.806E-5        RE     = 7.717           IKF    = 3E-4               
+ NKF    = 0.42            VAF    = 80.88           BR     = 1.25E-3            
+ NR     = 0.95            ISC    = 2.5E-19         NC     = 1.17               
+ RC     = 21.08           IKR    = 1E-4            VAR    = 15                 
+ XTI    = 3               EG     = 1.18            XTB    = 0                  
+ TRB1   = 5.256E-4        TIRB1  = 1.052E-3        TRE1   = -1.226E-5          
+ TRM1   = 9.44E-6         TIKF1  = -4.545E-3       TIKR1  = -0.3925            
+ TRC1   = 0               TBF1   = 6E-3            TVAF1  = -1.95E-3           
+ TBR1   = 9E-4            TNC1   = 1.0173E-5       TNR1   = 8E-7               
+ TNF1   = -1.905E-4       TNE1   = 1.2E-3          CJE    = 5.8965E-15       
+ VJE    = 0.82245         MJE    = 0.40377         FC     = 0                  
+ CJC    = 2.6357E-14      VJC    = 0.55            MJC    = 0.35             
+ TLEVC  = 1               CTE    = 8.5E-4          CTC    = 3.21E-3           
+ TVJE   = 1.9255E-3       TVJC   = 2.8E-3          TREF   = 25                 
+ SUBS   = 1               RBM    = 0.1            TLEV    = 0                  
+TBR2    = 1E-5           TBF2    = 2E-6           TVAR1   = -1E-3              
+TNF2    = -1E-7           ) 
*                                                                         
.ENDL BIP 
*
***************************************************************
*                                                             *
*  Vertical BIPOLAR MODELS for 3.3 device process             *
*                                                             *
***************************************************************
*
.LIB BIP3  
***************************************************************
*                                                             *
*        MODEL OF P+/NW/PSUB VERTICAL PNP10X10 BIPOLAR        *
*                                                             *
***************************************************************
*
*
*
.MODEL pnp10_3 PNP (                                LEVEL  = 1                  
+ SUBS   = 1               IS     = 8.46269E-18     BF     = 2.2871658          
+ NF     = 0.98672         VAF    = 210.8           IKF    = 2.564479E-3        
+ ISE    = 8.46269E-18     NE     = 1.247685        BR     = 0.0375             
+ NR     = 0.9731844       VAR    = 29              IKR    = 1E-4               
+ ISC    = 8.46269E-18     NC     = 1.0985          RB     = 118.8595944        
+ IRB    = 1.806E-4        RBM    = 0.1             RE     = 2                  
+ RC     = 20              XTI    = 3               EG     = 1.18               
+ XTB    = 0               CJE    = 1.31E-13        VJE    = 0.7289             
+ MJE    = 0.3909          FC     = 0               CJC    = 6.65453E-14        
+ VJC    = 0.67            MJC    = 0.39            NKF    = 0.5048667          
+TRB1    = 9.546411E-4    TIRB1   = 1.052E-7       TRE1    = -2.282413E-4       
+TIKF1   = -2.725794E-3   TBF1    = 5.142387E-3    TVAF1   = -6.95E-5           
+TBR1    = -4E-4          TNE1    = -1.569013E-5   TNF1    = -2.168943E-5       
+TNR1    = -7.73E-5       TLEVC   = 1              CTE     = 1.220089E-3         
+CTC     = 2.301159E-3    TVJE    = 1.739E-3       TVJC    = 2.761789E-3           
+TREF    = 25             TLEV    = 0              TBR2    = 9.35E-6            
+TBF2    = 4.083754E-6    TVAR1   = -6.211E-3      TNF2    = -5E-7           )  
*
*
***************************************************************
*                                                             *
*       MODEL OF P+/NW/PSUB VERTICAL PNP5X5 BIPOLAR           *
*                                                             *
***************************************************************
*
.MODEL pnp5_3 PNP (                                 LEVEL  = 1                  
+ SUBS   = 1               IS     = 2.54648E-18     BF     = 2.23               
+ NF     = 0.988504        VAF    = 210.8           IKF    = 1.201E-3           
+ ISE    = 2.54648E-18     NE     = 1.212           BR     = 0.0122             
+ NR     = 0.97            VAR    = 27              IKR    = 1E-4               
+ ISC    = 2.54648E-18     NC     = 1.1             RB     = 165.026            
+ IRB    = 1.806E-4        RBM    = 0.1             RE     = 2                  
+ RC     = 21.08           XTI    = 3               EG     = 1.18               
+ XTB    = 0               CJE    = 3.452E-14       VJE    = 0.7289             
+ MJE    = 0.3909          FC     = 0               CJC    = 3.91164E-14            
+ VJC    = 0.67            MJC    = 0.39            NKF    = 0.5                
+TRB1    = 9.54641E-4     TIRB1   = 1.052E-7       TRE1    = -2.28241E-4        
+TIKF1   = -3.07258E-3    TBF1    = 5.60822E-3     TVAF1   = -6.95E-5           
+TBR1    = -4E-4          TNE1    = -1.56901E-5    TNF1    = -2.16894E-5        
+TNR1    = -7.73E-5       TLEVC   = 1              CTE     = 1.220089E-3           
+CTC     = 2.301159E-3    TVJE    = 1.739E-3       TVJC    = 2.761789E-3           
+TREF    = 25             TLEV    = 0              TBR2    = 9.35E-6            
+TBF2    = 5.67144E-6     TVAR1   = -6.216142E-3   TNF2    = -5E-7           )  
*
***************************************************************
*                                                             *
*       MODEL OF P+/NW/PSUB VERTICAL PNP2X2 BIPOLAR           *
*                                                             *
***************************************************************
*                                                                     
.MODEL pnp2_3 PNP (                                 LEVEL  = 1                  
+ SUBS   = 1               IS     = 8.255329E-19    BF     = 2.05               
+ NF     = 1.0034417       VAF    = 210.8           IKF    = 3.81E-4            
+ ISE    = 8.255329E-19    NE     = 1.25            BR     = 3E-3               
+ NR     = 0.9913484       VAR    = 29              IKR    = 1E-4               
+ ISC    = 8.255329E-19    NC     = 0.9595          RB     = 270.849895         
+ IRB    = 1.806E-4        RBM    = 0.1             RE     = 2.5                
+ RC     = 21.08           XTI    = 3               EG     = 1.18               
+ XTB    = 0               CJE    = 6.38E-15        VJE    = 0.7289             
+ MJE    = 0.3909          FC     = 0               CJC    = 2.55537E-14            
+ VJC    = 0.67            MJC    = 0.39            NKF    = 0.45               
+TRB1    = 7.548792E-4    TIRB1   = 1.052E-7       TRE1    = -1.849742E-4       
+TIKF1   = -3.87258E-3    TBF1    = 6.531735E-3    TVAF1   = -6.95E-5           
+TBR1    = -4E-4          TNE1    = -1.169384E-5   TNF1    = 2.849184E-5        
+TNR1    = -7.73E-5       TLEVC   = 1              CTE     = 1.22089E-3           
+CTC     = 2.301159E-3    TVJE    = 1.739E-3       TVJC    = 2.761789E-3           
+TREF    = 25             TLEV    = 0              TBR2    = 9.35E-6            
+TBF2    = 7.088734E-6    TVAR1   = -7.21614E-3    TNF2    = -8E-7           )  
*                                                                               
*                                                                                                                                                              *                                                                               
.ENDL BIP3                                                                      
*
*                                                                       
***************************************************************
*                                                             *
*       Junction DIODE MODELS  for 1.5 device process         *
*                                                             *
***************************************************************
*
.LIB DIO                                                                        
*
*
***************************************************************
*                      MODEL OF N+/PW DIODE                   *
*                                                             *
***************************************************************
.MODEL NDIO D (                                     LEVEL  = 3                  
+ IS     = 7.15E-6         RS     = 2.65E-7         N      = 1.28               
+ BV     = 10.8            IBV    = 0.03            IK     = 1E20               
+ IKR    = 1E10            JSW    = 8.3E-12         AREA   = 7.5E-8             
+ PJ     = 1.1E-3          CJ     = 1.203895E-3     PB     = 0.7802155        
+ MJ     = 0.440821        CJSW   = 2.089474E-10    PHP    = 0.7802155         
+ MJSW   = 0.443955        TLEV   = 1               EG     = 1.17               
+ XTI    = 3               TCV    = -4E-4           TRS    = 1.4E-3             
+ TLEVC  = 1               CTA    = 1.01709E-3      CTP    = 7.730462E-4     
+ TPB    = 1.464986E-3     TPHP   = 1.464986E-3     TREF   = 25                 
+ FC     = 0               FCS    = 0  )
*                                                                                                               *                                                                               
***************************************************************
*                      MODEL OF P+/NW DIODE                   *
*                                                             *
***************************************************************
.MODEL PDIO D (                                     LEVEL  = 3                  
+ IS     = 1.42E-6         RS     = 2.7E-7          N      = 1.2                
+ BV     = 10.2            IBV    = 0.03            IK     = 1E20               
+ IKR    = 1E10            JSW    = 2.5E-12         AREA   = 7.5E-8            
+ PJ     = 0.0011          CJ     = 1.104157E-3     PB     = 0.82245           
+ MJ     = 0.40377         CJSW   = 1.84991E-10     PHP    = 0.82245          
+ MJSW   = 0.3932347       TLEV   = 1               EG     = 1.17               
+ XTI    = 3               TCV    = -8.9E-4         TRS    = 1.4E-3             
+ TLEVC  = 1               CTA    = 9.560416E-4     CTP    = 6.629025E-4       
+ TPB    = 1.925529E-3     TPHP   = 1.925529E-3     TREF   = 25                 
+ FC     = 0               FCS    = 0    )    
*                                                                                                                                             
***************************************************************
*                      MODEL OF NW/PSUB DIODE                 *
*                                                             *
***************************************************************
.MODEL NWDIO D (                                    LEVEL  = 3                  
+ IS     = 1.122E-5        RS     = 2.3E-7          N      = 1.32               
+ BV     = 14.7            IBV    = 0.03            IK     = 1E20               
+ IKR    = 1E10            JSW    = 3.27E-11        AREA   = 7.5E-8            
+ PJ     = 0.0011          CJ     = 1.156376E-4     PB     = 0.6678004          
+ MJ     = 0.4219964       CJSW   = 5.291044E-10    PHP    = 0.6678004          
+ MJSW   = 0.2512028       TLEV   = 1               EG     = 1.16               
+ XTI    = 3               TCV    = -9.1E-4         TRS    = 2.78E-3            
+ TLEVC  = 1               CTA    = 2.541522E-3     CTP    = 1.377391E-3        
+ TPB    = 2.757042E-3     TPHP   = 2.757042E-3     TREF   = 25                 
+ FC     = 0               FCS    = 0    )                                                                             
.ENDL DIO   
*
*                                                                       
***************************************************************
*                                                             *
*       Junction DIODE MODELS  for 3.3 device process         *
*                                                             *
***************************************************************
*
.LIB DIO3                                                                       
*
***************************************************************
*                      MODEL OF N+/PW DIODE                   *
*                                                             *
***************************************************************
*                                                                  
.MODEL NDIO_3 D (                                   LEVEL  = 3                  
+ IS     = 1E-5            RS     = 1.149E-7        N      = 1.4022          
+ BV     = 11.5            IBV    = 0.03            IK     = 1E20               
+ IKR    = 1E10            JSW    = 2.059E-11       AREA   = 7.5E-8             
+ PJ     = 1.1E-3          CJ     = 8.911E-4        PB     = 0.8545          
+ MJ     = 0.3436          CJSW   = 1.486E-10       PHP    = 0.8545           
+ MJSW   = 0.01            TLEV   = 1               EG     = 1.17               
+ XTI    = 3               TCV    = -6E-4           TRS    = 3.222E-3           
+ TLEVC  = 1               CTA    = 8.836E-4        CTP    = 1.200E-4        
+ TPB    = 1.830E-3        TPHP   = 1.830E-3        TREF   = 25                
+ FC     = 0               FCS    = 0 )      
*                                                                               
*                                                                               
***************************************************************
*                      MODEL OF P+/NW DIODE                   *
*                                                             *
***************************************************************
*                                                                   
.MODEL PDIO_3 D (                                   LEVEL  = 3                  
+ IS     = 5.4E-6          RS     = 1.049E-7        N      = 1.322              
+ BV     = 10.75           IBV    = 0.03            IK     = 1E20               
+ IKR    = 1E10            JSW    = 8.815E-11       AREA   = 7.5E-8             
+ PJ     = 1.1E-3          CJ     = 0.001238        PB     = 0.7289
+ MJ     = 0.3909          CJSW   = 1.785E-10       PHP    = 0.7289          
+ MJSW   = 0.2513          TLEV   = 1               EG     = 1.17               
+ XTI    = 3               TCV    = -8E-4           TRS    = 3.549E-3           
+ TLEVC  = 1               CTA    = 1.132198E-3     CTP    = 1.450717E-3        
+ TPB    = 1.739E-3        TPHP   = 1.739E-3        TREF   = 25                 
+ FC     = 0               FCS    = 0 )             
*                                                                               
*                                                                               
*                                                                               
.ENDL DIO3 
*
.lib RES
**************************************************************************  
.subckt rppolywo n1 n2 l=length w=width
.param rsh=360 dw=0u ptc1=-1.78e-4 ptc2=3.53e-7 pvc1=-2.22e-4 pvc2=-3.35e-5 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rppolywo

.subckt rppolyl n1 n2 l=length w=width
.param rsh=7.8 dw=0.02u ptc1=2.90e-3 ptc2=5.43e-7 pvc1=3.05e-3 pvc2=6.04e-3 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rppolyl

.subckt rppolys n1 n2 l=length w=width
.param rsh=7.4 dw=0.02u ptc1=3.16e-3 ptc2=2.46e-7 pvc1=1.60e-4 pvc2=2.42e-3 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rppolys

.subckt rnpolywo n1 n2 l=length w=width
.param rsh=320 dw=0.0u ptc1=-1.3e-3 ptc2=2.07e-6 pvc1=1.76e-3 pvc2=-2.5e-4 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rnpolywo

.subckt rnpolyl n1 n2 l=length w=width
.param rsh=7.4 dw=0.02u ptc1=2.91e-3 ptc2=2.74e-7 pvc1=4.32e-3 pvc2=5.94e-3 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rnpolyl

.subckt rnpolys n1 n2 l=length w=width
.param rsh=5.5 dw=0.02u ptc1=3.42e-3 ptc2=6.76e-7 pvc1=1.49e-3 pvc2=3.08e-3 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rnpolys

.subckt rnodwo n1 n2 l=length w=width
.param rsh=77 dw=0.0u ptc1=1.78e-3 ptc2=2.67e-7 pvc1=7.81e-4 pvc2=1.89e-4 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rnodwo

.subckt rnodl n1 n2 l=length w=width
.param rsh=6 dw=-0.083u ptc1=3.09e-3 ptc2=3.33e-7 pvc1=9.73e-4 pvc2=1.42e-3 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rnodl

.subckt rnods n1 n2 l=length w=width
.param rsh=4.5 dw=-0.083u ptc1=3.36e-3 ptc2=7.12e-7 pvc1=8.54e-4 pvc2=5.44e-4 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rnods

.subckt rpodwo n1 n2 l=length w=width
.param rsh=150 dw=0.00u ptc1=1.49e-3 ptc2=8.00e-7 pvc1=2.61e-4 pvc2=1.44e-4 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rpodwo

.subckt rpodl n1 n2 l=length w=width
.param rsh=6.5 dw=-0.094u ptc1=3.10e-3 ptc2=3.15e-7 pvc1=-3.07e-4 pvc2=1.49e-3 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rpodl

.subckt rpods n1 n2 l=length w=width
.param rsh=4.5 dw=-0.094u ptc1=3.45e-3 ptc2=5.76e-7 pvc1=-3.83e-4 pvc2=6.75e-4 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rpods

.subckt rnwod n1 n2 l=length w=width
.param rsh=450 dw=0.00u ptc1=2.98e-3 ptc2=9.29e-6 pvc1=4.36e-3 pvc2=-2.06e-4 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rnwod

.subckt rnwsti n1 n2 l=length w=width
.param rsh=870 dw=0.00u ptc1=2.96e-3 ptc2=9.88e-6 pvc1=7.91e-3 pvc2=-4.60e-4 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rnwsti

.subckt rm1 n1 n2 l=length w=width
.param rsh=0.125 dw=0.02u ptc1=3.10e-3 ptc2=-3.89e-7 pvc1=0 pvc2=0 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rm1

.subckt rm2 n1 n2 l=length w=width
.param rsh=0.078 dw=0.03u ptc1=3.26e-3 ptc2=-1.53e-7 pvc1=0 pvc2=0 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rm2

.subckt rm3 n1 n2 l=length w=width
.param rsh=0.078 dw=0.03u ptc1=3.26e-3 ptc2=-1.53e-7 pvc1=0 pvc2=0 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rm3

.subckt rm4 n1 n2 l=length w=width
.param rsh=0.078 dw=0.03u ptc1=3.26e-3 ptc2=-1.53e-7 pvc1=0 pvc2=0 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rm4

.subckt rm5 n1 n2 l=length w=width
.param rsh=0.078 dw=0.03u ptc1=3.26e-3 ptc2=-1.53e-7 pvc1=0 pvc2=0 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rm5

.subckt rm6 n1 n2 l=length w=width
.param rsh=0.078 dw=0.03u ptc1=3.26e-3 ptc2=-1.53e-7 pvc1=0 pvc2=0 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rm6


.subckt rm7 n1 n2 l=length w=width
.param rsh=0.036 dw=0.03u ptc1=3.50e-3 ptc2=2.19e-7 pvc1=0 pvc2=0 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rm7
.endl RES                                                                     
                                                                     
