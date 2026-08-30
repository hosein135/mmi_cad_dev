*  **********************************************
*  *             TSMC SPICE MODEL               *
*  **********************************************
*  
*    PROCESS :  TSMC 0.15um LOGIC 1P7M SALICIDE 1.5V/3.3V
*    DOC. NO.:  T-015-LO-SP-002
*    VERSION :  1.0 
*    DATE    :  May 15, 2000
*    HSPICE VERSION : For H98.2, H98.4
*
******************************************************************************
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
*        ( 3.3V normal devices with different geometric and corner models)   *
*                                                                            *
*       3.LIB BIP                                                            *
*        ( 1.5V P+/NW/PSUB 10x10,5x5 and 2x2 vertical PNP bipolar )          *
*                                                                            *
*       4.LIB BIP3                                                           *
*        ( 3.3V P+/NW/PSUB 10x10,5x5 and 2x2 vertical PNP bipolar )          *
*                                                                            *
*       5.LIB DIO                                                            *
*        ( 1.5V P+/NW ,N+/PW & NW/PSUB diode )                               *
*                                                                            *
*       6.LIB DIO3                                                           *
*        ( 3.3V P+/NW ,N+/PW diode )                                         *
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
*    EX: .lib '/home/user/tsmc/LOGIC/log015.l' TT                            *
*        for typical 1.5V N,PMOS                                             *
*        .lib '/home/user/tsmc/LOGIC/log015.l' TT_3V                         *
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
* 2)HDIF is the half distance from spacer edge to OD edge.                   *
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
.param
+toxn   = 3.51E-09        cjn    = 0.001038     cjswn  = 2.197E-10   
+cjgaten= 4.524E-10       cgon   = 4.185E-10        
+dvthn  = 0.              hdifn  = 1.5875E-07     
+toxp   = 3.474E-09       cjp    = 1.157E-3     cjswp  = 2.131E-10   
+cjgatep= 4.560E-10       cgop   = 3.419E-10       
+dvthp  = 0               hdifp  = 1.5875E-07     
+dxl    = 0               dxw    = 0              
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15.mod' MOS
.ENDL TT
***************** CORNER_LIB OF SNSP MODEL ****************************
.LIB SS
.param
+toxn   = 3.6033e-09      cjn    = 0.00109    cjswn  = 2.306E-10   
+cjgaten= 4.750E-10       cgon   = 3.976E-10       
+dvthn  = 0.06            hdifn  = 1.5875E-07     
+toxp   = 3.5673E-09      cjp    = 1.215E-3    cjswp  = 2.237E-10   
+cjgatep= 4.787e-10       cgop   = 3.248E-10      
+dvthp  = -0.04           hdifp  = 1.5875E-07     
+dxl    = 1.0E-8          dxw    = -1.2E-8
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15.mod' MOS
.ENDL SS
***************** CORNER_LIB OF FNFP MODEL ****************************
.LIB FF
.param
+toxn   = 3.4167e-09      cjn    = 0.0009861     cjswn  = 2.087E-10   
+cjgaten= 4.298E-10       cgon   = 4.394E-10       
+dvthn  = -0.06           hdifn  = 1.5875E-07     
+toxp   = 3.3807E-09      cjp    = 1.099E-3      cjswp  = 2.024E-10   
+cjgatep= 4.332E-10       cgop   = 3.589E-10      
+dvthp  = 0.04            hdifp  = 1.5875E-07     
+dxl    = -1.0E-8         dxw    = 1.2E-08
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15.mod' MOS
.ENDL FF
***************** CORNER_LIB OF SNFP MODEL ****************************
.LIB SF
.param
+toxn   = 3.51e-09        cjn    = 0.00109    cjswn  = 2.306E-10   
+cjgaten= 4.75E-10        cgon   = 4.185E-10        
+dvthn  = 0.06            hdifn  = 1.5875E-07     
+toxp   = 3.474E-09       cjp    = 1.099E-3    cjswp  = 2.024E-10   
+cjgatep= 4.332E-10       cgop   = 3.419E-10       
+dvthp  = 0.04            hdifp  = 1.5875E-07     
+dxl    = 0               dxw    = 0              
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15.mod' MOS
.ENDL SF
***************** CORNER_LIB OF FNSP MODEL ****************************
.LIB FS
.param
+toxn   = 3.51e-09        cjn    = 0.0009861      cjswn  = 2.087E-10   
+cjgaten= 4.298E-10       cgon   = 4.185E-10        
+dvthn  = -0.06           hdifn  = 1.5875E-07     
+toxp   = 3.474E-09       cjp    = 1.215E-3       cjswp  = 2.237E-10   
+cjgatep= 4.787E-10       cgop   = 3.419E-10       
+dvthp  = -0.04           hdifp  = 1.5875E-07     
+dxl    = 0               dxw    = 0              
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15.mod' MOS
.ENDL FS
***************************************************************
*
***************************************************************
*                                                             *
*                3.3V NORMAL DEVICES LIB                      *
*                                                             *
***************************************************************
**************** CORNER_LIB OF TYPICAL MODEL ****************************
.LIB TT_3V
.param toxn3 = 7.19E-09  toxp3 = 7.06E-09  
+dxl3 = 0 dxw3 = 0
+dvthn3 = 0              dvthp3 = 0  
+cjn3 = 8.91153E-4       cjp3 = 0.00123885      
+cjswn3 = 1.48665E-10    cjswp3 = 1.78516E-10   
+cjgaten3 = 1.70610E-10  cjgatep3 = 2.619152E-10 
+cgon3 = 2.66716E-10     cgop3 = 2.4926E-10  
+hdifn3 = 2E-07          hdifp3 = 2E-07  
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15.mod' MOS_3V
.ENDL TT_3V
**************** CORNER_LIB OF SNSP MODEL ****************************
.LIB SS_3V
.param toxn3 = 7.66E-09 toxp3 = 7.53E-09  
+dxl3 = 1.0E-08 dxw3 = -1.2E-08 
+dvthn3 = 0.10           dvthp3 = -0.10   
+cjn3 = 9.35711E-04      cjp3 = 1.30079E-03     
+cjswn3 = 1.56098E-10    cjswp3 = 1.87442E-10     
+cjgaten3 = 1.79141E-10  cjgatep3 = 2.75011E-10    
+cgon3 = 2.53380E-10     cgop3 = 2.36797E-10  
+hdifn3 = 2E-07          hdifp3 = 2E-07  
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15.mod' MOS_3V
.ENDL SS_3V
**************** CORNER_LIB OF FNFP MODEL ****************************
.LIB FF_3V
.param toxn3 = 6.72E-09 toxp3 = 6.59E-09  
+dxl3 = -1.0E-08 dxw3 = 1.2E-08
+dvthn3 = -0.10          dvthp3 = 0.10  
+cjn3 = 8.46595E-04      cjp3 = 1.17691E-03  
+cjswn3 = 1.41232E-10    cjswp3 = 1.69590E-10    
+cjgaten3 = 1.62080E-10  cjgatep3 = 2.48819E-10  
+cgon3 = 2.80052E-10     cgop3 = 2.61723E-10  
+hdifn3 = 2E-07          hdifp3 = 2E-07  
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15.mod' MOS_3V
.ENDL FF_3V
**************** CORNER_LIB OF SNFP MODEL ****************************
.LIB SF_3V
.param toxn3 = 7.19E-09  toxp3 = 7.06E-09  
+dxl3 = 0 dxw3 = 0
+dvthn3 = 0.10           dvthp3 = 0.10  
+cjn3 = 9.35711E-04      cjp3 = 1.17691E-03   
+cjswn3 = 1.56098E-10    cjswp3 = 1.69590E-10  
+cjgaten3 = 1.79141E-10  cjgatep3 = 2.48819E-10  
+cgon3 = 2.66716E-10     cgop3 = 2.49260E-10  
+hdifn3 = 2E-07          hdifp3 = 2E-07  
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15.mod' MOS_3V
.ENDL SF_3V
**************** CORNER_LIB OF FNSP MODEL ****************************
.LIB FS_3V
.param toxn3 = 7.19E-09  toxp3 = 7.06E-09  
+dxl3 = 0 dxw3 = 0
+dvthn3 = -0.10          dvthp3 = -0.10  
+cjn3 = 8.46595E-04      cjp3 = 1.30079E-03   
+cjswn3 = 1.41232E-10    cjswp3 = 1.87442E-10   
+cjgaten3 = 1.62080E-10  cjgatep3 = 2.75011E-10  
+cgon3 = 2.66716E-10     cgop3 = 2.49260E-10  
+hdifn3 = 2E-07          hdifp3 = 2E-07  
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15.mod' MOS_3V
.ENDL FS_3V
*
*
.LIB MOS
***************************************************************
*                                                             *
*               1.5V NMOS DEVICES MODEL                       *
*                                                             *
***************************************************************
*
.MODEL n.1            NMOS   (                    LMIN     = '1.193E-06-dxl'      
+LMAX    = 20.E-05        WMIN     = '1.005E-05-dxw' WMAX     = 0.000201    
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn           XJ       = 1.6E-07        NCH      = 6.7296E+17     
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.45E-08       WINT     = 1.25E-08       
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-1.5E-8+dxl'              
+XW      = '0+dxw'        DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 8.5E-08        HDIF     = hdifn       
+RSH     = 6              RD       = 0              RS       = 0              
+VTH0    = '0.3918394+dvthn' LVTH0    = 5.593829E-08   WVTH0    = -1.140931E-07  
+PVTH0   = 8.292996E-14   K1       = 0.4679653      LK1      = 3.896118E-08   
+WK1     = -7.730763E-08  PK1      = -2.671177E-13  K2       = 0.01273306     
+LK2     = -3.125741E-10  WK2      = -2.686016E-08  PK2      = 3.126523E-14   
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 88686.6        LVSAT    = 0.003720521    
+WVSAT   = 0.003743298    PVSAT    = -3.729822E-08  UA       = -1.18687E-09   
+LUA     = -5.536939E-16  WUA      = 1.797755E-15   PUA      = 2.308672E-21   
+UB      = 2.892547E-18   LUB      = 4.520279E-25   WUB      = -4.443575E-24  
+PUB     = -9.85314E-31   UC       = 1.240621E-10   LUC      = 1.000681E-16   
+WUC     = -4.259552E-16  PUC      = -4.450828E-22  RDSW     = 120            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.03448931     LU0      = -5.044066E-09  WU0      = -1.280753E-08  
+PU0     = 5.876133E-14   A0       = 1.564619       LA0      = -4.241039E-07  
+WA0     = 1.507065E-08   PA0      = -2.199067E-12  KETA     = -0.02857767    
+LKETA   = -2.260867E-08  WKETA    = 1.666842E-07   PKETA    = 1.926321E-13   
+A1      = 0              A2       = 0.99           AGS      = 0.52908        
+LAGS    = 3.945904E-07   WAGS     = -3.076243E-07  PAGS     = -1.859933E-12  
+B0      = 0              B1       = 0              VOFF     = -0.09656381    
+LVOFF   = -3.711379E-08  WVOFF    = 8.49013E-09    PVOFF    = 1.879905E-13   
+NFACTOR = 0.7814587      LNFACTOR = -6.445491E-07  WNFACTOR = -5.025528E-06  
+PNFACTOR= 8.443495E-12   CIT      = 0.0003424583   LCIT     = 1.013805E-09   
+WCIT    = 8.815001E-09   PCIT     = -1.229173E-14  CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = 0.000158053    
+LETA0   = 3.074703E-10   WETA0    = -1.112395E-09  PETA0    = 2.202651E-15   
+ETAB    = -3.677769E-05  LETAB    = 5.710346E-11   WETAB    = 4.107009E-10   
+PETAB   = -3.188557E-15  DSUB     = 0              PCLM     = 2.057558       
+LPCLM   = -8.814139E-07  WPCLM    = -1.725517E-05  PPCLM    = 2.618247E-11   
+PDIBLC1 = 0              PDIBLC2  = 0.0008922117   LPDIBLC2 = 4.550154E-09   
+WPDIBLC2= 4.053038E-08   PPDIBLC2 = -6.385926E-14  PDIBLCB  = 0.00101336     
+DROUT   = 0              PSCBE1   = 7.257309E+08   PSCBE2   = 4.06E-07       
+PVAG    = 0              DELTA    = 0.005                         
+KT1     = -0.22          KT2      = -0.022         
+AT      = 36634.44       LAT      = 0.0584444      WAT      = 0.05880219     
+PAT     = -5.859051E-07  UTE      = -1.374271      LUTE     = -4.562745E-08  
+WUTE    = -4.590677E-08  PUTE     = 4.574152E-13   UA1      = 1.83245E-09    
+LUA1    = -1.188371E-16  WUA1     = -1.719319E-16  PUA1     = 1.191342E-21   
+UB1     = -1.781333E-18  LUB1     = -3.808407E-25  WUB1     = -4.277395E-25  
+PUB1    = 3.817929E-30   UC1      = -8.959999E-11  KT1L     = 0              
+NLEV    = 3              AF       = 1.05           KF       = 4.2E-24
+PRT     = 0              ALPHA0   = 3.49E-08       BETA0    = 10.7
+CJ      = cjn            PB       = 0.854656       MJ       = 0.3995675      
+CJSW    = cjswn          PBSW     = 0.854656       MJSW     = 0.5138515       
+CJSWG   = cjgaten        PBSWG    = 0.854656       MJSWG    = 0.5138515 
+CGDO    = cgon           CGSO     = cgon           CTA      = 9.993914E-4    
+CTP     = 3.73684E-3     PTA      = 2.163759E-3    PTP      = 2.163759E-3
+JS      = 5.4E-6         JSW      = 2.94e-9        CAPMOD   = 0
+NQSMOD  = 0              XPART    = 1
+CALCACM = 1              SFVTFLAG = 0              VFBFLAG  = 1   
+CF      = 0              TLEV     = 1              TLEVC   = 1       )

.MODEL n.2            NMOS   (                    LMIN     = '4.93E-07-dxl'       
+LMAX    = '1.193E-06-dxl' WMIN     = '1.005E-05-dxw' WMAX     = 0.000201     
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn           XJ       = 1.6E-07        NCH      = 6.7296E+17     
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.45E-08       WINT     = 1.25E-08       
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-1.5E-8+dxl'              
+XW      = '0+dxw'        DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 8.5E-08        HDIF     = hdifn       
+RSH     = 6              RD       = 0              RS       = 0              
+VTH0    = '0.4224661+dvthn' LVTH0    = 2.028882E-08   WVTH0    = -7.12492E-08   
+PVTH0   = 3.305962E-14   K1       = 0.5034702      LK1      = -2.366497E-09  
+WK1     = -5.101484E-07  PK1      = 2.367089E-13   K2       = 0.01246453     
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 95227.51       LVSAT    = -0.003893093   
+WVSAT   = -0.06182931    PVSAT    = 3.902827E-08   UA       = -1.920735E-09  
+LUA     = 3.005249E-16   WUA      = 7.991351E-15   PUA      = -4.900672E-21  
+UB      = 3.416652E-18   LUB      = -1.580298E-25  WUB      = -6.922225E-24  
+PUB     = 1.899833E-30   UC       = 1.851462E-10   LUC      = 2.89662E-17    
+WUC     = -6.579484E-16  PUC      = -1.750427E-22  RDSW     = 120            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.02983257     LU0      = 3.763845E-10   WU0      = 6.338641E-08   
+PU0     = -2.992839E-14  A0       = 1.249518       LA0      = -5.732631E-08  
+WA0     = -2.367888E-06  PA0      = 5.746963E-13   KETA     = -0.03600216    
+LKETA   = -1.396657E-08  WKETA    = 4.059973E-07   PKETA    = -8.592838E-14  
+A1      = 0              A2       = 0.99           AGS      = 0.6595803      
+LAGS    = 2.426881E-07   WAGS     = 1.846571E-07   PAGS     = -2.432948E-12  
+B0      = 0              B1       = 0              VOFF     = -0.129575      
+LVOFF   = 1.311287E-09   WVOFF    = 2.826758E-07   PVOFF    = -1.311616E-13  
+NFACTOR = 0.2129552      LNFACTOR = 1.718878E-08   WNFACTOR = 3.705403E-06   
+PNFACTOR= -1.719307E-12  CIT      = 0.001224988    LCIT     = -1.345974E-11  
+WCIT    = -2.90153E-09   PCIT     = 1.34631E-15    CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = 8.179789E-05   
+LETA0   = 3.962312E-10   WETA0    = 6.318923E-09   PETA0    = -6.447401E-15  
+ETAB    = 1.228029E-05   WETAB    = -2.32861E-09   DSUB     = 0              
+PCLM    = 1.60889        LPCLM    = -3.591643E-07  WPCLM    = 4.270979E-06   
+PPCLM   = 1.126043E-12   PDIBLC1  = 0              PDIBLC2  = 0.004957109    
+LPDIBLC2= -1.813846E-10  WPDIBLC2 = -2.99183E-08   PPDIBLC2 = 1.814299E-14   
+PDIBLCB = 0.00101336     DROUT    = 0              PSCBE1   = 7.257309E+08   
+PSCBE2  = 4.06E-07       PVAG     = 0              DELTA    = 0.005          
+ALPHA0  = 3.49E-08       BETA0    = 10.7           KT1      = -0.22          
+KT2     = -0.022         AT       = 127437         LAT      = -0.0472498     
+WAT     = -0.7388586     PAT      = 3.425719E-07   UTE      = -1.436418      
+LUTE    = 2.671131E-08   WUTE     = 5.77114E-07    PUTE     = -2.677809E-13  
+UA1     = 1.858645E-09   LUA1     = -1.493276E-16  WUA1     = -4.657659E-16  
+PUA1    = 1.533365E-21   UB1      = -2.127559E-18  LUB1     = 2.216666E-26   
+WUB1    = 4.757096E-24   PUB1     = -2.217219E-30  UC1      = -8.96E-11      
+KT1L    = 0              
+NLEV    = 3              AF       = 1.05           KF       = 4.2E-24
+PRT     = 0   
+CJ      = cjn            PB       = 0.854656       MJ       = 0.3995675      
+CJSW    = cjswn          PBSW     = 0.854656       MJSW     = 0.5138515       
+CJSWG   = cjgaten        PBSWG    = 0.854656       MJSWG    = 0.5138515 
+CGDO    = cgon           CGSO     = cgon           CTA      = 9.993914E-4    
+CTP     = 3.73684E-3     PTA      = 2.163759E-3    PTP      = 2.163759E-3
+JS      = 5.4E-6         JSW      = 2.94e-9        CAPMOD   = 0
+NQSMOD  = 0              XPART    = 1
+CALCACM = 1              SFVTFLAG = 0              VFBFLAG  = 1   
+CF      = 0              TLEV     = 1              TLEVC    = 1       )

.MODEL n.3            NMOS   (                    LMIN     = 1.5E-07       
+LMAX    = '4.93E-07-dxl'  WMIN     = '1.005E-05-dxw' WMAX     = 0.000201     
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn           XJ       = 1.6E-07        NCH      = 6.7296E+17     
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.45E-08       WINT     = 1.25E-08       
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-1.5E-8+dxl'              
+XW      = '0+dxw'        DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 8.5E-08        HDIF     = hdifn       
+RSH     = 6              RD       = 0              RS       = 0              
+VTH0    = '0.4506809+dvthn' LVTH0    = 7.197164E-09   WVTH0    = -2.90321E-08   
+PVTH0   = 1.347088E-14   K1       = 0.4220791      LK1      = 3.539899E-08   
+K2      = 0.04330603     LK2      = -1.431046E-08  WK2      = -2.685462E-08  
+PK2     = 1.246054E-14   K3       = 0              DVT0     = 0              
+DVT1    = 0              DVT2     = 0              DVT0W    = 0              
+DVT1W   = 0              DVT2W    = 0              NLX      = 0              
+W0      = 0              K3B      = 0              VSAT     = 86149.35       
+LVSAT   = 0.0003191728   WVSAT    = 0.03244456     PVSAT    = -4.7148E-09    
+UA      = -9.113221E-10  LUA      = -1.678426E-16  WUA      = -3.543922E-15  
+PUA     = 4.516935E-22   UB       = 2.206179E-18   LUB      = 4.036297E-25   
+WUB     = 3.669246E-24   PUB      = -3.01461E-30   UC       = 1.163107E-10   
+LUC     = 6.09059E-17    WUC      = -5.704153E-17  PUC      = -4.538635E-22  
+RDSW    = 120            PRWB     = 0              PRWG     = 0              
+WR      = 1              U0       = 0.03224944     LU0      = -7.450418E-10  
+WU0     = -5.334993E-10  PU0      = -2.695569E-16  A0       = 1.002993       
+LA0     = 5.706156E-08   WA0      = -1.279821E-06  PA0      = 6.983285E-14   
+KETA    = -0.03452316    LKETA    = -1.465283E-08  WKETA    = -1.374116E-07  
+PKETA   = 1.662134E-13   A1       = 0              A2       = 0.99           
+AGS     = -1.143353      LAGS     = 1.079249E-06   WAGS     = 1.68403E-05    
+PAGS    = -1.016117E-11  B0       = 0              B1       = 0              
+VOFF    = -0.1275963     LVOFF    = 3.931285E-10   WVOFF    = 7.61528E-08    
+PVOFF   = -3.53349E-14   NFACTOR  = -0.1461243     LNFACTOR = 1.838017E-07   
+WNFACTOR= 1.061181E-06   PNFACTOR = -4.92388E-13   CIT      = 0.001524723    
+LCIT    = -1.525365E-10  WCIT     = 2.17739E-10    PCIT     = -1.010314E-16  
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = -0.000660885   LETA0    = 7.408359E-10   WETA0    = -1.427693E-08  
+PETA0   = 3.109074E-15   ETAB     = 0.0009679393   LETAB    = -4.434258E-10  
+WETAB   = -2.134458E-09  PETAB    = -9.008607E-17  DSUB     = 0              
+PCLM    = 0.8761657      LPCLM    = -1.918035E-08  WPCLM    = 5.988094E-06   
+PPCLM   = 3.293019E-13   PDIBLC1  = 0              PDIBLC2  = 0.003428834    
+LPDIBLC2= 5.277347E-10   WPDIBLC2 = 1.257101E-08   PPDIBLC2 = -1.572049E-15  
+PDIBLCB = 0.0007994832   LPDIBLCB = 9.923884E-11   DROUT    = 0              
+PSCBE1  = 7.257309E+08   PSCBE2   = 4.06E-07       PVAG     = 0              
+DELTA   = 0.005          ALPHA0   = 3.49E-08       BETA0    = 10.7             
+KT1     = -0.2407061     LKT1     = 9.607644E-09   WKT1     = 2.075789E-07   
+PKT1    = -9.631664E-14  KT2      = -0.022         AT       = 21623.19       
+LAT     = 0.001847823    WAT      = -0.01598035    PAT      = 7.156393E-09   
+UTE     = -1.421189      LUTE     = 1.964543E-08   WUTE     = 3.629004E-07   
+PUTE    = -1.683858E-13  UA1      = 1.85958E-09    LUA1     = -1.497614E-16  
+WUA1    = 1.800752E-15   PUA1     = 4.817008E-22   UB1      = -1.954421E-18  
+LUB1    = -5.816965E-26  WUB1     = -3.113013E-24  PUB1     = 1.434512E-30   
+UC1     = -5.583004E-12  LUC1     = -3.898388E-17  WUC1     = -6.123942E-16  
+PUC1    = 2.841509E-22   KT1L     = 0              
+NLEV    = 3              AF       = 1.05           KF       = 4.2E-24
+PRT     = 0   
+CJ      = cjn            PB       = 0.854656       MJ       = 0.3995675      
+CJSW    = cjswn          PBSW     = 0.854656       MJSW     = 0.5138515       
+CJSWG   = cjgaten        PBSWG    = 0.854656       MJSWG    = 0.5138515 
+CGDO    = cgon           CGSO     = cgon           CTA      = 9.993914E-4    
+CTP     = 3.73684E-3     PTA      = 2.163759E-3    PTP      = 2.163759E-3
+JS      = 5.4E-6         JSW      = 2.94e-9        CAPMOD   = 0
+NQSMOD  = 0              XPART    = 1
+CALCACM = 1              SFVTFLAG = 0              VFBFLAG  = 1   
+CF      = 0              TLEV     = 1              TLEVC    = 1       )

.MODEL n.4            NMOS   (                    LMIN     = '1.193E-06-dxl'      
+LMAX    = 20.E-05        WMIN     = '1.25E-06-dxw' WMAX     = '1.005E-05-dxw'      
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn           XJ       = 1.6E-07        NCH      = 6.7296E+17     
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.45E-08       WINT     = 1.25E-08       
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-1.5E-8+dxl'              
+XW      = '0+dxw'        DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 8.5E-08        HDIF     = hdifn       
+RSH     = 6              RD       = 0              RS       = 0              
+VTH0    = '0.3803551+dvthn' LVTH0    = 6.524088E-08   WVTH0    = 1.036582E-09   
+PVTH0   = -1.03285E-14   K1       = 0.4623682      LK1      = -8.751097E-09  
+WK1     = -2.119611E-08  PK1      = 2.111979E-13   K2       = 0.009243915    
+LK2     = 1.087527E-08   WK2      = 8.118524E-09   PK2      = -8.089294E-14  
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 89272.48       LVSAT    = -0.002117206   
+WVSAT   = -0.002130169   PVSAT    = 2.1225E-08     UA       = -1.071174E-09  
+LUA     = -1.690206E-16  WUA      = 6.378996E-16   PUA      = -1.547677E-21  
+UB      = 2.512334E-18   LUB      = 2.502304E-25   WUB      = -6.319331E-25  
+PUB     = 1.037707E-30   UC       = 8.370055E-11   LUC      = 5.494266E-17   
+WUC     = -2.13306E-17   PUC      = 7.300012E-24   RDSW     = 120            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.03298147     LU0      = 2.236291E-09   WU0      = 2.308558E-09   
+PU0     = -1.422424E-14  A0       = 1.561282       LA0      = -5.952288E-07  
+WA0     = 4.852872E-08   PA0      = -4.835402E-13  KETA     = -0.01224712    
+LKETA   = -4.411857E-10  WKETA    = 2.970386E-09   PKETA    = -2.959692E-14  
+A1      = 0              A2       = 0.99           AGS      = 0.5060657      
+LAGS    = 1.920947E-07   WAGS     = -7.690466E-08  PAGS     = 1.700869E-13   
+B0      = 0              B1       = 0              VOFF     = -0.09201732    
+LVOFF   = -1.399906E-08  WVOFF    = -3.708853E-08  PVOFF    = -4.373456E-14  
+NFACTOR = 0.2954127      LNFACTOR = 1.844118E-07   WNFACTOR = -1.529169E-07  
+PNFACTOR= 1.331621E-13   CIT      = 0.001134438    LCIT     = 2.858741E-11   
+WCIT    = 8.754002E-10   PCIT     = -2.414919E-15  CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = 4.569149E-05   
+LETA0   = 5.411297E-10   WETA0    = 1.402884E-11   PETA0    = -1.397832E-16  
+ETAB    = -6.341905E-07  LETAB    = -2.128888E-10  WETAB    = 4.836258E-11   
+PETAB   = -4.818847E-16  DSUB     = 0              PCLM     = 0.3224268      
+LPCLM   = 1.868979E-06   WPCLM    = 1.395243E-07   PPCLM    = -1.390219E-12  
+PDIBLC1 = 0              PDIBLC2  = 0.004948552    LPDIBLC2 = -1.953465E-09  
+WPDIBLC2= -1.344369E-10  PPDIBLC2 = 1.339529E-15   PDIBLCB  = 0.001025451    
+LPDIBLCB= -1.204715E-10  WPDIBLCB = -1.212091E-10  PPDIBLCB = 1.207727E-15   
+DROUT   = 0              PSCBE1   = 7.257309E+08   PSCBE2   = 4.06E-07       
+PVAG    = 0              DELTA    = 0.005          ALPHA0   = 3.49E-08      
+BETA0   = 10.7           KT1      = -0.22          KT2      = -0.022         
+AT      = 42269.84       LAT      = 0.002293335    WAT      = 0.002307376    
+PAT     = -2.299068E-08  UTE      = -1.376293      LUTE     = -2.547439E-08  
+WUTE    = -2.563035E-08  PUTE     = 2.553806E-13   UA1      = 1.815317E-09   
+LUA1    = -1.742968E-19  WUA1     = -1.753638E-19  PUA1     = 1.747325E-24   
+UB1     = -1.815641E-18  LUB1     = -8.329392E-26  WUB1     = -8.38039E-26   
+PUB1    = 8.350216E-31   UC1      = -8.841051E-11  LUC1     = -1.185196E-17  
+WUC1    = -1.192452E-17  PUC1     = 1.188158E-22   KT1L     = 0              
+NLEV    = 3              AF       = 1.05           KF       = 4.2E-24
+PRT     = 0   
+CJ      = cjn            PB       = 0.854656       MJ       = 0.3995675      
+CJSW    = cjswn          PBSW     = 0.854656       MJSW     = 0.5138515       
+CJSWG   = cjgaten        PBSWG    = 0.854656       MJSWG    = 0.5138515 
+CGDO    = cgon           CGSO     = cgon           CTA      = 9.993914E-4    
+CTP     = 3.73684E-3     PTA      = 2.163759E-3    PTP      = 2.163759E-3
+JS      = 5.4E-6         JSW      = 2.94e-9        CAPMOD   = 0
+NQSMOD  = 0              XPART    = 1
+CALCACM = 1              SFVTFLAG = 0              VFBFLAG  = 1   
+CF      = 0              TLEV     = 1              TLEVC    = 1       )

.MODEL n.5            NMOS   (                    LMIN     = '4.93E-07-dxl'       
+LMAX    = '1.193E-06-dxl' WMIN     = '1.25E-06-dxw' WMAX     = '1.005E-05-dxw'      
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn           XJ       = 1.6E-07        NCH      = 6.7296E+17     
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.45E-08       WINT     = 1.25E-08       
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-1.5E-8+dxl'              
+XW      = '0+dxw'        DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 8.5E-08        HDIF     = hdifn       
+RSH     = 6              RD       = 0              RS       = 0              
+VTH0    = '0.4157+dvthn'  LVTH0    = 2.409955E-08   WVTH0    = -3.418352E-09  
+PVTH0   = -5.142959E-15  K1       = 0.4340573      LK1      = 2.42028E-08    
+WK1     = 1.857166E-07   PK1      = -2.964843E-14  K2       = 0.01858693     
+WK2     = -6.137714E-08  K3       = 0              DVT0     = 0              
+DVT1    = 0              DVT2     = 0              DVT0W    = 0              
+DVT1W   = 0              DVT2W    = 0              NLX      = 0              
+W0      = 0              K3B      = 0              VSAT     = 86471.8        
+LVSAT   = 0.001142794    WVSAT    = 0.02594673     PVSAT    = -1.145651E-08  
+UA      = -1.03038E-09   LUA      = -2.165049E-16  WUA      = -9.344631E-16  
+PUA     = 2.82553E-22    UB       = 2.69099E-18    LUB      = 4.227398E-26   
+WUB     = 3.525332E-25   PUB      = -1.082121E-31  UC       = 1.196416E-10   
+LUC     = 1.310722E-17   WUC      = -1.264996E-18  PUC      = -1.605634E-23  
+RDSW    = 120            PRWB     = 0              PRWG     = 0              
+WR      = 1              U0       = 0.03747455     LU0      = -2.993655E-09  
+WU0     = -1.322452E-08  PU0      = 3.856261E-15   A0       = 1.070688       
+LA0     = -2.417695E-08  WA0      = -5.75109E-07   PA0      = 2.423741E-13   
+KETA    = 0.007384006    LKETA    = -2.329182E-08  WKETA    = -2.894906E-08  
+PKETA   = 7.557317E-15   A1       = 0              A2       = 0.99           
+AGS     = 0.6811661      LAGS     = -1.172223E-08  WAGS     = -3.174016E-08  
+PAGS    = 1.175154E-13   B0       = 0              B1       = 0              
+VOFF    = -0.09252262    LVOFF    = -1.341089E-08  WVOFF    = -8.877487E-08  
+PVOFF   = 1.642835E-14   NFACTOR  = 0.6048679      LNFACTOR = -1.757942E-07  
+WNFACTOR= -2.235233E-07  PNFACTOR = 2.153479E-13   CIT      = 0.001040736    
+LCIT    = 1.376563E-10   WCIT     = -1.054402E-09  PCIT     = -1.68629E-16   
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = 0.0008354952   LETA0    = -3.78202E-10   WETA0    = -1.236895E-09  
+PETA0   = 1.316293E-15   ETAB     = -0.0001412768  LETAB    = -4.918094E-11  
+WETAB   = -7.892007E-10  PETAB    = 4.930391E-16   DSUB     = 0              
+PCLM    = 2.189348       LPCLM    = -3.041171E-07  WPCLM    = -1.548116E-06  
+PPCLM   = 5.74195E-13    PDIBLC1  = 0              PDIBLC2  = 0.001676616    
+LPDIBLC2= 1.855068E-09   WPDIBLC2 = 2.968646E-09   PPDIBLC2 = -2.272459E-15  
+PDIBLCB = 0.0009219528   WPDIBLCB = 9.163568E-10   DROUT    = 0              
+PSCBE1  = 7.257309E+08   PSCBE2   = 4.06E-07       PVAG     = 0              
+DELTA   = 0.005          ALPHA0   = 3.49E-08       BETA0    = 10.7             
+KT1     = -0.22          KT2      = -0.022         AT       = 57039.5        
+LAT     = -0.01489856    WAT      = -0.03312339    PAT      = 1.825074E-08   
+UTE     = -1.400024      LUTE     = 2.148105E-09   WUTE     = 2.122695E-07   
+PUTE    = -2.153477E-14  UA1      = 1.811965E-09   LUA1     = 3.728496E-18   
+WUA1    = 2.204573E-18   PUA1     = -1.022922E-24  UB1      = -1.728422E-18  
+LUB1    = -1.848162E-25  WUB1     = 7.557471E-25   PUB1     = -1.422157E-31  
+UC1     = -1.003734E-10  LUC1     = 2.072912E-18   WUC1     = 1.080041E-16   
+PUC1    = -2.078106E-23  KT1L     = 0              
+NLEV    = 3              AF       = 1.05           KF       = 4.2E-24
+PRT     = 0   
+CJ      = cjn            PB       = 0.854656       MJ       = 0.3995675      
+CJSW    = cjswn          PBSW     = 0.854656       MJSW     = 0.5138515       
+CJSWG   = cjgaten        PBSWG    = 0.854656       MJSWG    = 0.5138515 
+CGDO    = cgon           CGSO     = cgon           CTA      = 9.993914E-4    
+CTP     = 3.73684E-3     PTA      = 2.163759E-3    PTP      = 2.163759E-3
+JS      = 5.4E-6         JSW      = 2.94e-9        CAPMOD   = 0
+NQSMOD  = 0              XPART    = 1
+CALCACM = 1              SFVTFLAG = 0              VFBFLAG  = 1   
+CF      = 0              TLEV     = 1              TLEVC    = 1       )

.MODEL n.6            NMOS   (                    LMIN     = 1.5E-07       
+LMAX    = '4.93E-07-dxl' WMIN     = '1.25E-06-dxw' WMAX     = '1.005E-05-dxw'      
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn           XJ       = 1.6E-07        NCH      = 6.7296E+17     
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.45E-08       WINT     = 1.25E-08       
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-1.5E-8+dxl'              
+XW      = '0+dxw'        DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 8.5E-08        HDIF     = hdifn       
+RSH     = 6              RD       = 0              RS       = 0              
+VTH0    = '0.44934+dvthn' LVTH0    = 8.49057E-09    WVTH0    = -1.558958E-08  
+PVTH0   = 5.044901E-16   K1       = 0.4059696      LK1      = 3.723547E-08   
+WK1     = 1.614973E-07   PK1      = -1.841069E-14  K2       = 0.0487438      
+LK2     = -1.399279E-08  WK2      = -8.136853E-08  PK2      = 9.276014E-15   
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 89264.96       LVSAT    = -0.0001532353  
+WVSAT   = 0.001210519    PVSAT    = 2.109079E-11   UA       = -1.21579E-09   
+LUA     = -1.304744E-16  WUA      = -4.916276E-16  PUA      = 7.707723E-23   
+UB      = 2.537956E-18   LUB      = 1.132818E-25   WUB      = 3.431798E-25   
+PUB     = -1.03872E-31   UC       = 1.114399E-10   LUC      = 1.691284E-17   
+WUC     = -8.211633E-18  PUC      = -1.28331E-23   RDSW     = 120            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.03278252     LU0      = -8.165517E-10  WU0      = -5.877684E-09  
+PU0     = 4.473301E-16   A0       = 0.8850212      LA0      = 6.197226E-08   
+WA0     = -9.715434E-08  PA0      = 2.060315E-14   KETA     = -0.04655565    
+LKETA   = 1.736181E-09   WKETA    = -1.678585E-08  PKETA    = 1.913587E-15   
+A1      = 0              A2       = 0.99           AGS      = 0.5692768      
+LAGS    = 4.019444E-08   WAGS     = -3.288162E-07  PAGS     = 2.553587E-13   
+B0      = 0              B1       = 0              VOFF     = -0.1129424     
+LVOFF   = -3.936111E-09  WVOFF    = -7.075199E-08  PVOFF    = 8.065726E-15   
+NFACTOR = -0.07208654    LNFACTOR = 1.383127E-07   WNFACTOR = 3.189518E-07   
+PNFACTOR= -3.63605E-14   CIT      = 0.001733937    LCIT     = -1.839888E-10  
+WCIT    = -1.879633E-09  PCIT     = 2.142782E-16   CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = -0.002281881   
+LETA0   = 1.068261E-09   WETA0    = 1.973567E-09   PETA0    = -1.733619E-16  
+ETAB    = 0.0006310843   LETAB    = -4.075565E-10  WETAB    = 1.242514E-09   
+PETAB   = -4.496766E-16  DSUB     = 0              PCLM     = 1.507464       
+LPCLM   = 1.227729E-08   WPCLM    = -3.406685E-07  PPCLM    = 1.393912E-14   
+PDIBLC1 = 0              PDIBLC2  = 0.004826226    LPDIBLC2 = 3.936494E-10   
+WPDIBLC2= -1.437853E-09  PPDIBLC2 = -2.278437E-16  PDIBLCB  = 0.0006783035   
+LPDIBLCB= 1.130533E-10   WPDIBLCB = 1.214827E-09   PPDIBLCB = -1.384903E-16  
+DROUT   = 0              PSCBE1   = 7.257309E+08   PSCBE2   = 4.06E-07       
+PVAG    = 0              DELTA    = 0.005          ALPHA0   = 3.49E-08       
+BETA0   = 10.7           KT1      = -0.22          KT2      = -0.022         
+AT      = 18917.73       LAT      = 0.002789942    WAT      = 0.01114188     
+PAT     = -2.28835E-09   UTE      = -1.406923      LUTE     = 5.349229E-09   
+WUTE    = 2.198808E-07   PUTE     = -2.506641E-14  UA1      = 2.045742E-09   
+LUA1    = -1.047441E-16  WUA1     = -6.55224E-17   PUA1     = 3.040239E-23   
+UB1     = -2.327075E-18  LUB1     = 9.295869E-26   WUB1     = 6.228468E-25   
+PUB1    = -8.054991E-32  UC1      = -7.176508E-11  LUC1     = -1.120137E-17  
+WUC1    = 5.108101E-17   PUC1     = 5.631238E-24   KT1L     = 0              
+NLEV    = 3              AF       = 1.05           KF       = 4.2E-24
+PRT     = 0   
+CJ      = cjn            PB       = 0.854656       MJ       = 0.3995675      
+CJSW    = cjswn          PBSW     = 0.854656       MJSW     = 0.5138515       
+CJSWG   = cjgaten        PBSWG    = 0.854656       MJSWG    = 0.5138515 
+CGDO    = cgon           CGSO     = cgon           CTA      = 9.993914E-4    
+CTP     = 3.73684E-3     PTA      = 2.163759E-3    PTP      = 2.163759E-3
+JS      = 5.4E-6         JSW      = 2.94e-9        CAPMOD   = 0
+NQSMOD  = 0              XPART    = 1              DLC      = 2.51E-08
+CALCACM = 1              SFVTFLAG = 0              VFBFLAG  = 1   
+CF      = 0              TLEV     = 1              TLEVC    = 1       )


.MODEL n.7            NMOS   (                     LMIN     = '1.193E-06-dxl'      
+LMAX    = 20.0E-05        WMIN     = '5.9E-07-dxw'  WMAX     = '1.25E-06-dxw'       
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn           XJ       = 1.6E-07        NCH      = 6.7296E+17     
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.45E-08       WINT     = 1.25E-08       
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-1.5E-8+dxl'              
+XW      = '0+dxw'        DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 8.5E-08        HDIF     = hdifn       
+RSH     = 6              RD       = 0              RS       = 0              
+VTH0    = '0.3790088+dvthn' LVTH0    = 7.86556E-08    WVTH0    = 2.685818E-09   
+PVTH0   = -2.676153E-14  K1       = 0.4450652      LK1      = 1.636553E-07   
+K2      = 0.01587128     LK2      = -5.515977E-08  K3       = 0              
+DVT0    = 0              DVT1     = 0              DVT2     = 0              
+DVT0W   = 0              DVT1W    = 0              DVT2W    = 0              
+NLX     = 0              W0       = 0              K3B      = 0              
+VSAT    = 86113.63       LVSAT    = 0.02935767     WVSAT    = 0.001739435    
+PVSAT   = -1.733174E-08  UA       = -7.196989E-10  LUA      = -1.1124E-15    
+WUA     = 2.073428E-16   PUA      = -3.92037E-22   UB       = 2.090081E-18   
+LUB     = 9.885736E-25   WUB      = -1.146737E-25  PUB      = 1.332361E-31   
+UC      = 6.598107E-11   LUC      = 6.395831E-17   WUC      = 3.757656E-19   
+PUC     = -3.744152E-24  RDSW     = 120            PRWB     = 0              
+PRWG    = 0              WR       = 1              U0       = 0.03462369     
+LU0     = -6.960849E-09  WU0      = 2.968426E-10   PU0      = -2.957741E-15  
+A0      = 2.081606       LA0      = -1.615297E-06  WA0      = -5.888689E-07  
+PA0     = 7.660434E-13   KETA     = -0.008333452   LKETA    = -1.74745E-08   
+WKETA   = -1.823861E-09  PKETA    = -8.731105E-15  A1       = 0              
+A2      = 0.99           AGS      = 0.5307538      LAGS     = 1.972424E-07   
+WAGS    = -1.071476E-07  PAGS     = 1.637808E-13   B0       = 0              
+B1      = 0              VOFF     = -0.1058107     LVOFF    = -9.463519E-08  
+WVOFF   = -2.019163E-08  PVOFF    = 5.50447E-14    NFACTOR  = 0.07930301     
+LNFACTOR= 3.496457E-07   WNFACTOR = 1.118174E-07   PNFACTOR = -6.924959E-14  
+CIT     = 0.002676203    LCIT     = -3.129783E-09  WCIT     = -1.013262E-09  
+PCIT    = 1.454085E-15   CDSC     = 0              CDSCB    = 0              
+CDSCD   = 0              ETA0     = 0.0001052449   LETA0    = -2.228558E-10  
+WETA0   = -5.892404E-11  PETA0    = 7.960988E-16   ETAB     = 0.0002823434   
+LETAB   = -1.343581E-09  WETAB    = -2.982851E-10  PETAB    = 9.032129E-16   
+DSUB    = 0              PCLM     = 0.2359977      LPCLM    = 1.207591E-06   
+WPCLM   = 2.453998E-07   PPCLM    = -5.800188E-13  PDIBLC1  = 0              
+PDIBLC2 = 0.007500331    LPDIBLC2 = -4.203114E-09  WPDIBLC2 = -3.260367E-09  
+PPDIBLC2= 4.095348E-15   PDIBLCB  = 0.0009265046   LPDIBLCB = 8.654277E-10   
+DROUT   = 0              PSCBE1   = 7.257309E+08   PSCBE2   = 4.06E-07       
+PVAG    = 0              DELTA    = 0.005          ALPHA0   = 3.49E-08       
+BETA0   = 10.7           KT1      = -0.22          KT2      = -0.022         
+AT      = 50607.71       LAT      = -0.08078528    WAT      = -0.00790652    
+PAT     = 7.878062E-08   UTE      = -1.426657      LUTE     = 4.763467E-07   
+WUTE    = 3.606482E-08   PUTE     = -3.593502E-13  UA1      = 1.744262E-09   
+LUA1    = 7.078236E-16   WUA1     = 8.68677E-17    PUA1     = -8.655502E-22  
+UB1     = -1.898772E-18  LUB1     = 7.450299E-25   WUB1     = 1.803241E-26   
+PUB1    = -1.796751E-31  UC1      = -1.144504E-10  LUC1     = 2.476097E-16   
+WUC1    = 1.997437E-17   PUC1     = -1.990247E-22  KT1L     = 0              
+NLEV    = 3              AF       = 1.05           KF       = 4.2E-24
+PRT     = 0   
+CJ      = cjn            PB       = 0.854656       MJ       = 0.3995675      
+CJSW    = cjswn          PBSW     = 0.854656       MJSW     = 0.5138515       
+CJSWG   = cjgaten        PBSWG    = 0.854656       MJSWG    = 0.5138515 
+CGDO    = cgon           CGSO     = cgon           CTA      = 9.993914E-4    
+CTP     = 3.73684E-3     PTA      = 2.163759E-3    PTP      = 2.163759E-3
+JS      = 5.4E-6         JSW      = 2.94e-9        CAPMOD   = 0
+NQSMOD  = 0              XPART    = 1
+CALCACM = 1              SFVTFLAG = 0              VFBFLAG  = 1   
+CF      = 0              TLEV     = 1              TLEVC    = 1       )

.MODEL n.8            NMOS   (                    LMIN     = '4.93E-07-dxl'       
+LMAX    = '1.193E-06-dxl' WMIN     = '5.9E-07-dxw' WMAX     = '1.25E-06-dxw'        
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn           XJ       = 1.6E-07        NCH      = 6.7296E+17     
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.45E-08       WINT     = 1.25E-08       
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-1.5E-8+dxl'              
+XW      = '0+dxw'        DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 8.5E-08        HDIF     = hdifn       
+RSH     = 6              RD       = 0              RS       = 0              
+VTH0    = '0.4258403+dvthn' LVTH0    = 2.414382E-08   WVTH0    = -1.584024E-08  
+PVTH0   = -5.197198E-15  K1       = 0.5856626      K2       = -0.03151685    
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 121588.2       LVSAT    = -0.01193472    
+WVSAT   = -0.01707086    PVSAT    = 4.563442E-09   UA       = -1.75596E-09   
+LUA     = 9.380775E-17   WUA      = -4.562702E-17  PUA      = -9.758014E-23  
+UB      = 2.950968E-18   LUB      = -1.34993E-26   WUB      = 3.405988E-26   
+PUB     = -3.98898E-32   UC       = 1.164265E-10   LUC      = 5.239796E-18   
+WUC     = 2.673533E-18   PUC      = -6.418752E-24  RDSW     = 120            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.02822729     LU0      = 4.845604E-10   WU0      = -1.896618E-09  
+PU0     = -4.04553E-16   A0       = 0.5327653      LA0      = 1.875542E-07   
+WA0     = 8.384578E-08   PA0      = -1.699648E-14  KETA     = 0.003956968    
+LKETA   = -3.178054E-08  WKETA    = -2.475094E-08  PKETA    = 1.795601E-14   
+A1      = 0              A2       = 0.99           AGS      = 0.5659308      
+LAGS    = 1.562964E-07   WAGS     = 1.094231E-07   PAGS     = -8.830749E-14  
+B0      = 0              B1       = 0              VOFF     = -0.17952       
+LVOFF   = -8.837584E-09  WVOFF    = 1.779691E-08   PVOFF    = 1.082604E-14   
+NFACTOR = 0.8021516      LNFACTOR = -4.917499E-07  WNFACTOR = -4.651958E-07  
+PNFACTOR= 6.023937E-13   CIT      = -1.261362E-05  WCIT     = 2.359517E-10   
+CDSC    = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0    = -0.0006189892  LETA0    = 6.201527E-10   WETA0    = 5.448482E-10   
+PETA0   = 9.330808E-17   ETAB     = -0.001721113   LETAB    = 9.884431E-10   
+WETAB   = 1.1461E-09     PETAB    = -7.780507E-16  DSUB     = 0              
+PCLM    = 1.323364       LPCLM    = -5.810272E-08  WPCLM    = -4.87286E-07   
+PPCLM   = 2.728274E-13   PDIBLC1  = 0              PDIBLC2  = 0.003889409    
+WPDIBLC2= 2.579739E-10   PDIBLCB  = 0.001669999    DROUT    = 0              
+PSCBE1  = 7.257309E+08   PSCBE2   = 4.06E-07       PVAG     = 0              
+DELTA   = 0.005          ALPHA0   = 3.49E-08       BETA0    = 10.7             
+KT1     = -0.22          KT2      = -0.022         AT       = -52728.7       
+LAT     = 0.0394983      WAT      = 0.1013427      PAT      = -4.838543E-08  
+UTE     = -0.9924778     LUTE     = -2.903771E-08  WUTE     = -2.869748E-07  
+PUTE    = 1.666786E-14   UA1      = 2.347982E-09   LUA1     = 5.09302E-18    
+WUA1    = -6.544173E-16  PUA1     = -2.694465E-24  UB1      = -8.980576E-19  
+LUB1    = -4.198019E-25  WUB1     = -2.614495E-25  PUB1     = 1.456418E-31   
+UC1     = 1.219188E-10   LUC1     = -2.752407E-17  WUC1     = -1.64304E-16   
+PUC1    = 1.547524E-23   KT1L     = 0             
+NLEV    = 3              AF       = 1.05           KF       = 4.2E-24
+PRT     = 0   
+CJ      = cjn            PB       = 0.854656       MJ       = 0.3995675      
+CJSW    = cjswn          PBSW     = 0.854656       MJSW     = 0.5138515       
+CJSWG   = cjgaten        PBSWG    = 0.854656       MJSWG    = 0.5138515 
+CGDO    = cgon           CGSO     = cgon           CTA      = 9.993914E-4    
+CTP     = 3.73684E-3     PTA      = 2.163759E-3    PTP      = 2.163759E-3
+JS      = 5.4E-6         JSW      = 2.94e-9        CAPMOD   = 0
+NQSMOD  = 0              XPART    = 1
+CALCACM = 1              SFVTFLAG = 0              VFBFLAG  = 1   
+CF      = 0              TLEV     = 1              TLEVC    = 1       )

.MODEL n.9            NMOS   (                    LMIN     = 1.5E-07       
+LMAX    = '4.93E-07-dxl' WMIN     = '5.9E-07-dxw'  WMAX     = '1.25E-06-dxw'       
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn           XJ       = 1.6E-07        NCH      = 6.7296E+17     
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.45E-08       WINT     = 1.25E-08       
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-1.5E-8+dxl'              
+XW      = '0+dxw'        DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 8.5E-08        HDIF     = hdifn       
+RSH     = 6              RD       = 0              RS       = 0              
+VTH0    = '0.4568565+dvthn' LVTH0    = 9.752283E-09   WVTH0    = -2.479732E-08  
+PVTH0   = -1.04111E-15   K1       = 0.5500614      LK1      = 1.651896E-08   
+WK1     = -1.501517E-08  PK1      = 6.967037E-15   K2       = -0.01722777    
+LK2     = -6.630132E-09  WK2      = -5.533409E-10  PK2      = 2.567503E-16   
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 98083.9        LVSAT    = -0.001028724   
+WVSAT   = -0.009592674   PVSAT    = 1.093565E-09   UA       = -1.39809E-09   
+LUA     = -7.224419E-17  WUA      = -2.683109E-16  PUA      = 5.745195E-24   
+UB      = 2.853368E-18   LUB      = 3.178739E-26   WUB      = -4.319955E-26  
+PUB     = -4.041421E-33  UC       = 1.156362E-10   LUC      = 5.606497E-18   
+WUC     = -1.335216E-17  PUC      = 1.017171E-24   RDSW     = 120            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.0305373      LU0      = -5.872827E-10  WU0      = -3.127283E-09  
+PU0     = 1.664756E-16   A0       = 0.8589565      LA0      = 3.620143E-08   
+WA0     = -6.522515E-08  PA0      = 5.217242E-14   KETA     = -0.1067266     
+LKETA   = 1.95766E-08    WKETA    = 5.692349E-08   PKETA    = -1.994092E-14  
+A1      = 0              A2       = 0.99           AGS      = 0.8064205      
+LAGS    = 4.470934E-08   WAGS     = -6.193172E-07  PAGS     = 2.498279E-13   
+B0      = 0              B1       = 0              VOFF     = -0.2274698     
+LVOFF   = 1.341111E-08   WVOFF    = 6.954404E-08   PVOFF    = -1.318462E-14  
+NFACTOR = -0.9264665     LNFACTOR = 3.103287E-07   WNFACTOR = 1.365567E-06   
+PNFACTOR= -2.470801E-13  CIT      = -3.907792E-05  LCIT     = 1.227943E-11   
+WCIT    = 2.923104E-10   PCIT     = -2.615046E-17  CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = -0.002442277   
+LETA0   = 1.466158E-09   WETA0    = 2.170051E-09   PETA0    = -6.607858E-16  
+ETAB    = 0.002601666    LETAB    = -1.017326E-09  WETAB    = -1.171448E-09  
+PETAB   = 2.972912E-16   DSUB     = 0              PCLM     = 1.061821       
+LPCLM   = 6.325308E-08   WPCLM    = 2.052435E-07   PPCLM    = -4.850623E-14  
+PDIBLC1 = 0              PDIBLC2  = 0.00383503     LPDIBLC2 = 2.523204E-11   
+WPDIBLC2= -2.236374E-10  PPDIBLC2 = 2.234676E-16   PDIBLCB  = 0.001669999    
+DROUT   = 0              PSCBE1   = 7.257309E+08   PSCBE2   = 4.06E-07       
+PVAG    = -0.05743924    LPVAG    = 2.66518E-08    WPVAG    = 7.036306E-08   
+PPVAG   = -3.264845E-14  DELTA    = 0.005          ALPHA0   = 3.49E-08       
+BETA0   = 10.7           KT1      = -0.22          KT2      = -0.022         
+AT      = 30619.24       LAT      = 0.0008248685   WAT      = -0.003192464   
+PAT     = 1.188657E-10   UTE      = -0.9292465     LUTE     = -5.837704E-08  
+WUTE    = -3.652731E-07  PUTE     = 5.299828E-14   UA1      = 2.645096E-09   
+LUA1    = -1.327676E-16  WUA1     = -7.997311E-16  PUA1     = 6.47311E-23    
+UB1     = -1.84749E-18   LUB1     = 2.07348E-26    WUB1     = 3.535542E-26   
+PUB1    = 7.92436E-33    UC1      = 9.269169E-11   LUC1     = -1.396267E-17  
+WUC1    = -1.503785E-16  PUC1     = 9.013827E-24   KT1L     = 0              
+NLEV    = 3              AF       = 1.05           KF       = 4.2E-24
+PRT     = 0   
+CJ      = cjn            PB       = 0.854656       MJ       = 0.3995675      
+CJSW    = cjswn          PBSW     = 0.854656       MJSW     = 0.5138515       
+CJSWG   = cjgaten        PBSWG    = 0.854656       MJSWG    = 0.5138515 
+CGDO    = cgon           CGSO     = cgon           CTA      = 9.993914E-4    
+CTP     = 3.73684E-3     PTA      = 2.163759E-3    PTP      = 2.163759E-3
+JS      = 5.4E-6         JSW      = 2.94e-9        CAPMOD   = 0
+NQSMOD  = 0              XPART    = 1
+CALCACM = 1              SFVTFLAG = 0              VFBFLAG  = 1   
+CF      = 0              TLEV     = 1              TLEVC    = 1       )

.MODEL n.10           NMOS   (                    LMIN     = '1.193E-06-dxl'      
+LMAX    = 20.E-05        WMIN     = 1.8E-07        WMAX     = '5.9E-07-dxw'        
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn           XJ       = 1.6E-07        NCH      = 6.7296E+17     
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.45E-08       WINT     = 1.25E-08       
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-1.5E-8+dxl'              
+XW      = '0+dxw'        DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 8.5E-08        HDIF     = hdifn       
+RSH     = 6              RD       = 0              RS       = 0              
+VTH0    = '0.4036109+dvthn' LVTH0    = 3.10274E-08    WVTH0    = -1.121434E-08  
+PVTH0   = 1.484008E-16   K1       = 0.4544645      LK1      = 1.527146E-07   
+WK1     = -5.310579E-09  PK1      = 6.181513E-15   K2       = 0.01894689     
+LK2     = -4.880579E-08  WK2      = -1.737722E-09  PK2      = -3.59E-15      
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 89273.52       LVSAT    = -0.002127573   
+WVSAT   = -4.590808E-05  PVSAT    = 4.574281E-10   UA       = -3.019933E-10  
+LUA     = -1.953588E-15  WUA      = -2.866083E-17  PUA      = 8.323387E-23   
+UB      = 1.846684E-18   LUB      = 1.195376E-24   WUB      = 2.28454E-26    
+PUB     = 1.639263E-32   UC       = 6.686626E-11   LUC      = 5.513826E-17   
+WUC     = -1.24365E-19   PUC      = 1.239173E-24   RDSW     = 120            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.03344877     LU0      = -1.193872E-08  WU0      = 9.606717E-10   
+PU0     = -1.452464E-16  A0       = 1.033996       LA0      = -2.060096E-07  
+WA0     = 3.031312E-09   PA0      = -3.020399E-14  KETA     = -0.01083902    
+LKETA   = -4.012681E-08  WKETA    = -4.082146E-10  PKETA    = 4.06745E-15    
+A1      = 0              A2       = 0.99           AGS      = 0.3415003      
+LAGS    = 5.355616E-07   WAGS     = -2.194022E-10  PAGS     = -2.736953E-14  
+B0      = 0              B1       = 0              VOFF     = -0.1415191     
+LVOFF   = 2.499706E-09   WVOFF    = -1.640775E-11  PVOFF    = 1.634868E-16   
+NFACTOR = 0.2645754      LNFACTOR = 3.529709E-07   WNFACTOR = 7.138523E-09   
+PNFACTOR= -7.112824E-14  CIT      = 0.0009206019   LCIT     = -9.326487E-10  
+WCIT    = -2.134726E-11  PCIT     = 2.127041E-16   CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = -0.0002499471  
+LETA0   = 1.464947E-09   WETA0    = 1.417594E-10   PETA0    = -1.575098E-16  
+ETAB    = -0.0002826056  LETAB    = 6.238025E-10   WETAB    = 2.091113E-11   
+PETAB   = -2.083585E-16  DSUB     = 0              PCLM     = 0.6514443      
+LPCLM   = 3.056049E-08   WPCLM    = 1.067247E-08   PPCLM    = 8.500371E-14   
+PDIBLC1 = 0              PDIBLC2  = -0.00063019    LPDIBLC2 = 5.968182E-09   
+WPDIBLC2= 1.333378E-09   PPDIBLC2 = -1.651434E-15  PDIBLCB  = 0.0009265046   
+LPDIBLCB= 8.654277E-10   DROUT    = 0              PSCBE1   = 7.257309E+08   
+PSCBE2  = 4.06E-07       PVAG     = 0              DELTA    = 0.005          
+ALPHA0  = 3.49E-08       BETA0    = 10.7           KT1      = -0.22          
+KT2     = -0.022         AT       = 2340.568       LAT      = 0.1207095      
+WAT     = 0.01936441     PAT      = -3.50639E-08   UTE      = -1.343147      
+LUTE    = -3.506091E-07  WUTE     = -1.111849E-08  PUTE     = 1.078798E-13   
+UA1     = 2.195741E-09   LUA1     = -1.435472E-15  WUA1     = -1.682182E-16  
+PUA1    = 3.45412E-22    UB1      = -1.880305E-18  LUB1     = 5.431363E-25   
+WUB1    = 7.598339E-27   PUB1     = -6.560523E-32  UC1      = -6.739706E-11  
+LUC1    = -2.212299E-16  WUC1     = -6.610767E-18  PUC1     = 6.586965E-23   
+KT1L    = 0              
+NLEV    = 3              AF       = 1.05           KF       = 4.2E-24
+PRT     = 0   
+CJ      = cjn            PB       = 0.854656       MJ       = 0.3995675      
+CJSW    = cjswn          PBSW     = 0.854656       MJSW     = 0.5138515       
+CJSWG   = cjgaten        PBSWG    = 0.854656       MJSWG    = 0.5138515 
+CGDO    = cgon           CGSO     = cgon           CTA      = 9.993914E-4    
+CTP     = 3.73684E-3     PTA      = 2.163759E-3    PTP      = 2.163759E-3
+JS      = 5.4E-6         JSW      = 2.94e-9        CAPMOD   = 0
+NQSMOD  = 0              XPART    = 1
+CALCACM = 1              SFVTFLAG = 0              VFBFLAG  = 1   
+CF      = 0              TLEV     = 1              TLEVC    = 1       )

.MODEL n.11           NMOS   (                    LMIN     = '4.93E-07-dxl'       
+LMAX    = '1.193E-06-dxl' WMIN     = 1.8E-07       WMAX     = '5.9E-07-dxw'        
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn           XJ       = 1.6E-07        NCH      = 6.7296E+17     
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.45E-08       WINT     = 1.25E-08       
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-1.5E-8+dxl'              
+XW      = '0+dxw'        DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 8.5E-08        HDIF     = hdifn       
+RSH     = 6              RD       = 0              RS       = 0              
+VTH0    = '0.4130948+dvthn' LVTH0    = 1.998819E-08   WVTH0    = -8.639025E-09  
+PVTH0   = -2.849267E-15  K1       = 0.5856626      K2       = -0.01732542    
+LK2     = -6.584822E-09  WK2      = -8.018156E-09  PK2      = 3.720425E-15   
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 92388.73       LVSAT    = -0.005753676   
+WVSAT   = -0.0005731638  PVSAT    = 1.071154E-09   UA       = -1.962816E-09  
+LUA     = -2.038992E-17  WUA      = 7.124667E-17   PUA      = -3.305846E-23  
+UB      = 2.922723E-18   LUB      = -5.713224E-26  WUB      = 5.001877E-26   
+PUB     = -1.523719E-32  UC       = 1.227245E-10   LUC      = -9.880763E-18  
+WUC     = -8.848388E-19  PUC      = 2.124364E-24   RDSW     = 120            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.02348709     LU0      = -3.433141E-10  WU0      = 7.815972E-10   
+PU0     = 6.319604E-17   A0       = 0.7486125      LA0      = 1.261762E-07   
+WA0     = -3.810792E-08  PA0      = 1.768207E-14   KETA     = -0.05977092    
+LKETA   = 1.682991E-08   WKETA    = 1.125532E-08   PKETA    = -9.508899E-15  
+A1      = 0              A2       = 0.99           AGS      = 0.8638209      
+LAGS    = -7.241948E-08  WAGS     = -5.888481E-08  PAGS     = 4.0917E-14     
+B0      = 0              B1       = 0              VOFF     = -0.1516535     
+LVOFF   = 1.429616E-08   WVOFF    = 2.052331E-09   PVOFF    = -2.244525E-15 
+NFACTOR = -6.7915710E-02 LNFACTOR = 7.3999050E-07  WNFACTOR = 2.6392261E-08 
+PNFACTOR= -9.3539560E-14 CIT      = -0.000124953   LCIT     = 2.843771E-10   
+WCIT    = 2.994235E-10   PCIT     = -1.606731E-16  CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = 0.0003263852   
+LETA0   = 7.940965E-10   WETA0    = 1.071162E-11   PETA0    = -4.970178E-18  
+ETAB    = 0.0007726603   LETAB    = -6.045272E-10  WETAB    = -2.628828E-10  
+PETAB   = 1.219776E-16   DSUB     = 0              PCLM     = 0.2145734      
+LPCLM   = 5.390783E-07   WPCLM    = 1.391807E-07   PPCLM    = -6.457983E-14  
+PDIBLC1 = 0              PDIBLC2  = 0.004597282    LPDIBLC2 = -1.165946E-10  
+WPDIBLC2= -1.41974E-10   PPDIBLC2 = 6.587596E-17   PDIBLCB  = 0.001669999    
+DROUT   = 0              PSCBE1   = 7.257309E+08   PSCBE2   = 4.06E-07       
+PVAG    = 0              DELTA    = 0.005          ALPHA0   = 3.49E-08      
+BETA0   = 10.7           KT1      = -0.22          KT2      = -0.022         
+AT      = 158284         LAT      = -0.06080874    WAT      = -0.01787953    
+PAT     = 8.288051E-09   UTE      = -1.642963      LUTE     = -1.622515E-09  
+WUTE    = 8.054953E-08   PUTE     = 1.178273E-15   UA1      = 9.640554E-10   
+LUA1    = -1.789808E-18  WUA1     = 1.275014E-16   PUA1     = 1.194333E-24   
+UB1     = -1.217284E-18  LUB1     = -2.286204E-25  WUB1     = -8.108682E-26  
+PUB1    = 3.762428E-32   UC1      = -2.651296E-10  LUC1     = 8.930726E-18   
+WUC1    = 5.437838E-17   PUC1     = -5.121719E-24  KT1L     = 0              
+NLEV    = 3              AF       = 1.05           KF       = 4.2E-24
+PRT     = 0   
+CJ      = cjn            PB       = 0.854656       MJ       = 0.3995675      
+CJSW    = cjswn          PBSW     = 0.854656       MJSW     = 0.5138515       
+CJSWG   = cjgaten        PBSWG    = 0.854656       MJSWG    = 0.5138515 
+CGDO    = cgon           CGSO     = cgon           CTA      = 9.993914E-4    
+CTP     = 3.73684E-3     PTA      = 2.163759E-3    PTP      = 2.163759E-3
+JS      = 5.4E-6         JSW      = 2.94e-9        CAPMOD   = 0
+NQSMOD  = 0              XPART    = 1
+CALCACM = 1              SFVTFLAG = 0              VFBFLAG  = 1   
+CF      = 0              TLEV     = 1              TLEVC    = 1       )

.MODEL n.12           NMOS   (                    LMIN     = 1.5E-07       
+LMAX    = '4.93E-07-dxl'  WMIN     = 1.8E-07       WMAX     = '5.9E-07-dxw'       
+LEVEL   = 49             TNOM     = 25             VERSION  = 3.1            
+TOX     = toxn           XJ       = 1.6E-07        NCH      = 6.7296E+17     
+LLN     = 1              LWN      = 1              WLN      = 1              
+WWN     = 1              LINT     = 1.45E-08       LL       = 0              
+LW      = 0              LWL      = 0              WINT     = 1.25E-08       
+WL      = 0              WW       = 0              WWL      = 0              
+MOBMOD  = 1              BINUNIT  = 2              XL       = '-1.5E-8+dxl'              
+XW      = '0+dxw'        DWG      = 0              DWB      = 0              
+ACM     = 12             LDIF     = 8.5E-08        HDIF     = hdifn       
+RSH     = 6              RD       = 0              RS       = 0              
+VTH0    = '0.4338077+dvthn' LVTH0    = 1.03774E-08    WVTH0    = -1.177473E-08  
+PVTH0   = -1.3943E-15    K1       = 0.5099083      LK1      = 3.515002E-08   
+WK1     = 7.671367E-09   PK1      = -3.559514E-15  K2       = -0.01964028    
+LK2     = -5.510728E-09  WK2      = 8.097256E-10   PK2      = -3.757126E-16  
+K3      = 0              DVT0     = 0              DVT1     = 0              
+DVT2    = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W   = 0              NLX      = 0              W0       = 0              
+K3B     = 0              VSAT     = 77033.88       LVSAT    = 0.001370978    
+WVSAT   = 0.002300588    PVSAT    = -2.62267E-10   UA       = -1.94102E-09   
+LUA     = -3.050357E-17  WUA      = 3.844453E-17   PUA      = -1.783826E-23  
+UB      = 2.742778E-18   LUB      = 2.63622E-26    WUB      = 1.928386E-26   
+PUB     = -9.761858E-34  UC       = 6.125235E-11   LUC      = 1.864233E-17   
+WUC     = 1.737472E-17   PUC      = -6.348073E-24  RDSW     = 120            
+PRWB    = 0              PRWG     = 0              WR       = 1              
+U0      = 0.02278699     LU0      = -1.847207E-11  WU0      = 1.251637E-09   
+PU0     = -1.549024E-16  A0       = 0.6279317      LA0      = 1.821721E-07   
+WA0     = 6.530389E-08   PA0      = -3.0301E-14    KETA     = -0.009343314   
+LKETA   = -6.568496E-09  WKETA    = 1.901962E-09   PKETA    = -5.168942E-15  
+A1      = 0              A2       = 0.99           AGS      = 0.4075335      
+LAGS    = 1.392978E-07   WAGS     = -3.93946E-07   PAGS     = 1.963854E-13   
+B0      = 0              B1       = 0              VOFF     = -0.08421178    
+LVOFF   = -1.699679E-08  WVOFF    = -1.139673E-08  PVOFF    = 3.995842E-15 
+NFACTOR = 1.9015590      LNFACTOR = -1.7384579E-07 WNFACTOR = -2.3226733E-07 
+PNFACTOR= 2.6478479E-14  CIT      = 0.0005882253   LCIT     = -4.653769E-11  
+WCIT    = -6.211587E-11  PCIT     = 7.08121E-18    CDSC     = 0              
+CDSCB   = 0              CDSCD    = 0              ETA0     = 0.002241852    
+LETA0   = -9.467984E-11  WETA0    = -4.764819E-10  PETA0    = 2.210876E-16   
+ETAB    = 0.0006920059   LETAB    = -5.671035E-10  WETAB    = -9.249021E-11  
+PETAB   = 4.291546E-17   DSUB     = 0              PCLM     = 1.980041       
+LPCLM   = -2.800986E-07  WPCLM    = -3.135506E-07  PPCLM    = 1.454875E-13   
+PDIBLC1 = 0              PDIBLC2  = 3.2044730E-03  LPDIBLC2 = 5.2966880E-10 
+WPDIBLC2= 1.3262745E-10  PPDIBLC2 = -6.1539140E-17 PDIBLCB  = 0.001669999    
+DROUT   = 0              PSCBE1   = 7.257309E+08   PSCBE2   = 4.06E-07       
+PVAG    = 0.1307237      LPVAG    = -6.065582E-08  WPVAG    = -3.594903E-08  
+PPVAG   = 1.668035E-14   DELTA    = 0.005          ALPHA0   = 3.49E-08     
+BETA0   = 10.7           KT1      = -0.22          KT2      = -0.022         
+AT      = 28854.97       LAT      = -0.0007536547  WAT      = -0.002195654   
+PAT     = 1.010731E-09   UTE      = -1.770707      LUTE     = 5.765061E-08   
+WUTE    = 1.101521E-07   PUTE     = -1.255735E-14  UA1      = 9.244339E-10   
+LUA1    = 1.659453E-17   WUA1     = 1.724429E-16   PUA1     = -1.965849E-23  
+UB1     = -1.726847E-18  LUB1     = 7.817125E-27   WUB1     = -3.280787E-26  
+PUB1    = 1.522285E-32   UC1      = -2.418006E-10  LUC1     = -1.893902E-18  
+WUC1    = 3.860965E-17   PUC1     = 2.194973E-24   KT1L     = 0              
+NLEV    = 3              AF       = 1.05           KF       = 4.2E-24
+PRT     = 0   
+CJ      = cjn            PB       = 0.854656       MJ       = 0.3995675      
+CJSW    = cjswn          PBSW     = 0.854656       MJSW     = 0.5138515       
+CJSWG   = cjgaten        PBSWG    = 0.854656       MJSWG    = 0.5138515 
+CGDO    = cgon           CGSO     = cgon           CTA      = 9.993914E-4    
+CTP     = 3.73684E-3     PTA      = 2.163759E-3    PTP      = 2.163759E-3
+JS      = 5.4E-6         JSW      = 2.94e-9        CAPMOD   = 0
+NQSMOD  = 0              XPART    = 1
+CALCACM = 1              SFVTFLAG = 0              VFBFLAG  = 1   
+CF      = 0              TLEV     = 1              TLEVC    = 1       )
*
***************************************************************
*                                                             *
*                 PMOS DEVICES MODEL                          *
*                                                             *
***************************************************************
*
*
.MODEL p.1     PMOS          (                     LEVEL    = 49 
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     
+LMIN   = '1.1991E-06-dxl' LMAX   = 2.1E-05        WMIN   = '1.005E-05-dxw'
+WMAX     = 0.000201       XL       = '-1.5E-08+dxl' XW       = '0+dxw'
+TNOM     = 25             VERSION  = 3.1            TOX      = toxp  
+XJ       = 1.8E-07        NCH      = 4.81E+17       LLN      = 1     
+LWN      = 1              WLN      = 1              WWN      = 1     
+LINT     = 1.203E-08      LL       = 0              LW       = 0     
+LWL      = 0              WINT     = 9.45E-09       WL       = 0     
+WW       = 0              WWL      = 0              MOBMOD   = 1     
+BINUNIT  = 2              DWG      = 0              DWB      = 0     
+ACM      = 12             LDIF     = 8.5E-08        HDIF     = hdifp 
+RSH      = 6.2            RD       = 0              RS       = 0     
+RSC     = 0              RDC     = 0              VTH0    = 'dvthp-0.350559'
+LVTH0    = -2.003981E-08  WVTH0    = 1.910611E-08   PVTH0    = 3.179443E-14
+K1       = 0.4473308      LK1      = 6.970389E-08   WK1      = -2.52377E-07
+PK1      = 2.927674E-13   K2       = 0.02313394     LK2      = -2.103609E-08
+K3       = 0              DVT0     = 0              DVT1     = 0     
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0     
+DVT2W    = 0              NLX      = 0              W0       = 0     
+K3B      = 0              VSAT     = 100000         UA       = 4.346223E-10
+LUA      = -4.183921E-17  WUA      = 7.130393E-16   PUA      = -4.391469E-22
+UB       = 7.884736E-19   LUB      = 6.849229E-25   WUB      = -1.728061E-25
+PUB      = -1.61022E-30   UC       = -1.296076E-10  LUC      = 1.246925E-16
+WUC      = -3.491712E-16  PUC      = 1.463836E-22   RDSW     = 671   
+PRWB     = 0              PRWG     = 0              WR       = 1     
+U0       = 0.009960146    LU0      = -1.463583E-12  WU0      = -1.469911E-11
+PU0      = 1.464037E-16   A0       = 0.9385321      LA0      = 6.122228E-07
+WA0      = 2.198927E-07   PA0      = -2.19014E-12   KETA     = 0.0003782401
+LKETA    = -6.018497E-09  WKETA    = 1.343391E-07   PKETA    = -1.165186E-13
+A1       = 0              A2       = 1              AGS      = 0.03484292
+LAGS     = 6.536994E-07   WAGS     = 9.429293E-08   PAGS     = -1.412569E-12
+B0       = 0              B1       = 0              VOFF     = -0.09797033
+LVOFF    = -1.005071E-08  WVOFF    = -1.114914E-07  NFACTOR  = 0.4144541
+LNFACTOR = -1.967078E-08  CIT      = 0.001          CDSC     = 0     
+CDSCB    = 0              CDSCD    = 0              ETA0     = 0.0003625643
+LETA0    = 1.453578E-10   WETA0    = 2.507866E-09   PETA0    = -2.768055E-15
+ETAB     = -8.18351E-05   LETAB    = -2.399417E-10  WETAB    = 5.178958E-10
+PETAB    = -4.816021E-15  DSUB     = 0              PCLM     = 0.9706969
+LPCLM    = 2.918597E-07   WPCLM    = 2.939419E-07   PPCLM    = -2.927673E-12
+PDIBLC1  = 0.0005020571   LPDIBLC1 = -1.315002E-10  WPDIBLC1 = 4.535441E-10
+PPDIBLC1 = 6.587264E-15   PDIBLC2  = 0.000348216    LPDIBLC2 = 1.400763E-09
+WPDIBLC2 = 1.996739E-09   PPDIBLC2 = -8.783018E-15  PDIBLCB  = -0.4783837
+LPDIBLCB = 1.377183E-06   DROUT    = 0              PSCBE1   = 7.258875E+08
+LPSCBE1  = -282.7181      WPSCBE1  = -2095.135      PPSCBE1  = 0.002433979
+PSCBE2   = 9.92491E-07    LPSCBE2  = 7.478009E-14   WPSCBE2  = 7.510014E-13
+PPSCBE2  = -7.48018E-18   PVAG     = 0              DELTA    = -0.0002160994
+LDELTA   = 1.247936E-08   WDELTA   = 2.433115E-08   PDELTA   = -9.107271E-14
+ALPHA0   = 1.9E-09        BETA0    = 12             KT1      = -0.2355184
+LKT1     = -3.180777E-09  KT2      = -0.02799823    LKT2     = -5.993676E-09
+AT       = 20602.38       LAT      = 0.005101417    WAT      = -0.1261884
+PAT      = 1.463836E-07   UTE      = -1.270621      LUTE     = 2.16488E-07
+WUTE     = -1.261884E-07  PUTE     = 1.463835E-13   UA1      = 4.408461E-10
+LUA1     = -4.225601E-16  UB1      = -1.519671E-18  LUB1     = 1.222046E-24
+UC1      = -4.773047E-12  LUC1     = 3.751008E-17   KT1L     = 0     
+NLEV     = 3              AF       = 1.13           KF       = 5.0E-24
+PRT      = 0              CJ       = cjp            MJ       = 0.4391504
+PB       = 0.892839       CJSW     = cjswp          MJSW     = 0.3013806
+PBSW     = 0.892839       CJSWG    = cjgatep        MJSWG    = 0.3013806
+PBSWG    = 0.892839       CTA      = 0.0009779284   CTP      = 0.0006857234
+PTA      = 0.001691764    PTP      = 0.001691764    CGDO     = cgop  
+CGSO     = cgop           JS       = 1.352E-05      JSW      = 4E-11 
+CAPMOD   = 0              XTI      = 3              N        = 1     
+NQSMOD   = 0              XPART    = 1              CF       = 0     
+TLEV     = 1              TLEVC    = 1              )
                                                                      
                                                                      
.MODEL p.2     PMOS          (                     LEVEL    = 49 
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     
+LMIN   = '4.991E-07-dxl' LMAX   = '1.1991E-06-dxl' WMIN   = '1.005E-05-dxw'
+WMAX     = 0.000201       XL       = '-1.5E-08+dxl' XW       = '0+dxw'
+TNOM     = 25             VERSION  = 3.1            TOX      = toxp  
+XJ       = 1.8E-07        NCH      = 4.81E+17       LLN      = 1     
+LWN      = 1              WLN      = 1              WWN      = 1     
+LINT     = 1.203E-08      LL       = 0              LW       = 0     
+LWL      = 0              WINT     = 9.45E-09       WL       = 0     
+WW       = 0              WWL      = 0              MOBMOD   = 1     
+BINUNIT  = 2              DWG      = 0              DWB      = 0     
+ACM      = 12             LDIF     = 8.5E-08        HDIF     = hdifp 
+RSH      = 6.2            RD       = 0              RS       = 0     
+RSC     = 0              RDC     = 0              VTH0    = 'dvthp-0.352974'
+LVTH0    = -1.723846E-08  WVTH0    = 5.641321E-08   PVTH0    = -1.14833E-14
+K1       = 0.5015458      LK1      = 6.812331E-09   K2       = 0.005 
+K3       = 0              DVT0     = 0              DVT1     = 0     
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0     
+DVT2W    = 0              NLX      = 0              W0       = 0     
+K3B      = 0              VSAT     = 100000         UA       = 3.766416E-10
+LUA      = 2.542077E-17   WUA      = 5.54296E-16    PUA      = -2.549983E-22
+UB       = 1.520599E-18   LUB      = -1.643718E-25  WUB      = -2.586688E-24
+PUB      = 1.18998E-30    UC       = -7.508774E-12  LUC      = -1.694701E-17
+WUC      = -3.695269E-16  PUC      = 1.699972E-22   RDSW     = 671   
+PRWB     = 0              PRWG     = 0              WR       = 1     
+U0       = 0.009958151    LU0      = 8.498383E-13   WU0      = 1.847888E-10
+PU0      = -8.501025E-17  A0       = 1.707019       LA0      = -2.792532E-07
+WA0      = -2.764366E-06  PA0      = 1.271719E-12   KETA     = -0.004103126
+LKETA    = -8.199334E-10  WKETA    = 1.294437E-07   PKETA    = -1.108398E-13
+A1       = 0              A2       = 1              AGS      = 0.5972779
+LAGS     = 1.252262E-09   WAGS     = -1.861694E-06  PAGS     = 8.564539E-13
+B0       = 0              B1       = 0              VOFF     = -0.09528618
+LVOFF    = -1.316442E-08  WVOFF    = -1.847634E-07  PVOFF    = 8.499856E-14
+NFACTOR  = 0.3991556      LNFACTOR = -1.924007E-09  CIT      = 0.001 
+CDSC     = 0              CDSCB    = 0              CDSCD    = 0     
+ETA0     = 0.0004945454   LETA0    = -7.745561E-12  WETA0    = -1.263772E-09
+PETA0    = 1.607195E-15   ETAB     = 1.511234E-05   LETAB    = -3.524046E-10
+WETAB    = -6.021773E-09  PETAB    = 2.770256E-15   DSUB     = 0     
+PCLM     = 1.368381       LPCLM    = -1.694701E-07  WPCLM    = -3.69527E-06
+PPCLM    = 1.699972E-12   PDIBLC1  = -1.304858E-05  LPDIBLC1 = 4.660429E-10
+WPDIBLC1 = 1.016199E-08   PPDIBLC1 = -4.674922E-15  PDIBLC2  = 0.001920953
+LPDIBLC2 = -4.236752E-10  WPDIBLC2 = -9.238172E-09  PPDIBLC2 = 4.249929E-15
+PDIBLCB  = 0.7088023      DROUT    = 0              PSCBE1   = 4.819736E+08
+LPSCBE1  = 0.2318351      WPSCBE1  = 5.055128       PPSCBE1  = -2.325561E-06
+PSCBE2   = 1.430214E-06   LPSCBE2  = -4.329961E-13  WPSCBE2  = -9.441413E-12
+PPSCBE2  = 4.343427E-18   PVAG     = 0              DELTA    = 0.01337984
+LDELTA   = -3.292475E-09  WDELTA   = -7.512786E-08  PDELTA   = 2.430372E-14
+ALPHA0   = 1.9E-09        BETA0    = 12             KT1      = -0.2382603
+KT2      = -0.03316501    AT       = 25000          UTE      = -1.077847
+LUTE     = -7.13766E-09   WUTE     = -6.154856E-07  PUTE     = 7.13988E-13
+UA1      = 7.658276E-11   UB1      = -4.662195E-19  UC1      = 2.756211E-11
+KT1L     = 0              PRT      = 0              CJ       = cjp   
+NLEV     = 3              AF       = 1.13           KF       = 5.0E-24
+MJ       = 0.4391504      PB       = 0.892839       CJSW     = cjswp 
+MJSW     = 0.3013806      PBSW     = 0.892839       CJSWG    = cjgatep
+MJSWG    = 0.3013806      PBSWG    = 0.892839       CTA      = 0.0009779284
+CTP      = 0.0006857234   PTA      = 0.001691764    PTP      = 0.001691764
+CGDO     = cgop           CGSO     = cgop           JS       = 1.352E-05
+JSW      = 4E-11          CAPMOD   = 0              XTI      = 3     
+N        = 1              NQSMOD   = 0              XPART    = 1     
+CF       = 0              TLEV     = 1              TLEVC    = 1              )
                                                                      
                                                                      
.MODEL p.3     PMOS          (                     LEVEL    = 49 
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     
+LMIN   = 1.5E-07      LMAX   = '4.991E-07-dxl' WMIN   = '1.005E-05-dxw'
+WMAX     = 0.000201       XL       = '-1.5E-08+dxl' XW       = '0+dxw'
+TNOM     = 25             VERSION  = 3.1            TOX      = toxp  
+XJ       = 1.8E-07        NCH      = 4.81E+17       LLN      = 1     
+LWN      = 1              WLN      = 1              WWN      = 1     
+LINT     = 1.203E-08      LL       = 0              LW       = 0     
+LWL      = 0              WINT     = 9.45E-09       WL       = 0     
+WW       = 0              WWL      = 0              MOBMOD   = 1     
+BINUNIT  = 2              DWG      = 0              DWB      = 0     
+ACM      = 12             LDIF     = 8.5E-08        HDIF     = hdifp 
+RSH      = 6.2            RD       = 0              RS       = 0     
+RSC     = 0              RDC     = 0              VTH0    = 'dvthp-0.373746'
+LVTH0    = -7.682393E-09  WVTH0    = 4.462458E-08   PVTH0    = -6.060069E-15
+K1       = 0.5163402      WK1      = -1.036948E-07  PK1      = 4.770374E-14
+K2       = 0.005          K3       = 0              DVT0     = 0     
+DVT1     = 0              DVT2     = 0              DVT0W    = 0     
+DVT1W    = 0              DVT2W    = 0              NLX      = 0     
+W0       = 0              K3B      = 0              VSAT     = 99685.6
+LVSAT    = 0.0001446366   UA       = 5.362484E-10   LUA      = -4.800478E-17
+UB       = 1.078892E-18   LUB      = 3.883126E-26   WUB      = 3.505328E-26
+PUB      = -1.612588E-32  UC       = -6.447448E-11  LUC      = 9.259491E-18
+WUC      = -7.361103E-17  PUC      = 3.386403E-23   RDSW     = 671   
+PRWB     = 0              PRWG     = 0              WR       = 1     
+U0       = 0.009640164    LU0      = 1.47137E-10    WU0      = 7.817012E-11
+PU0      = -3.596153E-17  A0       = 1.16288        LA0      = -2.892733E-08
+KETA     = -0.000751862   LKETA    = -2.361648E-09  WKETA    = -5.891203E-08
+PKETA    = -2.418859E-14  A1       = 0              A2       = 1     
+AGS      = 0.6723121      LAGS     = -3.326642E-08  B0       = 0     
+B1       = 0              VOFF     = -0.1222623     LVOFF    = -7.543369E-10
+WVOFF    = -1.407025E-08  PVOFF    = 6.472879E-15   NFACTOR  = 0.1534212
+LNFACTOR = 1.111237E-07   WNFACTOR = -6.513524E-07  PNFACTOR = 2.996482E-13
+CIT      = 0.001          CDSC     = 0              CDSCB    = 0     
+CDSCD    = 0              ETA0     = -0.0009441002  LETA0    = 6.540888E-10
+WETA0    = 2.930882E-09   PETA0    = -3.22514E-16   ETAB     = 1.152803E-05
+LETAB    = -3.507556E-10  DSUB     = 0              PCLM     = 1     
+PDIBLC1  = 0.00117292     LPDIBLC1 = -7.955013E-11  PDIBLC2  = 0.001 
+PDIBLCB  = 0.7088023      DROUT    = 0              PSCBE1   = 4.83425E+08
+LPSCBE1  = -0.435863      PSCBE2   = 3.283416E-07   LPSCBE2  = 7.39093E-14
+PVAG     = 0              DELTA    = 0.005664197    LDELTA   = 2.570318E-10
+WDELTA   = -2.930884E-08  PDELTA   = 3.225145E-15   ALPHA0   = 1.9E-09
+BETA0    = 12             KT1      = -0.2348335     LKT1     = -1.576455E-09
+WKT1     = -5.037318E-10  PKT1     = 2.317377E-16   KT2      = -0.03513003
+LKT2     = 9.039858E-10   WKT2     = -3.505414E-08  PKT2     = 1.61263E-14
+AT       = 26572          LAT      = -0.000723183   UTE      = -1.033282
+LUTE     = -2.763946E-08  WUTE     = 1.09076E-06    PUTE     = -7.095325E-14
+UA1      = 6.144941E-10   LUA1     = -2.474607E-16  UB1      = -1.136088E-18
+LUB1     = 3.081663E-25   UC1      = 3.107047E-11   LUC1     = -1.613987E-18
+KT1L     = 0              PRT      = 0              CJ       = cjp   
+NLEV     = 3              AF       = 1.13           KF       = 5.0E-24
+MJ       = 0.4391504      PB       = 0.892839       CJSW     = cjswp 
+MJSW     = 0.3013806      PBSW     = 0.892839       CJSWG    = cjgatep
+MJSWG    = 0.3013806      PBSWG    = 0.892839       CTA      = 0.0009779284
+CTP      = 0.0006857234   PTA      = 0.001691764    PTP      = 0.001691764
+CGDO     = cgop           CGSO     = cgop           JS       = 1.352E-05
+JSW      = 4E-11          CAPMOD   = 0              XTI      = 3     
+N        = 1              NQSMOD   = 0              XPART    = 1     
+CF       = 0              TLEV     = 1              TLEVC    = 1              )
                                                                      
                                                                      
.MODEL p.4     PMOS          (                     LEVEL    = 49 
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     
+LMIN   = '1.1991E-06-dxl' LMAX   = 2.1E-05        WMIN   = '1.25E-06-dxw'
+WMAX     = '1.005E-05-dxw' XL       = '-1.5E-08+dxl' XW       = '0+dxw'
+TNOM     = 25             VERSION  = 3.1            TOX      = toxp  
+XJ       = 1.8E-07        NCH      = 4.81E+17       LLN      = 1     
+LWN      = 1              WLN      = 1              WWN      = 1     
+LINT     = 1.203E-08      LL       = 0              LW       = 0     
+LWL      = 0              WINT     = 9.45E-09       WL       = 0     
+WW       = 0              WWL      = 0              MOBMOD   = 1     
+BINUNIT  = 2              DWG      = 0              DWB      = 0     
+ACM      = 12             LDIF     = 8.5E-08        HDIF     = hdifp 
+RSH      = 6.2            RD       = 0              RS       = 0     
+RSC     = 0              RDC     = 0              VTH0    = 'dvthp-0.34896'
+LVTH0    = -1.661307E-08  WVTH0    = 3.065647E-09   PVTH0    = -2.579507E-15
+K1       = 0.4221713      LK1      = 9.888986E-08   K2       = 0.02313394
+LK2      = -2.103609E-08  K3       = 0              DVT0     = 0     
+DVT1     = 0              DVT2     = 0              DVT0W    = 0     
+DVT1W    = 0              DVT2W    = 0              NLX      = 0     
+W0       = 0              K3B      = 0              VSAT     = 100000
+UA       = 4.917154E-10   LUA      = -8.56177E-17   WUA      = 1.403328E-16
+UB       = 7.719843E-19   LUB      = 5.170528E-25   WUB      = -7.399592E-27
+PUB      = 7.370047E-32   UC       = -1.7075E-10    LUC      = 1.466326E-16
+WUC      = 6.353276E-17   PUC      = -7.370052E-23  RDSW     = 671   
+PRWB     = 0              PRWG     = 0              WR       = 1     
+U0       = 0.009958495    LU0      = 1.496845E-11   WU0      = 1.85016E-12
+PU0      = -1.842766E-17  A0       = 0.9702144      LA0      = 3.663358E-07
+WA0      = -9.791499E-08  PA0      = 2.76377E-13    KETA     = 0.01228248
+LKETA    = -1.396063E-08  WKETA    = 1.492644E-08   PKETA    = -3.685026E-14
+A1       = 0              A2       = 1              AGS      = 0.04610778
+LAGS     = 5.162349E-07   WAGS     = -1.870542E-08  PAGS     = -3.365017E-14
+B0       = 0              B1       = 0              VOFF     = -0.1075015
+LVOFF    = -1.18875E-08   WVOFF    = -1.588318E-08  PVOFF    = 1.842513E-14
+NFACTOR  = 0.4144541      LNFACTOR = -1.967078E-08  CIT      = 0.001 
+CDSC     = 0              CDSCB    = 0              CDSCD    = 0     
+ETA0     = 0.0006436043   LETA0    = -3.065672E-10  WETA0    = -3.11275E-10
+PETA0    = 1.765251E-15   ETAB     = -1.575215E-05  LETAB    = -7.8971E-10
+WETAB    = -1.449886E-10  PETAB    = 6.987598E-16   DSUB     = 0     
+PCLM     = 1.031668       LPCLM    = -3.673599E-08  WPCLM    = -3.176637E-07
+PPCLM    = 3.685026E-13   PDIBLC1  = 0.0005054602   LPDIBLC1 = 6.629438E-10
+WPDIBLC1 = 4.194084E-10   PPDIBLC1 = -1.381885E-15  PDIBLC2  = 0.000502694
+LPDIBLC2 = 6.904958E-10   WPDIBLC2 = 4.47157E-10    PPDIBLC2 = -1.658262E-15
+PDIBLCB  = -0.4783837     LPDIBLCB = 1.377183E-06   DROUT    = 0     
+PSCBE1   = 4.907392E+08   LPSCBE1  = -9.583876      WPSCBE1  = 263.6615
+PPSCBE1  = -0.0003058579  PSCBE2   = 1.067358E-06   LPSCBE2  = -6.709185E-13
+PVAG     = 0              DELTA    = 0.002477893    LDELTA   = 2.624923E-09
+WDELTA   = -2.692553E-09  PDELTA   = 7.778188E-15   ALPHA0   = 1.9E-09
+BETA0    = 12             KT1      = -0.2355184     LKT1     = -3.180777E-09
+KT2      = -0.02799823    LKT2     = -5.993676E-09  AT       = 7930.451
+LAT      = 0.02061279     WAT      = 0.0009249522   PAT      = -9.212566E-09
+UTE      = -1.298223      LUTE     = 2.41367E-07    WUTE     = 1.506923E-07
+PUTE     = -1.031807E-13  UA1      = 4.408461E-10   LUA1     = -4.225601E-16
+UB1      = -1.519671E-18  LUB1     = 1.222046E-24   UC1      = -4.773047E-12
+LUC1     = 3.751008E-17   KT1L     = 0              PRT      = 0     
+NLEV     = 3              AF       = 1.13           KF       = 5.0E-24
+CJ       = cjp            MJ       = 0.4391504      PB       = 0.892839
+CJSW     = cjswp          MJSW     = 0.3013806      PBSW     = 0.892839
+CJSWG    = cjgatep        MJSWG    = 0.3013806      PBSWG    = 0.892839
+CTA      = 0.0009779284   CTP      = 0.0006857234   PTA      = 0.001691764
+PTP      = 0.001691764    CGDO     = cgop           CGSO     = cgop  
+JS       = 1.352E-05      JSW      = 4E-11          CAPMOD   = 0     
+XTI      = 3              N        = 1              NQSMOD   = 0     
+XPART    = 1              CF       = 0              TLEV     = 1     
+TLEVC    = 1              )
                                                                      
                                                                      
.MODEL p.5     PMOS          (                     LEVEL    = 49 
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     
+LMIN   = '4.991E-07-dxl' LMAX   = '1.1991E-06-dxl' WMIN   = '1.25E-06-dxw'
+WMAX     = '1.005E-05-dxw' XL       = '-1.5E-08+dxl' XW       = '0+dxw'
+TNOM     = 25             VERSION  = 3.1            TOX      = toxp  
+XJ       = 1.8E-07        NCH      = 4.81E+17       LLN      = 1     
+LWN      = 1              WLN      = 1              WWN      = 1     
+LINT     = 1.203E-08      LL       = 0              LW       = 0     
+LWL      = 0              WINT     = 9.45E-09       WL       = 0     
+WW       = 0              WWL      = 0              MOBMOD   = 1     
+BINUNIT  = 2              DWG      = 0              DWB      = 0     
+ACM      = 12             LDIF     = 8.5E-08        HDIF     = hdifp 
+RSH      = 6.2            RD       = 0              RS       = 0     
+RSC     = 0              RDC     = 0              VTH0    = 'dvthp-0.347145'
+LVTH0    = -1.871823E-08  WVTH0    = -2.054817E-09  PVTH0    = 3.360437E-15
+K1       = 0.4977862      LK1      = 1.11736E-08    WK1      = 3.77128E-08
+PK1      = -4.374836E-14  K2       = 0.005          K3       = 0     
+DVT0     = 0              DVT1     = 0              DVT2     = 0     
+DVT0W    = 0              DVT1W    = 0              DVT2W    = 0     
+NLX      = 0              W0       = 0              K3B      = 0     
+VSAT     = 100000         UA       = 4.110333E-10   LUA      = 7.976724E-18
+WUA      = 2.093088E-16   PUA      = -8.001537E-23  UB       = 1.222254E-18
+LUB      = -5.277555E-27  WUB      = 4.060439E-25   PUB      = -4.059106E-31
+UC       = -4.95034E-11   LUC      = 5.981752E-18   WUC      = 5.172544E-17
+PUC      = -6.000359E-23  RDSW     = 671            PRWB     = 0     
+PRWG     = 0              WR       = 1              U0       = 0.009863626
+LU0      = 1.250206E-10   WU0      = 1.132977E-09   PU0      = -1.33058E-15
+A0       = 1.399062       LA0      = -1.311446E-07  WA0      = 3.247863E-07
+PA0      = -2.139734E-13  KETA     = 0.01535275     LKETA    = -1.752226E-08
+WKETA    = -6.572009E-08  PKETA    = 5.670294E-14   A1       = 0     
+A2       = 1              AGS      = 0.3781949      LAGS     = 1.310006E-07
+WAGS     = 3.359499E-07   PAGS     = -4.450646E-13  B0       = 0     
+B1       = 0              VOFF     = -0.1133819     LVOFF    = -5.066021E-09
+WVOFF    = -3.243615E-09  PVOFF    = 3.762723E-15   NFACTOR  = 0.4032626
+LNFACTOR = -6.688186E-09  WNFACTOR = -4.119683E-08  PNFACTOR = 4.778997E-14
+CIT      = 0.001          CDSC     = 0              CDSCB    = 0     
+CDSCD    = 0              ETA0     = 0.0002785717   LETA0    = 1.16885E-10
+WETA0    = 9.02681E-10    PETA0    = 3.570135E-16   ETAB     = -0.0006014257
+LETAB    = -1.103053E-10  WETAB    = 1.627812E-10   PETAB    = 3.417347E-16
+DSUB     = 0              PCLM     = 0.9908059      LPCLM    = 1.06655E-08
+WPCLM    = 9.222673E-08   PPCLM    = -1.069867E-13  PDIBLC1  = 0.001127511
+LPDIBLC1 = -5.866022E-11  WPDIBLC1 = -1.279077E-09  PPDIBLC1 = 5.884267E-16
+PDIBLC2  = 0.001156647    LPDIBLC2 = -6.811626E-11  WPDIBLC2 = -1.571345E-09
+PPDIBLC2 = 6.832811E-16   PDIBLCB  = 0.6123642      LPDIBLCB = 1.11872E-07
+WPDIBLCB = 9.673798E-07   PPDIBLCB = -1.122199E-12  DROUT    = 0     
+PSCBE1   = 5.005034E+08   LPSCBE1  = -20.91079      WPSCBE1  = -180.8199
+PPSCBE1  = 0.0002097583   PSCBE2   = 5.359817E-07   LPSCBE2  = -5.450069E-14
+WPSCBE2  = -4.712785E-13  PPSCBE2  = 5.467019E-19   PVAG     = 0     
+DELTA    = 0.005779098    LDELTA   = -1.204607E-09  WDELTA   = 1.115996E-09
+PDELTA   = 3.360119E-15   ALPHA0   = 1.9E-09        BETA0    = 12    
+KT1      = -0.2380376     LKT1     = -2.583823E-10  WKT1     = -2.234285E-09
+PKT1     = 2.59186E-15    KT2      = -0.0327453     LKT2     = -4.868811E-10
+WKT2     = -4.21016E-09   PKT2     = 4.883954E-15   AT       = 24780.08
+LAT      = 0.00106655     WAT      = 0.002206031    PAT      = -1.069867E-08
+UTE      = -1.151245      LUTE     = 7.086569E-08   WUTE     = 1.207716E-07
+PUTE     = -6.847149E-14  UA1      = 1.061728E-10   LUA1     = -3.432559E-17
+WUA1     = -2.968205E-16  PUA1     = 3.443236E-22   UB1      = -5.517939E-19
+LUB1     = 9.926975E-26   WUB1     = 8.58406E-25    PUB1     = -9.957853E-31
+UC1      = 2.493545E-11   LUC1     = 3.047037E-18   WUC1     = 2.634834E-17
+PUC1     = -3.056513E-23  KT1L     = 0              PRT      = 0     
+NLEV     = 3              AF       = 1.13           KF       = 5.0E-24
+CJ       = cjp            MJ       = 0.4391504      PB       = 0.892839
+CJSW     = cjswp          MJSW     = 0.3013806      PBSW     = 0.892839
+CJSWG    = cjgatep        MJSWG    = 0.3013806      PBSWG    = 0.892839
+CTA      = 0.0009779284   CTP      = 0.0006857234   PTA      = 0.001691764
+PTP      = 0.001691764    CGDO     = cgop           CGSO     = cgop  
+JS       = 1.352E-05      JSW      = 4E-11          CAPMOD   = 0     
+XTI      = 3              N        = 1              NQSMOD   = 0     
+XPART    = 1              CF       = 0              TLEV     = 1     
+TLEVC    = 1              )
                                                                      
                                                                      
.MODEL p.6     PMOS          (                     LEVEL    = 49 
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     
+LMIN   = 1.5E-07      LMAX   = '4.991E-07-dxl' WMIN   = '1.25E-06-dxw'
+WMAX     = '1.005E-05-dxw' XL       = '-1.5E-08+dxl' XW       = '0+dxw'
+TNOM     = 25             VERSION  = 3.1            TOX      = toxp  
+XJ       = 1.8E-07        NCH      = 4.81E+17       LLN      = 1     
+LWN      = 1              WLN      = 1              WWN      = 1     
+LINT     = 1.203E-08      LL       = 0              LW       = 0     
+LWL      = 0              WINT     = 9.45E-09       WL       = 0     
+WW       = 0              WWL      = 0              MOBMOD   = 1     
+BINUNIT  = 2              DWG      = 0              DWB      = 0     
+ACM      = 12             LDIF     = 8.5E-08        HDIF     = hdifp 
+RSH      = 6.2            RD       = 0              RS       = 0     
+RSC     = 0              RDC     = 0              VTH0    = 'dvthp-0.370291'
+LVTH0    = -8.070338E-09  WVTH0    = 9.963688E-09   PVTH0    = -2.168556E-15
+K1       = 0.5122209      LK1      = 4.533055E-09   WK1      = -6.237367E-08
+PK1      = 2.295422E-15   K2       = 0.005          K3       = 0     
+DVT0     = 0              DVT1     = 0              DVT2     = 0     
+DVT0W    = 0              DVT1W    = 0              DVT2W    = 0     
+NLX      = 0              W0       = 0              K3B      = 0     
+VSAT     = 100081.4       LVSAT    = -3.747244E-05  WVSAT    = -0.003970858
+PVSAT    = 1.826753E-09   UA       = 5.316128E-10   LUA      = -4.749468E-17
+WUA      = 4.650012E-17   PUA      = -5.116877E-24  UB       = 1.147435E-18
+LUB      = 2.914202E-26   WUB      = -6.525128E-25  PUB      = 8.106786E-32
+UC       = -6.435981E-11  LUC      = 1.281629E-17   WUC      = -7.476129E-17
+PUC      = -1.814628E-24  RDSW     = 671            PRWB     = 0     
+PRWG     = 0              WR       = 1              U0       = 0.009844861
+LU0      = 1.336536E-10   WU0      = -1.97517E-09   PU0      = 9.929197E-17
+A0       = 1.181268       LA0      = -3.095076E-08  WA0      = -1.844535E-07
+PA0      = 2.029726E-14   KETA     = -0.01218467    LKETA    = -4.853945E-09
+WKETA    = 5.577162E-08   PKETA    = 8.118911E-16   A1       = 0     
+A2       = 1              AGS      = 0.7475815      LAGS     = -3.893203E-08
+WAGS     = -7.550354E-07  PAGS     = 5.683233E-14   B0       = 0     
+B1       = 0              VOFF     = -0.1240483     LVOFF    = -1.590245E-10
+WVOFF    = 3.84595E-09    PVOFF    = 5.012398E-16   NFACTOR  = 0.08089781
+LNFACTOR = 1.416125E-07   WNFACTOR = 7.613732E-08   PNFACTOR = -6.188436E-15
+CIT      = 0.001          CDSC     = 0              CDSCB    = 0     
+CDSCD    = 0              ETA0     = -0.0009172825  LETA0    = 6.670259E-10
+WETA0    = 2.661878E-09   PETA0    = -4.522876E-16  ETAB     = -0.0001657759
+LETAB    = -3.107217E-10  WETAB    = 1.778552E-09   PETAB    = -4.015844E-16
+DSUB     = 0              PCLM     = 1.018388       LPCLM    = -2.023433E-09
+WPCLM    = -1.844535E-07  PPCLM    = 2.029726E-14   PDIBLC1  = 0.001197111
+LPDIBLC1 = -9.067901E-11  WPDIBLC1 = -2.426636E-10  PPDIBLC1 = 1.116349E-16
+PDIBLC2  = 0.001110844    LPDIBLC2 = -4.704504E-11  WPDIBLC2 = -1.11189E-09
+PPDIBLC2 = 4.719133E-16   PDIBLCB  = 0.9016784      LPDIBLCB = -2.122409E-08
+WPDIBLCB = -1.93476E-06   PPDIBLCB = 2.12901E-13    DROUT    = 0     
+PSCBE1   = 4.473731E+08   LPSCBE1  = 3.531283       WPSCBE1  = 361.6398
+PPSCBE1  = -3.979485E-05  PSCBE2   = 2.343782E-07   LPSCBE2  = 8.424904E-14
+WPSCBE2  = 9.42557E-13    PPSCBE2  = -1.03719E-19   PVAG     = 0     
+DELTA    = 0.001595128    LDELTA   = 7.201867E-10   WDELTA   = 1.150841E-08
+PDELTA   = -1.420808E-15  ALPHA0   = 1.9E-09        BETA0    = 12    
+KT1      = -0.2348568     LKT1     = -1.721644E-09  WKT1     = -2.698527E-10
+PKT1     = 1.688143E-15   KT2      = -0.04022777    LKT2     = 2.955356E-09
+WKT2     = 1.608188E-08   PKT2     = -4.451194E-15  AT       = 28824.41
+LAT      = -0.0007940029  WAT      = -0.02259414    PAT      = 7.104038E-10
+UTE      = -0.9052081     LUTE     = -4.232089E-08  WUTE     = -1.939602E-07
+PUTE     = 7.631769E-14   UA1      = 6.305667E-10   LUA1     = -2.755678E-16
+WUA1     = -1.612254E-16  PUA1     = 2.819444E-22   UB1      = -1.058652E-18
+LUB1     = 3.324448E-25   WUB1     = -7.767671E-25  PUB1     = -2.435404E-31
+UC1      = 3.681462E-11   LUC1     = -2.417857E-18  WUC1     = -5.762007E-17
+PUC1     = 8.063698E-24   KT1L     = 0              PRT      = 0     
+NLEV     = 3              AF       = 1.13           KF       = 5.0E-24
+CJ       = cjp            MJ       = 0.4391504      PB       = 0.892839
+CJSW     = cjswp          MJSW     = 0.3013806      PBSW     = 0.892839
+CJSWG    = cjgatep        MJSWG    = 0.3013806      PBSWG    = 0.892839
+CTA      = 0.0009779284   CTP      = 0.0006857234   PTA      = 0.001691764
+PTP      = 0.001691764    CGDO     = cgop           CGSO     = cgop  
+JS       = 1.352E-05      JSW      = 4E-11          CAPMOD   = 0     
+XTI      = 3              N        = 1              NQSMOD   = 0     
+XPART    = 1              CF       = 0              TLEV     = 1     
+TLEVC    = 1              DLC      = 2.51E-08        )
                                                                      
                                                                      
.MODEL p.7     PMOS          (                     LEVEL    = 49 
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     
+LMIN   = '1.1991E-06-dxl' LMAX   = 2.1E-05        WMIN   = '5.8E-07-dxw'
+WMAX     = '1.25E-06-dxw' XL       = '-1.5E-08+dxl' XW       = '0+dxw'
+TNOM     = 25             VERSION  = 3.1            TOX      = toxp  
+XJ       = 1.8E-07        NCH      = 4.81E+17       LLN      = 1     
+LWN      = 1              WLN      = 1              WWN      = 1     
+LINT     = 1.203E-08      LL       = 0              LW       = 0     
+LWL      = 0              WINT     = 9.45E-09       WL       = 0     
+WW       = 0              WWL      = 0              MOBMOD   = 1     
+BINUNIT  = 2              DWG      = 0              DWB      = 0     
+ACM      = 12             LDIF     = 8.5E-08        HDIF     = hdifp 
+RSH      = 6.2            RD       = 0              RS       = 0     
+RSC     = 0              RDC     = 0              VTH0    = 'dvthp-0.354845'
+LVTH0    = -1.018569E-08  WVTH0    = 1.031078E-08   PVTH0    = -1.049226E-14
+K1       = 0.3987467      LK1      = 1.487198E-07   WK1      = 2.883809E-08
+PK1      = -6.134562E-14  K2       = 0.03832044     LK2      = -3.865304E-08
+WK2      = -1.86961E-08   PK2      = 2.168822E-14   K3       = 0     
+DVT0     = 0              DVT1     = 0              DVT2     = 0     
+DVT0W    = 0              DVT1W    = 0              DVT2W    = 0     
+NLX      = 0              W0       = 0              K3B      = 0     
+VSAT     = 100000         UA       = 7.976549E-10   LUA      = -4.020732E-16
+WUA      = -2.363094E-16  PUA      = 3.895879E-22   UB       = 4.723373E-19
+LUB      = 1.060066E-24   WUB      = 3.614958E-25   PUB      = -5.948031E-31
+UC       = -1.081958E-10  LUC      = 1.594313E-16   WUC      = -1.347775E-17
+PUC      = -8.945687E-23  RDSW     = 671            PRWB     = 0     
+PRWG     = 0              WR       = 1              U0       = 0.009959999
+A0       = 0.3583173      LA0      = 1.305543E-06   WA0      = 6.553913E-07
+PA0      = -8.798803E-13  KETA     = 0.04638855     LKETA    = -7.515476E-08
+WKETA    = -2.706153E-08  PKETA    = 3.848583E-14   A1       = 0     
+A2       = 1              AGS      = -0.2194341     LAGS     = 8.323651E-07
+WAGS     = 3.082031E-07   PAGS     = -4.228379E-13  B0       = 0     
+B1       = 0              VOFF     = -0.123362      LVOFF    = 5.657355E-09
+WVOFF    = 3.642653E-09   PVOFF    = -3.174341E-15  NFACTOR  = 0.2193509
+LNFACTOR = -3.614433E-08  WNFACTOR = 2.401915E-07   PNFACTOR = 2.028058E-14
+CIT      = 0.001          CDSC     = 0              CDSCB    = 0     
+CDSCD    = 0              ETA0     = 0.0002425461   LETA0    = 2.03962E-09
+WETA0    = 1.824678E-10   PETA0    = -1.123141E-15  ETAB     = -0.0004356864
+LETAB    = 4.450268E-10   WETAB    = 3.719925E-10   PETAB    = -8.213247E-16
+DSUB     = 0              PCLM     = 0.5840636      LPCLM    = 4.825029E-07
+WPCLM    = 2.333819E-07   PPCLM    = -2.707323E-13  PDIBLC1  = 0.001001642
+LPDIBLC1 = -1.174247E-09  WPDIBLC1 = -1.914411E-10  PPDIBLC1 = 8.798802E-16
+PDIBLC2  = 0.001037975    LPDIBLC2 = -1.536124E-09  WPDIBLC2 = -2.118274E-10
+PPDIBLC2 = 1.082929E-15   PDIBLCB  = -1.472608      LPDIBLCB = 2.530523E-06
+WPDIBLCB = 1.223989E-06   PPDIBLCB = -1.419877E-12  DROUT    = 0     
+PSCBE1   = 8.772551E+08   LPSCBE1  = -473.2128      WPSCBE1  = -212.1783
+PPSCBE1  = 0.0002649156   PSCBE2   = 1.123772E-06   LPSCBE2  = -1.232792E-12
+WPSCBE2  = -6.944832E-14  PPSCBE2  = 6.917197E-19   PVAG     = 0     
+DELTA    = -0.0005011006  LDELTA   = 1.423332E-08   WDELTA   = 9.748858E-10
+PDELTA   = -6.512914E-15  ALPHA0   = 1.9E-09        BETA0    = 12    
+KT1      = -0.2332221     LKT1     = -5.84456E-09   WKT1     = -2.826956E-09
+PKT1     = 3.279382E-15   KT2      = -0.02367124    LKT2     = -1.101316E-08
+WKT2     = -5.326956E-09  PKT2     = 6.179482E-15   AT       = -1348.802
+LAT      = 0.02962292     WAT      = 0.01234864     PAT      = -2.030493E-08
+UTE      = -1.186401      LUTE     = 1.795462E-07   WUTE     = 1.302817E-08
+PUTE     = -2.707321E-14  UA1      = 7.459031E-10   LUA1     = -7.764384E-16
+WUA1     = -3.755556E-16  PUA1     = 4.356596E-22   UB1      = -2.401897E-18
+LUB1     = 2.245463E-24   WUB1     = 1.086109E-24   PUB1     = -1.25993E-30
+UC1      = -3.185254E-11  LUC1     = 6.892338E-17   WUC1     = 3.333756E-17
+PUC1     = -3.867291E-23  KT1L     = 0              PRT      = 0     
+NLEV     = 3              AF       = 1.13           KF       = 5.0E-24
+CJ       = cjp            MJ       = 0.4391504      PB       = 0.892839
+CJSW     = cjswp          MJSW     = 0.3013806      PBSW     = 0.892839
+CJSWG    = cjgatep        MJSWG    = 0.3013806      PBSWG    = 0.892839
+CTA      = 0.0009779284   CTP      = 0.0006857234   PTA      = 0.001691764
+PTP      = 0.001691764    CGDO     = cgop           CGSO     = cgop  
+JS       = 1.352E-05      JSW      = 4E-11          CAPMOD   = 0     
+XTI      = 3              N        = 1              NQSMOD   = 0     
+XPART    = 1              CF       = 0              TLEV     = 1     
+TLEVC    = 1              )
                                                                      
                                                                      
.MODEL p.8     PMOS          (                     LEVEL    = 49 
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     
+LMIN   = '4.991E-07-dxl' LMAX   = '1.1991E-06-dxl' WMIN   = '5.8E-07-dxw'
+WMAX     = '1.25E-06-dxw' XL       = '-1.5E-08+dxl' XW       = '0+dxw'
+TNOM     = 25             VERSION  = 3.1            TOX      = toxp  
+XJ       = 1.8E-07        NCH      = 4.81E+17       LLN      = 1     
+LWN      = 1              WLN      = 1              WWN      = 1     
+LINT     = 1.203E-08      LL       = 0              LW       = 0     
+LWL      = 0              WINT     = 9.45E-09       WL       = 0     
+WW       = 0              WWL      = 0              MOBMOD   = 1     
+BINUNIT  = 2              DWG      = 0              DWB      = 0     
+ACM      = 12             LDIF     = 8.5E-08        HDIF     = hdifp 
+RSH      = 6.2            RD       = 0              RS       = 0     
+RSC     = 0              RDC     = 0              VTH0    = 'dvthp-0.34595'
+LVTH0    = -2.050428E-08  WVTH0    = -3.526243E-09  PVTH0    = 5.559243E-15
+K1       = 0.557085       LK1      = -3.495901E-08  WK1      = -3.528997E-08
+PK1      = 1.30455E-14    K2       = 0.005137128    LK2      = -1.590739E-10
+WK2      = -1.688182E-10  PK2      = 1.958359E-16   K3       = 0     
+DVT0     = 0              DVT1     = 0              DVT2     = 0     
+DVT0W    = 0              DVT1W    = 0              DVT2W    = 0     
+NLX      = 0              W0       = 0              K3B      = 0     
+VSAT     = 100557.3       LVSAT    = -0.0006464442  WVSAT    = -0.0006860432
+PVSAT    = 7.958375E-10   UA       = 5.218609E-10   LUA      = -8.214109E-17
+WUA      = 7.286899E-17   PUA      = 3.092866E-23   UB       = 1.933616E-18
+LUB      = -6.350755E-25  WUB      = -4.69714E-25   PUB      = 3.694336E-31
+UC       = 8.857808E-11   LUC      = -6.883432E-17  WUC      = -1.182667E-16
+PUC      = 3.210247E-23   RDSW     = 671            PRWB     = 0     
+PRWG     = 0              WR       = 1              U0       = 0.01133164
+LU0      = -1.591165E-09  WU0      = -6.743007E-10  PU0      = 7.822157E-16
+A0       = 2.065385       LA0      = -6.747238E-07  WA0      = -4.955235E-07
+PA0      = 4.552269E-13   KETA     = -0.06859269    LKETA    = 5.822807E-08
+WKETA    = 3.762512E-08   PKETA    = -3.655328E-14  A1       = 0     
+A2       = 1              AGS      = 1.023016       LAGS     = -6.089272E-07
+WAGS     = -4.578897E-07  PAGS     = 4.658604E-13   B0       = 0     
+B1       = 0              VOFF     = -0.1101929     LVOFF    = -9.619287E-09
+WVOFF    = -7.169549E-09  PVOFF    = 9.368246E-15   NFACTOR  = 0.368682
+LNFACTOR = -2.093745E-07  WNFACTOR = 1.375274E-09   PNFACTOR = 2.973171E-13
+CIT      = 0.001          CDSC     = 0              CDSCB    = 0     
+CDSCD    = 0              ETA0     = 0.001231128    LETA0    = 8.928256E-10
+WETA0    = -2.700111E-10  PETA0    = -5.982468E-16  ETAB     = 0.0003323215
+LETAB    = -4.458931E-10  WETAB    = -9.867549E-10  PETAB    = 7.548768E-16
+DSUB     = 0              PCLM     = 1.06458        LPCLM    = -7.491562E-08
+WPCLM    = 1.403227E-09   PPCLM    = -1.627803E-15  PDIBLC1  = -0.0006747739
+LPDIBLC1 = 7.704631E-10   WPDIBLC1 = 9.397156E-10   PPDIBLC1 = -4.323068E-16
+PDIBLC2  = -0.001508156   LPDIBLC2 = 1.41749E-09    WPDIBLC2 = 1.709294E-09
+PPDIBLC2 = -1.145648E-15  PDIBLCB  = 2.060165       LPDIBLCB = -1.567634E-06
+WPDIBLCB = -8.150069E-07  PPDIBLCB = 9.454407E-13   DROUT    = 0     
+PSCBE1   = 2.061901E+08   LPSCBE1  = 305.2495       WPSCBE1  = 181.5092
+PPSCBE1  = -0.0001917776  PSCBE2   = -5.560172E-07  LPSCBE2  = 7.158302E-13
+WPSCBE2  = 8.730812E-13   PPSCBE2  = -4.016523E-19  PVAG     = 0     
+DELTA    = 0.01224968     LDELTA   = -5.580951E-10  WDELTA   = -6.849941E-09
+PDELTA   = 2.564198E-15   ALPHA0   = 1.9E-09        BETA0    = 12    
+KT1      = -0.2413814     LKT1     = 3.620653E-09   WKT1     = 1.882365E-09
+PKT1     = -2.183619E-15  KT2      = -0.03904631    LKT2     = 6.822545E-09
+WKT2     = 3.547015E-09   PKT2     = -4.114679E-15  AT       = 37975.3
+LAT      = -0.01599463    WAT      = -0.01403861    PAT      = 1.030534E-08
+UTE      = -1.049992      LUTE     = 2.130658E-08   WUTE     = -3.879813E-09
+PUTE     = -7.459267E-15  UA1      = -3.380546E-10  LUA1     = 4.809959E-16
+WUA1     = 2.500677E-16   PUA1     = -2.900886E-22  UB1      = 7.329135E-19
+LUB1     = -1.391042E-24  WUB1     = -7.231971E-25  PUB1     = 8.389377E-31
+UC1      = 6.43689E-11    LUC1     = -4.269735E-17  WUC1     = -2.219817E-17
+PUC1     = 2.575077E-23   KT1L     = 0              PRT      = 0     
+NLEV     = 3              AF       = 1.13           KF       = 5.0E-24
+CJ       = cjp            MJ       = 0.4391504      PB       = 0.892839
+CJSW     = cjswp          MJSW     = 0.3013806      PBSW     = 0.892839
+CJSWG    = cjgatep        MJSWG    = 0.3013806      PBSWG    = 0.892839
+CTA      = 0.0009779284   CTP      = 0.0006857234   PTA      = 0.001691764
+PTP      = 0.001691764    CGDO     = cgop           CGSO     = cgop  
+JS       = 1.352E-05      JSW      = 4E-11          CAPMOD   = 0     
+XTI      = 3              N        = 1              NQSMOD   = 0     
+XPART    = 1              CF       = 0              TLEV     = 1     
+TLEVC    = 1              )
                                                                      
                                                                      
.MODEL p.9     PMOS          (                     LEVEL    = 49 
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     
+LMIN   = 1.5E-07      LMAX   = '4.991E-07-dxl' WMIN   = '5.8E-07-dxw'
+WMAX     = '1.25E-06-dxw' XL       = '-1.5E-08+dxl' XW       = '0+dxw'
+TNOM     = 25             VERSION  = 3.1            TOX      = toxp  
+XJ       = 1.8E-07        NCH      = 4.81E+17       LLN      = 1     
+LWN      = 1              WLN      = 1              WWN      = 1     
+LINT     = 1.203E-08      LL       = 0              LW       = 0     
+LWL      = 0              WINT     = 9.45E-09       WL       = 0     
+WW       = 0              WWL      = 0              MOBMOD   = 1     
+BINUNIT  = 2              DWG      = 0              DWB      = 0     
+ACM      = 12             LDIF     = 8.5E-08        HDIF     = hdifp 
+RSH      = 6.2            RD       = 0              RS       = 0     
+RSC     = 0              RDC     = 0              VTH0    = 'dvthp-0.374821'
+LVTH0    = -7.222618E-09  WVTH0    = 1.554042E-08   PVTH0    = -3.212184E-15
+K1       = 0.4545477      LK1      = 1.221225E-08   WK1      = 8.62781E-09
+PK1      = -7.158437E-15  K2       = 0.004520053    LK2      = 1.248055E-10
+WK2      = 5.908633E-10   PK2      = -1.53648E-16   K3       = 0     
+DVT0     = 0              DVT1     = 0              DVT2     = 0     
+DVT0W    = 0              DVT1W    = 0              DVT2W    = 0     
+NLX      = 0              W0       = 0              K3B      = 0     
+VSAT     = 91886.24       LVSAT    = 0.003342572    WVSAT    = 0.00611827
+PVSAT    = -2.334419E-09  UA       = 4.304021E-10   LUA      = -4.006637E-17
+WUA      = 1.711007E-16   PUA      = -1.426187E-23  UB       = 2.941233E-19
+LUB      = 1.191566E-25   WUB      = 3.97999E-25    PUB      = -2.974906E-32
+UC       = -9.241179E-11  LUC      = 1.442826E-17   WUC      = -4.022652E-17
+PUC      = -3.799116E-24  RDSW     = 671            PRWB     = 0     
+PRWG     = 0              WR       = 1              U0       = 0.007540377
+LU0      = 1.529699E-10   WU0      = 8.618791E-10   PU0      = 7.551164E-17
+A0       = 0.388342       LA0      = 9.678283E-08   WA0      = 7.917177E-07
+PA0      = -1.369556E-13  KETA     = 0.07508102     LKETA    = -7.867582E-09
+WKETA    = -5.166116E-08  PKETA    = 4.521979E-15   A1       = 0     
+A2       = 1              AGS      = -0.423322      LAGS     = 5.644636E-08
+WAGS     = 6.864637E-07   PAGS     = -6.058801E-14  B0       = 0     
+B1       = 0              VOFF     = -0.1441057     LVOFF    = 5.981936E-09
+WVOFF    = 2.853853E-08   PVOFF    = -7.058896E-15  NFACTOR  = -0.5040122
+LNFACTOR = 1.920997E-07   WNFACTOR = 7.962198E-07   PNFACTOR = -6.834314E-14
+CIT      = 0.001          CDSC     = 0              CDSCB    = 0     
+CDSCD    = 0              ETA0     = 0.002536083    LETA0    = 2.924937E-10
+WETA0    = -1.589561E-09  PETA0    = 8.798881E-18   ETAB     = 0.0005805094
+LETAB    = -5.600694E-10  WETAB    = 8.598001E-10   PETAB    = -9.46124E-17
+DSUB     = 0              PCLM     = 0.9672205      LPCLM    = -3.012625E-08
+WPCLM    = -1.21461E-07   PPCLM    = 5.489464E-14   PDIBLC1  = 0.001 
+PDIBLC2  = 0.001041553    LPDIBLC2 = 2.445216E-10   WPDIBLC2 = -1.026585E-09
+PPDIBLC2 = 1.129657E-16   PDIBLCB  = -1.993922      LPDIBLCB = 2.974078E-07
+WPDIBLCB = 1.630014E-06   PPDIBLCB = -1.793666E-13  DROUT    = 0     
+PSCBE1   = 9.924143E+08   LPSCBE1  = -56.44505      WPSCBE1  = -309.3603
+PPSCBE1  = 3.404201E-05   PSCBE2   = 1E-06          PVAG     = 0     
+DELTA    = 0.01423325     LDELTA   = -1.470612E-09  WDELTA   = -4.050372E-09
+PDELTA   = 1.276285E-15   ALPHA0   = 1.9E-09        BETA0    = 12    
+KT1      = -0.232018      LKT1     = -6.869015E-10  WKT1     = -3.764731E-09
+PKT1     = 4.14271E-16    KT2      = -0.02140241    LKT2     = -1.294357E-09
+WKT2     = -7.094029E-09  PKT2     = 7.80627E-16    AT       = 1543.412
+LAT      = 0.0007655038   WAT      = 0.01099149     PAT      = -1.209505E-09
+UTE      = -1.041305      LUTE     = 1.730981E-08   WUTE     = -2.641178E-08
+PUTE     = 2.906339E-15   UA1      = 9.058573E-10   LUA1     = -9.125339E-17
+WUA1     = -5.001354E-16  PUA1     = 5.503491E-23   UB1      = -2.864486E-18
+LUB1     = 2.639052E-25   WUB1     = 1.446395E-24   PUB1     = -1.591612E-31
+UC1      = -4.605145E-11  LUC1     = 8.100437E-18   WUC1     = 4.439634E-17
+PUC1     = -4.885373E-24  KT1L     = 0              PRT      = 0     
+NLEV     = 3              AF       = 1.13           KF       = 5.0E-24
+CJ       = cjp            MJ       = 0.4391504      PB       = 0.892839
+CJSW     = cjswp          MJSW     = 0.3013806      PBSW     = 0.892839
+CJSWG    = cjgatep        MJSWG    = 0.3013806      PBSWG    = 0.892839
+CTA      = 0.0009779284   CTP      = 0.0006857234   PTA      = 0.001691764
+PTP      = 0.001691764    CGDO     = cgop           CGSO     = cgop  
+JS       = 1.352E-05      JSW      = 4E-11          CAPMOD   = 0     
+XTI      = 3              N        = 1              NQSMOD   = 0     
+XPART    = 1              CF       = 0              TLEV     = 1     
+TLEVC    = 1              )
                                                                      
                                                                      
.MODEL p.10    PMOS          (                     LEVEL    = 49 
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     
+LMIN   = '1.1991E-06-dxl' LMAX   = 2.1E-05        WMIN   = 1.8E-07
+WMAX     = '5.8E-07-dxw'  XL       = '-1.5E-08+dxl' XW       = '0+dxw'
+TNOM     = 25             VERSION  = 3.1            TOX      = toxp  
+XJ       = 1.8E-07        NCH      = 4.81E+17       LLN      = 1     
+LWN      = 1              WLN      = 1              WWN      = 1     
+LINT     = 1.203E-08      LL       = 0              LW       = 0     
+LWL      = 0              WINT     = 9.45E-09       WL       = 0     
+WW       = 0              WWL      = 0              MOBMOD   = 1     
+BINUNIT  = 2              DWG      = 0              DWB      = 0     
+ACM      = 12             LDIF     = 8.5E-08        HDIF     = hdifp 
+RSH      = 6.2            RD       = 0              RS       = 0     
+RSC     = 0              RDC     = 0              VTH0    = 'dvthp-0.331443'
+LVTH0    = -3.36624E-08   WVTH0    = -2.819982E-09  PVTH0    = 2.680528E-15
+K1       = 0.454133       LK1      = 6.289937E-08   WK1      = -2.239158E-09
+PK1      = -1.319179E-14  K2       = 0.005087528    LK2      = 4.289853E-10
+WK2      = -4.911199E-11  PK2      = -2.407037E-16  K3       = 0     
+DVT0     = 0              DVT1     = 0              DVT2     = 0     
+DVT0W    = 0              DVT1W    = 0              DVT2W    = 0     
+NLX      = 0              W0       = 0              K3B      = 0     
+VSAT     = 100000         UA       = 3.956998E-10   LUA      = 1.391715E-16
+WUA      = -1.077233E-17  PUA      = 8.589554E-23   UB       = 1.487715E-18
+LUB      = 3.081763E-25   WUB      = -2.082324E-25  PUB      = -1.729178E-31
+UC       = -1.298377E-10  LUC      = 5.416762E-17   WUC      = -1.334434E-18
+PUC      = -3.039345E-23  RDSW     = 671            PRWB     = 0     
+PRWG     = 0              WR       = 1              U0       = 0.009965761
+LU0      = 7.84607E-12    WU0      = -3.233489E-12  PU0      = -4.402431E-18
+A0       = 1.792473       LA0      = -4.986258E-07  WA0      = -1.493132E-07
+PA0      = 1.324386E-13   KETA     = -0.005957355   LKETA    = -1.450542E-08
+WKETA    = 2.30975E-09    PKETA    = 4.455482E-15   A1       = 0     
+A2       = 1              AGS      = 0.4815682      LAGS     = 1.191362E-07
+WAGS     = -8.512933E-08  PAGS     = -2.26452E-14   B0       = 0     
+B1       = 0              VOFF     = -0.1060676     LVOFF    = -6.611465E-09
+WVOFF    = -6.061247E-09  PVOFF    = 3.709694E-15   NFACTOR  = 0.3620559
+LNFACTOR = -7.288885E-08  WNFACTOR = 1.601198E-07   PNFACTOR = 4.089794E-14
+CIT      = 0.001721467    LCIT     = -4.018944E-11  WCIT     = -4.048151E-10
+PCIT     = 2.255031E-17   CDSC     = 0              CDSCB    = 0     
+CDSCD    = 0              ETA0     = 0.0006537916   LETA0    = -3.521966E-10
+WETA0    = -4.828207E-11  PETA0    = 2.189079E-16   ETAB     = 0.0005492399
+LETAB    = -1.392231E-09  WETAB    = -1.806497E-10  PETAB    = 2.095609E-16
+DSUB     = 0              PCLM     = 0.991743       LPCLM    = 8.224074E-08
+WPCLM    = 4.633038E-09   PPCLM    = -4.614529E-14  PDIBLC1  = 0.0008087585
+LPDIBLC1 = 2.218478E-10   WPDIBLC1 = -8.321417E-11  PPDIBLC1 = 9.653178E-17
+PDIBLC2  = 0.0008087585   LPDIBLC2 = 2.218478E-10   WPDIBLC2 = -8.321417E-11
+PPDIBLC2 = 9.653178E-17   PDIBLCB  = 0.7088023      DROUT    = 0     
+PSCBE1   = 5.120492E+08   LPSCBE1  = -2.489139      WPSCBE1  = -7.261239
+PPSCBE1  = 7.926314E-07   PSCBE2   = 1E-06          PVAG     = 0     
+DELTA    = -0.001235134   LDELTA   = 4.403013E-09   WDELTA   = 1.386753E-09
+PDELTA   = -9.971274E-16  ALPHA0   = 1.9E-09        BETA0    = 12    
+KT1      = -0.2865437     LKT1     = 3.547611E-08   WKT1     = 2.709182E-08
+PKT1     = -1.990565E-14  KT2      = -0.02201616    LKT2     = -1.293312E-08
+WKT2     = -6.255623E-09  PKT2     = 7.256773E-15   AT       = 17777.18
+LAT      = -0.01048786    WAT      = 0.001617051    PAT      = 2.201233E-09
+UTE      = -1.171439      LUTE     = 2.135367E-07   WUTE     = 4.63304E-09
+PUTE     = -4.614529E-14  UA1      = 7.658276E-11   UB1      = -4.662195E-19
+UC1      = -1.770029E-10  LUC1     = 1.173267E-17   WUC1     = 1.147815E-16
+PUC1     = -6.583208E-24  KT1L     = 0              PRT      = 0     
+NLEV     = 3              AF       = 1.13           KF       = 5.0E-24
+CJ       = cjp            MJ       = 0.4391504      PB       = 0.892839
+CJSW     = cjswp          MJSW     = 0.3013806      PBSW     = 0.892839
+CJSWG    = cjgatep        MJSWG    = 0.3013806      PBSWG    = 0.892839
+CTA      = 0.0009779284   CTP      = 0.0006857234   PTA      = 0.001691764
+PTP      = 0.001691764    CGDO     = cgop           CGSO     = cgop  
+JS       = 1.352E-05      JSW      = 4E-11          CAPMOD   = 0     
+XTI      = 3              N        = 1              NQSMOD   = 0     
+XPART    = 1              CF       = 0              TLEV     = 1     
+TLEVC    = 1              )
                                                                      
                                                                      
.MODEL p.11    PMOS          (                     LEVEL    = 49 
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     
+LMIN   = '4.991E-07-dxl' LMAX   = '1.1991E-06-dxl' WMIN   = 1.8E-07
+WMAX     = '5.8E-07-dxw'  XL       = '-1.5E-08+dxl' XW       = '0+dxw'
+TNOM     = 25             VERSION  = 3.1            TOX      = toxp  
+XJ       = 1.8E-07        NCH      = 4.81E+17       LLN      = 1     
+LWN      = 1              WLN      = 1              WWN      = 1     
+LINT     = 1.203E-08      LL       = 0              LW       = 0     
+LWL      = 0              WINT     = 9.45E-09       WL       = 0     
+WW       = 0              WWL      = 0              MOBMOD   = 1     
+BINUNIT  = 2              DWG      = 0              DWB      = 0     
+ACM      = 12             LDIF     = 8.5E-08        HDIF     = hdifp 
+RSH      = 6.2            RD       = 0              RS       = 0     
+RSC     = 0              RDC     = 0              VTH0    = 'dvthp-0.353628'
+LVTH0    = -7.926806E-09  WVTH0    = 7.820541E-10   PVTH0    = -1.497978E-15
+K1       = 0.5210693      LK1      = -1.474945E-08  WK1      = -1.508156E-08
+PK1      = 1.705912E-15   K2       = 0.00547809     LK2      = -2.40815E-11
+WK2      = -3.601318E-10  PK2      = 1.200916E-16   K3       = 0     
+DVT0     = 0              DVT1     = 0              DVT2     = 0     
+DVT0W    = 0              DVT1W    = 0              DVT2W    = 0     
+NLX      = 0              W0       = 0              K3B      = 0     
+VSAT     = 98901.87       LVSAT    = 0.001273875    WVSAT    = 0.0002427967
+PVSAT    = -2.816538E-10  UA       = 4.196846E-10   LUA      = 1.113481E-16
+WUA      = 1.302001E-16   PUA      = -7.763813E-23  UB       = 1.890074E-18
+LUB      = -1.585766E-25  WUB      = -4.452827E-25  PUB      = 1.020701E-31
+UC       = -6.611937E-11  LUC      = -1.974826E-17  WUC      = -3.146593E-17
+PUC      = 4.560281E-24   RDSW     = 671            PRWB     = 0     
+PRWG     = 0              WR       = 1              U0       = 0.01026114
+LU0      = -3.348052E-10  WU0      = -7.364036E-11  PU0      = 7.727236E-17
+A0       = 1.294966       LA0      = 7.850225E-08   WA0      = -6.324134E-08
+PA0      = 3.259174E-14   KETA     = -0.002789443   LKETA    = -1.818032E-08
+WKETA    = 7.029235E-10   PKETA    = 6.319465E-15   A1       = 0     
+A2       = 1              AGS      = 0.2647121      LAGS     = 3.70698E-07
+WAGS     = -3.24052E-08   PAGS     = -8.38073E-14   B0       = 0     
+B1       = 0              VOFF     = -0.1203396     LVOFF    = 9.944634E-09
+WVOFF    = -1.476265E-09  PVOFF    = -1.609068E-15  NFACTOR  = -0.261152
+LNFACTOR = 6.500571E-07   WNFACTOR = 3.547751E-07   PNFACTOR = -1.8491E-13
+CIT      = 0.001668091    LCIT     = 2.172891E-11   WCIT     = -3.748658E-10
+PCIT     = -1.21921E-17   CDSC     = 0              CDSCB    = 0     
+CDSCD    = 0              ETA0     = 0.0006031154   LETA0    = -2.934101E-10
+WETA0    = 8.236684E-11   PETA0    = 6.734999E-17   ETAB     = -0.002058717
+LETAB    = 1.633102E-09   WETAB    = 3.548563E-10   PETAB    = -4.116475E-16
+DSUB     = 0              PCLM     = 1.299981       LPCLM    = -2.753281E-07
+WPCLM    = -1.306804E-07  PPCLM    = 1.108237E-13   PDIBLC1  = 0.001 
+PDIBLC2  = 0.001888141    LPDIBLC2 = -1.030279E-09  WPDIBLC2 = -1.963679E-10
+PPDIBLC2 = 2.277946E-16   PDIBLCB  = 0.5418683      LPDIBLCB = 1.936501E-07
+WPDIBLCB = 3.69091E-08    PPDIBLCB = -4.281603E-14  DROUT    = 0     
+PSCBE1   = 5.615905E+08   LPSCBE1  = -59.95903      WPSCBE1  = -17.90594
+PPSCBE1  = 1.314091E-05   PSCBE2   = 1E-06          PVAG     = 0     
+DELTA    = -0.0009864573  LDELTA   = 4.114537E-09   WDELTA   = 5.768568E-10
+PDELTA   = -5.761545E-17  ALPHA0   = 1.9E-09        BETA0    = 12    
+KT1      = -0.2585511     LKT1     = 3.003595E-09   WKT1     = 1.151627E-08
+PKT1     = -1.837388E-15  KT2      = -0.03243849    LKT2     = -8.42792E-10
+WKT2     = -1.606335E-10  PKT2     = 1.863413E-16   AT       = 5519.395
+LAT      = 0.003731659    WAT      = 0.004172401    PAT      = -7.630742E-10
+UTE      = -1.013154      LUTE     = 2.991959E-08   WUTE     = -2.45498E-08
+PUTE     = -1.229203E-14  UA1      = 1.278026E-10   LUA1     = -5.941708E-17
+WUA1     = -1.132471E-17  PUA1     = 1.313712E-23   UB1      = -6.14348E-19
+LUB1     = 1.718349E-25   WUB1     = 3.275121E-26   PUB1     = -3.79927E-32
+UC1      = -2.99229E-10   LUC1     = 1.535197E-16   WUC1     = 1.818166E-16
+PUC1     = -8.43466E-23   KT1L     = 0              PRT      = 0     
+NLEV     = 3              AF       = 1.13           KF       = 5.0E-24
+CJ       = cjp            MJ       = 0.4391504      PB       = 0.892839
+CJSW     = cjswp          MJSW     = 0.3013806      PBSW     = 0.892839
+CJSWG    = cjgatep        MJSWG    = 0.3013806      PBSWG    = 0.892839
+CTA      = 0.0009779284   CTP      = 0.0006857234   PTA      = 0.001691764
+PTP      = 0.001691764    CGDO     = cgop           CGSO     = cgop  
+JS       = 1.352E-05      JSW      = 4E-11          CAPMOD   = 0     
+XTI      = 3              N        = 1              NQSMOD   = 0     
+XPART    = 1              CF       = 0              TLEV     = 1     
+TLEVC    = 1              )
                                                                      
                                                                      
.MODEL p.12    PMOS          (                     LEVEL    = 49 
+CALCACM  = 1              SFVTFLAG = 0              VFBFLAG  = 1     
+LMIN   = 1.5E-07      LMAX   = '4.991E-07-dxl' WMIN   = 1.8E-07
+WMAX     = '5.8E-07-dxw'  XL       = '-1.5E-08+dxl' XW       = '0+dxw'
+TNOM     = 25             VERSION  = 3.1            TOX      = toxp  
+XJ       = 1.8E-07        NCH      = 4.81E+17       LLN      = 1     
+LWN      = 1              WLN      = 1              WWN      = 1     
+LINT     = 1.203E-08      LL       = 0              LW       = 0     
+LWL      = 0              WINT     = 9.45E-09       WL       = 0     
+WW       = 0              WWL      = 0              MOBMOD   = 1     
+BINUNIT  = 2              DWG      = 0              DWB      = 0     
+ACM      = 12             LDIF     = 8.5E-08        HDIF     = hdifp 
+RSH      = 6.2            RD       = 0              RS       = 0     
+RSC     = 0              RDC     = 0              VTH0    = 'dvthp-0.328952'
+LVTH0    = -1.927878E-08  WVTH0    = -1.019635E-08  PVTH0    = 3.552528E-15
+K1       = 0.5136911      LK1      = -1.135516E-08  WK1      = -2.455753E-08
+PK1      = 6.065236E-15   K2       = -0.01390325    LK2      = 8.892114E-09
+WK2      = 1.092818E-08   PK2      = -5.072985E-15  K3       = 0     
+DVT0     = 0              DVT1     = 0              DVT2     = 0     
+DVT0W    = 0              DVT1W    = 0              DVT2W    = 0     
+NLX      = 0              W0       = 0              K3B      = 0     
+VSAT     = 105298.2       LVSAT    = -0.001668691   WVSAT    = -0.001407178
+PVSAT    = 4.774007E-10   UA       = 8.979564E-10   LUA      = -1.08676E-16
+WUA      = -9.124398E-17  PUA      = 2.423501E-23   UB       = 1.012171E-18
+LUB      = 2.452941E-25   WUB      = -4.897396E-27  PUB      = -1.005248E-31
+UC       = -2.076564E-10  LUC      = 4.536443E-17   WUC      = 2.443722E-17
+PUC      = -2.11574E-23   RDSW     = 671            PRWB     = 0     
+PRWG     = 0              WR       = 1              U0       = 0.008229362
+LU0      = 5.998944E-10   WU0      = 4.752901E-10   PU0      = -1.752577E-16
+A0       = 2.131559       LA0      = -3.063643E-07  WA0      = -1.864013E-07
+PA0      = 8.925031E-14   KETA     = -0.04188204    LKETA    = -1.961624E-10
+WKETA    = 1.396681E-08   PKETA    = 2.175452E-16   A1       = 0     
+A2       = 1              AGS      = 1.220756       LAGS     = -6.912033E-08
+WAGS     = -2.360283E-07  PAGS     = 9.867467E-15   B0       = 0     
+B1       = 0              VOFF     = -0.08045699    LVOFF    = -8.402954E-09
+WVOFF    = -7.174755E-09  PVOFF    = 1.012466E-15   NFACTOR  = 1.006459
+LNFACTOR = 6.69054E-08    WNFACTOR = -5.130556E-08  PNFACTOR = 1.903351E-15
+CIT      = 0.001940221    LCIT     = -1.03462E-10   WCIT     = -5.275582E-10
+PCIT     = 5.805251E-17   CDSC     = 0              CDSCB    = 0     
+CDSCD    = 0              ETA0     = -0.0005623581  LETA0    = 2.427543E-10
+WETA0    = 1.489748E-10   PETA0    = 3.670768E-17   ETAB     = 0.004191499
+LETAB    = -1.242247E-09  WETAB    = -1.166327E-09  PETAB    = 2.881575E-16
+DSUB     = 0              PCLM     = 0.4868774      LPCLM    = 9.873222E-08
+WPCLM    = 1.480595E-07   PPCLM    = -1.740784E-14  PDIBLC1  = 0.001 
+PDIBLC2  = -0.001581272   LPDIBLC2 = 5.6579E-10     WPDIBLC2 = 4.45082E-10
+PPDIBLC2 = -6.729804E-17  PDIBLCB  = 1.04267        LPDIBLCB = -3.673861E-08
+WPDIBLCB = -7.381805E-08  PPDIBLCB = 8.12289E-15    DROUT    = 0     
+PSCBE1   = 4.160995E+08   LPSCBE1  = 6.972629       WPSCBE1  = 14.00989
+PPSCBE1  = -1.541648E-06  PSCBE2   = 1E-06          PVAG     = 0     
+DELTA    = 0.005135456    LDELTA   = 1.298212E-09   WDELTA   = 1.054396E-09
+PDELTA   = -2.773027E-16  ALPHA0   = 1.9E-09        BETA0    = 12    
+KT1      = -0.2563489     LKT1     = 1.990464E-09   WKT1     = 9.887303E-09
+PKT1     = -1.087999E-15  KT2      = -0.03461805    LKT2     = 1.598925E-10
+WKT2     = 3.21267E-10    PKT2     = -3.535223E-17  AT       = 15774.91
+LAT      = -0.0009862882  WAT      = 0.003006198    PAT      = -2.265743E-10
+UTE      = -0.9718137     LUTE     = 1.090136E-08   WUTE     = -6.540309E-08
+PUTE     = 6.502118E-15   UA1      = -2.585695E-11  LUA1     = 1.127247E-17
+WUA1     = 2.264942E-17   PUA1     = -2.492343E-24  UB1      = -1.69963E-19
+LUB1     = -3.259995E-26  WUB1     = -6.550229E-26  PUB1     = 7.207837E-33
+UC1      = 3.665556E-11   LUC1     = -1.000641E-18  WUC1     = -2.01056E-18
+PUC1     = 2.212416E-25   KT1L     = 0              PRT      = 0     
+NLEV     = 3              AF       = 1.13           KF       = 5.0E-24
+CJ       = cjp            MJ       = 0.4391504      PB       = 0.892839
+CJSW     = cjswp          MJSW     = 0.3013806      PBSW     = 0.892839
+CJSWG    = cjgatep        MJSWG    = 0.3013806      PBSWG    = 0.892839
+CTA      = 0.0009779284   CTP      = 0.0006857234   PTA      = 0.001691764
+PTP      = 0.001691764    CGDO     = cgop           CGSO     = cgop  
+JS       = 1.352E-05      JSW      = 4E-11          CAPMOD   = 0     
+XTI      = 3              N        = 1              NQSMOD   = 0     
+XPART    = 1              CF       = 0              TLEV     = 1     
+TLEVC    = 1              )                     
*
.ENDL MOS
*
****************************************************************
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
*
.ENDL MOS_3V
*
***************************************************************
*                                                             *
*  Vertical BIPOLAR MODELS for CL015G/1.5V process            *
*                                                             *
***************************************************************
*
.LIB BIP
*
***************************************************************
*                                                             *
*       MODEL OF P+/NW/PSUB VERTICAL PNP10X10 BIPOLAR         *
*                                                             *
***************************************************************
*
*
.MODEL pnp10 PNP (                                  LEVEL  = 1                  
+ BF     = 2.44            NF     = 0.97            ISE    = 4.15E-18           
+ NE     = 1.23            IS     = 4.15E-18        RB     = 115.9              
+ IRB    = 1.806E-4        RE     = 2.717           IKF    = 1.388E-3           
+ NKF    = 0.47            VAF    = 150             BR     = 0.0125             
+ NR     = 0.95            ISC    = 4.15E-18        NC     = 1.161              
+ RC     = 21.08           IKR    = 1E-5            VAR    = 20                 
+ XTI    = 3               EG     = 1.18            XTB    = 0                  
+ TRB1   = 1.2756E-3       TIRB1  = 1.052E-7        TRE1   = 8.826E-4           
+ TRM1   = 9.44E-6         TIKF1  = -3.845E-3       TIKR1  = -1.925E-3          
+ TRC1   = 0               TBF1   = 4.62121E-3      TVAF1  = -4.5E-7            
+ TBR1   = 1.2E-3          TNC1   = 3.017E-4        TNR1   = -5.501E-4          
+ TNF1   = -2.205E-4       TNE1   = 1E-3            CJE    = 1.230715E-13       
+ VJE    = 0.892839        MJE    = 0.4391504       FC     = 0                  
+ CJC    = 7.071403E-14    VJC    = 0.6672819       MJC    = 0.4247749          
+ TLEVC  = 1               CTE    = 9.779284E-4     CTC    = 9.506476E-4        
+ TVJE   = 1.691764E-3     TVJC   = 9.120919E-4     TREF   = 25                 
+ SUBS   = 1               RBM    = 0.1             TBF2   = 5E-6         
+ TLEV   = 0     )  
*
***************************************************************
*                                                             *
*       MODEL OF P+/NW/PSUB VERTICAL PNP5X5 BIPOLAR           *
*                                                             *
***************************************************************                                                                               *
*
.MODEL pnp5 PNP (                                   LEVEL  = 1                  
+ BF     = 2.44            NF     = 0.97            ISE    = 1.2E-18            
+ NE     = 1.23            IS     = 1.2E-18         RB     = 220                
+ IRB    = 7.806E-5        RE     = 3.717           IKF    = 9E-4               
+ NKF    = 0.47            VAF    = 140             BR     = 5.5E-3             
+ NR     = 0.945           ISC    = 1.2E-18         NC     = 1.161              
+ RC     = 26              IKR    = 1E-4            VAR    = 20                 
+ XTI    = 3               EG     = 1.18            XTB    = 0                  
+ TRB1   = 1E-3            TIRB1  = 1.052E-3        TRE1   = 6E-4               
+ TRM1   = 9.44E-6         TIKF1  = -3.845E-3       TIKR1  = -3.925E-3          
+ TRC1   = -1E-4           TBF1   = 5.2E-3          TVAF1  = -6.95E-5           
+ TBR1   = -5E-4           TNC1   = 3.017E-4        TNR1   = -6E-4              
+ TNF1   = -2.205E-4       TNE1   = 5.588E-5        CJE    = 3.262435E-14       
+ VJE    = 0.892839        MJE    = 0.4391504       FC     = 0                  
+ CJC    = 4.15932E-14     VJC    = 0.6672819       MJC    = 0.4247749          
+ TLEVC  = 1               CTE    = 9.779284E-4     CTC    = 9.506476E-4        
+ TVJE   = 1.691764E-3     TVJC   = 9.120919E-4     TREF   = 25                 
+ SUBS   = 1               RBM    = 0.1             TBF2   = 4.9E-6           
+ TLEV   = 0              )                                                                                 *
***************************************************************
*                                                             *
*       MODEL OF P+/NW/PSUB VERTICAL PNP2X2 BIPOLAR           *
*                                                             *
***************************************************************
*
*
.MODEL pnp2 PNP (                                   LEVEL  = 1                  
+ BF     = 2.47            NF     = 0.976           ISE    = 2.8E-19            
+ NE     = 1.255           IS     = 2.8E-19         RB     = 345.9              
+ IRB    = 8.806E-5        RE     = 6.717           IKF    = 3.3E-4             
+ NKF    = 0.42            VAF    = 80.88           BR     = 1.8E-3             
+ NR     = 0.945           ISC    = 2.8E-19         NC     = 1.161              
+ RC     = 21.08           IKR    = 1E-4            VAR    = 15                 
+ XTI    = 3               EG     = 1.18            XTB    = 0                  
+ TRB1   = 5.3E-4          TIRB1  = 1.052E-3        TRE1   = -1.226E-3          
+ TRM1   = 9.44E-6         TIKF1  = -4.345E-3       TIKR1  = -3.925E-3          
+ TRC1   = 4E-4            TBF1   = 5.520127E-3     TVAF1  = -5.95E-4           
+ TBR1   = -2.387286E-3    TNC1   = 3.0173E-4       TNR1   = -5.01E-4           
+ TNF1   = -2.205E-4       TNE1   = 1E-3            CJE    = 6.110996E-15       
+ VJE    = 0.892839        MJE    = 0.4391504       FC     = 0                  
+ CJC    = 2.718516E-14    VJC    = 0.6672819       MJC    = 0.4247749          
+ TLEVC  = 1               CTE    = 9.779284E-4     CTC    = 9.506476E-4        
+ TVJE   = 1.691764E-3     TVJC   = 9.120919E-4     TREF   = 25                 
+ SUBS   = 1              RBM     = 0.1             TBF2   = 4.9E-6         
+ TLEV   = 0       )  
*                                                                               
.ENDL BIP  
*    
* 
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
.MODEL PNP10_3 PNP (                                LEVEL  = 1                  
+ BF     = 2.275           NF     = 0.9435          ISE    = 2.517E-18       
+ NE     = 1.194           IS     = 2.517E-18       RB     = 132.1        
+ IRB    = 1.806E-4        RE     = 2               IKF    = 2.485E-3        
+ NKF    = 0.5             VAF    = 210.8           BR     = 0.0375             
+ NR     = 0.9             ISC    = 2.517E-18       NC     = 1.0985          
+ RC     = 21.08           IKR    = 1E-4            VAR    = 29                 
+ XTI    = 3               EG     = 1.18            XTB    = 0                  
+ TRB1   = 1.056E-3        TIRB1  = 1.052E-7        TRE1   = -1.826E-4        
+ TIKF1  = -3.84E-3        TIKR1  = -3.925E-3       TRC1   = 0                  
+ TBF1   = 5.3E-3          TVAF1  = -6.950E-5       TBR1   = -4E-4              
+ TNC1   = 0.02413         TNE1   = -1.573E-5       TNF1   = -3.158E-4        
+ TNR1   = -8.730E-4       RBM    = 0.1             TRM1   = 9.440E-6         
+ CJE    = 1.310E-13       VJE    = 0.7289          MJE    = 0.3909          
+ FC     = 0               CJC    = 7.4033E-14      VJC    = 0.7          
+ MJC    = 0.3902          TLEVC  = 1               CTE    = 8.836E-4        
+ CTC    = 2.7503E-3       TVJE   = 1.8307E-3       TVJC   = 2.572E-3        
+ TREF   = 25              SUBS   = 1               TLEV   = 0                  
+ TBR2   = 9.35E-6         TBF2   = 4.7E-6          TVAR1  = -6.211E-3       
+ TNF2   = -1E-6           )                                                    
*
*
***************************************************************
*                                                             *
*       MODEL OF P+/NW/PSUB VERTICAL PNP5X5 BIPOLAR           *
*                                                             *
***************************************************************
*
.MODEL pnp5_3 PNP (                                 LEVEL  = 1   
+ BF     = 2.250           NF     = 0.9320          ISE    = 5.177E-19        
+ NE     = 1.160           IS     = 5.395E-19       RB     = 188.8        
+ IRB    = 1.806E-4        RE     = 2               IKF    = 1.181E-3        
+ NKF    = 0.5             VAF    = 210.8           BR     = 0.0122             
+ NR     = 0.8922          ISC    = 5.177E-19       NC     = 1.0985          
+ RC     = 21.08           IKR    = 1E-4            VAR    = 29                 
+ XTI    = 3               EG     = 1.18            XTB    = 0                  
+ TRB1   = 1.0561E-3       TIRB1  = 1.052E-7        TRE1   = -1.826E-4        
+ TIKF1  = -1.045E-3       TIKR1  = -3.925E-3       TRC1   = 0                  
+ TBF1   = 5.8E-3          TVAF1  = -6.950E-5       TBR1   = -4E-4              
+ TNC1   = 0.02413         TNE1   = -1.573E-5       TNF1   = -3.258E-4        
+ TNR1   = -9.533E-4       RBM    = 0.1             TRM1   = 9.440E-6         
+ CJE    = 1.310E-13       VJE    = 0.7289          MJE    = 0.3909          
+ FC     = 0               CJC    = 4.200E-14       VJC    = 0.7          
+ MJC    = 0.3902          TLEVC  = 1               CTE    = 8.836E-4        
+ CTC    = 2.750E-3        TVJE   = 1.830E-3        TVJC   = 2.572E-3        
+ TREF   = 25              SUBS   = 1               TLEV   = 0                  
+ TBR2   = 9.35E-6         TBF2   = 4.3E-6          TVAR1  = -7.225E-3       
+ TNF2   = -1E-6           )                                                    
*
****************************************************************
*                                                             *
*       MODEL OF P+/NW/PSUB VERTICAL PNP2X2 BIPOLAR           *
*                                                             *
***************************************************************
*                                                                               
.MODEL pnp2_3 PNP (                                 LEVEL  = 1                  
+ BF     = 2.05            NF     = 0.955           ISE    = 2.2E-19            
+ NE     = 1.2             IS     = 2.2E-19         RB     = 280                
+ IRB    = 1.806E-4        RE     = 2               IKF    = 4.81E-4            
+ NKF    = 0.5             VAF    = 210.8           BR     = 3E-3               
+ NR     = 0.922           ISC    = 2.2E-19         NC     = 1.0985             
+ RC     = 21.08           IKR    = 1E-4            VAR    = 29                 
+ XTI    = 3               EG     = 1.18            XTB    = 0                  
+ TRB1   = 1.8E-3          TIRB1  = 1.052E-7        TRE1   = -1.826E-4          
+ TRM1   = 9.44E-6         TIKF1  = -7E-4           TIKR1  = -3.925E-3          
+ TRC1   = 0               TBF1   = 6.9E-3          TVAF1  = -6.95E-5           
+ TBR1   = -3.8E-4         TNC1   = 0.023           TNR1   = -1.0533E-4         
+ TNF1   = -1.7E-4         TNE1   = -3.73E-5        CJE    = 1.31E-13           
+ VJE    = 0.7289          MJE    = 0.3909          FC     = 0                  
+ CJC    = 4.2E-14         VJC    = 0.7             MJC    = 0.3902             
+ TLEVC  = 1               CTE    = 8.836E-4        CTC    = 2.7503E-3          
+ TVJE   = 1.83E-3         TVJC   = 2.572E-3        TREF   = 25                 
+ SUBS   = 1               RBM    = 0.1            TLEV    = 0                  
+ TBR2   = 9.2E-6          TBF2   = 1.35E-5        TVAR1   = -8.4E-3            
+ TNF2   = -1E-6           )                                           
*
*                                                                               
.ENDL BIP3 
*                                                                      
***************************************************************
*                                                             *
*       Junction DIODE MODELS for CL015G/1.5V process         *
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
*                                                                               
.MODEL NDIO D (                                     LEVEL  = 3                  
+ IS     = 5.4E-6          RS     = 2.44919E-7      N      = 1.2922863          
+ BV     = 11              IBV    = 0.03            IK     = 1E20               
+ IKR    = 1E10            JSW    = 6E-11           AREA   = 7.5E-8             
+ PJ     = 1.1E-3          CJ     = 9.97455E-4      PB     = 0.854656          
+ MJ     = 0.3995675       CJSW   = 1.542965E-10    PHP    = 0.854656           
+ MJSW   = 0.5138515       TLEV   = 1               EG     = 1.17               
+ XTI    = 3               TCV    = -3.1E-4         TRS    = 1.4E-3             
+ TLEVC  = 1               CTA    = 9.993914E-4     CTP    = 3.73684E-3        
+ TPB    = 2.163759E-3     TPHP   = 2.163759E-3     TREF   = 25                 
+ FC     = 0   )                                       
*                                                       
*                                                                               
***************************************************************
*                      MODEL OF P+/NW DIODE                   *
*                                                             *
***************************************************************
*
*                                                                               
.MODEL PDIO D (                                     LEVEL  = 3                  
+ IS     = 1.352E-5        RS     = 2.74919E-7      N      = 1.3022863          
+ BV     = 11              IBV    = 0.03            IK     = 1E20               
+ IKR    = 1E10            JSW    = 2.11E-10        AREA   = 7.5E-8             
+ PJ     = 1.1E-3          CJ     = 1.156457E-3        
+ PB     = 0.892839        MJ     = 0.4391504       CJSW   = 1.856467E-10       
+ PHP    = 0.892839        MJSW   = 0.3013806       TLEV   = 1     
+ EG     = 1.17               
+ XTI    = 3               TCV    = -3.1E-4         TRS    = 1.4E-3             
+ TLEVC  = 1               CTA    = 9.779284E-4     CTP    = 6.857234E-4        
+ TPB    = 1.691764E-3     TPHP   = 1.691764E-3     TREF   = 25                 
+ FC     = 0   )                                         
* 
*                                                                               
***************************************************************
*                      MODEL OF NW/PSUB DIODE                 *
*                                                             *
***************************************************************
* 
.MODEL NWDIO D (                                    LEVEL  = 3             
+ IS     = 1.6E-5          RS     = 1.97E-7         N      = 1.44       
+ BV     = 14.7            IBV    = 0.03            IK     = 1E20               
+ IKR    = 1E10            JSW    = 1.22083E-10     AREA   = 7.5E-8             
+ PJ     = 1.1E-3          CJ     = 1.300773E-4     PB     = 0.6678004    
+ MJ     = 0.4463257       CJSW   = 5.205748E-10    PHP    = 0.6678004    
+ MJSW   = 0.2544852       TLEV   = 1               EG     = 1.16               
+ XTI    = 3               TCV    = -9.1E-4         TRS    = 2.78E-3            
+ TLEVC  = 1               CTA    = 2.386385E-3     CTP    = 1.191753E-3      
+ TPB    = 2.757042E-3     TPHP   = 2.757042E-3     TREF   = 25                 
+ FC     = 0   )                                  
*         
*                                                                               
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
+ TLEVC  = 1               CTA    = 7.836E-4        CTP    = 1.301E-4        
+ TPB    = 1.739E-3        TPHP   = 1.739E-3        TREF   = 25                 
+ FC     = 0               FCS    = 0 )             
*
.ENDL DIO3 
*                                                                                                
**************************************************************************
*
*   resistor models
*
**************************************************************************
*
.lib RES
**************************************************************************  
.subckt rppolywo n1 n2 l=length w=width
.param rsh=360 dw=0u ptc1=-1.78e-4 ptc2=3.53e-7 pvc1=-2.22e-4 pvc2=3.35e-5 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rppolywo

.subckt rppolyl n1 n2 l=length w=width
.param rsh=7.8 dw=-0.051u ptc1=2.88e-3 ptc2=5.01e-7 pvc1=-7.89e-4 pvc2=-6.19e-3 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rppolyl

.subckt rppolys n1 n2 l=length w=width
.param rsh=6.7 dw=-0.051u ptc1=2.88e-3 ptc2=5.01e-7 pvc1=-7.89e-4 pvc2=-6.19e-3 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rppolys

.subckt rnpolywo n1 n2 l=length w=width
.param rsh=280 dw=0.0u ptc1=-1.14e-3 ptc2=1.26e-6 pvc1=5.35e-4 pvc2=-1.64e-4 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rnpolywo

.subckt rnpolyl n1 n2 l=length w=width
.param rsh=7.4 dw=-0.065u ptc1=2.92e-3 ptc2=2.66e-7 pvc1=1.35e-3 pvc2=7.15e-3 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rnpolyl

.subckt rnpolys n1 n2 l=length w=width
.param rsh=5.7 dw=-0.065u ptc1=2.92e-3 ptc2=2.66e-7 pvc1=1.35e-3 pvc2=7.15e-3 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rnpolys

.subckt rnodwo n1 n2 l=length w=width
.param rsh=77 dw=0.0u ptc1=1.76e-3 ptc2=1.80e-7 pvc1=1.56e-3 pvc2=4.68e-5 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-2*dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rnodwo

.subckt rnodl n1 n2 l=length w=width
.param rsh=6.8 dw=-0.165u ptc1=3.35e-3 ptc2=4.31e-7 pvc1=7.56e-5 pvc2=1.24e-3 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rnodl

.subckt rnods n1 n2 l=length w=width
.param rsh=4.1 dw=-0.165u ptc1=3.35e-3 ptc2=4.31e-7 pvc1=7.56e-5 pvc2=1.24e-3 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rnods

.subckt rpodwo n1 n2 l=length w=width
.param rsh=157 dw=0.00u ptc1=1.49e-3 ptc2=8.00e-7 pvc1=2.61e-4 pvc2=1.44e-4 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rpodwo

.subckt rpodl n1 n2 l=length w=width
.param rsh=7.2 dw=-0.148u ptc1=3.44e-3 ptc2=5.02e-7 pvc1=-2.51e-4 pvc2=1.03e-3 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rpodl

.subckt rpods n1 n2 l=length w=width
.param rsh=4.4 dw=-0.148u ptc1=3.44e-3 ptc2=5.02e-7 pvc1=-2.51e-4 pvc2=1.03e-3 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rpods

.subckt rnwod n1 n2 l=length w=width
.param rsh=450 dw=0.141u ptc1=3.68e-3 ptc2=9.54e-6 pvc1=2.77e-3 pvc2=2.49e-4 pt='temper'
.param tfac='1.0+ptc1*(pt-25.0)+ptc2*(pt-25.0)*(pt-25.0)'
r1 n1 n2 'rsh*l/(w-dw)*(1+pvc1*abs(v(n2,n1))+pvc2*v(n2,n1)*v(n2,n1))*tfac'
.ends rnwod

.subckt rnwsti n1 n2 l=length w=width
.param rsh=920 dw=0.182u ptc1=2.97e-3 ptc2=1.10e-5 pvc1=8.06e-3 pvc2=-3.32e-4 pt='temper'
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
                                                                     
                                                                 

