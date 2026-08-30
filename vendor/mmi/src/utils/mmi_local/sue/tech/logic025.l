* **********************************************
* *             TSMC SPICE MODEL               *
* **********************************************
*  
*    PROCESS :  0.25um LOGIC SALICIDE (1P5M, 2,5V, 2.5V/3.3V)
*     MODEL  :  BSIM3 ( V3.1 )
*    DOC. NO.:  TA-1099-6001
*    VERSION :  1.3
*    DATE    :  Jan 12, 1998
*    HSPICE VERSION : H97.2
*
******************************************************************************
*                                                                            * 
*       IN THIS MODEL LIB CONTAINS :                                         *  
*                                                                            *
*       1.LIB TT                                                             *
*             SS                                                             *
*             FF                                                             *
*             SF                                                             *
*             FS                                                             *
*        ( Normal devices with different geometric and corner models)        *
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
*        ( P+/NW/PSUB 10x10 vertical PNP bipolar )                           *
*                                                                            *
*       4.LIB DIO                                                            *
*        ( P+/NW , N+/PW & NW/PSUB diode )                                   *
*                                                                            *
******************************************************************************
*
* 1)To use these models directly by programming in this style: 
*
*     .lib 'lib_path/lib_name' model_name 
*
*  EX: .lib '/home/user/tsmc/LOGIC/logic025.l' TT   
*        
*             for typical N,PMOS
*      
*      .lib '/home/user/tsmc/LOGIC/logic025.l' TT_3V   
*        
*             for typical 3V N,PMOS
*      
*  note:
*      corner_name
*       TT : typical model
*       SS : Slow NMOS Slow PMOS model
*       FF : Fast NMOS Fast PMOS model
*       SF : Slow NMOS Fast PMOS model
*       FS : Fast NMOS Slow PMOS model
*      
*       TT_3V : typical model for 3.3V device
*       SS_3V : Slow NMOS Slow PMOS model for 3V device
*       FF_3V : Fast NMOS Fast PMOS model for 3V device
*       SF_3V : Slow NMOS Fast PMOS model for 3V device
*       FS_3V : Fast NMOS Slow PMOS model for 3V device
*
* 2)HDIF depends on your layout poly spacer to contact center distance.
*   The value listed here is TSMC testkey value. you can change it
*   according to your layout by change the parameters :
*  ( hdifn: NMOS; hdifp: PMOS; hdifn3: 3.3V NMOS; hdifp3: 3.3V PMOS )
*
* 3)Please note that AS/AD and PS/PD need to be specified to avoid
*   zero junction capacitance and to result in correct junction leakage
*   current.
*
***************************************************************
*                                                             *
*              2.5V NORMAL DEVICES LIB                        *
*                                                             *
***************************************************************
***************** CORNER_LIB OF TYPICAL MODEL ****************************
.LIB TT
.param toxp = 5.8e-9 toxn = 5.8e-9 
+dxl = 0 dxw = 0 
+dvthn = 0 dvthp = 0 
+cjn = 2.024128E-3    cjp = 1.931092e-3  
+cjswn = 2.751528E-10  cjswp = 2.232277e-10
+cgon =  3.11E-10 cgop = 2.68e-10  
+cjgaten = 2.135064E-10 cjgatep = 1.607088e-10
+hdifn = 3.1e-07 hdifp = 3.1e-7 
.lib '/volume/cad/mmi/mmi_local.dev/sue/tech/tsmc25.l' MOS
.ENDL TT
**************** CORNER_LIB OF  SNSP   MODEL ****************************
.LIB SS
.param toxp = 6.1e-9 toxn = 6.1e-9 
+dxl = 2.5e-8 dxw = -3e-8 
+dvthn = 0.06 dvthp = -0.06
+cjn = 2.2265408E-3 cjp = 2.1242e-3  
+cjswn = 3.0266808E-10 cjswp = 2.4555e-10 
+cgon = 3.421E-10 cgop = 2.948e-10 
+cjgaten = 2.3485704E-10 cjgatep = 1.7678e-10
+hdifn = 3.1e-07 hdifp = 3.1e-7
.lib '/volume/cad/mmi/mmi_local.dev/sue/tech/tsmc25.l' MOS
.ENDL SS
**************** CORNER_LIB OF  FNFP   MODEL ****************************
.LIB FF
.param toxp = 5.5e-9 toxn = 5.5e-9 
+dxl = -2.5e-8 dxw = 3e-8
+dvthn = -0.06 dvthp = 0.06 
+cjn = 1.8217152e-3 cjp = 1.738e-3  
+cjswn = 2.4763752e-10 cjswp = 2.009e-10 
+cgon = 2.799e-10 cgop = 2.412e-10 
+cjgaten = 1.9215576e-10 cjgatep = 1.4464e-10
+hdifn = 3.1e-07 hdifp = 3.1e-7 
.lib '/volume/cad/mmi/mmi_local.dev/sue/tech/tsmc25.l' MOS
.ENDL FF
**************** CORNER_LIB OF  SNFP   MODEL ****************************
.LIB SF
.param toxp = 5.8e-9 toxn = 5.8e-9 
+dxl = 0 dxw = 0
+dvthn = 0.06 dvthp = 0.06
+cjn = 2.2265408E-3 cjp = 1.738e-3  
+cjswn = 3.0266808E-10 cjswp = 2.009e-10 
+cgon =  3.11E-10 cgop = 2.68e-10
+cjgaten = 2.3485704E-10 cjgatep = 1.4464e-10
+hdifp = 3.1e-7 hdifn = 3.1e-07
.lib '/volume/cad/mmi/mmi_local.dev/sue/tech/tsmc25.l' MOS
.ENDL SF
**************** CORNER_LIB OF  FNSP   MODEL ****************************
.LIB FS
.param toxp = 5.8e-9 toxn = 5.8e-9 
+dxl = 0 dxw = 0
+dvthn = -0.06 dvthp = -0.06
+cjn = 1.8217152e-3 cjp = 2.1242e-3  
+cjswn = 2.4763752e-10 cjswp = 2.4555e-10 
+cgon =  3.11E-10 cgop = 2.68e-10 
+cjgaten = 1.9215576e-10 cjgatep = 1.7678e-10
+hdifp = 3.1e-7 hdifn = 3.1e-07
.lib '/volume/cad/mmi/mmi_local.dev/sue/tech/tsmc25.l' MOS
.ENDL FS
***************************************************************************
***************************************************************
*                                                             *
*                3.3V NORMAL DEVICES LIB                      *
*                                                             *
***************************************************************
************** CORNER_LIB OF TYPICAL MODEL ****************************
.LIB TT_3V
.param toxn3 = 7.1e-09 toxp3 = 7.1e-9 toxe3 = 7.1e-9 dxl3 = 0 dxw3 = 0
+dvthn3 = 0 dvthp3 = 0.0 dvthe3 = 0.0
+cjn3 = 0.00117874 cjp3 = 1.931092e-3 cje3 = 1.138888e-03
+cjswn3 = 2.23898e-10 cjswp3 = 2.232277e-10 cjswe3 = 3.263546e-10
+cjgaten3 = 1.40099e-10 cjgatep3 = 1.607088e-10 cjgatee3 = 1.944610e-10
+cgon3 = 2.416e-10 cgop3 = 2.21e-10 cgoe3= 2.942000e-10
+hdifn3 = 3.1e-07 hdifp3 = 3.1e-07 hdife3 = 1.68e-06
.lib '/volume/cad/mmi/mmi_local.dev/sue/tech/tsmc25.l' MOS3
.ENDL TT_3V
**************** CORNER_LIB OF  SNSP   MODEL ****************************
.LIB SS_3V
.param toxn3 = 7.8e-09 toxp3 = 7.8e-9 toxe3 = 7.8e-9 dxl3 = 2.5e-8 dxw3 = -3e-8
+dvthn3 = 0.1 dvthp3 = -0.1 dvthe3 = 0.1
+cjn3 = 0.00129661 cjp3 = 2.1242e-3  cje3 = 1.252777e-03
+cjswn3 = 2.46288e-10 cjswp3 = 2.4555e-10 cjswe3 = 3.589901e-10
+cjgaten3 = 1.54109e-10 cjgatep3 = 1.7678e-10 cjgatee3 = 2.139071e-10
+cgon3 = 2.6576e-10 cgop3 = 2.431e-10 cgoe3= 3.236200e-10
+hdifn3 = 3.1e-07 hdifp3 = 3.1e-07 hdife3 = 1.68e-06
.lib '/volume/cad/mmi/mmi_local.dev/sue/tech/tsmc25.l' MOS3
.ENDL SS_3V
**************** CORNER_LIB OF  FNFP   MODEL ****************************
.LIB FF_3V
.param toxn3 = 6.4e-09 toxp3 = 6.4e-9 toxe3 = 6.4e-9 dxl3 = -2.5e-8 dxw3 = 3e-8
+dvthn3 = -0.1 dvthp3 = 0.1 dvthe3 = -0.1
+cjn3 = 0.00106087 cjp3 = 1.738e-3 cje3 = 1.024999e-03
+cjswn3 = 2.01508e-10 cjswp3 = 2.009e-10 cjswe3 = 2.937191e-10
+cjgaten3 = 1.26089e-10 cjgatep3 = 1.4464e-10 cjgatee3 = 1.750149e-10
+cgon3 = 2.1744e-10 cgop3 = 1.989e-10 cgoe3= 2.647800e-10
+hdifn3 = 3.1e-07 hdifp3 = 3.1e-07 hdife3 = 1.68e-06
.lib '/volume/cad/mmi/mmi_local.dev/sue/tech/tsmc25.l' MOS3
.ENDL FF_3V
**************** CORNER_LIB OF  SNFP   MODEL ****************************
.LIB SF_3V
.param toxn3 = 7.1e-09 toxp3 = 7.1e-9 toxe3 = 7.1e-9 dxl3 = 0 dxw3 = 0
+dvthn3 = 0.1 dvthp3 = 0.1 dvthe3 = 0.1
+cjn3 = 0.00129661 cjp3 = 1.738e-3 cje3 = 1.252777e-03
+cjswn3 = 2.46288e-10 cjswp3 = 2.009e-10 cjswe3 = 3.589901e-10
+cjgaten3 = 1.54109e-10 cjgatep3 = 1.4464e-10 cjgatee3 = 2.139071e-10
+cgon3 = 2.416e-10 cgop3 = 2.21e-10 cgoe3= 2.942000e-10
+hdifn3 = 3.1e-07 hdifp3 = 3.1e-07 hdife3 = 1.68e-06
.lib '/volume/cad/mmi/mmi_local.dev/sue/tech/tsmc25.l' MOS3
.ENDL SF_3V
**************** CORNER_LIB OF  FNSP   MODEL ****************************
.LIB FS_3V
.param toxn3 = 7.1e-09 toxp3 = 7.1e-9 toxe3 = 7.1e-9 dxl3 = 0 dxw3 = 0
+dvthn3 = -0.1 dvthp3 = -0.1 dvthe3 = -0.1
+cjn3 = 0.00106087 cjp3 = 2.1242e-3 cje3 = 1.024999e-03
+cjswn3 = 2.01508e-10 cjswp3 = 2.4555e-10 cjswe3 = 2.937191e-10
+cjgaten3 = 1.26089e-10 cjgatep3 = 1.7678e-10 cjgatee3 = 1.750149e-10
+cgon3 = 2.416e-10 cgop3 = 2.21e-10 cgoe3= 2.942000e-10
+hdifn3 = 3.1e-07 hdifp3 = 3.1e-07 hdife3 = 1.68e-06
.lib '/volume/cad/mmi/mmi_local.dev/sue/tech/tsmc25.l' MOS3
.ENDL FS_3V
**************************************************************************
*
.LIB MOS
***************************************************************
*                                                             *
*               NORMAL DEVICES MODEL                          *
*                                                             *
***************************************************************
***************************************************************
*                 NMOS DEVICES MODEL                          *
***************************************************************
.model n.1          NMOS   (                     LMIN    = '1.21E-06-dxl' 
+LMAX    = '2.1E-5-dxl'   WMIN    = '1E-05-dxw'    WMAX    = '1.01E-4-dxw'   
+LEVEL   = 49             TNOM    = 25             XL      = '3E-8 + dxl'
+XW      = '0 + dxw'      VERSION = 3.1            TOX     = toxn           
+XJ      = 1E-07          NCH     = 2.354946E+17   LLN     = 1              
+LWN     = 1              WLN     = 1              WWN     = 1              
+LINT    = 1.76E-08       WINT    = 6.75E-09       MOBMOD  = 1              
+BINUNIT = 2              DWG     = 0              DWB     = 0              
+VTH0    = '0.4720165+dvthn' LVTH0 = 6.763138E-08  WVTH0   = 5.909916E-08   
+PVTH0   = -1.267861E-13  K1      = 0.4846933      LK1     = -8.103905E-09  
+WK1     = 6.395591E-07   PK1     = -8.123707E-13  K2      = -1.329505E-03  
+LK2     = 1.601787E-09   WK2     = -2.442723E-07  PK2     = 2.942993E-13   
+K3      = 0              DVT0    = 0              DVT1    = 0              
+DVT2    = 0              DVT0W   = 0              DVT1W   = 0              
+DVT2W   = 0              NLX     = 0              W0      = 0              
+K3B     = 0              VSAT    = 6.680925E+04   LVSAT   = 0.01581872     
+UA      = -2.688803E-10  LUA     = 3.072317E-16   WUA     = 3.122353E-15   
+PUA     = -4.808778E-21  UB      = 1.378474E-18   LUB     = -8.104835E-26  
+WUB     = -3.012338E-24  PUB     = 2.314651E-31   UC      = -1.019211E-12  
+LUC     = 9.686199E-20   WUC     = 5.634727E-18   PUC     = -7.294355E-24  
+RDSW    = 387.8871       PRWB    = 0              PRWG    = 0              
+WR      = 0.99           U0      = 0.04058542     LU0     = 7.839521E-09   
+WU0     = 2.711929E-08   PU0     = -6.130031E-14  A0      = 1.437861       
+LA0     = -6.330903E-07  WA0     = -9.171811E-07  PA0     = 5.919068E-12   
+KETA    = -0.01744284    LKETA   = -3.289727E-08  WKETA   = 4.462173E-08   
+PKETA   = 1.236839E-13   A1      = 0.01393712     LA1     = -4.743437E-09  
+A2      = 1              AGS     = 0.2865836      LAGS    = 4.61459E-08    
+WAGS    = 8.114026E-08   PAGS    = 5.962646E-13   B0      = 0              
+B1      = 0              VOFF    = -0.1332282     LVOFF   = 1.72989E-10    
+WVOFF   = -2.877484E-09  PVOFF   = 5.756347E-14   NFACTOR = 0.5551888      
+LNFACTOR= 4.030729E-07   WNFACTOR= -6.286855E-08  PNFACTOR= 1.257674E-12   
+CIT     = 7.778989E-06   LCIT    = 7.400302E-13   WCIT    = -5.435811E-14  
+PCIT    = 1.087422E-18   CDSC    = 0              CDSCB   = 0              
+CDSCD   = 0              ETA0    = 2.261984E-08   LETA0   = -3.96823E-16   
+ETAB    = 0              DSUB    = 0              PCLM    = 3.184159       
+LPCLM   = 7.149497E-07   WPCLM   = 1.513743E-05   PPCLM   = -4.259013E-11  
+PDIBLC1 = 0              PDIBLC2 = 4.078248E-04   LPDIBLC2= 1.743987E-08   
+WPDIBLC2= 1.214904E-09   PPDIBLC2= -2.352693E-14  PDIBLCB = -0.02512167    
+LPDIBLCB= 2.603515E-07   WPDIBLCB= 1.220889E-06   PPDIBLCB= -2.206903E-12  
+DROUT   = 0              PSCBE1  = 3.745101E+08   LPSCBE1 = 151.9988       
+WPSCBE1 = -245.6366      PPSCBE1 = 6.969467E-04   PSCBE2  = 2.722691E-05   
+LPSCBE2 = 1.104795E-11   WPSCBE2 = -1.745378E-11  PPSCBE2 = -2.002455E-16  
+PVAG    = 2.070493       LPVAG   = 3.875221E-06   WPVAG   = 2.810356E-05   
+PPVAG   = -9.057198E-11  DELTA   = 7.801694E-04   LDELTA  = 8.2386E-10     
+WDELTA  = 1.923998E-08   PDELTA  = -2.755968E-14  ALPHA0  = 0              
+BETA0   = 30             KT1     = -0.3042243     LKT1    = -1.66316E-08   
+WKT1    = -5.359253E-09  PKT1    = -1.243864E-14  KT2     = -0.0422918     
+LKT2    = -5.795485E-11  WKT2    = 1.170717E-08   PKT2    = -6.480251E-14  
+AT      = 135038.2       LAT     = -0.1222668     WAT     = 0.1783469      
+PAT     = -3.751067E-07  UTE     = -2.0181        LUTE    = -8.922353E-08  
+WUTE    = -5.639915E-08  PUTE    = -1.557E-13     UA1     = 0              
+UB1     = 0              UC1     = 1.248379E-10   LUC1    = 7.321837E-17   
+WUC1    = -1.254641E-16  PUC1    = -4.710471E-22  KT1L    = 0              
+PRT     = -1E-18         CJ      = cjn            MJ      = 0.4960069      
+PB      = 0.9173808      CJSW    = cjswn          MJSW    = 0.443145       
+PBSW    = 0.9173808      CJSWG   = cjgaten        MJSWG   = 0.443145       
+PBSWG   = 0.9173808      HDIF    = hdifn          ACM     = 12             
+LDIF    = 1.2E-07        RSH     = 4.5            CTA     = 7.707813E-04   
+CTP     = 5.512283E-04   PTA     = 1.167715E-03   PTP     = 1.167715E-03   
+N       = 1              XTI     = 3              CGDO    = 'cgon'         
+CGSO    = 'cgon'         CAPMOD  = 0              NQSMOD  = 0              
+ELM     = 5              XPART   = 1              CGSL    = 0              
+CGDL    = 0              CKAPPA  = 0.6            CF      = 0              
+CLC     = 1E-07          CLE     = 0.6            JS      = 1E-06          
+JSW     = 5E-11           )
*
.model n.2          NMOS   (                     LMIN    ='5.1E-07-dxl'
+LMAX    = '1.21E-06-dxl' WMIN    = '1E-05-dxw'    WMAX    = '1.01E-4-dxw'   
+LEVEL   = 49             TNOM    = 25             XL      = '3E-8 + dxl'
+XW      = '0 + dxw'      VERSION = 3.1            TOX     = toxn           
+XJ      = 1E-07          NCH     = 2.354946E+17   LLN     = 1              
+LWN     = 1              WLN     = 1              WWN     = 1              
+LINT    = 1.76E-08       WINT    = 6.75E-09       MOBMOD  = 1              
+BINUNIT = 2              DWG     = 0              DWB     = 0              
+VTH0    = '0.518545+dvthn' LVTH0 = 1.157375E-08   WVTH0   = -8.450174E-08  
+PVTH0   = 4.622434E-14   K1      = 0.4831486      LK1     = -6.242856E-09  
+WK1     = -4.51392E-07   PK1     = 5.020072E-13   K2      = -1.587109E-03  
+LK2     = 1.912151E-09   WK2     = 1.586897E-07   PK2     = -1.911894E-13  
+K3      = 0              DVT0    = 0              DVT1    = 0              
+DVT2    = 0              DVT0W   = 0              DVT1W   = 0              
+DVT2W   = 0              NLX     = 0              W0      = 0              
+K3B     = 0              VSAT    = 8.097673E+04   LVSAT   = -1.250251E-03  
+UA      = 7.734779E-10   LUA     = -9.486017E-16  WUA     = -9.458473E-15  
+PUA     = 1.03486E-20    UB      = 8.637677E-19   LUB     = 5.3907E-25     
+WUB     = 5.250728E-24   PUB     = -9.723879E-30  UC      = -9.595714E-13  
+LUC     = 2.500844E-20   WUC     = -1.141953E-19  PUC     = -3.680525E-25  
+RDSW    = 387.8871       PRWB    = 0              PRWG    = 0              
+WR      = 0.99           U0      = 0.05419929     LU0     = -8.562467E-09  
+WU0     = -1.175773E-07  PU0     = 1.130302E-13   A0      = 0.8910086      
+LA0     = 2.575726E-08   WA0     = 8.847705E-06   PA0     = -5.845667E-12  
+KETA    = -0.06264535    LKETA   = 2.156272E-08   WKETA   = 1.630745E-07   
+PKETA   = -1.902808E-14  A1      = 6.235518E-03   LA1     = 4.53545E-09    
+WA1     = 1.096108E-07   PA1     = -1.320591E-13  A2      = 1              
+AGS     = 0.4269327      LAGS    = -1.229466E-07  WAGS    = 1.800013E-06   
+PAGS    = -1.474634E-12  B0      = 0              B1      = 0              
+VOFF    = -0.1374708     LVOFF   = 5.284424E-09   WVOFF   = 7.38735E-08    
+PVOFF   = -3.490612E-14  NFACTOR = 0.9671855      LNFACTOR= -9.330086E-08  
+WNFACTOR= -5.708345E-07  PNFACTOR= 1.869672E-12   CIT     = 9.262503E-06   
+LCIT    = -1.047297E-12  WCIT    = 7.733935E-10   PCIT    = -9.307627E-16  
+CDSC    = 0              CDSCB   = 0              CDSCD   = 0              
+ETA0    = -7.482616E-05  LETA0   = 9.017744E-11   WETA0   = 2.028846E-10   
+PETA0   = -2.444355E-16  ETAB    = 0              DSUB    = 0              
+PCLM    = 4.525042       LPCLM   = -9.005466E-07  WPCLM   = -2.052889E-05  
+PPCLM   = 3.806555E-13   PDIBLC1 = 0              PDIBLC2 = 0.01383121     
+LPDIBLC2= 1.267376E-09   WPDIBLC2= -7.169089E-08  PPDIBLC2= 6.430999E-14   
+PDIBLCB = 0.3326946      LPDIBLCB= -1.707456E-07  WPDIBLCB= -1.379426E-06  
+PPDIBLCB= 9.259572E-13   DROUT   = 0              PSCBE1  = 5.282298E+08   
+LPSCBE1 = -33.20259      WPSCBE1 = -43.19918      PPSCBE1 = 4.530501E-04   
+PSCBE2  = 5.701096E-05   LPSCBE2 = -2.483589E-11  WPSCBE2 = -3.369074E-10  
+PPSCBE2 = 1.846324E-16   PVAG    = 8.518275       LPVAG   = -3.893069E-06  
+WPVAG   = -7.746803E-05  PPVAG   = 3.662068E-11   DELTA   = -4.442067E-03  
+LDELTA  = 7.115609E-09   WDELTA  = -9.192873E-08  PDELTA  = 1.063764E-13   
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.3099148     
+LKT1    = -9.775668E-09  WKT1    = -7.244304E-08  PKT1    = 6.838391E-14   
+KT2     = -0.0401275     LKT2    = -2.665505E-09  WKT2    = -9.205855E-08  
+PKT2    = 6.021444E-14   AT      = 4.892142E+04   LAT     = -0.01851329    
+WAT     = -0.286452      PAT     = 1.84883E-07    UTE     = -2.0167        
+LUTE    = -9.090994E-08  WUTE    = -1.075375E-06  PUTE    = 1.071963E-12   
+UA1     = 5.716753E-12   LUA1    = -6.887557E-18  WUA1    = -5.715996E-16  
+PUA1    = 6.886634E-22   UB1     = 0              UC1     = 2.32284E-10    
+LUC1    = -5.623275E-17  WUC1    = 2.49962E-17    PUC1    = -6.523217E-22  
+KT1L    = 0              PRT     = -1E-18         CJ      = cjn
+MJ      = 0.4960069      PB      = 0.9173808      CJSW    = cjswn
+MJSW    = 0.443145       PBSW    = 0.9173808      CJSWG   = cjgaten
+MJSWG   = 0.443145       PBSWG   = 0.9173808      HDIF    = hdifn
+ACM     = 12             LDIF    = 1.2E-07        RSH     = 4.5
+CTA     = 7.707813E-04   CTP     = 5.512283E-04   PTA     = 1.167715E-03
+PTP     = 1.167715E-03   N       = 1              XTI     = 3
+CGDO    = 'cgon'         CGSO    = 'cgon'         CAPMOD  = 0
+NQSMOD  = 0              ELM     = 5              XPART   = 1
+CGSL    = 0              CGDL    = 0              CKAPPA  = 0.6
+CF      = 0              CLC     = 1E-07          CLE     = 0.6
+JS      = 1E-06          JSW     = 5E-11           )
*
.model n.3          NMOS   (                     LMIN    = 2.4E-07        
+LMAX    = '5.1E-07-dxl'  WMIN    = '1E-05-dxw'    WMAX    = '1.01E-4-dxw'   
+LEVEL   = 49             TNOM    = 25             XL      = '3E-8 + dxl'
+XW      = '0 + dxw'      VERSION = 3.1            TOX     = toxn           
+XJ      = 1E-07          NCH     = 2.354946E+17   LLN     = 1              
+LWN     = 1              WLN     = 1              WWN     = 1              
+LINT    = 1.76E-08       WINT    = 6.75E-09       MOBMOD  = 1              
+BINUNIT = 2              DWG     = 0              DWB     = 0              
+VTH0    = '0.5026714+dvthn' LVTH0 = 1.958678E-08  WVTH0   = 4.290585E-08   
+PVTH0   = -1.809101E-14  K1      = 0.4108423      LK1     = 3.025735E-08   
+WK1     = 7.951467E-07   PK1     = -1.272456E-13  K2      = 0.03311436     
+LK2     = -1.560515E-08  WK2     = -3.042514E-07  PK2     = 4.250328E-14   
+K3      = 0              DVT0    = 0              DVT1    = 0              
+DVT2    = 0              DVT0W   = 0              DVT1W   = 0              
+DVT2W   = 0              NLX     = 0              W0      = 0              
+K3B     = 0              VSAT    = 7.020505E+04   LVSAT   = 4.187292E-03   
+UA      = -5.190661E-11  LUA     = -5.319476E-16  WUA     = 5.18367E-16    
+PUA     = 5.312294E-21   UB      = 8.803119E-19   LUB     = 5.307185E-25   
+WUB     = 1.456933E-24   PUB     = -7.808771E-30  UC      = -3.820008E-11  
+LUC     = 1.882402E-17   WUC     = 7.437185E-16   PUC     = -3.758548E-22  
+RDSW    = 387.8871       PRWB    = 0              PRWG    = 0              
+WR      = 0.99           U0      = 0.04175936     LU0     = -2.282794E-09  
+WU0     = -7.312229E-08  PU0     = 9.05893E-14    A0      = 0.8317479      
+LA0     = 5.567204E-08   WA0     = -9.149302E-06  PA0     = 3.239223E-12   
+KETA    = -0.03588897    LKETA   = 8.056102E-09   WKETA   = -8.414997E-08  
+PKETA   = 1.057709E-13   A1      = 0.02955053     LA1     = -7.23397E-09   
+WA1     = -2.951059E-07  PA1     = 7.224193E-14   A2      = 1              
+AGS     = 0.2507229      LAGS    = -3.399592E-08  WAGS    = -1.374348E-06  
+PAGS    = 1.27784E-13    B0      = 0              B1      = 0              
+VOFF    = -0.1193689     LVOFF   = -3.85344E-09   WVOFF   = -1.206406E-07  
+PVOFF   = 6.32846E-14    NFACTOR = 0.7024593      LNFACTOR= 4.033299E-08   
+WNFACTOR= 7.471343E-06   PNFACTOR= -2.19002E-12   CIT     = -3.698666E-04  
+LCIT    = 1.90337E-10    WCIT    = -7.512456E-09  PCIT    = 3.251935E-15   
+CDSC    = 0              CDSCB   = 0              CDSCD   = 0              
+ETA0    = 7.714566E-05   LETA0   = 1.346205E-11   WETA0   = -7.262536E-10  
+PETA0   = 2.245935E-16   ETAB    = 3.626082E-03   LETAB   = -1.830446E-09  
+WETAB   = -5.557273E-09  PETAB   = 2.805312E-15   DSUB    = 0              
+PCLM    = 4.370182       LPCLM   = -8.223728E-07  WPCLM   = -3.689682E-05  
+PPCLM   = 8.643188E-12   PDIBLC1 = 0              PDIBLC2 = -0.010542      
+LPDIBLC2= 1.357097E-08   WPDIBLC2= 1.551217E-07   PPDIBLC2= -5.018501E-14  
+PDIBLCB = -0.2294693     LPDIBLCB= 1.130348E-07   WPDIBLCB= 2.421621E-06   
+PPDIBLCB= -9.928114E-13  DROUT   = 0              PSCBE1  = 4.43164E+08    
+LPSCBE1 = 9.738602       WPSCBE1 = 1.559390E+03   PPSCBE1 = -3.559371E-04  
+PSCBE2  = 2.738866E-06   LPSCBE2 = 2.560667E-12   WPSCBE2 = 1.463441E-10   
+PPSCBE2 = -5.931305E-17  PVAG    = 1.509716       LPVAG   = -3.551481E-07  
+WPVAG   = -9.092639E-06  PPVAG   = 2.104782E-12   DELTA   = -0.01515751    
+LDELTA  = 1.252476E-08   WDELTA  = 1.017532E-07   PDELTA  = 8.605775E-15   
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.3076133     
+LKT1    = -1.093746E-08  WKT1    = -5.441676E-09  PKT1    = 3.456163E-14   
+KT2     = -0.04727656    LKT2    = 9.4334E-10     WKT2    = -4.608597E-08  
+PKT2    = 3.700749E-14   AT      = 4.723467E+03   LAT     = 3.797835E-03   
+WAT     = 0.1549309      PAT     = -3.792708E-08  UTE     = -2.57966       
+LUTE    = 1.93272E-07    WUTE    = 4.212042E-06   PUTE    = -1.597126E-12  
+UA1     = -7.857595E-10  LUA1    = 3.926497E-16   WUA1    = -3.082724E-16  
+PUA1    = 5.557358E-22   UB1     = 0              UC1     = 1.48779E-10    
+LUC1    = -1.407942E-17  WUC1    = -2.972607E-15  PUC1    = 8.608687E-22   
+KT1L    = 0              PRT     = -1E-18         CJ      = cjn
+MJ      = 0.4960069      PB      = 0.9173808      CJSW    = cjswn          
+MJSW    = 0.443145       PBSW    = 0.9173808      CJSWG   = cjgaten        
+MJSWG   = 0.443145       PBSWG   = 0.9173808      HDIF    = hdifn          
+ACM     = 12             LDIF    = 1.2E-07        RSH     = 4.5            
+CTA     = 7.707813E-04   CTP     = 5.512283E-04   PTA     = 1.167715E-03   
+PTP     = 1.167715E-03   N       = 1              XTI     = 3              
+CGDO    = 'cgon'         CGSO    = 'cgon'         CAPMOD  = 0              
+NQSMOD  = 0              ELM     = 5              XPART   = 1              
+CGSL    = 0              CGDL    = 0              CKAPPA  = 0.6            
+CF      = 0              CLC     = 1E-07          CLE     = 0.6            
+JS      = 1E-06          JSW     = 5E-11           )
*
.model n.4          NMOS   (                     LMIN    = '1.21E-06-dxl'
+LMAX    = '2.1E-5-dxl'   WMIN    = '1.2E-06-dxw'  WMAX    = '1E-05-dxw' 
+LEVEL   = 49             TNOM    = 25             XL      = '3E-8 + dxl'
+XW      = '0 + dxw'      VERSION = 3.1            TOX     = toxn           
+XJ      = 1E-07          NCH     = 2.354946E+17   LLN     = 1              
+LWN     = 1              WLN     = 1              WWN     = 1              
+LINT    = 1.76E-08       WINT    = 6.75E-09       MOBMOD  = 1              
+BINUNIT = 2              DWG     = 0              DWB     = 0              
+VTH0    = '0.4792625+dvthn' LVTH0 = 5.569981E-08  WVTH0   = -1.326327E-08  
+PVTH0   = -7.631499E-15  K1      = 0.5587199      LK1     = -1.004252E-07  
+WK1     = -9.970723E-08  PK1     = 1.095961E-13   K2      = -0.02926698    
+LK2     = 3.526087E-08   WK2     = 3.472528E-08   PK2     = -4.183702E-14  
+K3      = 0              DVT0    = 0              DVT1    = 0              
+DVT2    = 0              DVT0W   = 0              DVT1W   = 0              
+DVT2W   = 0              NLX     = 0              W0      = 0              
+K3B     = 0              VSAT    = 6.680891E+04   LVSAT   = 0.01582546     
+WVSAT   = 3.364873E-06   PVSAT   = -6.732159E-11  UA      = 4.207572E-11   
+LUA     = -4.568364E-17  WUA     = 1.699074E-17   PUA     = -1.284389E-21  
+UB      = 1.092096E-18   LUB     = -1.63771E-25   WUB     = -1.524245E-25  
+PUB     = 1.057574E-30   UC      = -4.626925E-13  LUC     = -6.535668E-19  
+WUC     = 7.70575E-20    PUC     = 1.998017E-25   RDSW    = 387.8871       
+PRWB    = 0              PRWG    = 0              WR      = 0.99           
+U0      = 0.04370826     LU0     = 2.934503E-09   WU0     = -4.066885E-09  
+PU0     = -1.231635E-14  A0      = 1.36774        LA0     = 3.090297E-08   
+WA0     = -2.169181E-07  PA0     = -7.118999E-13  KETA    = -0.01222097    
+LKETA   = -2.239483E-08  WKETA   = -7.526517E-09  PKETA   = 1.880134E-14   
+A1      = 0.01393711     LA1     = -4.743436E-09  A2      = 1              
+AGS     = 0.3028839      LAGS    = 1.407165E-07   WAGS    = -8.164266E-08  
+PAGS    = -3.481648E-13  B0      = 0              B1      = 0              
+VOFF    = -0.1347032     LVOFF   = 7.26876E-09    WVOFF   = 1.185249E-08   
+PVOFF   = -1.329843E-14  NFACTOR = 0.3460114      LNFACTOR= 7.449701E-07   
+WNFACTOR= 2.026081E-06   PNFACTOR= -2.156682E-12  CIT     = 7.685324E-06   
+LCIT    = 9.576392E-13   WCIT    = 8.810289E-13   PCIT    = -1.085731E-18  
+CDSC    = 0              CDSCB   = 0              CDSCD   = 0              
+ETA0    = 2.261984E-08   LETA0   = -3.96823E-16   ETAB    = 0              
+DSUB    = 0              PCLM    = 4.704744       LPCLM   = -3.64575E-06   
+WPCLM   = -4.788822E-08  PPCLM   = 9.579929E-13   PDIBLC1 = 0              
+PDIBLC2 = 5.069677E-04   LPDIBLC2= 1.553435E-08   WPDIBLC2= 2.248176E-10   
+PPDIBLC2= -4.497429E-15  PDIBLCB = 0.06319939     LPDIBLCB= 8.11881E-08    
+WPDIBLCB= 3.388711E-07   PPDIBLCB= -4.176874E-13  DROUT   = 0              
+PSCBE1  = 3.496826E+08   LPSCBE1 = 226.4029       WPSCBE1 = 2.303916       
+PPSCBE1 = -4.60894E-05   PSCBE2  = 2.551178E-05   LPSCBE2 = -9.65602E-12   
+WPSCBE2 = -3.25655E-13   PPSCBE2 = 6.514657E-18   PVAG    = 4.880464       
+LPVAG   = -5.1105E-06    WPVAG   = 4.179453E-08   PPVAG   = -8.360929E-13  
+DELTA   = 2.705904E-03   LDELTA  = -1.918548E-09  WDELTA  = 8.629108E-12   
+PDELTA  = -1.726216E-16  ALPHA0  = 0              BETA0   = 30             
+KT1     = -0.3048811     LKT1    = -1.547364E-08  WKT1    = 1.199841E-09   
+PKT1    = -2.400256E-14  KT2     = -0.0410787     LKT2    = -7.363195E-09  
+WKT2    = -4.074656E-10  PKT2    = 8.151264E-15   AT      = 156096.3       
+LAT     = -0.16563       WAT     = -0.03194987    PAT     = 5.793973E-08   
+UTE     = -2.04048       LUTE    = -1.051236E-07  WUTE    = 1.670963E-07   
+PUTE    = 3.086059E-15   UA1     = 0              UB1     = 0              
+UC1     = 1.159747E-10   LUC1    = 3.996027E-17   WUC1    = -3.69526E-17   
+PUC1    = -1.389151E-22  KT1L    = 0              PRT     = -1E-18         
+CJ      = cjn            MJ      = 0.4960069      PB      = 0.9173808      
+CJSW    = cjswn          MJSW    = 0.443145       PBSW    = 0.9173808      
+CJSWG   = cjgaten        MJSWG   = 0.443145       PBSWG   = 0.9173808      
+HDIF    = hdifn          ACM     = 12             LDIF    = 1.2E-07        
+RSH     = 4.5            CTA     = 7.707813E-04   CTP     = 5.512283E-04   
+PTA     = 1.167715E-03   PTP     = 1.167715E-03   N       = 1              
+XTI     = 3              CGDO    = 'cgon'         CGSO    = 'cgon'         
+CAPMOD  = 0              NQSMOD  = 0              ELM     = 5              
+XPART   = 1              CGSL    = 0              CGDL    = 0              
+CKAPPA  = 0.6            CF      = 0              CLC     = 1E-07          
+CLE     = 0.6            JS      = 1E-06          JSW     = 5E-11           )
*
.model n.5          NMOS   (                     LMIN    = '5.1E-07-dxl'
+LMAX    = '1.21E-06-dxl' WMIN    = '1.2E-06-dxw'  WMAX    = '1E-05-dxw'    
+LEVEL   = 49             TNOM    = 25             XL      = '3E-8 + dxl'
+XW      = '0 + dxw'      VERSION = 3.1            TOX     = toxn           
+XJ      = 1E-07          NCH     = 2.354946E+17   LLN     = 1              
+LWN     = 1              WLN     = 1              WWN     = 1              
+LINT    = 1.76E-08       WINT    = 6.75E-09       MOBMOD  = 1              
+BINUNIT = 2              DWG     = 0              DWB     = 0              
+VTH0    = '0.5119424+dvthn' LVTH0 = 1.632708E-08  WVTH0   = -1.856437E-08  
+PVTH0   = -1.244736E-15  K1      = 0.4340792      LK1     = 4.974184E-08   
+WK1     = 3.863939E-08   PK1     = -5.708396E-14  K2      = 0.01603632     
+LK2     = -1.932056E-08  WK2     = -1.730663E-08  PK2     = 2.085102E-14   
+K3      = 0              DVT0    = 0              DVT1    = 0              
+DVT2    = 0              DVT0W   = 0              DVT1W   = 0              
+DVT2W   = 0              NLX     = 0              W0      = 0              
+K3B     = 0              VSAT    = 8.098577E+04   LVSAT   = -1.254819E-03  
+WVSAT   = -9.038166E-05  PVSAT   = 4.562463E-11   UA      = 7.155866E-12   
+LUA     = -3.612276E-18  WUA     = -1.805598E-15  PUA     = 9.114656E-22   
+UB      = 1.26923E-18    LUB     = -3.77182E-25   WUB     = 1.201578E-24   
+PUB     = -5.737284E-31  UC      = -9.891652E-13  LUC     = -1.927236E-20  
+WUC     = 1.813437E-19   PUC     = 7.415769E-26   RDSW    = 387.8871       
+PRWB    = 0              PRWG    = 0              WR      = 0.99           
+U0      = 0.04459833     LU0     = 1.862139E-09   WU0     = -2.169738E-08  
+PU0     = 8.924873E-15   A0      = 1.973751       LA0     = -6.992191E-07  
+WA0     = -1.9651E-06    PA0     = 1.39431E-12    KETA    = -0.04796345    
+LKETA   = 2.066771E-08   WKETA   = 1.645372E-08   PKETA   = -1.009006E-14  
+A1      = 0.01721141     LA1     = -8.688307E-09  A2      = 1              
+AGS     = 0.7040285      LAGS    = -3.425826E-07  WAGS    = -9.672052E-07  
+PAGS    = 7.18761E-13    B0      = 0              B1      = 0              
+VOFF    = -0.1291355     LVOFF   = 5.607987E-10   WVOFF   = -9.366625E-09  
+PVOFF   = 1.226636E-14   NFACTOR = 0.8696613      LNFACTOR= 1.140766E-07   
+WNFACTOR= 4.030911E-07   PNFACTOR= -2.01303E-13   CIT     = 8.670988E-05   
+LCIT    = -9.425115E-11  WCIT    = -3.467122E-14  PCIT    = 1.75004E-20    
+CDSC    = 0              CDSCB   = 0              CDSCD   = 0              
+ETA0    = -5.451027E-05  LETA0   = 6.570084E-11   ETAB    = 0              
+DSUB    = 0              PCLM    = 2.347101       LPCLM   = -8.052613E-07  
+WPCLM   = 1.221124E-06   PPCLM   = -5.709126E-13  PDIBLC1 = 0              
+PDIBLC2 = 7.689529E-03   LPDIBLC2= 6.880802E-09   WPDIBLC2= -1.035697E-08  
+PPDIBLC2= 8.251507E-15   PDIBLCB = 0.1959124      LPDIBLCB= -7.870458E-08  
+WPDIBLCB= -1.345065E-08  PPDIBLCB= 6.789883E-15   DROUT   = 0              
+PSCBE1  = 5.301E+08      LPSCBE1 = 9.035908       WPSCBE1 = -61.87663      
+PPSCBE1 = 3.123532E-05   PSCBE2  = 2.239887E-05   LPSCBE2 = -5.905592E-12  
+WPSCBE2 = 8.746155E-12   PPSCBE2 = -4.415059E-18  PVAG    = 0.8434053      
+LPVAG   = -2.466524E-07  WPVAG   = -8.229416E-07  PPVAG   = 2.057414E-13   
+DELTA   = -0.01371118    LDELTA  = 1.786076E-08   WDELTA  = 6.372918E-10   
+PDELTA  = -9.300375E-16  ALPHA0  = 0              BETA0   = 30             
+KT1     = -0.3139421     LKT1    = -4.556913E-09  WKT1    = -3.222427E-08  
+PKT1    = 1.626681E-14   KT2     = -0.05044162    LKT2    = 3.917246E-09   
+WKT2    = 1.094335E-08   PKT2    = -5.524206E-15  AT      = 1.629011E+04   
+LAT     = 2.808535E-03   WAT     = 0.03942062     PAT     = -2.804744E-08  
+UTE     = -2.152937      LUTE    = 3.036489E-08   WUTE    = 2.851529E-07   
+PUTE    = -1.391486E-13  UA1     = -4.936494E-11  LUA1    = 5.947488E-17   
+WUA1    = -2.152628E-17  PUA1    = 2.593486E-23   UB1     = 0              
+UC1     = 2.645138E-10   LUC1    = -1.389996E-16  WUC1    = -2.968668E-16  
+PUC1    = 1.742296E-22   KT1L    = 0              PRT     = -1E-18         
+CJ      = cjn            MJ      = 0.4960069      PB      = 0.9173808      
+CJSW    = cjswn          MJSW    = 0.443145       PBSW    = 0.9173808      
+CJSWG   = cjgaten        MJSWG   = 0.443145       PBSWG   = 0.9173808      
+HDIF    = hdifn          ACM     = 12             LDIF    = 1.2E-07        
+RSH     = 4.5            CTA     = 7.707813E-04   CTP     = 5.512283E-04   
+PTA     = 1.167715E-03   PTP     = 1.167715E-03   N       = 1              
+XTI     = 3              CGDO    = 'cgon'         CGSO    = 'cgon'         
+CAPMOD  = 0              NQSMOD  = 0              ELM     = 5              
+XPART   = 1              CGSL    = 0              CGDL    = 0              
+CKAPPA  = 0.6            CF      = 0              CLC     = 1E-07          
+CLE     = 0.6            JS      = 1E-06          JSW     = 5E-11           )
*
.model n.6          NMOS   (                     LMIN    = 2.4E-07        
+LMAX    = '5.1E-07-dxl'  WMIN    = '1.2E-06-dxw'  WMAX    = '1E-05-dxw'   
+LEVEL   = 49             TNOM    = 25             XL      = '3E-8 + dxl' 
+XW      = '0 + dxw'      VERSION = 3.1            TOX     = toxn           
+XJ      = 1E-07          NCH     = 2.354946E+17   LLN     = 1              
+LWN     = 1              WLN     = 1              WWN     = 1              
+LINT    = 1.76E-08       WINT    = 6.75E-09       MOBMOD  = 1              
+BINUNIT = 2              DWG     = 0              DWB     = 0              
+VTH0    = '0.5099462+dvthn' LVTH0   = 1.733475E-08   WVTH0   = -2.974431E-08  
+PVTH0   = 4.398902E-15   K1      = 0.5001482      LK1     = 1.639021E-08   
+WK1     = -9.670633E-08  PK1     = 1.123856E-14   K2      = -5.008289E-04  
+LK2     = -1.09726E-08   WK2     = 3.144655E-08   PK2     = -3.759582E-15  
+K3      = 0              DVT0    = 0              DVT1    = 0              
+DVT2    = 0              DVT0W   = 0              DVT1W   = 0              
+DVT2W   = 0              NLX     = 0              W0      = 0              
+K3B     = 0              VSAT    = 7.020505E+04   LVSAT   = 4.187292E-03   
+UA      = 0              UB      = 1.014562E-18   LUB     = -2.486255E-25  
+WUB     = 1.162478E-25   PUB     = -2.585357E-32  UC      = 3.770638E-11   
+LUC     = -1.955278E-17  WUC     = -1.432124E-17  PUC     = 7.395062E-24   
+RDSW    = 387.8871       PRWB    = 0              PRWG    = 0              
+WR      = 0.99           U0      = 0.033889       LU0     = 7.268208E-09   
+WU0     = 5.475063E-09   PU0     = -4.79178E-15   A0      = -0.2393695     
+LA0     = 4.179641E-07   WA0     = 1.547412E-06   PA0     = -3.788064E-13  
+KETA    = -0.04362817    LKETA   = 1.847927E-08   WKETA   = -6.86238E-09   
+PKETA   = 1.679911E-15   A1      = 4.924793E-08   LA1     = -1.205589E-14  
+WA1     = -5.843266E-14  PA1     = 1.430432E-20   A2      = 1              
+AGS     = 0.02419032     LAGS    = 5.998053E-10   WAGS    = 8.8792E-07     
+PAGS    = -2.177063E-13  B0      = 0              B1      = 0              
+VOFF    = -0.1335701     LVOFF   = 2.799351E-09   WVOFF   = 2.117984E-08   
+PVOFF   = -3.153492E-15  NFACTOR = 1.536522       LNFACTOR= -2.225549E-07  
+WNFACTOR= -8.580287E-07  PNFACTOR= 4.353103E-13   CIT     = -1.235092E-03  
+LCIT    = 5.729944E-10   WCIT    = 1.128116E-09   PCIT    = -5.694728E-16  
+CDSC    = 0              CDSCB   = 0              CDSCD   = 0              
+ETA0    = 4.422122E-06   LETA0   = 3.595177E-11   ETAB    = 3.007522E-03   
+LETAB   = -1.518197E-09  WETAB   = 6.199715E-10   PETAB   = -3.129618E-16  
+DSUB    = 0              PCLM    = 0.6914982      LPCLM   = 3.048691E-08   
+WPCLM   = -1.596545E-07  PPCLM   = 1.261043E-13   PDIBLC1 = 0              
+PDIBLC2 = 3.826756E-03   LPDIBLC2= 8.830731E-09   WPDIBLC2= 1.162811E-08   
+PPDIBLC2= -2.846562E-15  PDIBLCB = 0.033054       LPDIBLCB= 3.506332E-09   
+WPDIBLCB= -2.000674E-07  PPDIBLCB= 1.009941E-13   DROUT   = 0              
+PSCBE1  = 5.993139E+08   LPSCBE1 = -25.90323      PSCBE2  = 1.739306E-05   
+LPSCBE2 = -3.378656E-12  PVAG    = 0.6793554      LPVAG   = -1.6384E-07    
+WPVAG   = -8.002434E-07  PPVAG   = 1.942833E-13   DELTA   = -4.734139E-03  
+LDELTA  = 1.332915E-08   WDELTA  = -2.339739E-09  PDELTA  = 5.727675E-16   
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.3066478     
+LKT1    = -8.239115E-09  WKT1    = -1.508441E-08  PKT1    = 7.614608E-15   
+KT2     = -0.05245571    LKT2    = 4.933963E-09   WKT2    = 5.63564E-09    
+PKT2    = -2.844872E-15  AT      = 2.305132E+04   LAT     = -6.045266E-04  
+WAT     = -0.02810027    PAT     = 6.037104E-09   UTE     = -2.13662       
+LUTE    = 2.212806E-08   WUTE    = -2.123736E-07  PUTE    = 1.120028E-13   
+UA1     = -8.406026E-10  LUA1    = 4.588917E-16   WUA1    = 2.39419E-16    
+PUA1    = -1.057904E-22  UB1     = 0              UC1     = -1.777721E-10  
+LUC1    = 8.426636E-17   WUC1    = 2.884956E-16   PUC1    = -1.212614E-22  
+KT1L    = 0              PRT     = -1E-18         CJ      = cjn
+MJ      = 0.4960069      PB      = 0.9173808      CJSW    = cjswn          
+MJSW    = 0.443145       PBSW    = 0.9173808      CJSWG   = cjgaten        
+MJSWG   = 0.443145       PBSWG   = 0.9173808      HDIF    = hdifn          
+ACM     = 12             LDIF    = 1.2E-07        RSH     = 4.5            
+CTA     = 7.707813E-04   CTP     = 5.512283E-04   PTA     = 1.167715E-03   
+PTP     = 1.167715E-03   N       = 1              XTI     = 3              
+CGDO    = 'cgon'         CGSO    = 'cgon'         CAPMOD  = 0              
+NQSMOD  = 0              ELM     = 5              XPART   = 1              
+CGSL    = 0              CGDL    = 0              CKAPPA  = 0.6            
+CF      = 0              CLC     = 1E-07          CLE     = 0.6            
+JS      = 1E-06          JSW     = 5E-11           )
*
.model n.7          NMOS   (                     LMIN    = '1.21E-06-dxl' 
+LMAX    = '2.1E-5-dxl'   WMIN    = '6E-07-dxw'    WMAX    = '1.2E-06-dxw'
+LEVEL   = 49             TNOM    = 25             XL      = '3E-8 + dxl'
+XW      = '0 + dxw'      VERSION = 3.1            TOX     = toxn           
+XJ      = 1E-07          NCH     = 2.354946E+17   LLN     = 1              
+LWN     = 1              WLN     = 1              WWN     = 1              
+LINT    = 1.76E-08       WINT    = 6.75E-09       MOBMOD  = 1              
+BINUNIT = 2              DWG     = 0              DWB     = 0              
+VTH0    = '0.4895258+dvthn' LVTH0 = 3.594205E-08  WVTH0   = -2.544063E-08  
+PVTH0   = 1.581109E-14   K1      = 0.472571       LK1     = 1.088808E-08   
+WK1     = 2.508395E-09   PK1     = -2.247719E-14  K2      = 5.389562E-15   
+LK2     = -1.07817E-19   K3      = 0              DVT0    = 0              
+DVT1    = 0              DVT2    = 0              DVT0W   = 0              
+DVT1W   = 0              DVT2W   = 0              NLX     = 0              
+W0      = 0              K3B     = 0              VSAT    = 6.681175E+04   
+LVSAT   = 0.01576872     UA      = 5.601528E-11   LUA     = -2.164112E-15  
+WUA     = 4.515757E-19   PUA     = 1.229126E-21   UB      = 1.006573E-18   
+LUB     = 1.674872E-24   WUB     = -5.095188E-26  PUB     = -1.123976E-30  
+UC      = 1.78094E-13    LUC     = -9.004496E-19  WUC     = -6.832356E-19  
+PUC     = 4.92728E-25    RDSW    = 387.8871       PRWB    = 0              
+PRWG    = 0              WR      = 0.99           U0      = 0.04160499     
+LU0     = -1.779956E-08  WU0     = -1.571352E-09  PU0     = 1.228461E-14   
+A0      = 0.7904361      LA0     = -3.729251E-07  WA0     = 4.680527E-07   
+PA0     = -2.327578E-13  KETA    = -0.02273424    LKETA   = -1.878997E-08  
+WKETA   = 4.947485E-09   PKETA   = 1.452416E-14   A1      = 0.01393712     
+LA1     = -4.743437E-09  A2      = 1              AGS     = 0.1717122      
+LAGS    = -3.436247E-07  WAGS    = 7.399261E-08   PAGS    = 2.265061E-13   
+B0      = 0              B1      = 0              VOFF    = -0.1152589     
+LVOFF   = -1.856542E-08  WVOFF   = -1.121827E-08  PVOFF   = 1.735383E-14   
+NFACTOR = 3.817119       LNFACTOR= -3.161193E-06  WNFACTOR= -2.092389E-06  
+PNFACTOR= 2.477981E-12   CIT     = 9.044437E-06   LCIT    = -7.548436E-13  
+WCIT    = -7.315584E-13  PCIT    = 9.461297E-19   CDSC    = 0              
+CDSCB   = 0              CDSCD   = 0              ETA0    = 2.262043E-08   
+LETA0   = -4.087681E-16  WETA0   = -7.084601E-19  PETA0   = 1.417284E-23   
+ETAB    = 0              DSUB    = 0              PCLM    = 2.121202       
+LPCLM   = 3.729256E-07   WPCLM   = 3.017485E-06   PPCLM   = -3.810165E-12  
+PDIBLC1 = 0              PDIBLC2 = 4.287668E-04   LPDIBLC2= 1.211817E-08   
+WPDIBLC2= 3.176034E-10   PPDIBLC2= -4.441315E-16  PDIBLCB = 0.5929481      
+LPDIBLCB= -5.367241E-07  WPDIBLCB= -2.896758E-07  PPDIBLCB= 3.154654E-13   
+DROUT   = 0              PSCBE1  = 3.516055E+08   LPSCBE1 = 187.934        
+WPSCBE1 = 0.02230535     PPSCBE1 = -4.46064E-07   PSCBE2  = 2.449938E-05   
+LPSCBE2 = 1.059691E-11   WPSCBE2 = 8.75561E-13    PPSCBE2 = -1.751544E-17  
+PVAG    = 1.919701       LPVAG   = -2.100768E-06  WPVAG   = 3.55474E-06    
+PPVAG   = -4.40714E-12   DELTA   = 3.399672E-03   LDELTA  = -2.891124E-09  
+WDELTA  = -8.145255E-10  PDELTA  = 9.813402E-16   ALPHA0  = 0              
+BETA0   = 30             KT1     = -0.3140651     LKT1    = -2.342013E-08  
+WKT1    = 1.209666E-08   PKT1    = -1.457406E-14  KT2     = -0.04695809    
+LKT2    = 6.176543E-09   WKT2    = 6.568424E-09   PKT2    = -7.913637E-15  
+AT      = 9.853626E+04   LAT     = -0.07989181    WAT     = 0.03634513     
+PAT     = -4.378861E-08  UTE     = -1.980039      LUTE    = -7.094765E-08  
+WUTE    = 9.538309E-08   PUTE    = -3.746371E-14  UA1     = 0              
+UB1     = 0              UC1     = 1.219121E-10   LUC1    = -9.392169E-17  
+WUC1    = -4.399721E-17  PUC1    = 1.993586E-23   KT1L    = 0              
+PRT     = -1E-18         CJ      = cjn            MJ      = 0.4960069      
+PB      = 0.9173808      CJSW    = cjswn          MJSW    = 0.443145       
+PBSW    = 0.9173808      CJSWG   = cjgaten        MJSWG   = 0.443145       
+PBSWG   = 0.9173808      HDIF    = hdifn          ACM     = 12             
+LDIF    = 1.2E-07        RSH     = 4.5            CTA     = 7.707813E-04   
+CTP     = 5.512283E-04   PTA     = 1.167715E-03   PTP     = 1.167715E-03   
+N       = 1              XTI     = 3              CGDO    = 'cgon'         
+CGSO    = 'cgon'         CAPMOD  = 0              NQSMOD  = 0              
+ELM     = 5              XPART   = 1              CGSL    = 0              
+CGDL    = 0              CKAPPA  = 0.6            CF      = 0              
+CLC     = 1E-07          CLE     = 0.6            JS      = 1E-06          
+JSW     = 5E-11           )
*
.model n.8          NMOS   (                     LMIN    = '5.1E-07-dxl'  
+LMAX    = '1.21E-06-dxl' WMIN    = '6E-07-dxw'    WMAX    = '1.2E-06-dxw'
+LEVEL   = 49             TNOM    = 25             XL      = '3E-8 + dxl'
+XW      = '0 + dxw'      VERSION = 3.1            TOX     = toxn           
+XJ      = 1E-07          NCH     = 2.354946E+17   LLN     = 1              
+LWN     = 1              WLN     = 1              WWN     = 1              
+LINT    = 1.76E-08       WINT    = 6.75E-09       MOBMOD  = 1              
+BINUNIT = 2              DWG     = 0              DWB     = 0              
+VTH0    = '0.5120831+dvthn' LVTH0 = 8.764935E-09  WVTH0   = -1.873135E-08  
+PVTH0   = 7.727748E-15   K1      = 0.495975       LK1     = -1.730902E-08  
+WK1     = -3.479995E-08  PK1     = 2.24719E-14    K2      = -5.524951E-03  
+LK2     = 6.656464E-09   WK2     = 8.275826E-09   PK2     = -9.970717E-15  
+K3      = 0              DVT0    = 0              DVT1    = 0              
+DVT2    = 0              DVT0W   = 0              DVT1W   = 0              
+DVT2W   = 0              NLX     = 0              W0      = 0              
+K3B     = 0              VSAT    = 8.337681E+04   LVSAT   = -4.188861E-03  
+WVSAT   = -2.927345E-03  PVSAT   = 3.526865E-09   UA      = -2.692882E-09  
+LUA     = 1.14776E-15    WUA     = 1.397998E-15   PUA     = -4.54638E-22   
+UB      = 3.304871E-18   LUB     = -1.094117E-24  WUB     = -1.21371E-24   
+PUB     = 2.769152E-31   UC      = -9.571974E-12  LUC     = 1.084643E-17   
+WUC     = 1.036485E-17   PUC     = -1.2818E-23    RDSW    = 387.8871       
+PRWB    = 0              PRWG    = 0              WR      = 0.99           
+U0      = 0.01355998     LU0     = 1.598907E-08   WU0     = 1.512963E-08   
+PU0     = -7.836737E-15  A0      = -0.6656294     LA0     = 1.381343E-06   
+WA0     = 1.166525E-06   PA0     = -1.074278E-12  KETA    = -0.04893794    
+LKETA   = 1.278025E-08   WKETA   = 1.760996E-08   PKETA   = -7.315815E-16  
+A1      = 0.02686879     LA1     = -2.032352E-08  WA1     = -1.145846E-08  
+PA1     = 1.380516E-14   A2      = 1              AGS     = -1.432579      
+LAGS    = 1.589225E-06   WAGS    = 1.56788E-06    PAGS    = -1.573329E-12  
+B0      = 0              B1      = 0              VOFF    = -0.1632509     
+LVOFF   = 3.925541E-08   WVOFF   = 3.111126E-08   PVOFF   = -3.36448E-14   
+NFACTOR = 1.123145       LNFACTOR= 8.450812E-08   WNFACTOR= 1.02333E-07    
+PNFACTOR= -1.6622E-13    CIT     = 1.630248E-04   LCIT    = -1.862704E-10  
+WCIT    = -9.058234E-11  PCIT    = 1.091983E-16   CDSC    = 0              
+CDSCB   = 0              CDSCD   = 0              ETA0    = -3.663496E-05  
+LETA0   = 4.416466E-11   WETA0   = -2.120906E-11  PETA0   = 2.555269E-17   
+ETAB    = 0              DSUB    = 0              PCLM    = 4.634336       
+LPCLM   = -2.654898E-06  WPCLM   = -1.492681E-06  PPCLM   = 1.623682E-12   
+PDIBLC1 = 0              PDIBLC2 = -4.856500E-03  LPDIBLC2= 1.848586E-08   
+WPDIBLC2= 4.528896E-09   PPDIBLC2= -5.517896E-15  PDIBLCB = 0.1960524      
+LPDIBLCB= -5.854413E-08  WPDIBLCB= -1.361676E-08  PPDIBLCB= -1.713049E-14  
+DROUT   = 0              PSCBE1  = 4.474379E+08   LPSCBE1 = 72.47522       
+WPSCBE1 = 36.20206       PPSCBE1 = -4.403543E-05  PSCBE2  = 4.735455E-05   
+LPSCBE2 = -1.693901E-11  WPSCBE2 = -2.086376E-11  PPSCBE2 = 8.67609E-18    
+PVAG    = 0.2962652      LPVAG   = -1.448532E-07  WPVAG   = -1.737597E-07  
+PPVAG   = 8.495662E-14   DELTA   = -0.02702921    LDELTA  = 3.376959E-08   
+WDELTA  = 1.643913E-08   PDELTA  = -1.980587E-14  ALPHA0  = 0              
+BETA0   = 30             KT1     = -0.3292386     LKT1    = -5.139084E-09  
+WKT1    = -1.4075E-08    PKT1    = 1.695756E-14   KT2     = -0.03890148    
+LKT2    = -3.530056E-09  WKT2    = -2.749019E-09  PKT2    = 3.312019E-15   
+AT      = 4.457998E+04   LAT     = -0.01488528    WAT     = 5.854690E-03   
+PAT     = -7.053731E-09  UTE     = -1.916223      LUTE    = -1.47833E-07   
+WUTE    = 4.291675E-09   PUTE    = 7.228324E-14   UA1     = -1.334963E-10  
+LUA1    = 1.608363E-16   WUA1    = 7.829559E-17   PUA1    = -9.433052E-23  
+UB1     = 0              UC1     = 2.736447E-11   LUC1    = 1.998924E-17   
+WUC1    = -1.548909E-17  PUC1    = -1.441072E-23  KT1L    = 0              
+PRT     = -1E-18         CJ      = cjn            MJ      = 0.4960069      
+PB      = 0.9173808      CJSW    = cjswn          MJSW    = 0.443145       
+PBSW    = 0.9173808      CJSWG   = cjgaten        MJSWG   = 0.443145       
+PBSWG   = 0.9173808      HDIF    = hdifn          ACM     = 12             
+LDIF    = 1.2E-07        RSH     = 4.5            CTA     = 7.707813E-04   
+CTP     = 5.512283E-04   PTA     = 1.167715E-03   PTP     = 1.167715E-03   
+N       = 1              XTI     = 3              CGDO    = 'cgon'         
+CGSO    = 'cgon'         CAPMOD  = 0              NQSMOD  = 0              
+ELM     = 5              XPART   = 1              CGSL    = 0              
+CGDL    = 0              CKAPPA  = 0.6            CF      = 0              
+CLC     = 1E-07          CLE     = 0.6            JS      = 1E-06          
+JSW     = 5E-11           )
*
.model n.9          NMOS   (                     LMIN    = 2.4E-07
+LMAX    = '5.1E-07-dxl'  WMIN    = '6E-07-dxw'    WMAX    = '1.2E-06-dxw' 
+LEVEL   = 49             TNOM    = 25             XL      = '3E-8 + dxl'
+XW      = '0 + dxw'      VERSION = 3.1            TOX     = toxn           
+XJ      = 1E-07          NCH     = 2.354946E+17   LLN     = 1              
+LWN     = 1              WLN     = 1              WWN     = 1              
+LINT    = 1.76E-08       WINT    = 6.75E-09       MOBMOD  = 1              
+BINUNIT = 2              DWG     = 0              DWB     = 0              
+VTH0    = '0.4851089+dvthn' LVTH0 = 2.238153E-08  WVTH0   = -2.748251E-10  
+PVTH0   = -1.589107E-15  K1      = 0.4591525      LK1     = 1.27894E-09    
+WK1     = -4.806498E-08  PK1     = 2.916809E-14   K2      = 0.03127931     
+LK2     = -1.192233E-08  WK2     = -6.260591E-09  PK2     = -2.632732E-15  
+K3      = 0              DVT0    = 0              DVT1    = 0              
+DVT2    = 0              DVT0W   = 0              DVT1W   = 0              
+DVT2W   = 0              NLX     = 0              W0      = 0              
+K3B     = 0              VSAT    = 6.758037E+04   LVSAT   = 3.785186E-03   
+WVSAT   = 3.114187E-03   PVSAT   = 4.770995E-10   UA      = -8.138723E-10  
+LUA     = 1.99236E-16    WUA     = 9.656598E-16   PUA     = -2.363935E-22  
+UB      = 2.194702E-18   LUB     = -5.337039E-25  WUB     = -1.283989E-24  
+PUB     = 3.12392E-31    UC      = 6.612582E-11   LUC     = -2.736582E-17  
+WUC     = -4.804093E-17  PUC     = 1.666524E-23   RDSW    = 387.8871       
+PRWB    = 0              PRWG    = 0              WR      = 0.99           
+U0      = 0.03213844     LU0     = 6.610664E-09   WU0     = 7.552112E-09   
+PU0     = -4.011606E-15  A0      = 2.622718       LA0     = -2.786152E-07  
+WA0     = -1.848456E-06  PA0     = 4.476851E-13   KETA    = -0.07559809    
+LKETA   = 2.62383E-08    WKETA   = 3.106994E-08   PKETA   = -7.526186E-15  
+A1      = -0.02600059    LA1     = 6.364945E-09   WA1     = 3.08497E-08    
+PA1     = -7.552009E-15  A2      = 1              AGS     = 3.517003       
+LAGS    = -9.093239E-07  WAGS    = -3.256303E-06  PAGS    = 8.619184E-13   
+B0      = 0              B1      = 0              VOFF    = -0.07614343    
+LVOFF   = -4.716451E-09  WVOFF   = -4.695688E-08  PVOFF   = 5.764009E-15   
+NFACTOR = 0.6944715      LNFACTOR= 3.009024E-07   WNFACTOR= 1.410649E-07   
+PNFACTOR= -1.857719E-13  CIT     = -2.312463E-04  LCIT    = 1.275764E-11   
+WCIT    = -6.294739E-11  PCIT    = 9.524823E-17   CDSC    = 0              
+CDSCB   = 0              CDSCD   = 0              ETA0    = -5.957423E-05  
+LETA0   = 5.574441E-11   WETA0   = 7.59317E-11    PETA0   = -2.348397E-17  
+ETAB    = 4.661370E-03   LETAB   = -2.35306E-09   WETAB   = -1.342319E-09  
+PETAB   = 6.776026E-16   DSUB    = 0              PCLM    = -2.496264      
+LPCLM   = 9.446288E-07   WPCLM   = 3.622626E-06   PPCLM   = -9.585253E-13  
+PDIBLC1 = 0              PDIBLC2 = 0.02076947     LPDIBLC2= 5.54987E-09    
+WPDIBLC2= -8.474421E-09  PPDIBLC2= 1.046179E-15   PDIBLCB = -0.2029092     
+LPDIBLCB= 1.428517E-07   WPDIBLCB= 7.990297E-08   PPDIBLCB= -6.433925E-14  
+DROUT   = 0              PSCBE1  = 7.217503E+08   LPSCBE1 = -65.99773      
+WPSCBE1 = -145.2709      PPSCBE1 = 4.757214E-05   PSCBE2  = 2.829501E-05   
+LPSCBE2 = -7.317751E-12  WPSCBE2 = -1.293517E-11  PPSCBE2 = 4.673735E-18   
+PVAG    = 0.01114361     LPVAG   = -9.238048E-10  WPVAG   = -7.410052E-09  
+PPVAG   = 9.833084E-16   DELTA   = 0.02591161     LDELTA  = 7.045069E-09   
+WDELTA  = -3.870092E-08  PDELTA  = 8.028832E-15   ALPHA0  = 0              
+BETA0   = 30             KT1     = -0.3521225     LKT1    = 6.412733E-09   
+WKT1    = 3.887146E-08   PKT1    = -9.769814E-15  KT2     = -0.04396189    
+LKT2    = -9.755584E-10  WKT2    = -4.442279E-09  PKT2    = 4.166777E-15   
+AT      = 8.683487E+03   LAT     = 3.235270E-03   WAT     = -0.01105283    
+PAT     = 1.481186E-09   UTE     = -2.529454      LUTE    = 1.617261E-07   
+WUTE    = 2.53724E-07    PUTE    = -5.363024E-14  UA1     = -6.880983E-10  
+LUA1    = 4.407994E-16   WUA1    = 5.847268E-17   PUA1    = -8.432389E-23  
+UB1     = 0              UC1     = 1.64777E-10    LUC1    = -4.937662E-17  
+WUC1    = -1.17939E-16   PUC1    = 3.730601E-23   KT1L    = 0              
+PRT     = -1E-18         CJ      = cjn            MJ      = 0.4960069      
+PB      = 0.9173808      CJSW    = cjswn          MJSW    = 0.443145       
+PBSW    = 0.9173808      CJSWG   = cjgaten        MJSWG   = 0.443145       
+PBSWG   = 0.9173808      HDIF    = hdifn          ACM     = 12             
+LDIF    = 1.2E-07        RSH     = 4.5            CTA     = 7.707813E-04   
+CTP     = 5.512283E-04   PTA     = 1.167715E-03   PTP     = 1.167715E-03   
+N       = 1              XTI     = 3              CGDO    = 'cgon'         
+CGSO    = 'cgon'         CAPMOD  = 0              NQSMOD  = 0              
+ELM     = 5              XPART   = 1              CGSL    = 0              
+CGDL    = 0              CKAPPA  = 0.6            CF      = 0              
+CLC     = 1E-07          CLE     = 0.6            JS      = 1E-06          
+JSW     = 5E-11           )
*
.model n.10          NMOS   (                    LMIN    = '1.21E-06-dxl'
+LMAX    = '2.1E-5-dxl'   WMIN    = 3.0E-07        WMAX    = '6E-07-dxw'     
+LEVEL   = 49             TNOM    = 25             XL      = '3E-8 + dxl'
+XW      = '0 + dxw'      VERSION = 3.1            TOX     = toxn           
+XJ      = 1E-07          NCH     = 2.354946E+17   LLN     = 1              
+LWN     = 1              WLN     = 1              WWN     = 1              
+LINT    = 1.76E-08       WINT    = 6.75E-09       MOBMOD  = 1              
+BINUNIT = 2              DWG     = 0              DWB     = 0              
+VTH0    = '0.4749925+dvthn' LVTH0 = 5.198451E-08  WVTH0   = -1.691685E-08  
+PVTH0   = 6.402182E-15   K1      = 0.4775012      LK1     = -1.818087E-08  
+WK1     = -3.831493E-10  PK1     = -5.428248E-15  K2      = 5.389562E-15   
+LK2     = -1.07817E-19   K3      = 0              DVT0    = 0              
+DVT1    = 0              DVT2    = 0              DVT0W   = 0              
+DVT1W   = 0              DVT2W   = 0              NLX     = 0              
+W0      = 0              K3B     = 0              VSAT    = 6.681788E+04   
+LVSAT   = 0.01564629     WVSAT   = -3.589282E-06  PVSAT   = 7.180632E-11   
+UA      = 1.17135E-10    LUA     = -2.561826E-16  WUA     = -3.539521E-17  
+PUA     = 1.101259E-22   UB      = 1.026414E-18   LUB     = -2.846229E-25  
+WUB     = -6.258823E-26  PUB     = 2.526803E-32   UC      = -1.666444E-12  
+LUC     = 7.159695E-19   WUC     = 3.985861E-19   PUC     = -4.553018E-25  
+RDSW    = 387.8871       PRWB    = 0              PRWG    = 0              
+WR      = 0.99           U0      = 0.04640217     LU0     = -2.00866E-09   
+WU0     = -4.384901E-09  PU0     = 3.023248E-15   A0      = 1.838461       
+LA0     = -7.756182E-07  WA0     = -1.466137E-07  PA0     = 3.421681E-15   
+KETA    = -0.02585755    LKETA   = 9.128606E-09   WKETA   = 6.779302E-09   
+PKETA   = -1.850079E-15  A1      = 0.01393711     LA1     = -4.743436E-09  
+A2      = 1              AGS     = 0.3458827      LAGS    = 1.661894E-07   
+WAGS    = -2.815839E-08  PAGS    = -7.249991E-14  B0      = 0              
+B1      = 0              VOFF    = -0.1400116     LVOFF   = 3.269983E-08   
+WVOFF   = 3.299217E-09   PVOFF   = -1.271324E-14  NFACTOR = -0.04573279    
+LNFACTOR= 1.762946E-06   WNFACTOR= 1.731742E-07   PNFACTOR= -4.100269E-13  
+CIT     = 7.819197E-06   LCIT    = 8.665547E-13   WCIT    = -1.295544E-14  
+PCIT    = -4.820345E-21  CDSC    = 0              CDSCB   = 0              
+CDSCD   = 0              ETA0    = 2.261923E-08   LETA0   = -3.84603E-16   
+ETAB    = 0              DSUB    = 0              PCLM    = 10.82235       
+LPCLM   = -1.023148E-05  WPCLM   = -2.085742E-06  PPCLM   = 2.409318E-12   
+PDIBLC1 = 0              PDIBLC2 = 1.356842E-03   LPDIBLC2= 2.841111E-09   
+WPDIBLC2= -2.267124E-10  PPDIBLC2= 4.996865E-15   PDIBLCB = 0.09286096     
+LPDIBLCB= 1.248101E-07   WPDIBLCB= 3.625353E-09   PPDIBLCB= -7.25244E-14   
+DROUT   = 0              PSCBE1  = 3.516436E+08   LPSCBE1 = 187.1734       
+PSCBE2  = 2.599223E-05   LPSCBE2 = -1.926745E-11  PVAG    = 14.33847       
+LPVAG   = -1.787617E-05  WPVAG   = -3.728868E-06  PPVAG   = 4.845132E-12   
+DELTA   = 2.010881E-03   LDELTA  = -1.21791E-09   ALPHA0  = 0              
+BETA0   = 30             KT1     = -0.2929601     LKT1    = -5.786936E-08  
+WKT1    = -2.814523E-10  PKT1    = 5.630414E-15   KT2     = -0.03572946    
+LKT2    = -7.901914E-09  WKT2    = -1.716485E-11  PKT2    = 3.433783E-16   
+AT      = 159772.1       LAT     = -0.1398762     WAT     = 4.302851E-04   
+PAT     = -8.607784E-09  UTE     = -1.994088      LUTE    = -1.652676E-08  
+WUTE    = 1.036229E-07   PUTE    = -6.938157E-14  UA1     = 0              
+UB1     = 0              UC1     = 1.150038E-10   LUC1    = -1.394755E-16  
+WUC1    = -3.994551E-17  PUC1    = 4.665316E-23   KT1L    = 0              
+PRT     = -1E-18         CJ      = cjn            MJ      = 0.4960069      
+PB      = 0.9173808      CJSW    = cjswn          MJSW    = 0.443145       
+PBSW    = 0.9173808      CJSWG   = cjgaten        MJSWG   = 0.443145       
+PBSWG   = 0.9173808      HDIF    = hdifn          ACM     = 12             
+LDIF    = 1.2E-07        RSH     = 4.5            CTA     = 7.707813E-04   
+CTP     = 5.512283E-04   PTA     = 1.167715E-03   PTP     = 1.167715E-03   
+N       = 1              XTI     = 3              CGDO    = 'cgon'         
+CGSO    = 'cgon'         CAPMOD  = 0              NQSMOD  = 0              
+ELM     = 5              XPART   = 1              CGSL    = 0              
+CGDL    = 0              CKAPPA  = 0.6            CF      = 0              
+CLC     = 1E-07          CLE     = 0.6            JS      = 1E-06          
+JSW     = 5E-11           )
*
.model n.11          NMOS   (                    LMIN    = '5.1E-07-dxl' 
+LMAX    = '1.21E-06-dxl' WMIN    = 3.0E-07        WMAX    = '6E-07-dxw'      
+LEVEL   = 49             TNOM    = 25             XL      = '3E-8 + dxl'
+XW      = '0 + dxw'      VERSION = 3.1            TOX     = toxn           
+XJ      = 1E-07          NCH     = 2.354946E+17   LLN     = 1              
+LWN     = 1              WLN     = 1              WWN     = 1              
+LINT    = 1.76E-08       WINT    = 6.75E-09       MOBMOD  = 1              
+BINUNIT = 2              DWG     = 0              DWB     = 0              
+VTH0    = '0.5124911+dvthn' LVTH0 = 6.806128E-09  WVTH0   = -1.897065E-08  
+PVTH0   = 8.876588E-15   K1      = 0.4272733      LK1     = 4.233367E-08   
+WK1     = 5.493593E-09   PK1     = -1.250855E-14  K2      = 0.0167848      
+LK2     = -2.022233E-08  WK2     = -4.808846E-09  PK2     = 5.793698E-15   
+K3      = 0              DVT0    = 0              DVT1    = 0              
+DVT2    = 0              DVT0W   = 0              DVT1W   = 0              
+DVT2W   = 0              NLX     = 0              W0      = 0              
+K3B     = 0              VSAT    = 7.822123E+04   LVSAT   = 1.907523E-03   
+WVSAT   = 9.640249E-05   PVSAT   = -4.866398E-11  UA      = -5.919894E-10  
+LUA     = 5.981705E-16   WUA     = 1.658245E-16   PUA     = -1.323036E-22  
+UB      = 1.355927E-18   LUB     = -6.816204E-25  WUB     = -7.065415E-26  
+PUB     = 3.498582E-32   UC      = -8.728106E-12  LUC     = 9.223858E-18   
+WUC     = 9.869919E-18   PUC     = -1.186636E-23  RDSW    = 387.8871       
+PRWB    = 0              PRWG    = 0              WR      = 0.99           
+U0      = 0.04271699     LU0     = 2.431246E-09   WU0     = -1.970958E-09  
+PU0     = 1.149295E-16   A0      = 2.198391       LA0     = -1.209262E-06  
+WA0     = -5.132228E-07  PA0     = 4.451123E-13   KETA    = -0.02968962    
+LKETA   = 1.374549E-08   WKETA   = 6.320813E-09   PKETA   = -1.297692E-15  
+A1      = 7.331771E-03   LA1     = 3.214682E-09   A2      = 1              
+AGS     = 2.17154        LAGS    = -2.033362E-06  WAGS    = -5.459364E-07  
+PAGS    = 5.513189E-13   B0      = 0              B1      = 0              
+VOFF    = -0.07654053    LVOFF   = -4.377011E-08  WVOFF   = -1.974438E-08  
+PVOFF   = 1.504968E-14   NFACTOR = 1.900724       LNFACTOR= -5.821448E-07  
+WNFACTOR= -3.537173E-07  PNFACTOR= 2.247719E-13   CIT     = 8.55803E-06    
+LCIT    = -2.359085E-14  WCIT    = 1.244314E-14   PCIT    = -3.542055E-20  
+CDSC    = 0              CDSCB   = 0              CDSCD   = 0              
+ETA0    = -7.279705E-05  LETA0   = 8.773275E-11   ETAB    = 0              
+DSUB    = 0              PCLM    = 2.407983       LPCLM   = -9.384299E-08  
+WPCLM   = -1.869249E-07  PPCLM   = 1.216227E-13   PDIBLC1 = 0              
+PDIBLC2 = -8.640438E-03  LPDIBLC2= 1.488583E-08   WPDIBLC2= 6.748174E-09   
+PPDIBLC2= -3.406478E-15  PDIBLCB = 0.3559794      LPDIBLCB= -1.921951E-07  
+WPDIBLCB= -1.07414E-07   PPDIBLCB= 6.125579E-14   DROUT   = 0              
+PSCBE1  = 5.091634E+08   LPSCBE1 = -2.606499      PSCBE2  = 1.178122E-05   
+LPSCBE2 = -2.146017E-12  PVAG    = -0.8588293     LPVAG   = 4.335375E-07   
+WPVAG   = 5.037032E-07   PPVAG   = -2.542695E-13  DELTA   = 1.041322E-03   
+LDELTA  = -4.978441E-11  WDELTA  = -2.423519E-11  PDELTA  = 2.919856E-17   
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.3770615     
+LKT1    = 4.345605E-08   WKT1    = 1.397311E-08   PKT1    = -1.154349E-14  
+KT2     = -0.04599916    LKT2    = 4.471021E-09   WKT2    = 1.413771E-09   
+PKT2    = -1.380613E-15  AT      = 7.409398E+04   LAT     = -0.03665112    
+WAT     = -0.01145527    PAT     = 5.711935E-09   UTE     = -2.028027      
+LUTE    = 2.436214E-08   WUTE    = 6.986435E-08   PUTE    = -2.870921E-14  
+UA1     = 0              UB1     = 0              UC1     = 4.541511E-12   
+LUC1    = -6.390489E-18  WUC1    = -2.103421E-18  PUC1    = 1.060994E-24   
+KT1L    = 0              PRT     = -1E-18         CJ      = cjn
+MJ      = 0.4960069      PB      = 0.9173808      CJSW    = cjswn          
+MJSW    = 0.443145       PBSW    = 0.9173808      CJSWG   = cjgaten        
+MJSWG   = 0.443145       PBSWG   = 0.9173808      HDIF    = hdifn          
+ACM     = 12             LDIF    = 1.2E-07        RSH     = 4.5            
+CTA     = 7.707813E-04   CTP     = 5.512283E-04   PTA     = 1.167715E-03   
+PTP     = 1.167715E-03   N       = 1              XTI     = 3              
+CGDO    = 'cgon'         CGSO    = 'cgon'         CAPMOD  = 0              
+NQSMOD  = 0              ELM     = 5              XPART   = 1              
+CGSL    = 0              CGDL    = 0              CKAPPA  = 0.6            
+CF      = 0              CLC     = 1E-07          CLE     = 0.6            
+JS      = 1E-06          JSW     = 5E-11           )
*
.model n.12          NMOS   (                    LMIN    = 2.4E-07        
+LMAX    = '5.1E-07-dxl'  WMIN    = 3.0E-07        WMAX    = '6E-07-dxw'     
+LEVEL   = 49             TNOM    = 25             XL      = '3E-8 + dxl'
+XW      = '0 + dxw'      VERSION = 3.1            TOX     = toxn           
+XJ      = 1E-07          NCH     = 2.354946E+17   LLN     = 1              
+LWN     = 1              WLN     = 1              WWN     = 1              
+LINT    = 1.76E-08       WINT    = 6.75E-09       MOBMOD  = 1              
+BINUNIT = 2              DWG     = 0              DWB     = 0              
+VTH0    = '0.4847336+dvthn' LVTH0 = 2.081814E-08  WVTH0  = -5.470342E-11  
+PVTH0   = -6.721795E-16  K1      = 0.3281252      LK1     = 9.238362E-08   
+WK1     = 2.878255E-08   PK1     = -2.426481E-14  K2      = 0.0402824      
+LK2     = -3.208392E-08  WK2     = -1.154091E-08  PK2     = 9.192045E-15   
+K3      = 0              DVT0    = 0              DVT1    = 0              
+DVT2    = 0              DVT0W   = 0              DVT1W   = 0              
+DVT2W   = 0              NLX     = 0              W0      = 0              
+K3B     = 0              VSAT    = 7.586954E+04   LVSAT   = 3.094656E-03   
+WVSAT   = -1.747416E-03  PVSAT   = 8.820956E-10   UA      = 8.924498E-10   
+LUA     = -1.511745E-16  WUA     = -3.509821E-17  PUA     = -3.08778E-23   
+UB      = 8.928832E-21   LUB     = -1.655745E-27  WUB     = -2.03282E-27   
+PUB     = 3.4578E-34     UC      = -1.364265E-11  LUC     = 1.170473E-17   
+WUC     = -1.256705E-18  PUC     = -6.249644E-24  RDSW    = 387.8871       
+PRWB    = 0              PRWG    = 0              WR      = 0.99           
+U0      = 0.06005258     LU0     = -6.31976E-09   WU0     = -8.819531E-09  
+PU0     = 3.57209E-15    A0      = -1.468837      LA0     = 6.419548E-07   
+WA0     = 5.512414E-07   PA0     = -9.222928E-14  KETA    = -0.04922795    
+LKETA   = 2.360844E-08   WKETA   = 1.560385E-08   PKETA   = -5.98377E-15   
+A1      = 0.02659908     LA1     = -6.511454E-09  A2      = 1              
+AGS     = -4.01637       LAGS    = 1.090294E-06   WAGS    = 1.162021E-06   
+PAGS    = -3.108579E-13  B0      = 0              B1      = 0              
+VOFF    = -0.1829426     LVOFF   = 9.941631E-09   WVOFF   = 1.568082E-08   
+PVOFF   = -2.832958E-15  NFACTOR = 0.6790636      LNFACTOR= 3.454948E-08   
+WNFACTOR= 1.501016E-07   PNFACTOR= -2.955591E-14  CIT     = 2.218499E-04   
+LCIT    = -1.076934E-10  WCIT    = -3.286884E-10  PCIT    = 1.658928E-16   
+CDSC    = 0              CDSCB   = 0              CDSCD   = 0              
+ETA0    = 1.215578E-04   LETA0   = -1.037758E-11  WETA0   = -3.030225E-11  
+PETA0   = 1.529658E-17   ETAB    = 3.548681E-03   LETAB   = -1.791374E-09  
+WETAB   = -6.897268E-10  PETAB   = 3.481742E-16   DSUB    = 0              
+PCLM    = 3.583838       LPCLM   = -6.874146E-07  WPCLM   = 5.664574E-08   
+PPCLM   = -1.33176E-15   PDIBLC1 = 0              PDIBLC2 = 5.379674E-03   
+LPDIBLC2= 7.808481E-09   WPDIBLC2= 5.516945E-10   PPDIBLC2= -2.784957E-16  
+PDIBLCB = -0.1229374     LPDIBLCB= 4.956215E-08   WPDIBLCB= 3.299946E-08   
+PPDIBLCB= -9.624918E-15  DROUT   = 0              PSCBE1  = 4.472639E+08   
+LPSCBE1 = 28.64041       WPSCBE1 = 15.7154        PPSCBE1 = -7.933138E-06  
+PSCBE2  = 1.842585E-06   LPSCBE2 = 2.871008E-12   WPSCBE2 = 2.579183E-12   
+PPSCBE2 = -1.301972E-18  PVAG    = -2.015254E-03  LPVAG   = 1.017757E-09   
+WPVAG   = 3.07622E-10    PPVAG   = -1.55418E-16   DELTA   = -0.02862256    
+LDELTA  = 1.492454E-08   WDELTA  = -6.71663E-09   PDELTA  = 3.407521E-15   
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.2579945     
+LKT1    = -1.664895E-08  WKT1    = -1.633463E-08  PKT1    = 3.755864E-15   
+KT2     = -0.05347481    LKT2    = 8.244731E-09   WKT2    = 1.13705E-09    
+PKT2    = -1.240924E-15  AT      = -1.132632E+04  LAT     = 6.469047E-03   
+WAT     = 6.829220E-04   PAT     = -4.154249E-10  UTE     = -2.309089      
+LUTE    = 1.662427E-07   WUTE    = 1.244801E-07   PUTE    = -5.627924E-14  
+UA1     = -3.461758E-10  LUA1    = 1.747495E-16   WUA1    = -1.42065E-16   
+PUA1    = 7.171442E-23   UB1     = 0              UC1     = -2.38157E-12   
+LUC1    = -2.895726E-18  WUC1    = -1.990052E-17  PUC1    = 1.004497E-23   
+KT1L    = 0              PRT     = -1E-18         CJ      = cjn
+MJ      = 0.4960069      PB      = 0.9173808      CJSW    = cjswn          
+MJSW    = 0.443145       PBSW    = 0.9173808      CJSWG   = cjgaten        
+MJSWG   = 0.443145       PBSWG   = 0.9173808      HDIF    = hdifn          
+ACM     = 12             LDIF    = 1.2E-07        RSH     = 4.5            
+CTA     = 7.707813E-04   CTP     = 5.512283E-04   PTA     = 1.167715E-03   
+PTP     = 1.167715E-03   N       = 1              XTI     = 3              
+CGDO    = 'cgon'         CGSO    = 'cgon'         CAPMOD  = 0              
+NQSMOD  = 0              ELM     = 5              XPART   = 1              
+CGSL    = 0              CGDL    = 0              CKAPPA  = 0.6            
+CF      = 0              CLC     = 1E-07          CLE     = 0.6            
+JS      = 1E-06          JSW     = 5E-11          )
*
***************************************************************
*                 PMOS DEVICES MODEL                          *
***************************************************************
.model p.1 PMOS (                                LEVEL   = 49                 
+VERSION = 3.1            LMIN    = '1.20E-6-dxl'  LMAX    = '2.1E-5-dxl'  
+WMIN    = '1E-5-dxw'     WMAX    = '1.01E-4-dxw'  XL      = '3e-8+dxl'     
+XW      = '0+dxw'        TNOM    = 25             TOX     = toxp          
+XJ      = 1E-7           NCH     = 4.1589E17          
+LLN     = 1              LWN     = 1              WLN     = 1                  
+WWN     = 1              LINT    = 1.2365E-8      WINT    = 7.8E-9             
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0                  
+DWB     = 0              VTH0    = 'dvthp-0.6413387'  LVTH0   = -6.558956E-8 
+WVTH0   = 1.990676E-7    PVTH0   = 4.527135E-13   K1      = 0.6439384          
+LK1     = 1.723606E-8    WK1     = 2.217245E-8    PK1     = -4.43566E-13       
+K2      = -5.810239E-3   LK2     = 4.785001E-12   K3      = 0                  
+DVT0    = 0              DVT1    = 0              DVT2    = 0                  
+DVT0W   = 0              DVT1W   = 0              DVT2W   = 0                  
+NLX     = 0              W0      = 0              K3B     = 0                  
+VSAT    = 1.41E5         UA      = 5.182996E-10   LUA     = 1.520285E-16       
+WUA     = 7.258698E-16   PUA     = -1.51791E-21   UB      = 6.465259E-19       
+LUB     = 1.335173E-25   WUB     = 1.211736E-25   PUB     = -2.42411E-30       
+UC      = -8.77643E-11   LUC     = 5.943362E-17   WUC     = 1.713747E-16       
+PUC     = -5.93409E-22   RDSW    = 1.03E3         PRWB    = 0                  
+PRWG    = 0              WR      = 1              U0      = 0.0100835          
+LU0     = 4.487984E-10   WU0     = 2.880001E-10   PU0     = -5.76152E-15       
+A0      = 1.7593143      LA0     = -3.125438E-7   WA0     = -7.863855E-7       
+PA0     = 9.478069E-13   KETA    = 4.521459E-4    LKETA   = -2.484942E-8       
+WKETA   = -6.186675E-9   PKETA   = 1.237661E-13   A1      = 0                  
+A2      = 0.4            AGS     = 0.2817301      LAGS    = 9.472343E-8        
+WAGS    = 1.349982E-11   PAGS    = -2.70067E-16   B0      = 0                  
+B1      = 0              VOFF    = -0.1168423     LVOFF   = -1.637201E-9       
+WVOFF   = -8.347608E-8   PVOFF   = 1.694334E-14   NFACTOR = 0.6469985          
+LNFACTOR= 3.065458E-11   CIT     = 7.970132E-4    LCIT    = -2.64573E-13       
+CDSC    = 0              CDSCB   = 0              CDSCD   = 0                  
+ETA0    = 1.602731E-5    LETA0   = 7.94747E-11    WETA0   = 1.066676E-13       
+PETA0   = -2.13392E-18   ETAB    = 0              DSUB    = 0                  
+PCLM    = 0.6662269      LPCLM   = 1.3973E-6      WPCLM   = 3.348465E-11       
+PPCLM   = -6.69869E-16   PDIBLC1 = 0              PDIBLC2 = 1.824584E-4        
+LPDIBLC2= 4.309455E-10   WPDIBLC2= -3.84001E-11   PPDIBLC2= 7.682038E-16       
+PDIBLCB = 0.1921199      DROUT   = 0              PSCBE1  = 7.19E8             
+PSCBE2  = 1E-20          PVAG    = -1.585648E-7   LPVAG   = 1.911134E-13       
+DELTA   = 0.01           ALPHA0  = 0              BETA0   = 30                 
+KT1     = -0.2394749     LKT1    = -2.077719E-8   WKT1    = -5.289451E-7       
+PKT1    = 2.074478E-13   KT2     = -0.0176408     LKT2    = -2.304767E-8       
+WKT2    = -1.909258E-7   PKT2    = 2.301171E-13   AT      = 1E4                
+UTE     = -1.0231078     LUTE    = -1.479736E-8   WUTE    = -1.688959E-6       
+PUTE    = 1.479505E-12   UA1     = 3.56765E-10    LUA1    = 5.119645E-17       
+WUA1    = 4.241089E-16   PUA1    = -5.11166E-22   UB1     = -5.32636E-19       
+LUB1    = -7.30662E-25   WUB1    = -6.05277E-24   PUB1    = 7.295223E-30       
+UC1     = -1.00699E-12   KT1L    = 0              PRT     = 0                  
+CJ      = cjp            MJ      = 0.4812153      PB      = 0.9134669          
+CJSW    = cjswp          MJSW    = 0.3237595      PBSW    = 0.9134669          
+CJSWG   = cjgatep        MJSWG   = 0.3237595      PBSWG   = 0.9134669          
+HDIF    = hdifp          LDIF    = 1.2E-7         ACM     = 12                 
+RS      = 0              RD      = 0              RSH     = 3.5                
+CTA     = 8.3043E-4      CTP     = 4.30175E-4     PTA     = 1.3004E-3          
+PTP     = 1.3004E-3      CGDO    = cgop           CGSO    = cgop           
+CAPMOD  = 0              NQSMOD  = 0              ELM     = 5                  
+XPART   = 1              CF      = 0              TLEV    = 1                  
+TLEVC   = 1              JS      = 3E-7           JSW     = 5E-12           )  
*       
.model p.2 PMOS (                                LEVEL   = 49                 
+VERSION = 3.1            LMIN    = '5.0E-7-dxl'   LMAX    = '1.2E-6-dxl'
+WMIN    = '1E-5-dxw'     WMAX    = '1.01E-4-dxw'  XL      = '3e-8+dxl'     
+XW      = '0+dxw'        TNOM    = 25             TOX     = toxp          
+XJ      = 1E-7           NCH     = 4.1589E17          
+LLN     = 1              LWN     = 1              WLN     = 1                  
+WWN     = 1              LINT    = 1.2365E-8      WINT    = 7.8E-9             
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0                  
+DWB     = 0              VTH0    = 'dvthp-0.7114595'  LVTH0   = 1.892485E-8 
+WVTH0   = 6.860486E-7    PVTH0   = -1.34230E-13   K1      = 0.6330663          
+LK1     = 3.033991E-8    WK1     = -2.833355E-7   PK1     = -7.53465E-14       
+K2      = 5.016417E-3    LK2     = -1.304426E-8   K3      = 0                  
+DVT0    = 0              DVT1    = 0              DVT2    = 0                  
+DVT0W   = 0              DVT1W   = 0              DVT2W   = 0                  
+NLX     = 0              W0      = 0              K3B     = 0                  
+VSAT    = 1.459634E5     LVSAT   = -5.982263E-3   WVSAT   = -0.4627777         
+PVSAT   = 5.577721E-7    UA      = 8.734954E-10   LUA     = -2.76078E-16       
+WUA     = -2.98139E-16   PUA     = -2.83707E-22   UB      = 5.519431E-19       
+LUB     = 2.475151E-25   WUB     = -2.18192E-24   PUB     = 3.517375E-31       
+UC      = -6.69541E-11   LUC     = 3.435179E-17   WUC     = -2.75670E-16       
+PUC     = -5.45990E-23   RDSW    = 1.03E3         PRWB    = 0                  
+PRWG    = 0              WR      = 1              U0      = 0.0105634          
+LU0     = -1.29609E-10   WU0     = -4.60556E-9    PU0     = 1.365406E-16       
+A0      = 1.910224       LA0     = -4.944307E-7   WA0     = -2.377908E-6       
+PA0     = 2.866021E-12   KETA    = -0.0136134     LKETA   = -7.896579E-9       
+WKETA   = 4.766175E-8    PKETA   = 5.886425E-14   A1      = 0                  
+A2      = 0.4            AGS     = 0.408117       LAGS    = -5.760699E-8       
+WAGS    = 3.519617E-8    PAGS    = -4.26747E-14   B0      = 0                  
+B1      = 0              VOFF    = -0.1323205     LVOFF   = 1.70182E-8         
+WVOFF   = 3.397148E-8    PVOFF   = -1.24613E-13   NFACTOR = 0.4558186          
+LNFACTOR= 2.304541E-7    CIT     = 1.14792E-3     LCIT    = -4.23202E-10       
+CDSC    = 0              CDSCB   = 0              CDSCD   = 0                  
+ETA0    = 1.66552E-5     LETA0   = 7.871791E-11   WETA0   = -4.17916E-10       
+PETA0   = 5.016967E-16   ETAB    = 3.101491E-4    LETAB   = -3.73813E-10       
+DSUB    = 0              PCLM    = 1.8009619      LPCLM   = 2.963821E-8        
+WPCLM   = -8.99301E-10   PPCLM   = 4.543899E-16   PDIBLC1 = 0                  
+PDIBLC2 = -1.055193E-3   LPDIBLC2= 1.92265E-9     WPDIBLC2= 1.031316E-9        
+PPDIBLC2= -5.21093E-16   PDIBLCB = 0.1921199      DROUT   = 0                  
+PSCBE1  = 7.19E8         PSCBE2  = 1E-20          PVAG    = 0                  
+DELTA   = 0.01           ALPHA0  = 0              BETA0   = 30                 
+KT1     = -0.2309169     LKT1    = -3.109184E-8   WKT1    = -6.143911E-7       
+PKT1    = 3.104334E-13   KT2     = -0.0367632     AT      = 1E4                
+UTE     = -0.9986951     LUTE    = -4.422114E-8   WUTE    = -1.127561E-6       
+PUTE    = 8.028689E-13   UA1     = 3.992421E-10   UB1     = -1.13886E-18       
+UC1     = -1.00699E-12   KT1L    = 0              PRT     = 0              
+CJ      = cjp            MJ      = 0.4812153          
+PB      = 0.9134669      CJSW    = cjswp          MJSW    = 0.3237595          
+PBSW    = 0.9134669      CJSWG   = cjgatep        MJSWG   = 0.3237595          
+PBSWG   = 0.9134669      HDIF    = hdifp          LDIF    = 1.2E-7             
+ACM     = 12             RS      = 0              RD      = 0                  
+RSH     = 3.5            CTA     = 8.3043E-4      CTP     = 4.30175E-4         
+PTA     = 1.3004E-3      PTP     = 1.3004E-3      CGDO    = cgop  
+CGSO    = cgop           CAPMOD  = 0              NQSMOD  = 0                  
+ELM     = 5              XPART   = 1              CF      = 0                  
+TLEV    = 1              TLEVC   = 1              JS      = 3E-7               
+JSW     = 5E-12           )                                                    
*       
.model p.3 PMOS (                                LEVEL   = 49                 
+VERSION = 3.1            LMIN    = 2.4E-7         LMAX    = '5.0E-7-dxl'    
+WMIN    = '1E-5-dxw'     WMAX    = '1.01E-4-dxw'  XL      = '3e-8+dxl'     
+XW      = '0+dxw'        TNOM    = 25             TOX     = toxp          
+XJ      = 1E-7           NCH     = 4.1589E17          
+LLN     = 1              LWN     = 1              WLN     = 1                  
+WWN     = 1              LINT    = 1.2365E-8      WINT    = 7.8E-9             
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0                  
+DWB     = 0              VTH0    = 'dvthp-0.763313'  LVTH0   = 4.51249E-8 
+WVTH0   = 7.667344E-7    PVTH0   = -1.74998E-13   K1      = 0.738312           
+LK1     = -2.283758E-8   WK1     = -8.404132E-7   PK1     = 2.061281E-13       
+K2      = 0.0167397      LK2     = -1.896769E-8   K3      = 0                  
+DVT0    = 0              DVT1    = 0              DVT2    = 0                  
+DVT0W   = 0              DVT1W   = 0              DVT2W   = 0                  
+NLX     = 0              W0      = 0              K3B     = 0                  
+VSAT    = 1.227019E5     LVSAT   = 5.771108E-3    WVSAT   = 1.4930081          
+PVSAT   = -4.304277E-7   UA      = 5.457064E-10   LUA     = -1.10456E-16       
+WUA     = -1.28383E-15   PUA     = 2.143336E-22   UB      = 6.180035E-19       
+LUB     = 2.141367E-25   WUB     = -3.34256E-25   PUB     = -5.81830E-31       
+UC      = 8.268225E-12   LUC     = -3.65580E-18   WUC     = -5.26610E-16       
+PUC     = 7.219351E-23   RDSW    = 1.03E3         PRWB    = 0                  
+PRWG    = 0              WR      = 1              U0      = 8.868651E-3        
+LU0     = 7.267038E-10   WU0     = -7.378679E-9   PU0     = 1.537714E-15       
+A0      = 0.3369117      LA0     = 3.005167E-7    WA0     = 1.015223E-5        
+PA0     = -3.46508E-12   KETA    = -0.0523715     LKETA   = 1.16867E-8         
+WKETA   = 2.912088E-7    PKETA   = -6.41927E-14   A1      = 0                  
+A2      = 0.4            AGS     = 0.0336813      LAGS    = 1.315841E-7        
+WAGS    = -1.523918E-6   PAGS    = 7.45099E-13    B0      = 0                  
+B1      = 0              VOFF    = -0.0896817     LVOFF   = -4.525919E-9       
+WVOFF   = -4.132613E-7   PVOFF   = 1.013606E-13   NFACTOR = 1.5081245          
+LNFACTOR= -3.012444E-7   CIT     = -7.63131E-4    LCIT    = 5.423945E-10       
+CDSC    = 0              CDSCB   = 0              CDSCD   = 0                  
+ETA0    = -4.413257E-3   LETA0   = 2.31702E-9     WETA0   = 5.57773E-9         
+PETA0   = -2.52772E-15   ETAB    = 2.221426E-3    LETAB   = -1.339524E-9       
+DSUB    = 0              PCLM    = 1.3553969      LPCLM   = 2.547687E-7        
+WPCLM   = -4.509466E-6   PPCLM   = 2.278498E-12   PDIBLC1 = 0                  
+PDIBLC2 = -3.122018E-3   LPDIBLC2= 2.966955E-9    WPDIBLC2= -5.02259E-11       
+PPDIBLC2= 2.537762E-17   PDIBLCB = 0.1921199      DROUT   = 0                  
+PSCBE1  = 7.19E8         PSCBE2  = 1E-20          PVAG    = 0                  
+DELTA   = 0.01           ALPHA0  = 0              BETA0   = 30                 
+KT1     = -0.2924017     LKT1    = -2.54074E-11   WKT1    = -5.02064E-10       
+PKT1    = 2.536777E-16   KT2     = -0.0367247     LKT2    = -1.94718E-11       
+WKT2    = -3.84773E-10   PKT2    = 1.944141E-16   AT      = 1E4                
+UTE     = -1.1298118     LUTE    = 2.202813E-8    WUTE    = 8.967165E-7        
+PUTE    = -2.19938E-13   UA1     = 3.994959E-10   LUA1    = -1.28204E-19       
+WUA1    = -2.53337E-18   PUA1    = 1.280037E-24   UB1     = -5.40304E-19       
+LUB1    = -3.02432E-25   WUB1    = -5.97621E-24   PUB1    = 3.0196E-30         
+UC1     = -1.00383E-12   LUC1    = -1.59442E-21   WUC1    = -3.15065E-20       
+PUC1    = 1.59193E-26    KT1L    = 0              PRT     = 0              
+CJ      = cjp            MJ      = 0.4812153          
+PB      = 0.9134669      CJSW    = cjswp          MJSW    = 0.3237595          
+PBSW    = 0.9134669      CJSWG   = cjgatep        MJSWG   = 0.3237595          
+PBSWG   = 0.9134669      HDIF    = hdifp          LDIF    = 1.2E-7             
+ACM     = 12             RS      = 0              RD      = 0                  
+RSH     = 3.5            CTA     = 8.3043E-4      CTP     = 4.30175E-4         
+PTA     = 1.3004E-3      PTP     = 1.3004E-3      CGDO    = cgop  
+CGSO    = cgop           CAPMOD  = 0              NQSMOD  = 0                  
+ELM     = 5              XPART   = 1              CF      = 0                  
+TLEV    = 1              TLEVC   = 1              JS      = 3E-7               
+JSW     = 5E-12           )                                                    
*       
.model p.4 PMOS (                                LEVEL   = 49                 
+VERSION = 3.1            LMIN    = '1.20E-6-dxl'  LMAX    = '2.1E-5-dxl'    
+WMIN    = '1.2E-6-dxw'   WMAX    = '1E-5-dxw'     XL      = '3e-8+dxl'     
+XW      = '0+dxw'        TNOM    = 25             TOX     = toxp          
+XJ      = 1E-7           NCH     = 4.1589E17          
+LLN     = 1              LWN     = 1              WLN     = 1                  
+WWN     = 1              LINT    = 1.2365E-8      WINT    = 7.8E-9             
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0                  
+DWB     = 0              VTH0    = 'dvthp-0.6255264'  LVTH0   = -2.28345E-8
+WVTH0   = 4.119069E-8    PVTH0   = 2.582992E-14   K1      = 0.6528723          
+LK1     = -3.224756E-8   WK1     = -6.702707E-8   PK1     = 5.04982E-14        
+K2      = -5.810239E-3   LK2     = 4.785001E-12   K3      = 0                  
+DVT0    = 0              DVT1    = 0              DVT2    = 0                  
+DVT0W   = 0              DVT1W   = 0              DVT2W   = 0                  
+NLX     = 0              W0      = 0              K3B     = 0                  
+VSAT    = 1.41E5         UA      = 5.855996E-10   LUA     = 1.121328E-17       
+WUA     = 5.391975E-17   PUA     = -1.11958E-22   UB      = 6.586622E-19       
+LUB     = -1.09272E-25   UC      = -6.41184E-11   LUC     = -5.62218E-18       
+WUC     = -6.47153E-17   PUC     = 5.613405E-23   RDSW    = 1.03E3             
+PRWB    = 0              PRWG    = 0              WR      = 1                  
+U0      = 0.0100829      LU0     = -2.70074E-11   WU0     = 2.940821E-10       
+PU0     = -1.01089E-15   A0      = 1.7181934      LA0     = -2.873148E-7       
+WA0     = -3.758184E-7   PA0     = 6.959106E-13   KETA    = -2.734731E-4       
+LKETA   = -1.232573E-8   WKETA   = 1.058172E-9    PKETA   = -1.27538E-15       
+A1      = 0              A2      = 0.4            AGS     = 0.2916126          
+LAGS    = 8.278692E-8    WAGS    = -9.865731E-8   PAGS    = 1.189087E-13       
+B0      = 0              B1      = 0              VOFF    = -0.125203          
+LVOFF   = 5.978026E-11   NFACTOR = 0.6469985      LNFACTOR= 3.065458E-11       
+CIT     = 7.970132E-4    LCIT    = -2.64573E-13   CDSC    = 0                  
+CDSCB   = 0              CDSCD   = 0              ETA0    = 9.372549E-6        
+LETA0   = 8.729463E-11   WETA0   = 6.655041E-11   PETA0   = -8.02112E-17       
+ETAB    = 0              DSUB    = 0              PCLM    = 0.6036321          
+LPCLM   = 1.472681E-6    WPCLM   = 6.250053E-7    PPCLM   = -7.53300E-13       
+PDIBLC1 = 0              PDIBLC2 = 1.210381E-4    LPDIBLC2= 5.772785E-10       
+WPDIBLC2= 5.748446E-10   PPDIBLC2= -6.92843E-16   PDIBLCB = 0.1921199          
+DROUT   = 0              PSCBE1  = 7.19E8         PSCBE2  = 1E-20              
+PVAG    = -1.585648E-7   LPVAG   = 1.911134E-13   DELTA   = 0.01               
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.292452          
+KT2     = -0.0367632     AT      = 1E4            UTE     = -1.199356          
+LUTE    = 1.351795E-7    WUTE    = 7.077414E-8    PUTE    = -1.79244E-14       
+UA1     = 3.906446E-10   WUA1    = 8.584079E-17   UB1     = -1.13886E-18       
+UC1     = -1.00699E-12   KT1L    = 0              PRT     = 0                  
+CJ      = cjp            MJ      = 0.4812153      PB      = 0.9134669          
+CJSW    = cjswp          MJSW    = 0.3237595      PBSW    = 0.9134669          
+CJSWG   = cjgatep        MJSWG   = 0.3237595      PBSWG   = 0.9134669          
+HDIF    = hdifp          LDIF    = 1.2E-7         ACM     = 12                 
+RS      = 0              RD      = 0              RSH     = 3.5                
+CTA     = 8.3043E-4      CTP     = 4.30175E-4     PTA     = 1.3004E-3          
+PTP     = 1.3004E-3      CGDO    = cgop           CGSO    = cgop               
+CAPMOD  = 0              NQSMOD  = 0              ELM     = 5                  
+XPART   = 1              CF      = 0              TLEV    = 1                  
+TLEVC   = 1              JS      = 3E-7           JSW     = 5E-12           )  
*       
.model p.5 PMOS (                                LEVEL   = 49                 
+VERSION = 3.1            LMIN    = '5.0E-7-dxl'   LMAX    = '1.2E-6-dxl'
+WMIN    = '1.2E-6-dxw'   WMAX    = '1E-5-dxw'     XL      = '3e-8+dxl'     
+XW      = '0+dxw'        TNOM    = 25             TOX     = toxp          
+XJ      = 1E-7           NCH     = 4.1589E17          
+LLN     = 1              LWN     = 1              WLN     = 1                  
+WWN     = 1              LINT    = 1.2365E-8      WINT    = 7.8E-9             
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0                  
+DWB     = 0              VTH0    = 'dvthp-0.6487376'  LVTH0   = 5.14129E-9   
+WVTH0   = 5.980856E-8    PVTH0   = 3.390362E-15   K1      = 0.6027586          
+LK1     = 2.815305E-8    WK1     = 1.926907E-8    PK1     = -5.35120E-14       
+K2      = 6.303799E-3    LK2     = -1.45959E-8    WK2     = -1.285373E-8       
+PK2     = 1.549222E-14   K3      = 0              DVT0    = 0                  
+DVT1    = 0              DVT2    = 0              DVT0W   = 0                  
+DVT1W   = 0              DVT2W   = 0              NLX     = 0                  
+W0      = 0              K3B     = 0              VSAT    = 9.471953E4         
+LVSAT   = 0.0557805      WVSAT   = 0.0488618      PVSAT   = -5.889167E-8       
+UA      = 8.803747E-10   LUA     = -3.44070E-16   WUA     = -3.66824E-16       
+PUA     = 3.95152E-22    UB      = 2.979222E-19   LUB     = 3.255167E-25       
+WUB     = 3.543287E-25   PUB     = -4.27062E-31   UC      = -9.55254E-11       
+LUC     = 3.223174E-17   WUC     = 9.596388E-18   PUC     = -3.34316E-23       
+RDSW    = 1.03E3         PRWB    = 0              PRWG    = 0                  
+WR      = 1              U0      = 0.0102182      LU0     = -1.90079E-10       
+WU0     = -1.158852E-9   PU0     = 7.402912E-16   A0      = 1.6643689          
+LA0     = -2.224416E-7   WA0     = 7.680865E-8    PA0     = 1.503728E-13       
+KETA    = -8.762106E-3   LKETA   = -2.094631E-9   WKETA   = -7.75986E-10       
+PKETA   = 9.352726E-16   A1      = 0              A2      = 0.4                
+AGS     = 0.4200659      LAGS    = -7.203406E-8   WAGS    = -8.410634E-8       
+PAGS    = 1.013708E-13   B0      = 0              B1      = 0                  
+VOFF    = -0.1286433     LVOFF   = 4.206296E-9    WVOFF   = -2.743397E-9       
+PVOFF   = 3.306534E-15   NFACTOR = 0.4119358      LNFACTOR= 2.833446E-7        
+WNFACTOR= 4.381429E-7    PNFACTOR= -5.28080E-13   CIT     = 1.218123E-3        
+LCIT    = -5.07816E-10   WCIT    = -7.00936E-10   PCIT    = 8.448168E-16       
+CDSC    = 0              CDSCB   = 0              CDSCD   = 0                  
+ETA0    = -6.733725E-7   LETA0   = 9.940269E-11   WETA0   = -2.44901E-10       
+PETA0   = 2.951716E-16   ETAB    = 3.085655E-4    LETAB   = -3.71905E-10       
+WETAB   = 1.581165E-11   PETAB   = -1.90573E-17   DSUB    = 0                  
+PCLM    = 1.843225       LPCLM   = -2.136339E-8   WPCLM   = -4.228719E-7       
+PPCLM   = 5.096747E-13   PDIBLC1 = 0              PDIBLC2 = -1.083052E-3       
+LPDIBLC2= 2.028533E-9    WPDIBLC2= 1.309474E-9    PPDIBLC2= -1.57827E-15       
+PDIBLCB = 0.1921199      DROUT   = 0              PSCBE1  = 7.19E8             
+PSCBE2  = 1E-20          PVAG    = 0              DELTA   = 0.01               
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.292452          
+KT2     = -0.0367632     AT      = 1E4            UTE     = -1.1212678         
+LUTE    = 4.10622E-8     WUTE    = 9.625366E-8    PUTE    = -4.86341E-14       
+UA1     = 3.844388E-10   LUA1    = 7.479652E-18   WUA1    = 1.478019E-16       
+PUA1    = -7.46798E-23   UB1     = -1.13886E-18   UC1     = -1.00699E-12       
+KT1L    = 0              PRT     = 0              CJ      = cjp                
+MJ      = 0.4812153      PB      = 0.9134669      CJSW    = cjswp              
+MJSW    = 0.3237595      PBSW    = 0.9134669      CJSWG   = cjgatep            
+MJSWG   = 0.3237595      PBSWG   = 0.9134669      HDIF    = hdifp              
+LDIF    = 1.2E-7         ACM     = 12             RS      = 0                  
+RD      = 0              RSH     = 3.5            CTA     = 8.3043E-4          
+CTP     = 4.30175E-4     PTA     = 1.3004E-3      PTP     = 1.3004E-3          
+CGDO    = cgop           CGSO    = cgop           CAPMOD  = 0                  
+NQSMOD  = 0              ELM     = 5              XPART   = 1                  
+CF      = 0              TLEV    = 1              TLEVC   = 1                  
+JS      = 3E-7           JSW     = 5E-12           )                           
*       
.model p.6 PMOS (                                LEVEL   = 49                 
+VERSION = 3.1            LMIN    = 2.4E-7         LMAX    = '5.0E-7-dxl'      
+WMIN    = '1.2E-6-dxw'   WMAX    = '1E-5-dxw'     XL      = '3e-8+dxl'     
+XW      = '0+dxw'        TNOM    = 25             TOX     = toxp          
+XJ      = 1E-7           NCH     = 4.1589E17          
+LLN     = 1              LWN     = 1              WLN     = 1                  
+WWN     = 1              LINT    = 1.2365E-8      WINT    = 7.8E-9             
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0                  
+DWB     = 0              VTH0    = 'dvthp-0.6954928'  LVTH0   = 2.87653E-8
+WVTH0   = 8.959028E-8    PVTH0   = -1.16574E-14   K1      = 0.6574672          
+LK1     = 5.10387E-10    WK1     = -3.322696E-8   PK1     = -2.69873E-14       
+K2      = 0.017654       LK2     = -2.03308E-8    WK2     = -9.128389E-9       
+PK2     = 1.360991E-14   K3      = 0              DVT0    = 0                  
+DVT1    = 0              DVT2    = 0              DVT0W   = 0                  
+DVT1W   = 0              DVT2W   = 0              NLX     = 0                  
+W0      = 0              K3B     = 0              VSAT    = 2.869824E5         
+LVSAT   = -0.0413642     WVSAT   = -0.1472348     PVSAT   = 4.019004E-8        
+UA      = 3.875896E-10   LUA     = -9.50808E-17   WUA     = 2.948711E-16       
+PUA     = 6.081734E-23   UB      = 5.869413E-19   LUB     = 1.79484E-25        
+WUB     = -2.41186E-26   PUB     = -2.35844E-31   UC      = -4.34123E-11       
+LUC     = 5.900587E-18   WUC     = -1.06113E-17   PUC     = -2.32212E-23       
+RDSW    = 1.03E3         PRWB    = 0              PRWG    = 0                  
+WR      = 1              U0      = 7.882399E-3    LU0     = 9.90134E-10        
+WU0     = 2.468454E-9    PU0     = -1.09248E-15   A0      = 1.3869886          
+LA0     = -8.22897E-8    WA0     = -3.321558E-7   PA0     = 3.570102E-13       
+KETA    = -0.0231896     LKETA   = 5.195164E-9    WKETA   = -1.54596E-10       
+PKETA   = 6.213031E-16   A1      = 0              A2      = 0.4                
+AGS     = -0.1626683     LAGS    = 2.22404E-7     WAGS    = 4.365136E-7        
+PAGS    = -1.61683E-13   B0      = 0              B1      = 0                  
+VOFF    = -0.1323654     LVOFF   = 6.08695E-9     WVOFF   = 1.290973E-8        
+PVOFF   = -4.60252E-15   NFACTOR = 1.6369926      LNFACTOR= -3.356397E-7       
+WNFACTOR= -1.28667E-6    PNFACTOR= 3.434156E-13   CIT     = -9.697059E-4       
+LCIT    = 5.976283E-10   WCIT    = 2.062526E-9    PCIT    = -5.51477E-16       
+CDSC    = 0              CDSCB   = 0              CDSCD   = 0                  
+ETA0    = -4.081364E-3   LETA0   = 2.161253E-9    WETA0   = 2.263976E-9        
+PETA0   = -9.72488E-16   ETAB    = 2.362597E-3    LETAB   = -1.409745E-9       
+WETAB   = -1.409507E-9   PETAB   = 7.011133E-16   DSUB    = 0                  
+PCLM    = 0.7656701      LPCLM   = 5.230927E-7    WPCLM   = 1.378602E-6        
+PPCLM   = -4.00556E-13   PDIBLC1 = 0              PDIBLC2 = -2.771409E-3       
+LPDIBLC2= 2.881608E-9    WPDIBLC2= -3.550861E-9   PPDIBLC2= 8.775114E-16       
+PDIBLCB = 0.1921199      DROUT   = 0              PSCBE1  = 7.19E8             
+PSCBE2  = 1E-20          PVAG    = 0              DELTA   = 0.01               
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.2924581         
+WKT1    = 6.082539E-11   PKT1    = -3.07332E-17   KT2     = -0.0367679         
+LKT2    = 2.359021E-12   WKT2    = 4.661549E-11   PKT2    = -2.35534E-17       
+AT      = 1E4            UTE     = -1.04          UA1     = 3.790111E-10       
+LUA1    = 1.022212E-17   WUA1    = 2.019945E-16   PUA1    = -1.02062E-22       
+UB1     = -1.13900E-18   LUB1    = 7.317045E-29   WUB1    = 1.445887E-27       
+PUB1    = -7.30563E-34   UC1     = -1.00737E-12   LUC1    = 1.931648E-22       
+WUC1    = 3.817037E-21   PUC1    = -1.92863E-27   KT1L    = 0                  
+PRT     = 0              CJ      = cjp            MJ      = 0.4812153          
+PB      = 0.9134669      CJSW    = cjswp          MJSW    = 0.3237595          
+PBSW    = 0.9134669      CJSWG   = cjgatep        MJSWG   = 0.3237595          
+PBSWG   = 0.9134669      HDIF    = hdifp          LDIF    = 1.2E-7             
+ACM     = 12             RS      = 0              RD      = 0                  
+RSH     = 3.5            CTA     = 8.3043E-4      CTP     = 4.30175E-4         
+PTA     = 1.3004E-3      PTP     = 1.3004E-3      CGDO    = cgop  
+CGSO    = cgop           CAPMOD  = 0              NQSMOD  = 0                  
+ELM     = 5              XPART   = 1              CF      = 0                  
+TLEV    = 1              TLEVC   = 1              JS      = 3E-7               
+JSW     = 5E-12           )                                                    
*       
.model p.7 PMOS (                                LEVEL   = 49                 
+VERSION = 3.1            LMIN    = '1.20E-6-dxl'  LMAX    = '2.1E-5-dxl'   
+WMIN    = '6E-7-dxw'     WMAX    = '1.2E-6-dxw'   XL      = '3e-8+dxl'     
+XW      = '0+dxw'        TNOM    = 25             TOX     = toxp          
+XJ      = 1E-7           NCH     = 4.1589E17          
+LLN     = 1              LWN     = 1              WLN     = 1                  
+WWN     = 1              LINT    = 1.2365E-8      WINT    = 7.8E-9             
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0                  
+DWB     = 0              VTH0    = 'dvthp-0.5884309'  LVTH0   = -2.401123E-8 
+WVTH0   = -2.745175E-9   PVTH0   = 2.722365E-14   K1      = 0.595419           
+LK1     = 2.762745E-8    WK1     = 1.020619E-9    PK1     = -2.04178E-14       
+K2      = -5.810239E-3   LK2     = 4.785001E-12   K3      = 0                  
+DVT0    = 0              DVT1    = 0              DVT2    = 0                  
+DVT0W   = 0              DVT1W   = 0              DVT2W   = 0                  
+NLX     = 0              W0      = 0              K3B     = 0                  
+VSAT    = 1.41E5         UA      = 8.285853E-10   LUA     = -3.90628E-16       
+WUA     = -2.33872E-16   PUA     = 3.639829E-22   UB      = 6.785205E-19       
+LUB     = -1.33207E-25   WUB     = -2.35202E-26   PUB     = 2.834814E-32       
+UC      = -1.41204E-10   LUC     = 6.880613E-17   WUC     = 2.65853E-17        
+PUC     = -3.20188E-23   RDSW    = 1.03E3         PRWB    = 0                  
+PRWG    = 0              WR      = 1              U0      = 0.0103455          
+LU0     = -1.726956E-9   WU0     = -1.69351E-11   PU0     = 1.002532E-15       
+A0      = 1.4008813      LA0     = 3.002553E-7    PA0     = -7.40777E-18       
+KETA    = 6.199512E-4    LKETA   = -1.340254E-8   A1      = 0                  
+A2      = 0.4            AGS     = 0.2082863      LAGS    = 1.832176E-7        
+WAGS    = 3.437089E-11   PAGS    = -4.14262E-17   B0      = 0                  
+B1      = 0              VOFF    = -0.125203      LVOFF   = 5.978026E-11       
+NFACTOR = 0.6469985      LNFACTOR= 3.065458E-11   CIT     = 7.970132E-4        
+LCIT    = -2.64573E-13   CDSC    = 0              CDSCB   = 0                  
+CDSCD   = 0              ETA0    = 6.164736E-5    LETA0   = 9.865801E-11       
+WETA0   = 4.636117E-12   PETA0   = -9.36700E-17   ETAB    = 0                  
+DSUB    = 0              PCLM    = 1.1312834      LPCLM   = 8.366598E-7        
+WPCLM   = 5.512454E-11   PDIBLC1 = 0              PDIBLC2 = 6.063847E-4        
+LPDIBLC2= -7.69522E-12   PDIBLCB = 0.1921199      DROUT   = 0                  
+PSCBE1  = 7.19E8         PSCBE2  = 1E-20          PVAG    = -1.585648E-7       
+LPVAG   = 1.911134E-13   DELTA   = 0.01           ALPHA0  = 0                  
+BETA0   = 30             KT1     = -0.3423514     LKT1    = 5.211262E-9        
+WKT1    = 5.91009E-8     PKT1    = -6.17222E-15   KT2     = -0.0367632         
+AT      = 1E4            UTE     = -1.2366118     LUTE    = 2.369704E-7        
+WUTE    = 1.149E-7       PUTE    = -1.38486E-13   UA1     = 5.253386E-10       
+WUA1    = -7.36908E-17   UB1     = -1.61123E-18   LUB1    = 5.693319E-25       
+WUB1    = 5.594735E-25   PUB1    = -6.74317E-31   UC1     = -1.00699E-12       
+KT1L    = 0              PRT     = 0              CJ      = cjp                
+MJ      = 0.4812153      PB      = 0.9134669      CJSW    = cjswp              
+MJSW    = 0.3237595      PBSW    = 0.9134669      CJSWG   = cjgatep            
+MJSWG   = 0.3237595      PBSWG   = 0.9134669      HDIF    = hdifp              
+LDIF    = 1.2E-7         ACM     = 12             RS      = 0                  
+RD      = 0              RSH     = 3.5            CTA     = 8.3043E-4          
+CTP     = 4.30175E-4     PTA     = 1.3004E-3      PTP     = 1.3004E-3          
+CGDO    = cgop           CGSO    = cgop           CAPMOD  = 0                  
+NQSMOD  = 0              ELM     = 5              XPART   = 1                  
+CF      = 0              TLEV    = 1              TLEVC   = 1                  
+JS      = 3E-7           JSW     = 5E-12           )                           
*       
.model p.8 PMOS (                                LEVEL   = 49                 
+VERSION = 3.1            LMIN    = '5.0E-7-dxl'   LMAX    = '1.2E-6-dxl'
+WMIN    = '6E-7-dxw'     WMAX    = '1.2E-6-dxw'   XL      = '3e-8+dxl'     
+XW      = '0+dxw'        TNOM    = 25             TOX     = toxp          
+XJ      = 1E-7           NCH     = 4.1589E17          
+LLN     = 1              LWN     = 1              WLN     = 1                  
+WWN     = 1              LINT    = 1.2365E-8      WINT    = 7.8E-9             
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0                  
+DWB     = 0              VTH0    = 'dvthp-0.618174'  LVTH0   = 1.183726E-8  
+WVTH0   = 2.360908E-8    PVTH0   = -4.54035E-15   K1      = 0.6061273          
+LK1     = 1.472115E-8    WK1     = 1.527921E-8    PK1     = -3.76032E-14       
+K2      = -1.000259E-3   LK2     = -5.79254E-9    WK2     = -4.202804E-9       
+PK2     = 5.065514E-15   K3      = 0              DVT0    = 0                  
+DVT1    = 0              DVT2    = 0              DVT0W   = 0                  
+DVT1W   = 0              DVT2W   = 0              NLX     = 0                  
+W0      = 0              K3B     = 0              VSAT    = 1.255949E5         
+LVSAT   = 0.0185673      WVSAT   = 0.012293       PVSAT   = -1.481637E-8       
+UA      = 7.589674E-10   LUA     = -3.06720E-16   WUA     = -2.23029E-16       
+PUA     = 3.509139E-22   UB      = 3.024353E-19   LUB     = 3.200773E-25       
+WUB     = 3.489835E-25   PUB     = -4.20619E-31   UC      = -1.21211E-10       
+LUC     = 4.470926E-17   WUC     = 4.00189E-17    PUC     = -4.82099E-23       
+RDSW    = 1.03E3         PRWB    = 0              PRWG    = 0                  
+WR      = 1              U0      = 8.882446E-3    LU0     = 3.642163E-11       
+WU0     = 4.232219E-10   PU0     = 4.720241E-16   A0      = 1.7009215          
+LA0     = -6.137418E-8   WA0     = 3.351568E-8    PA0     = -4.03954E-14       
+KETA    = -9.417279E-3   LKETA   = -1.304972E-9   A1      = 0                  
+A2      = 0.4            AGS     = 0.3675323      LAGS    = -8.716892E-9       
+WAGS    = -2.188555E-8   PAGS    = 2.6378E-14     B0      = 0                  
+B1      = 0              VOFF    = -0.1176577     LVOFF   = -9.034299E-9       
+WVOFF   = -1.575472E-8   PVOFF   = 1.89887E-14    NFACTOR = 0.9008439          
+LNFACTOR= -3.059216E-7   WNFACTOR= -1.409199E-7   PNFACTOR= 1.698465E-13       
+CIT     = 3.511628E-4    LCIT    = 5.371056E-10   WCIT    = 3.258923E-10       
+PCIT    = -3.92788E-16   CDSC    = 0              CDSCB   = 0                  
+CDSCD   = 0              ETA0    = -1.263878E-4   LETA0   = 3.252911E-10       
+WETA0   = -9.60047E-11   PETA0   = 2.762939E-17   ETAB    = 4.691741E-4        
+LETAB   = -5.65481E-10   WETAB   = -1.74413E-10   PETAB   = 2.102151E-16       
+DSUB    = 0              PCLM    = 1.2440341      LPCLM   = 7.007647E-7        
+WPCLM   = 2.8681E-7      PPCLM   = -3.45614E-13   PDIBLC1 = 0                  
+PDIBLC2 = 5.849861E-4    LPDIBLC2= 1.809594E-11   WPDIBLC2= -6.66151E-10       
+PPDIBLC2= 8.028916E-16   PDIBLCB = 0.1921199      DROUT   = 0                  
+PSCBE1  = 7.19E8         PSCBE2  = 1E-20          PVAG    = 0                  
+DELTA   = 0.01           ALPHA0  = 0              BETA0   = 30                 
+KT1     = -0.3709249     LKT1    = 3.965E-8       WKT1    = 9.29433E-8         
+PKT1    = -4.69615E-14   KT2     = -0.0367632     AT      = 1E4                
+UTE     = -1.04          UA1     = 6.163569E-10   LUA1    = -1.09702E-16       
+WUA1    = -1.26882E-16   PUA1    = 6.410959E-23   UB1     = -1.09883E-18       
+LUB1    = -4.82513E-26   WUB1    = -4.74158E-26   PUB1    = 5.714885E-32       
+UC1     = -1.00699E-12   KT1L    = 0              PRT     = 0                  
+CJ      = cjp            MJ      = 0.4812153      PB      = 0.9134669          
+CJSW    = cjswp          MJSW    = 0.3237595      PBSW    = 0.9134669          
+CJSWG   = cjgatep        MJSWG   = 0.3237595      PBSWG   = 0.9134669          
+HDIF    = hdifp          LDIF    = 1.2E-7         ACM     = 12                 
+RS      = 0              RD      = 0              RSH     = 3.5                
+CTA     = 8.3043E-4      CTP     = 4.30175E-4     PTA     = 1.3004E-3          
+PTP     = 1.3004E-3      CGDO    = cgop           CGSO    = cgop               
+CAPMOD  = 0              NQSMOD  = 0              ELM     = 5                  
+XPART   = 1              CF      = 0              TLEV    = 1                  
+TLEVC   = 1              JS      = 3E-7           JSW     = 5E-12           )  
*       
.model p.9 PMOS (                                LEVEL   = 49                 
+VERSION = 3.1            LMIN    = 2.4E-7         LMAX    = '5.0E-7-dxl'       
+WMIN    = '6E-7-dxw'     WMAX    = '1.2E-6-dxw'   XL      = '3e-8+dxl'     
+XW      = '0+dxw'        TNOM    = 25             TOX     = toxp          
+XJ      = 1E-7           NCH     = 4.1589E17          
+LLN     = 1              LWN     = 1              WLN     = 1                  
+WWN     = 1              LINT    = 1.2365E-8      WINT    = 7.8E-9             
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0                  
+DWB     = 0              VTH0    = 'dvthp-0.6282244'  LVTH0   = 1.691537E-8 
+WVTH0   = 9.917492E-9    PVTH0   = 2.377605E-15   K1      = 0.7406093          
+LK1     = -5.32286E-8    WK1     = -1.317004E-7   PK1     = 3.666116E-14       
+K2      = 3.932248E-4    LK2     = -6.496625E-9   WK2     = 1.131525E-8        
+PK2     = -2.77529E-15   K3      = 0              DVT0    = 0                  
+DVT1    = 0              DVT2    = 0              DVT0W   = 0                  
+DVT1W   = 0              DVT2W   = 0              NLX     = 0                  
+W0      = 0              K3B     = 0              VSAT    = 1.906144E5         
+LVSAT   = -0.0142851     WVSAT   = -0.0330965     PVSAT   = 8.117581E-9        
+UA      = -7.20643E-11   LUA     = 1.131757E-16   WUA     = 8.392853E-16       
+PUA     = -1.85842E-22   UB      = 1.449361E-18   LUB     = -2.59430E-25       
+WUB     = -1.04557E-24   PUB     = 2.840059E-31   UC      = 4.254018E-11       
+LUC     = -3.80295E-17   WUC     = -1.12413E-16   PUC     = 2.880952E-23       
+RDSW    = 1.03E3         PRWB    = 0              PRWG    = 0                  
+WR      = 1              U0      = 8.198703E-3    LU0     = 3.818962E-10       
+WU0     = 2.093824E-9    PU0     = -3.72081E-16   A0      = 1.1827321          
+LA0     = 2.004513E-7    WA0     = -9.023455E-8   PA0     = 2.213183E-14       
+KETA    = -0.0325083     LKETA   = 1.036225E-8    WKETA   = 1.08825E-8         
+PKETA   = -5.49860E-15   A1      = 0              A2      = 0.4                
+AGS     = 0.1561353      LAGS    = 9.809567E-8    WAGS    = 5.892267E-8        
+PAGS    = -1.44520E-14   B0      = 0              B1      = 0                  
+VOFF    = -0.1572783     LVOFF   = 1.098479E-8    WVOFF   = 4.241658E-8        
+PVOFF   = -1.04035E-14   NFACTOR = 0.2303142      LNFACTOR= 3.287689E-8        
+WNFACTOR= 3.793998E-7    PNFACTOR= -9.30554E-14   CIT     = 1.512503E-3        
+LCIT    = -4.96847E-11   WCIT    = -8.77403E-10   PCIT    = 2.152006E-16       
+CDSC    = 0              CDSCB   = 0              CDSCD   = 0                  
+ETA0    = -1.935761E-3   LETA0   = 1.239513E-9    WETA0   = -2.77277E-10       
+PETA0   = 1.192206E-16   ETAB    = 9.265732E-4    LETAB   = -7.96591E-10       
+WETAB   = 2.91319E-10    PETAB   = -2.51054E-17   DSUB    = 0                  
+PCLM    = 2.5813706      LPCLM   = 2.504877E-8    WPCLM   = -7.719133E-7       
+PPCLM   = 1.893272E-13   PDIBLC1 = 0              PDIBLC2 = -7.283689E-3       
+LPDIBLC2= 3.9939E-9      WPDIBLC2= 1.793484E-9    PPDIBLC2= -4.39888E-16       
+PDIBLCB = 0.1921199      DROUT   = 0              PSCBE1  = 7.19E8             
+PSCBE2  = 1E-20          PVAG    = 0              DELTA   = 0.01               
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.3299822         
+LKT1    = 1.896285E-8    WKT1    = 4.450431E-8    PKT1    = -2.24867E-14       
+KT2     = -0.0366947     LKT2    = -3.45990E-11   WKT2    = -4.00175E-11       
+PKT2    = 2.021964E-17   AT      = 1E4            UTE     = -1.04              
+UA1     = 6.959636E-10   LUA1    = -1.49924E-16   WUA1    = -1.73404E-16       
+PUA1    = 8.761584E-23   UB1     = -1.24452E-18   LUB1    = 2.536273E-26       
+WUB1    = 1.264167E-25   PUB1    = -3.06835E-32   UC1     = -1.00138E-12       
+LUC1    = -2.83308E-21   WUC1    = -3.27677E-21   PUC1    = 1.655653E-27       
+KT1L    = 0              PRT     = 0              CJ      = cjp                
+MJ      = 0.4812153      PB      = 0.9134669      CJSW    = cjswp              
+MJSW    = 0.3237595      PBSW    = 0.9134669      CJSWG   = cjgatep            
+MJSWG   = 0.3237595      PBSWG   = 0.9134669      HDIF    = hdifp              
+LDIF    = 1.2E-7         ACM     = 12             RS      = 0                  
+RD      = 0              RSH     = 3.5            CTA     = 8.3043E-4          
+CTP     = 4.30175E-4     PTA     = 1.3004E-3      PTP     = 1.3004E-3          
+CGDO    = cgop           CGSO    = cgop           CAPMOD  = 0                  
+NQSMOD  = 0              ELM     = 5              XPART   = 1                  
+CF      = 0              TLEV    = 1              TLEVC   = 1                  
+JS      = 3E-7           JSW     = 5E-12           )                           
*       
.model p.10 PMOS (                               LEVEL   = 49                 
+VERSION = 3.1            LMIN    = '1.20E-6-dxl'  LMAX    = '2.1E-5-dxl'       
+WMIN    = 3E-7           WMAX    = '6E-7-dxw'     XL      = '3e-8+dxl'     
+XW      = '0+dxw'        TNOM    = 25             TOX     = toxp          
+XJ      = 1E-7           NCH     = 4.1589E17          
+LLN     = 1              LWN     = 1              WLN     = 1                  
+WWN     = 1              LINT    = 1.2365E-8      WINT    = 7.8E-9             
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0                  
+DWB     = 0              VTH0    = 'dvthp-0.6266034'  LVTH0   = -2.780125E-9
+WVTH0   = 1.956281E-8    PVTH0   = 1.481619E-14   K1      = 0.6273518          
+LK1     = 3.171814E-8    WK1     = -1.764088E-8   PK1     = -2.28084E-14       
+K2      = -5.810239E-3   LK2     = 4.785001E-12   K3      = 0                  
+DVT0    = 0              DVT1    = 0              DVT2    = 0                  
+DVT0W   = 0              DVT1W   = 0              DVT2W   = 0                  
+NLX     = 0              W0      = 0              K3B     = 0                  
+VSAT    = 1.392952E5     LVSAT   = 0.0341045      WVSAT   = 9.962722E-4        
+PVSAT   = -1.993069E-8   UA      = 6.032154E-10   LUA     = 2.903141E-16       
+WUA     = -1.02166E-16   PUA     = -3.39596E-23   UB      = 7.152652E-19       
+LUB     = 9.215839E-26   WUB     = -4.49938E-26   PUB     = -1.03355E-31       
+UC      = -7.99076E-11   LUC     = 2.00098E-17    WUC     = -9.23648E-18       
+PUC     = -3.50226E-24   RDSW    = 1.03E3         PRWB    = 0                  
+PRWG    = 0              WR      = 1              U0      = 0.0111332          
+LU0     = 6.416406E-10   WU0     = -4.77288E-10   PU0     = -3.81675E-16       
+A0      = 1.2442259      LA0     = 3.176779E-7    WA0     = 9.155555E-8        
+PA0     = -1.01892E-14   KETA    = 9.069688E-4    LKETA   = -1.914439E-8       
+WKETA   = -1.67733E-10   PKETA   = 3.355533E-15   A1      = 0                  
+A2      = 0.4            AGS     = 0.2083451      LAGS    = 1.831467E-7        
+B0      = 0              B1      = 0              VOFF    = -0.1240623         
+LVOFF   = -2.275974E-8   WVOFF   = -6.66611E-10   PVOFF   = 1.333573E-14       
+NFACTOR = 0.6469985      LNFACTOR= 3.065458E-11   CIT     = 7.970132E-4        
+LCIT    = -2.64573E-13   CDSC    = 0              CDSCB   = 0                  
+CDSCD   = 0              ETA0    = 7.115035E-5    LETA0   = -9.30314E-11       
+WETA0   = -9.17423E-13   PETA0   = 1.835329E-17   ETAB    = 0                  
+DSUB    = 0              PCLM    = 1.1313808      LPCLM   = 8.366044E-7        
+PPCLM   = 3.549063E-17   PDIBLC1 = 0              PDIBLC2 = 6.824768E-4        
+LPDIBLC2= -1.529937E-9   WPDIBLC2= -4.44682E-11   PPDIBLC2= 8.895983E-16       
+PDIBLCB = 0.1921199      DROUT   = 0              PSCBE1  = 7.19E8             
+PSCBE2  = 1E-20          PVAG    = -1.585648E-7   LPVAG   = 1.911134E-13       
+DELTA   = 0.01           ALPHA0  = 0              BETA0   = 30                 
+KT1     = -0.3076598     LKT1    = 7.137368E-8    WKT1    = 3.882708E-8        
+PKT1    = -4.48375E-14   KT2     = -0.0367632     AT      = 1E4                
+UTE     = -1.0520093     LUTE    = 2.402516E-7    WUTE    = 7.0183E-9          
+PUTE    = -1.40403E-13   UA1     = 1.691779E-10   LUA1    = 6.946074E-16       
+WUA1    = 1.344495E-16   PUA1    = -4.05929E-22   UB1     = -5.11093E-19       
+LUB1    = -1.27713E-24   WUB1    = -8.34451E-26   PUB1    = 4.047556E-31       
+UC1     = -1.00699E-12   KT1L    = 0              PRT     = 0              
+CJ      = cjp            MJ      = 0.4812153          
+PB      = 0.9134669      CJSW    = cjswp          MJSW    = 0.3237595          
+PBSW    = 0.9134669      CJSWG   = cjgatep        MJSWG   = 0.3237595          
+PBSWG   = 0.9134669      HDIF    = hdifp          LDIF    = 1.2E-7             
+ACM     = 12             RS      = 0              RD      = 0                  
+RSH     = 3.5            CTA     = 8.3043E-4      CTP     = 4.30175E-4         
+PTA     = 1.3004E-3      PTP     = 1.3004E-3      CGDO    = cgop  
+CGSO    = cgop           CAPMOD  = 0              NQSMOD  = 0                  
+ELM     = 5              XPART   = 1              CF      = 0                  
+TLEV    = 1              TLEVC   = 1              JS      = 3E-7               
+JSW     = 5E-12           )                                                    
*       
.model p.11 PMOS (                               LEVEL   = 49                 
+VERSION = 3.1            LMIN    = '5.0E-7-dxl'   LMAX    = '1.2E-6-dxl'
+WMIN    = 3E-7           WMAX    = '6E-7-dxw'     XL      = '3e-8+dxl'     
+XW      = '0+dxw'        TNOM    = 25             TOX     = toxp          
+XJ      = 1E-7           NCH     = 4.1589E17          
+LLN     = 1              LWN     = 1              WLN     = 1                  
+WWN     = 1              LINT    = 1.2365E-8      WINT    = 7.8E-9             
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0                  
+DWB     = 0              VTH0    = 'dvthp-0.6398095'  LVTH0   = 1.313687E-8 
+WVTH0   = 3.625287E-8    PVTH0   = -5.29984E-15   K1      = 0.7400303          
+LK1     = -1.040899E-7   WK1     = -6.297374E-8   PK1     = 3.182998E-14       
+K2      = -8.191097E-3   LK2     = 2.874362E-9    WK2     = -4.78851E-13       
+PK2     = 5.77145E-19    K3      = 0              DVT0    = 0                  
+DVT1    = 0              DVT2    = 0              DVT0W   = 0                  
+DVT1W   = 0              DVT2W   = 0              NLX     = 0                  
+W0      = 0              K3B     = 0              VSAT    = 1.854359E5         
+LVSAT   = -0.0215075     WVSAT   = -0.0226781     PVSAT   = 8.603328E-9        
+UA      = 5.884384E-10   LUA     = 3.081244E-16   WUA     = -1.23372E-16       
+PUA     = -8.40093E-24   UB      = 1.247662E-18   LUB     = -5.49523E-25       
+WUB     = -2.03407E-25   PUB     = 8.757512E-32   UC      = -3.02909E-11       
+LUC     = -3.97917E-17   WUC     = -1.31150E-17   PUC     = 1.172444E-24       
+RDSW    = 1.03E3         PRWB    = 0              PRWG    = 0                  
+WR      = 1              U0      = 0.0112689      LU0     = 4.780936E-10       
+WU0     = -9.71440E-10   PU0     = 2.13911E-16    A0      = 1.85557            
+LA0     = -4.191568E-7   WA0     = -5.686091E-8   PA0     = 1.686927E-13       
+KETA    = -0.0171257     LKETA   = 2.589872E-9    WKETA   = 4.504813E-9        
+PKETA   = -2.27615E-15   A1      = 0              A2      = 0.4                
+AGS     = 0.330108       LAGS    = 3.638948E-8    WAGS    = -1.48018E-11       
+PAGS    = 1.784021E-17   B0      = 0              B1      = 0                  
+VOFF    = -0.1752518     LVOFF   = 3.893742E-8    WVOFF   = 1.790325E-8        
+PVOFF   = -9.04598E-15   NFACTOR = 0.6597079      LNFACTOR= -1.528765E-8       
+CIT     = 9.088157E-4    LCIT    = -1.35017E-10   CDSC    = 0                  
+CDSCB   = 0              CDSCD   = 0              ETA0    = -3.326234E-4       
+LETA0   = 3.93625E-10    WETA0   = 2.451938E-11   PETA0   = -1.23049E-17       
+ETAB    = 1.703993E-4    LETAB   = -2.05377E-10   WETAB   = 1.907304E-13       
+PETAB   = -2.29882E-19   DSUB    = 0              PCLM    = 2.0818837          
+LPCLM   = -3.090082E-7   WPCLM   = -2.028293E-7   PPCLM   = 2.444974E-13       
+PDIBLC1 = 0              PDIBLC2 = -2.598516E-3   LPDIBLC2= 2.424546E-9        
+WPDIBLC2= 1.194288E-9    PPDIBLC2= -6.03438E-16   PDIBLCB = 0.1921199          
+DROUT   = 0              PSCBE1  = 7.19E8         PSCBE2  = 1E-20              
+PVAG    = 0              DELTA   = 0.01           ALPHA0  = 0                  
+BETA0   = 30             KT1     = -0.1766771     LKT1    = -8.649587E-8       
+WKT1    = -2.057514E-8   PKT1    = 2.675819E-14   KT2     = -0.0367632         
+AT      = 1E4            UTE     = -0.7174615     LUTE    = -1.62969E-7        
+WUTE    = -1.884915E-7   PUTE    = 9.523909E-14   UA1     = 9.954103E-10       
+LUA1    = -3.01226E-16   WUA1    = -3.48401E-16   PUA1    = 1.760364E-22       
+UB1     = -1.96250E-18   LUB1    = 4.722086E-25   WUB1    = 4.573163E-25       
+PUB1    = -2.47008E-31   UC1     = -1.00699E-12   KT1L    = 0                  
+PRT     = 0              CJ      = cjp                
+MJ      = 0.4812153      PB      = 0.9134669      CJSW    = cjswp              
+MJSW    = 0.3237595      PBSW    = 0.9134669      CJSWG   = cjgatep            
+MJSWG   = 0.3237595      PBSWG   = 0.9134669      HDIF    = hdifp              
+LDIF    = 1.2E-7         ACM     = 12             RS      = 0                  
+RD      = 0              RSH     = 3.5            CTA     = 8.3043E-4          
+CTP     = 4.30175E-4     PTA     = 1.3004E-3      PTP     = 1.3004E-3          
+CGDO    = cgop           CGSO    = cgop           CAPMOD  = 0                  
+NQSMOD  = 0              ELM     = 5              XPART   = 1                  
+CF      = 0              TLEV    = 1              TLEVC   = 1                  
+JS      = 3E-7           JSW     = 5E-12           )                           
*       
.model p.12 PMOS (                               LEVEL   = 49                 
+VERSION = 3.1            LMIN    = 2.4E-7         LMAX    = '5.0E-7-dxl'       
+WMIN    = 3E-7           WMAX    = '6E-7-dxw'     XL      = '3e-8+dxl'     
+XW      = '0+dxw'        TNOM    = 25             TOX     = toxp          
+XJ      = 1E-7           NCH     = 4.1589E17          
+LLN     = 1              LWN     = 1              WLN     = 1                  
+WWN     = 1              LINT    = 1.2365E-8      WINT    = 7.8E-9             
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0                  
+DWB     = 0              VTH0    = 'dvthp-0.6662537'  LVTH0   = 2.649834E-8
+WVTH0   = 3.214189E-8    PVTH0   = -3.22268E-15   K1      = 0.4198155          
+LK1     = 5.770498E-8    WK1     = 5.577151E-8    PK1     = -2.81684E-14       
+K2      = 0.0429467      LK2     = -2.296405E-8   WK2     = -1.355302E-8       
+PK2     = 6.848271E-15   K3      = 0              DVT0    = 0                  
+DVT1    = 0              DVT2    = 0              DVT0W   = 0                  
+DVT1W   = 0              DVT2W   = 0              NLX     = 0                  
+W0      = 0              K3B     = 0              VSAT    = 1.443912E5         
+LVSAT   = -7.688012E-4   WVSAT   = -6.083648E-3   PVSAT   = 2.186471E-10       
+UA      = 1.846811E-9    LUA     = -3.27694E-16   WUA     = -2.82106E-16       
+PUA     = 7.180233E-23   UB      = -7.84535E-19   LUB     = 4.772849E-25       
+WUB     = 2.599205E-25   PUB     = -1.46530E-31   UC      = -1.75560E-10       
+LUC     = 3.360832E-17   WUC     = 1.504425E-17   PUC     = -1.30556E-23       
+RDSW    = 1.03E3         PRWB    = 0              PRWG    = 0                  
+WR      = 1              U0      = 0.0136443      LU0     = -7.22084E-10       
+WU0     = -1.088554E-9   PU0     = 2.730854E-16   A0      = 0.1071803          
+LA0     = 4.64252E-7     WA0     = 5.383179E-7    PA0     = -1.32033E-13       
+KETA    = -4.943762E-3   LKETA   = -3.565304E-9   WKETA   = -5.226247E-9       
+PKETA   = 2.640665E-15   A1      = 0              A2      = 0.4                
+AGS     = 0.1664005      LAGS    = 1.19106E-7     WAGS    = 5.29237E-8         
+PAGS    = -2.67304E-14   B0      = 0              B1      = 0                  
+VOFF    = -0.0592623     LVOFF   = -1.96686E-8    WVOFF   = -1.486398E-8       
+PVOFF   = 7.510321E-15   NFACTOR = 0.8588103      LNFACTOR= -1.158881E-7       
+WNFACTOR= 1.210664E-8    PNFACTOR= -6.11712E-15   CIT     = 6.439495E-5        
+LCIT    = 2.916437E-10   WCIT    = -3.11284E-11   PCIT    = 1.572825E-17       
+CDSC    = 0              CDSCB   = 0              CDSCD   = 0                  
+ETA0    = -3.819468E-3   LETA0   = 2.155422E-9    WETA0   = 8.235612E-10       
+PETA0   = -4.16037E-16   ETAB    = 1.334637E-3    LETAB   = -7.93631E-10       
+WETAB   = 5.284657E-11   PETAB   = -2.68353E-17   DSUB    = 0                  
+PCLM    = 0.1098002      LPCLM   = 6.874263E-7    WPCLM   = 6.724724E-7        
+PPCLM   = -1.97766E-13   PDIBLC1 = 0              PDIBLC2 = 5.801323E-3        
+LPDIBLC2= -1.81964E-9    WPDIBLC2= -5.853396E-9   PPDIBLC2= 2.957545E-15       
+PDIBLCB = 0.1921199      DROUT   = 0              PSCBE1  = 7.19E8             
+PSCBE2  = 1E-20          PVAG    = 0              DELTA   = 0.01               
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.3248987         
+LKT1    = -1.160393E-8   WKT1    = 4.153356E-8    PKT1    = -4.62347E-15       
+KT2     = -0.0367632     AT      = 1E4            UTE     = -1.04              
+UA1     = 3.992421E-10   UB1     = -9.23294E-19   LUB1    = -5.28718E-26       
+WUB1    = -6.13069E-26   PUB1    = 1.503674E-32   UC1     = -1.00699E-12       
+KT1L    = 0              PRT     = 0              CJ      = cjp                
+MJ      = 0.4812153      PB      = 0.9134669      CJSW    = cjswp              
+MJSW    = 0.3237595      PBSW    = 0.9134669      CJSWG   = cjgatep            
+MJSWG   = 0.3237595      PBSWG   = 0.9134669      HDIF    = hdifp              
+LDIF    = 1.2E-7         ACM     = 12             RS      = 0                  
+RD      = 0              RSH     = 3.5            CTA     = 8.3043E-4          
+CTP     = 4.30175E-4     PTA     = 1.3004E-3      PTP     = 1.3004E-3          
+CGDO    = cgop           CGSO    = cgop           CAPMOD  = 0                  
+NQSMOD  = 0              ELM     = 5              XPART   = 1                  
+CF      = 0              TLEV    = 1              TLEVC   = 1                  
+JS      = 3E-7           JSW     = 5E-12           )                           
*
.ENDL MOS
.LIB MOS3
***************************************************************
*                                                             *
*              3.3V NORMAL DEVICES MODEL                      *
*                                                             *
***************************************************************
***************************************************************
*              3.3V NMOS DEVICES MODEL                        *
***************************************************************
.MODEL  nch3.1 NMOS (      LEVEL    = 49             
+VERSION  = 3.1            LMIN     = '1.21E-6-dxl3' LMAX   = '2.1E-5-dxl3'
+WMIN     = '1.002E-5-dxw3' WMAX  = '1.01E-4-dxw3'   XL     = '3E-8+dxl3'  
+XW       = '0+dxw3'       TNOM     = 25             TOX      = toxn3      
+XJ       = 1E-07          NCH      = 2.1206E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 6.35E-09       WINT     = 1.5785E-08     MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = 'dvthn3+0.561303' LVTH0  = -1.45267E-08  WVTH0    = -5.8429E-08  
+PVTH0    = 1.45082E-14    K1       = 0.550952       LK1      = -3.30834E-08   
+WK1      = -2.82216E-11   PK1      = 5.65537E-16    K2       = 0.0127207      
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 138000         UA       = 1.6542E-11     
+LUA      = -1.8925E-18    UB       = 1.10596E-18    LUB      = -4.23339E-25   
+WUB      = 1.46801E-24    PUB      = -1.80441E-30   UC       = 3.31194E-11    
+LUC      = -4.44889E-17   RDSW     = 770.203        PRWB     = 0              
+PRWG     = 0              WR       = 0.99           U0       = 0.0407048      
+LU0      = 1.04496E-09    A0       = 0.798929       LA0      = 1.31395E-09    
+KETA     = -0.000796438   LKETA    = 1.59505E-08    PKETA    = 1.05502E-20    
+A1       = 0              A2       = 0.99           AGS      = 0.15905        
+LAGS     = -5.81802E-07   B0       = 0              B1       = 0              
+VOFF     = -0.146488      LVOFF    = 5.37439E-08    WVOFF    = 1.28655E-11    
+PVOFF    = -2.58206E-16   NFACTOR  = 1.02562        LNFACTOR = -3.30724E-11   
+PNFACTOR = 3.30342E-16    CIT      = 0.000505134    CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = 6.43485E-05    
+LETA0    = 6.97203E-14    WETA0    = 3.47723E-14    PETA0    = -6.96396E-19   
+ETAB     = -2.29938E-05   LETAB    = 1.09213E-11    WETAB    = -1.33661E-13   
+PETAB    = -4.35201E-19   DSUB     = 0              PCLM     = 0.852786       
+LPCLM    = 5.83189E-08    WPCLM    = 2.64376E-11    PPCLM    = -5.30065E-16   
+PDIBLC1  = 0              PDIBLC2  = 4.933122E-5    LPDIBLC2 = 5.020222E-09    
+WPDIBLC2 = -1.364883E-12  PPDIBLC2 = 2.7284066E-17  PDIBLCB  = 0.138753       
+DROUT    = 0              PSCBE1   = 7.19939E+08    PSCBE2   = 0.0125586      
+LPSCBE2  = -1.50499E-08   WPSCBE2  = -6.61537E-08   PPSCBE2  = 8.11892E-14    
+PVAG     = 0.39           DELTA    = 0.01           ALPHA0   = 0              
+BETA0    = 30             KT1      = -0.361551      LKT1     = 1.90485E-08    
+WKT1     = 5.94279E-08    PKT1     = 1.10409E-14    KT2      = -0.0229887     
+LKT2     = -1.73497E-08   WKT2     = -9.12916E-09   PKT2     = 1.73826E-13    
+AT       = 20000          UTE      = -1.35581       LUTE     = 8.63837E-08    
+WUTE     = 7.83246E-09    PUTE     = -1.56864E-13   UA1      = 2.44697E-09    
+LUA1     = -2.75637E-16   WUA1     = -1.16959E-15   PUA1     = -2.29244E-23   
+UB1      = -2.16479E-18   LUB1     = 6.21908E-28    WUB1     = 5.0667E-26     
+PUB1     = -6.21836E-32   UC1      = -5.62707E-11   LUC1     = 1.32547E-16    
+WUC1     = 6.56035E-17    PUC1     = -1.32338E-21   KT1L     = 0              
+PRT      = 0              CJ       = cjn3           MJ       = 0.34976        
+PB       = 0.830941       CJSW     = cjswn3         MJSW     = 0.198171       
+PBSW     = 0.830941       CJSWG    = cjgaten3       MJSWG    = 0.444916       
+PBSWG    = 0.830941       HDIF     = hdifn3         LDIF     = 1.2E-07        
+ACM      = 12             RS       = 0              RD       = 0              
+RSH      = 4.5            CTA      = 0.000891915    CTP      = 0.000422248    
+PTA      = 0.00172089     PTP      = 0.00172089     CGDO     = cgon3        
+CGSO     = cgon3          CAPMOD   = 0              NQSMOD   = 0              
+ELM      = 5              XPART    = 1              CF       = 0              
+TLEV     = 1              TLEVC    = 1              JS       = 1E-06          
+JSW      = 5E-11          )
*
.MODEL  nch3.2 NMOS (      LEVEL    = 49             
+VERSION  = 3.1            LMIN     = '6.1E-7-dxl3'  LMAX   = '1.21E-6-dxl3'
+WMIN     = '1.002E-5-dxw3' WMAX  = '1.01E-4-dxw3'   XL     = '3E-8+dxl3'
+XW       = '0+dxw3'       TNOM     = 25             TOX      = toxn3      
+XJ       = 1E-07          NCH      = 2.1206E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 6.35E-09       WINT     = 1.5785E-08     MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = 'dvthn3+0.543659' LVTH0  = 7.12774E-09 WVTH0    = 1.14016E-08    
+PVTH0    = -7.11949E-14   K1       = 0.529323       LK1      = -6.53849E-09   
+WK1      = 8.84834E-10    PK1      = -5.55056E-16   K2       = 0.0127207      
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 156819         LVSAT    = -0.0230966     
+UA       = 2.02275E-11    LUA      = -6.41571E-18   PUA      = -1.72905E-28   
+UB       = 7.10303E-19    LUB      = 6.22477E-26    WUB      = 1.82844E-24    
+PUB      = -2.24677E-30   UC       = -4.03565E-12   LUC      = 1.1115E-18     
+WUC      = 9.01466E-18    PUC      = -1.10637E-23   RDSW     = 770.203        
+PRWB     = 0              PRWG     = 0              WR       = 0.99           
+U0       = 0.0397459      LU0      = 2.22177E-09    A0       = 0.332139       
+LA0      = 5.74206E-07    KETA     = 0.0040451      LKETA    = 1.00085E-08    
+PKETA    = -7.95666E-20   A1       = 0              A2       = 0.99           
+AGS      = -0.330682      LAGS     = 1.92471E-08    B0       = 0              
+B1       = 0              VOFF     = -0.102698      WVOFF    = -1.9752E-10    
+NFACTOR  = 1.0256         WNFACTOR = 2.52667E-10    CIT      = 0.000505134    
+CDSC     = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0     = -0.000743021   LETA0    = 9.90954E-10    WETA0    = -2.33307E-09   
+PETA0    = 2.86272E-15    ETAB     = 4.36216E-05    LETAB    = -7.08357E-11   
+WETAB    = -9.98739E-13   PETAB    = 6.26509E-19    DSUB     = 0              
+PCLM     = 0.413419       LPCLM    = 5.97554E-07    WPCLM    = -8.29363E-10   
+PPCLM    = 5.20259E-16    PDIBLC1  = 0              PDIBLC2  = 0.0042964      
+LPDIBLC2 = -1.92203E-10   WPDIBLC2 = 4.26816E-11    PPDIBLC2 = -2.67741E-17   
+PDIBLCB  = 0.138753       DROUT    = 0              PSCBE1   = 7.19939E+08    
+PSCBE2   = 0.000228318    LPSCBE2  = 8.30775E-11    WPSCBE2  = 2.06318E-09    
+PPSCBE2  = -2.53331E-15   PVAG     = 0.39           DELTA    = 0.01           
+ALPHA0   = 0              BETA0    = 30             KT1      = -0.362926      
+LKT1     = 2.0736E-08     WKT1     = 2.37185E-07    PKT1     = -2.0712E-13    
+KT2      = -0.039346      LKT2     = 2.72565E-09    WKT2     = 1.54686E-07    
+PKT2     = -2.72249E-14   AT       = 20000          UTE      = -1.19924       
+LUTE     = -1.05785E-07   WUTE     = -1.95669E-06   PUTE     = 2.2542E-12     
+UA1      = 2.39988E-09    LUA1     = -2.17844E-16   WUA1     = -7.3846E-15    
+PUA1     = 7.60476E-21    UB1      = -2.16877E-18   LUB1     = 5.49959E-27    
+UC1      = 1.03219E-10    LUC1     = -6.31946E-17   WUC1     = -1.52699E-15   
+PUC1     = 6.31214E-22    KT1L     = 0              PRT      = 0              
+CJ       = cjn3           MJ       = 0.34976        PB       = 0.830941       
+CJSW     = cjswn3         MJSW     = 0.198171       PBSW     = 0.830941       
+CJSWG    = cjgaten3       MJSWG    = 0.444916       PBSWG    = 0.830941       
+HDIF     = hdifn3         LDIF     = 1.2E-07        ACM      = 12             
+RS       = 0              RD       = 0              RSH      = 4.5            
+CTA      = 0.000891915    CTP      = 0.000422248    PTA      = 0.00172089     
+PTP      = 0.00172089     CGDO     = cgon3          CGSO     = cgon3        
+CAPMOD   = 0              NQSMOD   = 0              ELM      = 5              
+XPART    = 1              CF       = 0              TLEV     = 1              
+TLEVC    = 1              JS       = 1E-06          JSW      = 5E-11          )
*
.MODEL  nch3.3 NMOS (      LEVEL    = 49             
+VERSION  = 3.1            LMIN     = 3.5E-7         LMAX     = '6.1E-7-dxl3' 
+WMIN     = '1.002E-5-dxw3' WMAX  = '1.01E-4-dxw3'   XL       = '3E-8+dxl3'  
+XW       = '0+dxw3'       TNOM     = 25             TOX      = toxn3      
+XJ       = 1E-07          NCH      = 2.1206E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 6.35E-09       WINT     = 1.5785E-08     MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = 'dvthn3+0.558038' LVTH0  = -1.89244E-09  WVTH0    = 1.61274E-07    
+PVTH0    = -1.6521E-13    K1       = 0.487865       LK1      = 1.94682E-08    
+WK1      = -2.44555E-07   PK1      = 1.5341E-13     K2       = 0.0644544      
+LK2      = -3.24526E-08   K3       = 0              DVT0     = 0              
+DVT1     = 0              DVT2     = 0              DVT0W    = 0              
+DVT1W    = 0              DVT2W    = 0              NLX      = 0              
+W0       = 0              K3B      = 0              VSAT     = 124708         
+LVSAT    = -0.0029536     WVSAT    = -0.0470298     PVSAT    = 2.95018E-08    
+UA       = -2.8009E-10    LUA      = 1.81974E-16    WUA      = -1.51906E-15   
+PUA      = 9.52908E-22    UB       = 1.35417E-18    LUB      = -3.41653E-25   
+WUB      = -4.22996E-24   PUB      = 1.55366E-30    UC       = -8.05775E-12   
+LUC      = 3.63457E-18    WUC      = 2.70406E-16    PUC      = -1.75034E-22   
+RDSW     = 770.203        PRWB     = 0              PRWG     = 0              
+WR       = 0.99           U0       = 0.0394736      LU0      = 2.39259E-09    
+WU0      = 1.22756E-07    PU0      = -7.70045E-14   A0       = 0.766385       
+LA0      = 3.01804E-07    WA0      = 9.75085E-06    PA0      = -6.11671E-12   
+KETA     = -0.00473258    LKETA    = 1.55148E-08    WKETA    = 4.51643E-07    
+PKETA    = -2.83316E-13   A1       = 0              A2       = 0.99           
+AGS      = -0.3           B0       = 0              B1       = 0              
+VOFF     = -0.103         LVOFF    = 1.89579E-10    WVOFF    = -4.76555E-10   
+PVOFF    = 1.75039E-16    NFACTOR  = 1.09678        LNFACTOR = -4.4656E-08    
+WNFACTOR = 6.09607E-10    PNFACTOR = -2.23909E-16   CIT      = 0.000319511    
+LCIT     = 1.16441E-10    CDSC     = 0              CDSCB    = 0              
+CDSCD    = 0              ETA0     = 4.09124E-05    LETA0    = 4.99193E-10    
+WETA0    = 5.38149E-09    PETA0    = -1.97662E-15   ETAB     = 0.00142914     
+LETAB    = -9.39973E-10   DSUB     = 0              PCLM     = 1.3851         
+LPCLM    = -1.19787E-08   PDIBLC1  = 0              PDIBLC2  = -0.014767      
+LPDIBLC2 = 1.17663E-08    PDIBLCB  = 0.138753       DROUT    = 0              
+PSCBE1   = 7.19939E+08    PSCBE2   = 0.000498728    LPSCBE2  = -8.65506E-11   
+WPSCBE2  = -2.72854E-09   PPSCBE2  = 4.72531E-16    PVAG     = 0.39           
+DELTA    = 0.01           ALPHA0   = 0              BETA0    = 30             
+KT1      = -0.287699      LKT1     = -2.64542E-08   WKT1     = -9.48544E-07   
+PKT1     = 5.36687E-13    KT2      = -0.0340643     LKT2     = -5.87596E-10   
+WKT2     = -4.98924E-08   PKT2     = 1.01107E-13    AT       = 20000          
+UTE      = -1.46781       LUTE     = 6.26898E-08    WUTE     = 2.46589E-06    
+PUTE     = -5.20087E-13   UA1      = 1.93483E-09    LUA1     = 7.38845E-17    
+WUA1     = 1.60322E-14    PUA1     = -7.08456E-21   UB1      = -2.86736E-18   
+LUB1     = 4.43729E-25    WUB1     = 7.06545E-24    PUB1     = -4.43216E-30   
+UC1      = 5.02877E-11    LUC1     = -2.9991E-17    WUC1     = -1.48168E-15   
+PUC1     = 6.02793E-22    KT1L     = 0              PRT      = 0              
+CJ       = cjn3           MJ       = 0.34976        PB       = 0.830941       
+CJSW     = cjswn3         MJSW     = 0.198171       PBSW     = 0.830941       
+CJSWG    = cjgaten3       MJSWG    = 0.444916       PBSWG    = 0.830941       
+HDIF     = hdifn3         LDIF     = 1.2E-07        ACM      = 12             
+RS       = 0              RD       = 0              RSH      = 4.5            
+CTA      = 0.000891915    CTP      = 0.000422248    PTA      = 0.00172089     
+PTP      = 0.00172089     CGDO     = cgon3          CGSO     = cgon3        
+CAPMOD   = 0              NQSMOD   = 0              ELM      = 5              
+XPART    = 1              CF       = 0              TLEV     = 1              
+TLEVC    = 1              JS       = 1E-06          JSW      = 5E-11          )
*
.MODEL  nch3.4 NMOS (      LEVEL    = 49             
+VERSION  = 3.1            LMIN     = '1.21E-6-dxl3' LMAX     = '2.1E-5-dxl3' 
+WMIN     = '1.22E-6-dxw3'  WMAX  = '1.002E-5-dxw3'  XL       = '3E-8+dxl3'
+XW       = '0+dxw3'       TNOM     = 25             TOX      = toxn3      
+XJ       = 1E-07          NCH      = 2.1206E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 6.35E-09       WINT     = 1.5785E-08     MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = 'dvthn3+0.561367' LVTH0  = -1.63053E-08  WVTH0    = -5.90757E-08   
+PVTH0    = 3.22741E-14    K1       = 0.551037       LK1      = -3.47856E-08   
+WK1      = -8.77171E-10   PK1      = 1.75674E-14    K2       = 0.0127207      
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 138000         UA       = 1.6542E-11     
+LUA      = -1.8925E-18    UB       = 1.25265E-18    LUB      = -5.9848E-25    
+WUB      = 2.74749E-27    PUB      = -5.50248E-32   UC       = 3.31194E-11    
+LUC      = -4.44889E-17   RDSW     = 770.203        PRWB     = 0              
+PRWG     = 0              WR       = 0.99           U0       = 0.0407767      
+LU0      = 9.56676E-10    WU0      = -7.18493E-10   PU0      = 8.81807E-16    
+A0       = 0.798929       LA0      = 1.31395E-09    KETA     = -0.000839462   
+LKETA    = 1.68122E-08    WKETA    = 4.29735E-10    PKETA    = -8.60644E-15   
+A1       = 0              A2       = 0.99           AGS      = 0.161782       
+LAGS     = -6.01339E-07   WAGS     = -2.728E-08     PAGS     = 1.95144E-13    
+B0       = 0              B1       = 0              VOFF     = -0.147522      
+LVOFF    = 5.49885E-08    WVOFF    = 1.0339E-08     PVOFF    = -1.2689E-14    
+NFACTOR  = 1.02563        WNFACTOR = -3.27187E-11   PNFACTOR = 4.01557E-17    
+CIT      = 0.000505134    CDSC     = 0              CDSCB    = 0              
+CDSCD    = 0              ETA0     = 6.4352E-05     ETAB     = -2.30071E-05   
+LETAB    = 1.08777E-11    DSUB     = 0              PCLM     = 0.852868       
+LPCLM    = 5.66786E-08    WPCLM    = -7.9162E-10    PPCLM    = 1.5854E-14     
+PDIBLC1  = 0              PDIBLC2  = 4.919457E-5    LPDIBLC2 = 5.022953E-09  
+PDIBLCB  = 0.138753       DROUT    = 0              PSCBE1   = 7.19939E+08    
+PSCBE2   = 0.00513053     LPSCBE2  = -5.93352E-09   WPSCBE2  = 8.04152E-09    
+PPSCBE2  = -9.86936E-15   PVAG     = 0.386562       LPVAG    = 6.88606E-08    
+WPVAG    = 3.43436E-08    PPVAG    = -6.87809E-13   DELTA    = 0.01           
+ALPHA0   = 0              BETA0    = 30             KT1      = -0.358348      
+LKT1     = 1.89264E-08    WKT1     = 2.74388E-08    PKT1     = 1.22606E-14    
+KT2      = -0.0239026     LKT2     = 5.2984E-11     AT       = 20000          
+UTE      = -1.35658       LUTE     = 7.25881E-08    WUTE     = 1.55366E-08    
+PUTE     = -1.90681E-14   UA1      = 2.36023E-09    LUA1     = -3.15187E-16   
+WUA1     = -3.03204E-16   PUA1     = 3.72123E-22    UB1      = -2.15972E-18   
+LUB1     = -5.60365E-27   UC1      = -4.97028E-11   LUC1     = 5.5961E-20     
+KT1L     = 0              PRT      = 0              CJ       = cjn3         
+MJ       = 0.34976        PB       = 0.830941       CJSW     = cjswn3       
+MJSW     = 0.198171       PBSW     = 0.830941       CJSWG    = cjgaten3     
+MJSWG    = 0.444916       PBSWG    = 0.830941       HDIF     = hdifn3       
+LDIF     = 1.2E-07        ACM      = 12             RS       = 0              
+RD       = 0              RSH      = 4.5            CTA      = 0.000891915    
+CTP      = 0.000422248    PTA      = 0.00172089     PTP      = 0.00172089     
+CGDO     = cgon3          CGSO     = cgon3        CAPMOD   = 0              
+NQSMOD   = 0              ELM      = 5              XPART    = 1              
+CF       = 0              TLEV     = 1              TLEVC    = 1              
+JS       = 1E-06          JSW      = 5E-11          )
*
.MODEL  nch3.5 NMOS (      LEVEL    = 49             
+VERSION  = 3.1            LMIN     = '6.1E-7-dxl3'  LMAX     = '1.21E-6-dxl3'
+WMIN     = '1.22E-6-dxw3' WMAX   = '1.002E-5-dxw3'  XL       = '3E-8+dxl3'
+XW       = '0+dxw3'       TNOM     = 25             TOX      = toxn3      
+XJ       = 1E-07          NCH      = 2.1206E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 6.35E-09       WINT     = 1.5785E-08     MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = 'dvthn3+0.547729' LVTH0  = 4.33217E-10   WVTH0    = -2.92531E-08   
+PVTH0    = -4.32716E-15   K1       = 0.52666        LK1      = -4.86795E-09   
+WK1      = 2.74847E-08    PK1      = -1.72411E-14   K2       = 0.0127207      
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 156537         LVSAT    = -0.02275       
+WVSAT    = 0.0028206      PVSAT    = -3.46173E-09   UA       = -4.20388E-11   
+LUA      = 7.00038E-17    WUA      = 6.21943E-16    PUA      = -7.63311E-22   
+UB       = 9.29337E-19    LUB      = -2.01674E-25   WUB      = -3.59365E-25   
+PUB      = 3.89396E-31    UC       = -3.32731E-12   LUC      = 2.42153E-19    
+WUC      = 1.93945E-18    PUC      = -2.38028E-24   RDSW     = 770.203        
+PRWB     = 0              PRWG     = 0              WR       = 0.99           
+U0       = 0.0393602      LU0      = 2.69511E-09    WU0      = 3.85225E-09    
+PU0      = -4.72787E-15   A0       = 0.332139       LA0      = 5.74206E-07    
+KETA     = 0.00581675     LKETA    = 8.643E-09      WKETA    = -1.76959E-08   
+PKETA    = 1.36392E-14    A1       = 0              A2       = 0.99           
+AGS      = -0.357658      LAGS     = 3.61686E-08    WAGS     = 2.69439E-07    
+PAGS     = -1.69019E-13   B0       = 0              B1       = 0              
+VOFF     = -0.102718      NFACTOR  = 1.02562        CIT      = 0.000505134    
+CDSC     = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0     = -0.000976598   LETA0    = 1.27756E-09    ETAB     = 4.35216E-05    
+LETAB    = -7.0773E-11    DSUB     = 0              PCLM     = 0.410853       
+LPCLM    = 5.99164E-07    WPCLM    = 2.48041E-08    PPCLM    = -1.55596E-14   
+PDIBLC1  = 0              PDIBLC2  = 0.00430067     LPDIBLC2 = -1.94884E-10   
+PDIBLCB  = 0.138753       DROUT    = 0              PSCBE1   = 7.19939E+08    
+PSCBE2   = 0.000430481    LPSCBE2  = -1.65154E-10   WPSCBE2  = 4.38957E-11    
+PPSCBE2  = -5.38732E-17   PVAG     = 0.442669       WPVAG    = -5.26081E-07   
+DELTA    = 0.01           ALPHA0   = 0              BETA0    = 30             
+KT1      = -0.342493      LKT1     = -5.33307E-10   WKT1     = 3.30883E-08    
+PKT1     = 5.3269E-15     KT2      = -0.0238595     AT       = 20000          
+UTE      = -1.41596       LUTE     = 1.45456E-07    WUTE     = 2.08019E-07    
+PUTE     = -2.55302E-13   UA1      = 1.60076E-09    LUA1     = 6.16914E-16    
+WUA1     = 5.97376E-16    PUA1     = -7.33159E-22   UB1      = -2.16937E-18   
+LUB1     = 6.24231E-27    WUB1     = 6.0446E-27     PUB1     = -7.41854E-33   
+UC1      = -4.96572E-11   KT1L     = 0              PRT      = 0              
+CJ       = cjn3           MJ       = 0.34976        PB       = 0.830941       
+CJSW     = cjswn3         MJSW     = 0.198171       PBSW     = 0.830941       
+CJSWG    = cjgaten3       MJSWG    = 0.444916       PBSWG    = 0.830941       
+HDIF     = hdifn3         LDIF     = 1.2E-07        ACM      = 12             
+RS       = 0              RD       = 0              RSH      = 4.5            
+CTA      = 0.000891915    CTP      = 0.000422248    PTA      = 0.00172089     
+PTP      = 0.00172089     CGDO     = cgon3          CGSO     = cgon3        
+CAPMOD   = 0              NQSMOD   = 0              ELM      = 5              
+XPART    = 1              CF       = 0              TLEV     = 1              
+TLEVC    = 1              JS       = 1E-06          JSW      = 5E-11          )
*
.MODEL  nch3.6 NMOS (      LEVEL    = 49             
+VERSION  = 3.1            LMIN     = 3.5E-7         LMAX     = '6.1E-7-dxl3' 
+WMIN     = '1.22E-6-dxw3' WMAX   = '1.002E-5-dxw3'   XL      = '3E-8+dxl3'  
+XW       = '0+dxw3'       TNOM     = 25             TOX      = toxn3      
+XJ       = 1E-07          NCH      = 2.1206E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 6.35E-09       WINT     = 1.5785E-08     MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = 'dvthn3+0.579406' LVTH0  = -1.94379E-08  WVTH0    = -5.21583E-08   
+PVTH0    = 1.00413E-14    K1       = 0.463381       LK1      = 3.4827E-08     
+K2       = 0.0644544      LK2      = -3.24526E-08   K3       = 0              
+DVT0     = 0              DVT1     = 0              DVT2     = 0              
+DVT0W    = 0              DVT1W    = 0              DVT2W    = 0              
+NLX      = 0              W0       = 0              K3B      = 0              
+VSAT     = 117218         LVSAT    = 0.00191485     WVSAT    = 0.027792       
+PVSAT    = -1.91263E-08   UA       = -3.47032E-10   LUA      = 2.61326E-16    
+WUA      = -8.5042E-16    PUA      = 1.60302E-22    UB       = 8.14164E-19    
+LUB      = -1.29426E-25   WUB      = 1.16391E-24    PUB      = -5.66153E-31   
+UC       = 1.55348E-11    LUC      = -1.159E-17     WUC      = 3.47534E-17    
+PUC      = -2.29645E-23   RDSW     = 770.203        PRWB     = 0              
+PRWG     = 0              WR       = 0.99           U0       = 0.0534359      
+LU0      = -6.13456E-09   WU0      = -1.67061E-08   PU0      = 8.16837E-15    
+A0       = 1.76827        LA0      = -3.26681E-07   WA0      = -2.56444E-07   
+PA0      = 1.60867E-13    KETA     = 0.043036       LKETA    = -1.47046E-08   
+WKETA    = -2.54903E-08   PKETA    = 1.85286E-14    A1       = 0              
+A2       = 0.99           AGS      = -0.3           B0       = 0              
+B1       = 0              VOFF     = -0.103048      LVOFF    = 2.07103E-10    
+NFACTOR  = 1.09685        LNFACTOR = -4.46784E-08   CIT      = 0.000319511    
+LCIT     = 1.16441E-10    CDSC     = 0              CDSCB    = 0              
+CDSCD    = 0              ETA0     = 0.000579685    LETA0    = 3.01302E-10    
+ETAB     = 0.00147226     LETAB    = -9.6702E-10    WETAB    = -4.3067E-10    
+PETAB    = 2.70159E-16    DSUB     = 0              PCLM     = 1.3851         
+LPCLM    = -1.19787E-08   PDIBLC1  = 0              PDIBLC2  = -0.014767      
+LPDIBLC2 = 1.17663E-08    PDIBLCB  = 0.138753       DROUT    = 0              
+PSCBE1   = 7.19939E+08    PSCBE2   = 0.0002357      LPSCBE2  = -4.29678E-11   
+WPSCBE2  = -1.01298E-10   PPSCBE2  = 3.72066E-17    PVAG     = 0.444577       
+LPVAG    = -1.19678E-09   WPVAG    = -5.45137E-07   PPVAG    = 1.19539E-14    
+DELTA    = 0.01           ALPHA0   = 0              BETA0    = 30             
+KT1      = -0.386815      LKT1     = 2.727E-08      WKT1     = 4.14745E-08    
+PKT1     = 6.62278E-17    KT2      = -0.041112      LKT2     = 1.08225E-08    
+WKT2     = 2.05034E-08    PKT2     = -1.28618E-14   AT       = 20000          
+UTE      = -1.19298       LUTE     = 5.58539E-09    WUTE     = -2.79145E-07   
+PUTE     = 5.02963E-14    UA1      = 3.7339E-09     LUA1     = -7.21201E-16   
+WUA1     = -1.93771E-15   PUA1     = 8.57098E-22    UB1      = -2.15942E-18   
+WUB1     = -5.78155E-27   UC1      = -1.04588E-10   LUC1     = 3.44579E-17    
+WUC1     = 6.52811E-17    PUC1     = -4.09509E-23   KT1L     = 0              
+PRT      = 0              CJ       = cjn3           MJ       = 0.34976        
+PB       = 0.830941       CJSW     = cjswn3         MJSW     = 0.198171       
+PBSW     = 0.830941       CJSWG    = cjgaten3       MJSWG    = 0.444916       
+PBSWG    = 0.830941       HDIF     = hdifn3         LDIF     = 1.2E-07        
+ACM      = 12             RS       = 0              RD       = 0              
+RSH      = 4.5            CTA      = 0.000891915    CTP      = 0.000422248    
+PTA      = 0.00172089     PTP      = 0.00172089     CGDO     = cgon3        
+CGSO     = cgon3          CAPMOD   = 0              NQSMOD   = 0              
+ELM      = 5              XPART    = 1              CF       = 0              
+TLEV     = 1              TLEVC    = 1              JS       = 1E-06          
+JSW      = 5E-11          )
*
.MODEL  nch3.7 NMOS (      LEVEL    = 49             
+VERSION  = 3.1            LMIN     = '1.21E-6-dxl3' LMAX     = '2.1E-5-dxl3' 
+WMIN     = '6.2E-7-dxw3'  WMAX   = '1.22E-6-dxw3'   XL       = '3E-8+dxl3'  
+XW       = '0+dxw3'       TNOM     = 25             TOX      = toxn3      
+XJ       = 1E-07          NCH      = 2.1206E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 6.35E-09       WINT     = 1.5785E-08     MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = 'dvthn3+0.528993' LVTH0  = 1.9186E-08    WVTH0    = -2.06012E-08   
+PVTH0    = -9.90481E-15   K1       = 0.549274       LK1      = 5.11727E-10    
+WK1      = 1.21739E-09    PK1      = -2.4381E-14    K2       = 0.0127207      
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 138000         UA       = 1.6542E-11     
+LUA      = -1.8925E-18    UB       = 1.31167E-18    LUB      = -5.38742E-25   
+WUB      = -6.73912E-26   PUB      = -1.2602E-31    UC       = 3.31214E-11    
+LUC      = -4.4529E-17    WUC      = -2.38151E-21   PUC      = 4.76952E-26    
+RDSW     = 770.203        PRWB     = 0              PRWG     = 0              
+WR       = 0.99           U0       = 0.0404077      LU0      = 9.09395E-10    
+WU0      = -2.79938E-10   PU0      = 9.37997E-16    A0       = 0.798929       
+LA0      = 1.31395E-09    KETA     = 2.01082E-05    LKETA    = -4.02703E-10   
+WKETA    = -5.91804E-10   PKETA    = 1.18522E-14    A1       = 0              
+A2       = 0.99           AGS      = 0.138966       LAGS     = -4.39923E-07   
+WAGS     = -1.65376E-10   PAGS     = 3.31203E-15    B0       = 0              
+B1       = 0              VOFF     = -0.138822      LVOFF    = 4.43114E-08    
+NFACTOR  = 1.0256         LNFACTOR = 2.97686E-11    CIT      = 0.000505134    
+CDSC     = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0     = 9.30816E-05    LETA0    = -5.75376E-10   WETA0    = -3.41431E-11   
+PETA0    = 6.83794E-16    ETAB     = -2.31339E-05   LETAB    = 1.34167E-11    
+WETAB    = 1.50664E-13    PETAB    = -3.0174E-18    DSUB     = 0              
+PCLM     = 0.855826       LPCLM    = -2.55284E-09   WPCLM    = -4.30644E-09   
+PPCLM    = 8.62465E-14    PDIBLC1  = 0              PDIBLC2  = 4.919495E-5   
+LPDIBLC2 = 5.022953E-9   
+PDIBLCB  = 0.138753       DROUT    = 0              PSCBE1   = 7.19939E+08    
+PSCBE2   = 0.0164552      LPSCBE2  = -1.98323E-08   WPSCBE2  = -5.4171E-09    
+PPSCBE2  = 6.64841E-15    PVAG     = 0.41546        LPVAG    = -5.09894E-07   
+DELTA    = 0.01           ALPHA0   = 0              BETA0    = 30             
+KT1      = -0.348768      LKT1     = 4.2117E-08     WKT1     = 1.60531E-08    
+PKT1     = -1.52997E-14   KT2      = -0.023945      LKT2     = 1.04946E-10    
+WKT2     = 5.03165E-11    PKT2     = -6.17535E-17   AT       = 20000          
+UTE      = -1.388         LUTE     = 9.81333E-08    WUTE     = 5.28741E-08    
+PUTE     = -4.94267E-14   UA1      = 2.05809E-09    LUA1     = 5.56336E-17    
+WUA1     = 5.5872E-17     PUA1     = -6.85717E-23   UB1      = -2.15524E-18   
+LUB1     = -1.10992E-26   WUB1     = -5.32154E-27   PUB1     = 6.53113E-33    
+UC1      = -4.97475E-11   LUC1     = 1.10843E-19    WUC1     = 5.31437E-20    
+PUC1     = -6.52232E-26   KT1L     = 0              PRT      = 0              
+CJ       = cjn3           MJ       = 0.34976        PB       = 0.830941       
+CJSW     = cjswn3         MJSW     = 0.198171       PBSW     = 0.830941       
+CJSWG    = cjgaten3       MJSWG    = 0.444916       PBSWG    = 0.830941       
+HDIF     = hdifn3         LDIF     = 1.2E-07        ACM      = 12             
+RS       = 0              RD       = 0              RSH      = 4.5            
+CTA      = 0.000891915    CTP      = 0.000422248    PTA      = 0.00172089     
+PTP      = 0.00172089     CGDO     = cgon3          CGSO     = cgon3        
+CAPMOD   = 0              NQSMOD   = 0              ELM      = 5              
+XPART    = 1              CF       = 0              TLEV     = 1              
+TLEVC    = 1              JS       = 1E-06          JSW      = 5E-11          )
*
.MODEL  nch3.8 NMOS (      LEVEL    = 49             
+VERSION  = 3.1            LMIN     = '6.1E-7-dxl3'  LMAX     = '1.21E-6-dxl3'
+WMIN     = '6.2E-7-dxw3' WMAX    = '1.22E-6-dxw3'   XL       = '3E-8+dxl3'  
+XW       = '0+dxw3'       TNOM     = 25             TOX      = toxn3      
+XJ       = 1E-07          NCH      = 2.1206E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 6.35E-09       WINT     = 1.5785E-08     MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = 'dvthn3+0.559133' LVTH0  = -1.78053E-08  WVTH0    = -4.28067E-08   
+PVTH0    = 1.7348E-14     K1       = 0.57686        LK1      = -3.33437E-08   
+WK1      = -3.2174E-08    PK1      = 1.66002E-14    K2       = 0.0127207      
+K3       = 0              DVT0     = 0              DVT1     = 0              
+DVT2     = 0              DVT0W    = 0              DVT1W    = 0              
+DVT2W    = 0              NLX      = 0              W0       = 0              
+K3B      = 0              VSAT     = 143530         LVSAT    = -0.00678687    
+WVSAT    = 0.0182781      PVSAT    = -2.24328E-08   UA       = 4.85199E-10    
+LUA      = -5.77076E-16   WUA      = -4.64266E-18   PUA      = 5.69794E-24    
+UB       = 6.83406E-19    LUB      = 2.32328E-25    WUB      = -6.70934E-26   
+PUB      = -1.26385E-31   UC       = -3.15625E-11   LUC      = 3.48575E-17    
+WUC      = 3.5495E-17     PUC      = -4.35182E-23   RDSW     = 770.203        
+PRWB     = 0              PRWG     = 0              WR       = 0.99           
+U0       = 0.0417681      LU0      = -7.60205E-10   WU0      = 9.90713E-10    
+PU0      = -6.21474E-16   A0       = 0.127071       LA0      = 8.25886E-07    
+WA0      = 2.43709E-07    PA0      = -2.99104E-13   KETA     = -0.0338738     
+LKETA    = 4.11953E-08    WKETA    = 2.94735E-08    PKETA    = -2.50469E-14   
+A1       = 0              A2       = 0.99           AGS      = -0.1353        
+LAGS     = -1.03316E-07   WAGS     = 5.18178E-09    PAGS     = -3.25053E-15   
+B0       = 0              B1       = 0              VOFF     = -0.102718      
+NFACTOR  = 1.02562        CIT      = 0.000505134    CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = -0.00240935    
+LETA0    = 2.49586E-09    WETA0    = 1.70273E-09    PETA0    = -1.44787E-15   
+ETAB     = -2.00144E-05   LETAB    = 9.58815E-12    WETAB    = 7.55081E-11    
+PETAB    = -9.55036E-17   DSUB     = 0              PCLM     = 0.332189       
+LPCLM    = 6.40106E-07    WPCLM    = 1.1829E-07     PPCLM    = -6.42162E-14   
+PDIBLC1  = 0              PDIBLC2  = 0.00963346     LPDIBLC2 = -6.73981E-09   
+WPDIBLC2 = -6.33765E-09   PPDIBLC2 = 7.77819E-15    PDIBLCB  = 0.138753       
+DROUT    = 0              PSCBE1   = 7.19939E+08    PSCBE2   = 0.000434986    
+LPSCBE2  = -1.70683E-10   WPSCBE2  = 3.85413E-11    PPSCBE2  = -4.73018E-17   
+PVAG     = 0              DELTA    = 0.01           ALPHA0   = 0              
+BETA0    = 30             KT1      = -0.320824      LKT1     = 7.82184E-09    
+WKT1     = 7.33716E-09    PKT1     = -4.6026E-15    KT2      = -0.0238595     
+AT       = 20000          UTE      = -1.20718       LUTE     = -1.2379E-07    
+WUTE     = -4.00982E-08   PUTE     = 6.46783E-14    UA1      = 2.10342E-09    
+UB1      = -2.16429E-18   UC1      = -4.96572E-11   KT1L     = 0              
+PRT      = 0              CJ       = cjn3           MJ       = 0.34976        
+PB       = 0.830941       CJSW     = cjswn3         MJSW     = 0.198171       
+PBSW     = 0.830941       CJSWG    = cjgaten3       MJSWG    = 0.444916       
+PBSWG    = 0.830941       HDIF     = hdifn3         LDIF     = 1.2E-07        
+ACM      = 12             RS       = 0              RD       = 0              
+RSH      = 4.5            CTA      = 0.000891915    CTP      = 0.000422248    
+PTA      = 0.00172089     PTP      = 0.00172089     CGDO     = cgon3        
+CGSO     = cgon3          CAPMOD   = 0              NQSMOD   = 0              
+ELM      = 5              XPART    = 1              CF       = 0              
+TLEV     = 1              TLEVC    = 1              JS       = 1E-06          
+JSW      = 5E-11          )
*
.MODEL  nch3.9 NMOS (      LEVEL    = 49             
+VERSION  = 3.1            LMIN     = 3.5E-7         LMAX     = '6.1E-7-dxl3' 
+WMIN     = '6.2E-7-dxw3'  WMAX    = '1.22E-6-dxw3'  XL       = '3E-8+dxl3'  
+XW       = '0+dxw3'       TNOM     = 25             TOX      = toxn3      
+XJ       = 1E-07          NCH      = 2.1206E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 6.35E-09       WINT     = 1.5785E-08     MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = 'dvthn3+0.525268' LVTH0  = 3.43823E-09   WVTH0    = 1.21803E-08    
+PVTH0    = -1.71454E-14   K1       = 0.464861       LK1      = 3.69128E-08    
+WK1      = -1.75929E-09   PK1      = -2.4789E-15    K2       = 0.0644544      
+LK2      = -3.24526E-08   K3       = 0              DVT0     = 0              
+DVT1     = 0              DVT2     = 0              DVT0W    = 0              
+DVT1W    = 0              DVT2W    = 0              NLX      = 0              
+W0       = 0              K3B      = 0              VSAT     = 176096         
+LVSAT    = -0.0272153     WVSAT    = -0.0421804     PVSAT    = 1.54929E-08    
+UA       = -1.07163E-09   LUA      = 3.99523E-16    WUA      = 1.07138E-17    
+PUA      = -3.93519E-24   UB       = 2.15899E-18    LUB      = -6.93305E-25   
+WUB      = -4.34321E-25   PUB      = 1.03977E-31    UC       = 8.54256E-11    
+LUC      = -3.85291E-17   WUC      = -4.83069E-17   PUC      = 9.05072E-24    
+RDSW     = 770.203        PRWB     = 0              PRWG     = 0              
+WR       = 0.99           U0       = 0.0386859      LU0      = 1.17322E-09    
+WU0      = 8.23256E-10    PU0      = -5.16428E-16   A0       = 2.02572        
+LA0      = -3.65139E-07   WA0      = -5.62405E-07   PA0      = 2.06571E-13    
+KETA     = 0.0428118      LKETA    = -6.90959E-09   WKETA    = -2.52239E-08   
+PKETA    = 9.26472E-15    A1       = 0              A2       = 0.99           
+AGS      = -0.3           B0       = 0              B1       = 0              
+VOFF     = -0.103048      LVOFF    = 2.07103E-10    NFACTOR  = 1.09685        
+LNFACTOR = -4.46784E-08   CIT      = 0.000319511    LCIT     = 1.16441E-10    
+CDSC     = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0     = 0.00142075     LETA0    = 9.32407E-11    WETA0    = -9.99543E-10   
+PETA0    = 2.47266E-16    ETAB     = 0.00126566     LETAB    = -7.96917E-10   
+WETAB    = -1.85144E-10   PETAB    = 6.80033E-17    DSUB     = 0              
+PCLM     = 2.0273         LPCLM    = -4.2324E-07    WPCLM    = -7.6322E-07    
+PPCLM    = 4.88755E-13    PDIBLC1  = 0              PDIBLC2  = -0.0270735     
+LPDIBLC2 = 1.62864E-08    WPDIBLC2 = 1.46253E-08    PPDIBLC2 = -5.37189E-15   
+PDIBLCB  = 0.138753       DROUT    = 0              PSCBE1   = 7.19939E+08    
+PSCBE2   = 0.000225303    LPSCBE2  = -3.91489E-11   WPSCBE2  = -8.89415E-11   
+PPSCBE2  = 3.26682E-17    PVAG     = -0.0279814     LPVAG    = 1.75528E-08    
+WPVAG    = 1.64651E-08    PPVAG    = -1.03286E-14   DELTA    = 0.01           
+ALPHA0   = 0              BETA0    = 30             KT1      = -0.373273      
+LKT1     = 4.07228E-08    WKT1     = 2.5381E-08     PKT1     = -1.59215E-14   
+KT2      = -0.0238595     AT       = 20000          UTE      = -1.63068       
+LUTE     = 1.41873E-07    WUTE     = 2.41028E-07    PUTE     = -1.11672E-13   
+UA1      = 2.10342E-09    UB1      = -2.16429E-18   UC1      = -4.96572E-11   
+KT1L     = 0              PRT      = 0              CJ       = cjn3         
+MJ       = 0.34976        PB       = 0.830941       CJSW     = cjswn3       
+MJSW     = 0.198171       PBSW     = 0.830941       CJSWG    = cjgaten3     
+MJSWG    = 0.444916       PBSWG    = 0.830941       HDIF     = hdifn3       
+LDIF     = 1.2E-07        ACM      = 12             RS       = 0              
+RD       = 0              RSH      = 4.5            CTA      = 0.000891915    
+CTP      = 0.000422248    PTA      = 0.00172089     PTP      = 0.00172089     
+CGDO     = cgon3          CGSO     = cgon3          CAPMOD   = 0              
+NQSMOD   = 0              ELM      = 5              XPART    = 1              
+CF       = 0              TLEV     = 1              TLEVC    = 1              
+JS       = 1E-06          JSW      = 5E-11          )
*
.model n3.10 NMOS (      LEVEL    = 49             
+VERSION  = 3.1            LMIN     = '1.21E-6-dxl3' LMAX     = '2.1E-5-dxl3'
+WMIN     = 3E-7           WMAX     = '6.2E-7-dxw3'  XL       = '3E-8+dxl3'  
+XW       = '0+dxw3'       TNOM     = 25             TOX      = toxn3      
+XJ       = 1E-07          NCH      = 2.1206E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 6.35E-09       WINT     = 1.5785E-08     MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = 'dvthn3+0.52245'  LVTH0  = -7.4512E-09   WVTH0    = -1.6751E-08    
+PVTH0    = 5.7693E-15     K1       = 0.551343       LK1      = -4.09223E-08   
+K2       = 0.0127207      K3       = 0              DVT0     = 0              
+DVT1     = 0              DVT2     = 0              DVT0W    = 0              
+DVT1W    = 0              DVT2W    = 0              NLX      = 0              
+W0       = 0              K3B      = 0              VSAT     = 138000         
+UA       = 1.5657E-11     LUA      = 1.58312E-17    WUA      = 5.20746E-19    
+PUA      = -1.04291E-23   UB       = 1.30761E-18    LUB      = -8.52873E-25   
+WUB      = -6.50042E-26   PUB      = 5.88248E-32    UC       = 3.30385E-11    
+LUC      = -4.28693E-17   WUC      = 4.63834E-20    PUC      = -9.28933E-25   
+RDSW     = 770.203        PRWB     = 0              PRWG     = 0              
+WR       = 0.99           U0       = 0.0436764      LU0      = 3.59718E-10    
+WU0      = -2.20331E-09   PU0      = 1.26144E-15    A0       = 0.798929       
+LA0      = 1.31395E-09    KETA     = -0.000718978   LKETA    = 1.43992E-08    
+WKETA    = -1.56903E-10   PKETA    = 3.14235E-15    A1       = 0              
+A2       = 0.99           AGS      = 0.135957       LAGS     = -3.79665E-07   
+WAGS     = 1.6051E-09     PAGS     = -3.21458E-14   B0       = 0              
+B1       = 0              VOFF     = -0.138822      LVOFF    = 4.43114E-08    
+NFACTOR  = 1.0256         LNFACTOR = 2.97686E-11    CIT      = 0.000505134    
+CDSC     = 0              CDSCB    = 0              CDSCD    = 0              
+ETA0     = 3.50575E-05    LETA0    = 5.8669E-10     ETAB     = -2.28779E-05   
+LETAB    = 8.28884E-12    DSUB     = 0              PCLM     = 0.848507       
+LPCLM    = 1.44018E-07    PDIBLC1  = 0              PDIBLC2  = 4.919495E-5 
+LPDIBLC2 = 5.022953E-9    PDIBLCB  = 0.138753       DROUT    = 0              
+PSCBE1   = 7.19939E+08    PSCBE2   = 0.00724568     LPSCBE2  = -8.46319E-09   
+WPSCBE2  = 2.07389E-12    PPSCBE2  = -4.15345E-17   PVAG     = 0.41546        
+LPVAG    = -5.09894E-07   DELTA    = 0.01           ALPHA0   = 0              
+BETA0    = 30             KT1      = -0.318671      LKT1     = 1.90846E-08    
+WKT1     = -1.65696E-09   PKT1     = -1.74677E-15   KT2      = -0.0238595     
+AT       = 2178.96        LAT      = 0.0218718      WAT      = 0.0104864      
+PAT      = -1.287E-08     UTE      = -1.45841       LUTE     = 9.60064E-08    
+WUTE     = 9.43036E-08    PUTE     = -4.81751E-14   UA1      = 1.87507E-09    
+LUA1     = 2.78389E-16    WUA1     = 1.63566E-16    PUA1     = -1.99648E-22   
+UB1      = -2.16429E-18   UC1      = -4.96572E-11   KT1L     = 0              
+PRT      = 0              CJ       = cjn3           MJ       = 0.34976        
+PB       = 0.830941       CJSW     = cjswn3         MJSW     = 0.198171       
+PBSW     = 0.830941       CJSWG    = cjgaten3       MJSWG    = 0.444916       
+PBSWG    = 0.830941       HDIF     = hdifn3         LDIF     = 1.2E-07        
+ACM      = 12             RS       = 0              RD       = 0              
+RSH      = 4.5            CTA      = 0.000891915    CTP      = 0.000422248    
+PTA      = 0.00172089     PTP      = 0.00172089     CGDO     = cgon3        
+CGSO     = cgon3          CAPMOD   = 0              NQSMOD   = 0              
+ELM      = 5              XPART    = 1              CF       = 0              
+TLEV     = 1              TLEVC    = 1              JS       = 1E-06          
+JSW      = 5E-11          )
*
.model n3.11 NMOS (      LEVEL    = 49             
+VERSION  = 3.1            LMIN     = '6.1E-7-dxl3'  LMAX     = '1.21E-6-dxl3'
+WMIN     = 3E-7           WMAX    = '6.2E-7-dxw3'   XL       = '3E-8+dxl3'  
+XW       = '0+dxw3'       TNOM     = 25             TOX      = toxn3      
+XJ       = 1E-07          NCH      = 2.1206E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 6.35E-09       WINT     = 1.5785E-08     MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = 'dvthn3+0.541342' LVTH0  = -3.06378E-08  WVTH0    = -3.23379E-08   
+PVTH0    = 2.48991E-14    K1       = 0.522182       LK1      = -5.13258E-09   
+K2       = 0.0127207      K3       = 0              DVT0     = 0              
+DVT1     = 0              DVT2     = 0              DVT0W    = 0              
+DVT1W    = 0              DVT2W    = 0              NLX      = 0              
+W0       = 0              K3B      = 0              VSAT     = 169506         
+LVSAT    = -0.0386677     WVSAT    = 0.00299287     PVSAT    = -3.67315E-09   
+UA       = 3.14417E-10    LUA      = -3.50837E-16   WUA      = 9.5851E-17     
+PUA      = -1.27428E-22   UB       = 7.52963E-19    LUB      = -1.7215E-25    
+WUB      = -1.08023E-25   PUB      = 1.11622E-31    UC       = 2.5326E-11     
+LUC      = -3.34037E-17   WUC      = 2.02011E-18    PUC      = -3.35128E-24   
+RDSW     = 770.203        PRWB     = 0              PRWG     = 0              
+WR       = 0.99           U0       = 0.0459073      LU0      = -2.37837E-09   
+WU0      = -1.44495E-09   PU0      = 3.307E-16      A0       = 0.541239       
+LA0      = 3.17578E-07    KETA     = 0.0166449      LKETA    = -6.91148E-09   
+WKETA    = -2.53205E-10   PKETA    = 3.26054E-15    A1       = 0              
+A2       = 0.99           AGS      = -0.0410235     LAGS     = -1.62456E-07   
+WAGS     = -5.02931E-08   PAGS     = 3.15489E-14    B0       = 0              
+B1       = 0              VOFF     = -0.102718      NFACTOR  = 1.02562        
+CIT      = 0.000505134    CDSC     = 0              CDSCB    = 0              
+CDSCD    = 0              ETA0     = 0.000484329    LETA0    = 3.52989E-11    
+ETAB     = -0.000235299   LETAB    = 2.68994E-10    WETAB    = 2.02188E-10    
+PETAB    = -2.48146E-16   DSUB     = 0              PCLM     = 0.601869       
+LPCLM    = 4.46716E-07    WPCLM    = -4.03979E-08   PPCLM    = 4.95803E-14    
+PDIBLC1  = 0              PDIBLC2  = -0.00104751    LPDIBLC2 = 6.36894E-09    
+WPDIBLC2 = -5.26415E-11   PPDIBLC2 = 6.46069E-17    PDIBLCB  = 0.138753       
+DROUT    = 0              PSCBE1   = 7.19939E+08    PSCBE2   = 0.000610918    
+LPSCBE2  = -3.20344E-10   WPSCBE2  = -6.49821E-11   PPSCBE2  = 4.07633E-17    
+PVAG     = 0              DELTA    = 0.01           ALPHA0   = 0              
+BETA0    = 30             KT1      = -0.289149      LKT1     = -1.71478E-08   
+WKT1     = -1.13018E-08   PKT1     = 1.00903E-14    KT2      = -0.0238595     
+AT       = 20000          UTE      = -1.46669       LUTE     = 1.06171E-07    
+WUTE     = 1.12606E-07    PUTE     = -7.06378E-14   UA1      = 2.10031E-09    
+LUA1     = 1.94926E-18    WUA1     = 1.82848E-18    PUA1     = -1.147E-24     
+UB1      = -2.16429E-18   UC1      = -2.48699E-12   LUC1     = -5.7892E-17    
+WUC1     = -2.77564E-17   PUC1     = 3.40654E-23    KT1L     = 0              
+PRT      = 0              CJ       = cjn3           MJ       = 0.34976        
+PB       = 0.830941       CJSW     = cjswn3         MJSW     = 0.198171       
+PBSW     = 0.830941       CJSWG    = cjgaten3       MJSWG    = 0.444916       
+PBSWG    = 0.830941       HDIF     = hdifn3         LDIF     = 1.2E-07        
+ACM      = 12             RS       = 0              RD       = 0              
+RSH      = 4.5            CTA      = 0.000891915    CTP      = 0.000422248    
+PTA      = 0.00172089     PTP      = 0.00172089     CGDO     = cgon3        
+CGSO     = cgon3          CAPMOD   = 0              NQSMOD   = 0              
+ELM      = 5              XPART    = 1              CF       = 0              
+TLEV     = 1              TLEVC    = 1              JS       = 1E-06          
+JSW      = 5E-11          )
*
.model n3.12 NMOS (      LEVEL    = 49             
+VERSION  = 3.1            LMIN     = 3.5E-7         LMAX     = '6.1E-7-dxl3' 
+WMIN     = 3E-7           WMAX     = '6.2E-7-dxw3'  XL       = '3E-8+dxl3'  
+XW       = '0+dxw3'       TNOM     = 25             TOX      = toxn3      
+XJ       = 1E-07          NCH      = 2.1206E+17     LLN      = 1              
+LWN      = 1              WLN      = 1              WWN      = 1              
+LINT     = 6.35E-09       WINT     = 1.5785E-08     MOBMOD   = 1              
+BINUNIT  = 2              DWG      = 0              DWB      = 0              
+VTH0     = 'dvthn3+0.465559' LVTH0  = 1.6901E-08    WVTH0    = 4.73151E-08    
+PVTH0    = -2.50673E-14   K1       = 0.42446        LK1      = 5.61686E-08    
+WK1      = 2.20143E-08    PK1      = -1.38095E-14   K2       = 0.0644544      
+LK2      = -3.24526E-08   K3       = 0              DVT0     = 0              
+DVT1     = 0              DVT2     = 0              DVT0W    = 0              
+DVT1W    = 0              DVT2W    = 0              NLX      = 0              
+W0       = 0              K3B      = 0              VSAT     = 110330         
+LVSAT    = -0.00154649    WVSAT    = -0.00348201    PVSAT    = 3.88543E-10    
+UA       = -1.52927E-09   LUA      = 8.0571E-16     WUA      = 2.80005E-16    
+PUA      = -2.42948E-22   UB       = 1.13421E-18    LUB      = -4.11306E-25   
+WUB      = 1.68688E-25    PUB      = -6.19592E-32   UC       = -5.09477E-11   
+LUC      = 1.44428E-17    WUC      = 3.19392E-17    PUC      = -2.21195E-23   
+RDSW     = 770.203        PRWB     = 0              PRWG     = 0              
+WR       = 0.99           U0       = 0.043848       LU0      = -1.08658E-09   
+WU0      = -2.21429E-09   PU0      = 8.13307E-16    A0       = 1.22407        
+LA0      = -1.10759E-07   WA0      = -9.06853E-08   PA0      = 5.68869E-14    
+KETA     = -0.00598553    LKETA    = 7.28458E-09    WKETA    = 3.48997E-09    
+PKETA    = 9.12449E-16    A1       = 0              A2       = 0.99           
+AGS      = -0.3           B0       = 0              B1       = 0              
+VOFF     = -0.075209      LVOFF    = -1.72563E-08   WVOFF    = -1.63813E-08   
+PVOFF    = 1.0276E-14     NFACTOR  = 1.09685        LNFACTOR = -4.46784E-08   
+CIT      = 0.000319511    LCIT     = 1.16441E-10    CDSC     = 0              
+CDSCB    = 0              CDSCD    = 0              ETA0     = -0.00079512    
+LETA0    = 8.37897E-10    WETA0    = 3.0434E-10     PETA0    = -1.90912E-16   
+ETAB     = 0.00182107     LETAB    = -1.02097E-09   WETAB    = -5.11961E-10   
+PETAB    = 1.9984E-16     DSUB     = 0              PCLM     = 0.846624       
+LPCLM    = 2.93181E-07    WPCLM    = -6.84728E-08   PPCLM    = 6.71917E-14    
+PDIBLC1  = 0              PDIBLC2  = -0.00242506    LPDIBLC2 = 7.23308E-09    
+WPDIBLC2 = 1.2148E-10     PPDIBLC2 = -4.46197E-17   PDIBLCB  = 0.138753       
+DROUT    = 0              PSCBE1   = 7.19939E+08    PSCBE2   = 4.35231E-05    
+LPSCBE2  = 3.55823E-11    WPSCBE2  = 1.8023E-11     PPSCBE2  = -1.13058E-17   
+PVAG     = 0              DELTA    = 0.01           ALPHA0   = 0              
+BETA0    = 30             KT1      = -0.314664      LKT1     = -1.14225E-09   
+WKT1     = -9.10646E-09   PKT1     = 8.71318E-15    KT2      = -0.0238595     
+AT       = 20000          UTE      = -1.14765       LUTE     = -9.39663E-08   
+WUTE     = -4.32053E-08   PUTE     = 2.71027E-14    UA1      = 2.67873E-09    
+LUA1     = -3.60892E-16   WUA1     = -3.3853E-16    PUA1     = 2.1236E-22     
+UB1      = -2.16429E-18   UC1      = -9.50462E-11   LUC1     = 1.70401E-19    
+WUC1     = 2.67083E-17    PUC1     = -1.00269E-25   KT1L     = 0              
+PRT      = 0              CJ       = cjn3           MJ       = 0.34976        
+PB       = 0.830941       CJSW     = cjswn3         MJSW     = 0.198171       
+PBSW     = 0.830941       CJSWG    = cjgaten3       MJSWG    = 0.444916       
+PBSWG    = 0.830941       HDIF     = hdifn3         LDIF     = 1.2E-07        
+ACM      = 12             RS       = 0              RD       = 0              
+RSH      = 4.5            CTA      = 0.000891915    CTP      = 0.000422248    
+PTA      = 0.00172089     PTP      = 0.00172089     CGDO     = cgon3        
+CGSO     = cgon3          CAPMOD   = 0              NQSMOD   = 0              
+ELM      = 5              XPART    = 1              CF       = 0              
+TLEV     = 1              TLEVC    = 1              JS       = 1E-06          
+JSW      = 5E-11          )
*
***************************************************************
*                3.3V PMOS DEVICES MODEL                      *
***************************************************************
.model p3.1          PMOS   (                    LMIN    = '1.21E-6-dxl3' 
+LMAX    = '2.1E-5-dxl3'  WMIN   = '1.002E-5-dxw3' WMAX    = '1.01E-4-dxw3' 
+LEVEL   = 49             VERSION = 3.1            LDIF    = 1.2E-07        
+HDIF    = hdifp3         RSH     = 3.5            RD      = 0              
+RS      = 0              TOX     = toxp3          XL      = '3E-8 + dxl3'   
+XW      = '0 + dxw3'     XJ      = 1E-07          NCH     = 3.5713E+17     
+LLN     = 1              LWN     = 1              WLN     = 1              
+WWN     = 1              LINT    = 1.508E-08      WINT    = 3.975E-09      
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0              
+DWB     = 0       VTH0    = 'dvthp3-0.7658884'    LVTH0   = -2.353905E-08  
+WVTH0   = 5.196981E-08   PVTH0   = -2.161281E-13  K1      = 0.7771087      
+LK1     = 3.927237E-08   WK1     = 7.295371E-09   PK1     = -4.374782E-13  
+K2      = 7.720425E-04   LK2     = -1.545329E-08  WK2     = -7.732305E-09  
+PK2     = 1.547223E-13   K3      = 0              DVT0    = 0              
+DVT1    = 0              DVT2    = 0              DVT0W   = 0              
+DVT1W   = 0              DVT2W   = 0              NLX     = 0              
+W0      = 0              K3B     = 0              VSAT    = 9.980694E+04   
+LVSAT   = 3.863092E-03   UA      = 0              UB      = 1.039485E-18   
+LUB     = 1.49205E-25    WUB     = -1.039241E-24  PUB     = 9.057012E-32   
+UC      = -5.693709E-11  LUC     = 2.866874E-17   WUC     = -1.13536E-16   
+PUC     = -1.389506E-23  RDSW    = 1.098009E+03   PRWB    = 0              
+PRWG    = 0              WR      = 1.0108         U0      = 8.488032E-03   
+LU0     = 6.917146E-10   WU0     = -2.509743E-09  PU0     = -1.383056E-16  
+A0      = 1.139775       LA0     = -5.417045E-08  WA0     = 5.568569E-07   
+PA0     = -6.737077E-13  KETA    = -2.650192E-03  LKETA   = -2.083926E-08  
+WKETA   = 1.214676E-08   PKETA   = -1.469562E-14  A1      = 4.608649E-03   
+LA1     = -5.575729E-09  A2      = 1              AGS     = 0.130281       
+LAGS    = 1.13385E-07    WAGS    = 1.623316E-08   PAGS    = -1.963953E-14  
+B0      = 0              B1      = 0              VOFF    = -0.1268682     
+LVOFF   = 9.796369E-09   WVOFF   = -7.707408E-08  PVOFF   = -2.177278E-13  
+NFACTOR = 0.8933148      LNFACTOR= 1.883205E-07   WNFACTOR= -3.020754E-07  
+PNFACTOR= -1.035331E-12  CIT     = -1.000000E-04  CDSC    = 0              
+CDSCB   = 0              CDSCD   = 0              ETA0    = 0              
+ETAB    = 4.504726E-06   LETAB   = -9.013881E-11  DSUB    = 0              
+PCLM    = 1.140181       LPCLM   = 6.954392E-07   WPCLM   = 4.796044E-06   
+PPCLM   = -5.802446E-12  PDIBLC1 = 0              PDIBLC2 = 2.567192E-05   
+LPDIBLC2= 1.48729E-09    PDIBLCB = 0.2767538      LPDIBLCB= 4.511447E-07   
+DROUT   = 0              PSCBE1  = 4.855003E+08   LPSCBE1 = 130.0574       
+PSCBE2  = 5.864262E-06   LPSCBE2 = 2.707183E-12   WPSCBE2 = 4.737012E-14   
+PPSCBE2 = -5.730752E-20  PVAG    = 8.823746E-09   LPVAG   = -1.067532E-14  
+WPVAG   = -8.823044E-13  PPVAG   = 1.067447E-18   DELTA   = 4.503381E-03   
+LDELTA  = 1.185234E-08   WDELTA  = -1.124999E-08  PDELTA  = 1.361068E-14   
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.3391362     
+LKT1    = -2.139925E-08  WKT1    = 1.428911E-07   PKT1    = 1.531757E-13   
+KT2     = -0.03188891    LKT2    = -1.754705E-08  WKT2    = -1.775474E-08  
+PKT2    = 8.681878E-14   AT      = 2.037897E+04   LAT     = -2.830889E-03  
+WAT     = -0.01414636    PAT     = 2.830664E-07   UTE     = -1.031927      
+LUTE    = 3.778367E-07   WUTE    = 4.558647E-07   PUTE    = -4.630637E-12  
+UA1     = 1.150038E-09   LUA1    = 1.43538E-15    WUA1    = -1.971709E-15  
+PUA1    = -2.591603E-20  UB1     = -1.915005E-18  LUB1    = -1.163711E-24  
+WUB1    = 5.9328E-24     PUB1    = 2.766981E-29   UC1     = -2.353807E-11  
+LUC1    = 2.273586E-17   WUC1    = 3.928923E-16   PUC1    = 9.455838E-22   
+KT1L    = 0              PRT     = -1E-18         CJ      = cjp3           
+MJ      = 0.4812153      PB      = 0.9134669      CJSW    = cjswp3         
+MJSW    = 0.3237595      PBSW    = 0.9134669      CJSWG   = cjgatep3       
+MJSWG   = 0.3237595      PBSWG   = 0.9134669      CTA     = 8.3043E-4      
+CTP     = 4.30175E-4     PTA     = 1.3004E-3      PTP     = 1.3004E-3      
+JS      = 4E-07          JSW     = 1.5E-11        N       = 1         
+XTI     = 3              CGDO    = cgop3          CGSO    = cgop3    
+CAPMOD  = 0              NQSMOD  = 0              ELM     = 5         
+XPART   = 1              CGSL    = 0              CGDL    = 0          
+CKAPPA  = 0.6            CF      = 0              CLC     = 1E-07      
+CLE     = 0.6            ACM     = 12             )
*
.model p3.2          PMOS   (                    LMIN    = '6.1E-7-dxl3'
+LMAX    = '1.21E-6-dxl3' WMIN = '1.002E-5-dxw3'   WMAX    = '1.01E-4-dxw3' 
+LEVEL   = 49             VERSION = 3.1            LDIF    = 1.2E-07        
+HDIF    = hdifp3         RSH     = 3.5            RD      = 0              
+RS      = 0              TOX     = toxp3          XL      = '3E-8 + dxl3'   
+XW      = '0 + dxw3'     XJ      = 1E-07          NCH     = 3.5713E+17     
+LLN     = 1              LWN     = 1              WLN     = 1              
+WWN     = 1              LINT    = 1.508E-08      WINT    = 3.975E-09      
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0              
+DWB     = 0    VTH0    = 'dvthp3-0.7787412'       LVTH0   = -7.989225E-09  
+WVTH0   = -8.815329E-08  PVTH0   = -4.660162E-14  K1      = 0.8648968      
+LK1     = -6.693708E-08  WK1     = -1.409035E-06  PK1     = 1.276055E-12   
+K2      = -0.02659275    LK2     = 1.765373E-08   WK2     = 4.816605E-07   
+PK2     = -4.373647E-13  K3      = 0              DVT0    = 0              
+DVT1    = 0              DVT2    = 0              DVT0W   = 0              
+DVT1W   = 0              DVT2W   = 0              NLX     = 0              
+W0      = 0              K3B     = 0              VSAT    = 100967.2       
+LVSAT   = 2.459363E-03   UA      = 0              UB      = 1.119411E-18   
+LUB     = 5.250653E-26   WUB     = -4.890315E-24  PUB     = 4.749753E-30   
+UC      = -6.492389E-11  LUC     = 3.83315E-17    WUC     = -2.578813E-16  
+PUC     = 1.607398E-22   RDSW    = 1.098009E+03   PRWB    = 0              
+PRWG    = 0              WR      = 1.0108         U0      = 7.884884E-03   
+LU0     = 1.421426E-09   WU0     = -2.457324E-11  PU0     = -3.144964E-15  
+A0      = 1.343983       LA0     = -3.012292E-07  WA0     = -1.581927E-06  
+PA0     = 1.913878E-12   KETA    = -0.01443932    LKETA   = -6.576297E-09  
+WKETA   = -2.268973E-09  PKETA   = 2.745096E-15   A1      = 0              
+A2      = 1              AGS     = 0.3089089      LAGS    = -1.027261E-07  
+WAGS    = -1.375975E-06  PAGS    = 1.66471E-12    B0      = 0              
+B1      = 0              VOFF    = -0.1254649     LVOFF   = 8.098635E-09   
+WVOFF   = -2.628756E-07  PVOFF   = 7.062292E-15   NFACTOR = 0.958062       
+LNFACTOR= 1.099869E-07   WNFACTOR= -3.169983E-06  PNFACTOR= 2.434379E-12   
+CIT     = -1.000000E-04  CDSC    = 0              CDSCB   = 0              
+CDSCD   = 0              ETA0    = -5.082000E-04  LETA0   = 6.148407E-10   
+ETAB    = -1.750764E-04  LETAB   = 1.271256E-10   WETAB   = 3.392567E-09   
+PETAB   = -4.104463E-15  DSUB    = 0              PCLM    = 1.798016       
+LPCLM   = -1.004357E-07  WPCLM   = -6.785128E-07  PPCLM   = 8.208919E-13   
+PDIBLC1 = 0              PDIBLC2 = 1.673297E-03   LPDIBLC2= -5.060723E-10  
+WPDIBLC2= 8.481412E-09   PPDIBLC2= -1.026115E-14  PDIBLCB = 1.18661        
+LPDIBLCB= -6.496357E-07  WPDIBLCB= 2.261711E-06   PPDIBLCB= -2.736309E-12  
+DROUT   = 0              PSCBE1  = 6.907049E+08   LPSCBE1 = -118.2073      
+WPSCBE1 = -1.232633E+03  PPSCBE1 = 1.491288E-03   PSCBE2  = 1.038609E-05   
+LPSCBE2 = -2.763505E-12  WPSCBE2 = 8.594499E-12   PPSCBE2 = -1.039797E-17  
+PVAG    = -8.426216E-09  LPVAG   = 1.019437E-14   WPVAG   = 8.425532E-13   
+PPVAG   = -1.019355E-18  DELTA   = 0.01488128     LDELTA  = -7.032502E-10  
+WDELTA  = 2.318254E-08   PDELTA  = -2.804717E-14  ALPHA0  = 0              
+BETA0   = 30             KT1     = -0.3502311     LKT1    = -7.976104E-09  
+WKT1    = 5.444722E-07   PKT1    = -3.326733E-13  KT2     = -0.04522876    
+LKT2    = -1.407963E-09  WKT2    = 7.066122E-08   PKT2    = -2.015039E-14  
+AT      = 1.851607E+04   LAT     = -5.770658E-04  WAT     = 0.1721299      
+PAT     = 5.770191E-08   UTE     = -0.2939757     LUTE    = -5.149665E-07  
+WUTE    = -4.149904E-06  PUTE    = 9.416063E-13   UA1     = 4.098808E-09   
+LUA1    = -2.13216E-15   WUA1    = -4.744851E-14  PUA1    = 2.910362E-20   
+UB1     = -4.345198E-18  LUB1    = 1.776433E-24   WUB1    = 7.147221E-23   
+PUB1    = -5.162239E-29  UC1     = 5.971514E-11   LUC1    = -7.798723E-17  
+WUC1    = 2.285847E-15   PUC1    = -1.344589E-21  KT1L    = 0              
+PRT     = -1E-18         CJ      = cjp3           MJ      = 0.4812153    
+PB      = 0.9134669      CJSW    = cjswp3         MJSW    = 0.3237595    
+PBSW    = 0.9134669      CJSWG   = cjgatep3       MJSWG   = 0.3237595    
+PBSWG   = 0.9134669      CTA     = 8.3043E-4      CTP     = 4.30175E-4   
+PTA     = 1.3004E-3      PTP     = 1.3004E-3      JS      = 4E-07        
+JSW     = 1.5E-11        N       = 1              XTI     = 3          
+CGDO    = cgop3          CGSO    = cgop3          CAPMOD  = 0          
+NQSMOD  = 0              ELM     = 5              XPART   = 1          
+CGSL    = 0              CGDL    = 0              CKAPPA  = 0.6         
+CF      = 0              CLC     = 1E-07          CLE     = 0.6 
+ACM     = 12       )
*
.model p3.3          PMOS   (                    LMIN    = 3.0E-7
+LMAX    = '6.1E-7-dxl3'  WMIN = '1.002E-5-dxw3'   WMAX    = '1.01E-4-dxw3' 
+LEVEL   = 49             VERSION = 3.1            LDIF    = 1.2E-07        
+HDIF    = hdifp3         RSH     = 3.5            RD      = 0              
+RS      = 0              TOX     = toxp3          XL      = '3E-8 + dxl3'   
+XW      = '0 + dxw3'     XJ      = 1E-07          NCH     = 3.5713E+17     
+LLN     = 1              LWN     = 1              WLN     = 1              
+WWN     = 1              LINT    = 1.508E-08      WINT    = 3.975E-09      
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0              
+DWB     = 0     VTH0    = 'dvthp3 - 0.8105334'    LVTH0   = 1.139889E-08   
+WVTH0   = -5.147498E-08  PVTH0   = -6.896951E-14  K1      = 0.6946849      
+LK1     = 3.686494E-08   WK1     = 1.583435E-06   PK1     = -5.488731E-13  
+K2      = 0.04433798     LK2     = -2.560267E-08  WK2     = -4.337952E-07  
+PK2     = 1.209168E-13   K3      = 0              DVT0    = 0              
+DVT1    = 0              DVT2    = 0              DVT0W   = 0              
+DVT1W   = 0              DVT2W   = 0              NLX     = 0              
+W0      = 0              K3B     = 0              VSAT    = 9.570480E+04   
+LVSAT   = 5.668584E-03   UA      = 1.149196E-11   LUA     = -7.008252E-18  
+WUA     = -1.149103E-15  PUA     = 7.007687E-22   UB      = 1.01852E-18    
+LUB     = 1.140344E-25   WUB     = 5.545721E-24   PUB     = -1.614559E-30  
+UC      = -3.172816E-12  LUC     = 6.732269E-19   WUC     = 1.15781E-17    
+PUC     = -3.587372E-24  RDSW    = 1.098009E+03   PRWB    = 0              
+PRWG    = 0              WR      = 1.0108         U0      = 9.562983E-03   
+LU0     = 3.980543E-10   WU0     = -1.132408E-08  PU0     = 3.745925E-15   
+A0      = 0.8621702      LA0     = -7.400688E-09  WA0     = 1.491644E-06   
+PA0     = 3.94914E-14    KETA    = -0.03264993    LKETA   = 4.529256E-09   
+WKETA   = 3.471264E-08   PKETA   = -1.980777E-14  A1      = 0              
+A2      = 1              AGS     = 0.3538826      LAGS    = -1.301529E-07  
+WAGS    = 1.11701E-07    PAGS    = 7.574655E-13   B0      = 0              
+B1      = 0              VOFF    = -0.09486866    LVOFF   = -1.056016E-08  
+WVOFF   = -5.108326E-07  PVOFF   = 1.582764E-13   NFACTOR = 1.032306       
+LNFACTOR= 6.471025E-08   WNFACTOR= 1.670655E-06   PNFACTOR= -5.176357E-13  
+CIT     = -2.289652E-04  LCIT    = 7.864812E-11   CDSC    = 0              
+CDSCB   = 0              CDSCD   = 0              ETA0    = -1.729492E-03  
+LETA0   = 1.359633E-09   WETA0   = -1.45936E-08   PETA0   = 8.899762E-15   
+ETAB    = 1.244450E-03   LETAB   = -7.385584E-10  WETAB   = -6.705273E-09  
+PETAB   = 2.053603E-15   DSUB    = 0              PCLM    = 1.963528       
+LPCLM   = -2.013718E-07  WPCLM   = -4.466856E-06  PPCLM   = 3.131175E-12   
+PDIBLC1 = 0              PDIBLC2 = -1.199175E-03  LPDIBLC2= 1.245676E-09   
+WPDIBLC2= 1.018818E-08   PPDIBLC2= -1.1302E-14    PDIBLCB = -0.09693905    
+LPDIBLCB= 1.331238E-07   WPDIBLCB= -1.072667E-06  PPDIBLCB= -7.02871E-13   
+DROUT   = 0              PSCBE1  = 5.761836E+08   LPSCBE1 = -48.36762      
+WPSCBE1 = 98.11403       PPSCBE1 = 6.797457E-04   PSCBE2  = 1.034254E-05   
+LPSCBE2 = -2.736943E-12  WPSCBE2 = -1.204991E-10  PPSCBE2 = 6.832847E-17   
+PVAG    = -0.05163997    LPVAG   = 3.149213E-08   WPVAG   = -1.906604E-12  
+PPVAG   = 6.526417E-19   DELTA   = -3.163702E-03  LDELTA  = 1.03013E-08    
+WDELTA  = -3.774682E-08  PDELTA  = 9.110004E-15   ALPHA0  = 0              
+BETA0   = 30             KT1     = -0.3911383     LKT1    = 1.697076E-08   
+WKT1    = 2.389603E-07   PKT1    = -1.463599E-13  KT2     = -0.06434983    
+LKT2    = 1.025283E-08   WKT2    = 2.459298E-07   PKT2    = -1.270361E-13  
+AT      = 1.481030E+04   LAT     = 1.682857E-03   WAT     = 0.5426763      
+PAT     = -1.682721E-07  UTE     = -0.79171       LUTE    = -2.114282E-07  
+WUTE    = -9.545538E-06  PUTE    = 4.232079E-12   UA1     = 1.265856E-09   
+LUA1    = -4.04512E-16   WUA1    = -3.540695E-15  PUA1    = 2.326876E-21   
+UB1     = -1.380873E-18  LUB1    = -3.133061E-26  WUB1    = -2.504441E-23  
+PUB1    = 7.237305E-30   UC1     = -6.082557E-11  LUC1    = -4.476678E-18  
+WUC1    = -4.503395E-16  PUC1    = 3.240473E-22   KT1L    = 0              
+PRT     = -1E-18         CJ      = cjp3           MJ      = 0.4812153    
+PB      = 0.9134669      CJSW    = cjswp3         MJSW    = 0.3237595     
+PBSW    = 0.9134669      CJSWG   = cjgatep3       MJSWG   = 0.3237595      
+PBSWG   = 0.9134669      CTA     = 8.3043E-4      CTP     = 4.30175E-4   
+PTA     = 1.3004E-3      PTP     = 1.3004E-3      JS      = 4E-07      
+JSW     = 1.5E-11        N       = 1              XTI     = 3          
+CGDO    = cgop3          CGSO    = cgop3          CAPMOD  = 0          
+NQSMOD  = 0              ELM     = 5              XPART   = 1          
+CGSL    = 0              CGDL    = 0              CKAPPA  = 0.6         
+CF      = 0              CLC     = 1E-07          CLE     = 0.6        
+ACM     = 12             )
*
.model p3.4          PMOS   (                    LMIN    = '1.21E-6-dxl3' 
+LMAX    = '2.1E-5-dxl3'  WMIN  = '1.22E-6-dxw3'   WMAX    = '1.002E-5-dxw3' 
+LEVEL   = 49             VERSION = 3.1            LDIF    = 1.2E-07        
+HDIF    = hdifp3         RSH     = 3.5            RD      = 0              
+RS      = 0              TOX     = toxp3          XL      = '3E-8 + dxl3'   
+XW      = '0 + dxw3'     XJ      = 1E-07          NCH     = 3.5713E+17     
+LLN     = 1              LWN     = 1              WLN     = 1              
+WWN     = 1              LINT    = 1.508E-08      WINT    = 3.975E-09      
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0              
+DWB     = 0       VTH0    = 'dvthp3-0.7638058'    LVTH0   = -4.948918E-08  
+WVTH0   = 3.111849E-08   PVTH0   = 4.368585E-14   K1      = 0.7791258      
+LK1     = -7.560775E-09  WK1     = -1.28986E-08   PK1     = 3.141758E-14   
+K2      = -5.597151E-05  LK2     = 1.115123E-09   WK2     = 5.578022E-10   
+PK2     = -1.116154E-14  K3      = 0              DVT0    = 0              
+DVT1    = 0              DVT2    = 0              DVT0W   = 0              
+DVT1W   = 0              DVT2W   = 0              NLX     = 0              
+W0      = 0              K3B     = 0              VSAT    = 9.980694E+04   
+LVSAT   = 3.863091E-03   UA      = 0              UB      = 9.440003E-19   
+LUB     = 1.590789E-25   WUB     = -8.324545E-26  PUB     = -8.28868E-33   
+UC      = -6.655298E-11  LUC     = 2.820655E-17   WUC     = -1.726117E-17  
+PUC     = -9.267535E-24  RDSW    = 1.098009E+03   PRWB    = 0              
+PRWG    = 0              WR      = 1.0108         U0      = 8.233800E-03   
+LU0     = 7.20452E-10    WU0     = 3.564123E-11   PU0     = -4.260255E-16  
+A0      = 1.205055       LA0     = -1.339818E-07  WA0     = -9.67282E-08   
+PA0     = 1.253674E-13   KETA    = -1.438525E-03  LKETA   = -2.214055E-08  
+WKETA   = 1.547562E-11   PKETA   = -1.667062E-15  A1      = 4.608649E-03   
+LA1     = -5.575729E-09  A2      = 1              AGS     = 0.1344129      
+LAGS    = 1.100524E-07   WAGS    = -2.513589E-08  PAGS    = 1.372683E-14   
+B0      = 0              B1      = 0              VOFF    = -0.1325441     
+LVOFF   = -1.840357E-08  WVOFF   = -2.024599E-08  PVOFF   = 6.461137E-14   
+NFACTOR = 0.8662418      LNFACTOR= 8.419841E-08   WNFACTOR= -3.101805E-08  
+PNFACTOR= 7.145231E-15   CIT     = -1.076673E-04  LCIT    = 9.276272E-12   
+WCIT    = 7.676596E-11   PCIT    = -9.287453E-17  CDSC    = 0              
+CDSCB   = 0              CDSCD   = 0              ETA0    = 0              
+ETAB    = 4.416089E-06   LETAB   = -8.836522E-11  WETAB   = 8.874201E-13   
+PETAB   = -1.77572E-17   DSUB    = 0              PCLM    = 1.619607       
+LPCLM   = 1.079119E-07   WPCLM   = -3.993219E-09  PPCLM   = 7.990693E-14   
+PDIBLC1 = 0              PDIBLC2 = 2.571638E-05   LPDIBLC2= 1.486403E-09   
+WPDIBLC2= -4.437201E-13  PPDIBLC2= 8.878671E-18   PDIBLCB = 0.2732048      
+LPDIBLCB= 5.221589E-07   WPDIBLCB= 3.55325E-08    PPDIBLCB= -7.109985E-13  
+DROUT   = 0              PSCBE1  = 4.855003E+08   LPSCBE1 = 130.0574       
+PSCBE2  = 5.882862E-06   LPSCBE2 = 2.434979E-12   WPSCBE2 = -1.388513E-13  
+PPSCBE2 = 2.66802E-18    PVAG    = -9.022279E-08  LPVAG   = 1.091551E-13   
+WPVAG   = 1.093545E-13   PPVAG   = -1.323015E-19  DELTA   = 3.415102E-03   
+LDELTA  = 1.250411E-08   WDELTA  = -3.540822E-10  PDELTA  = 7.085125E-15   
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.328533      
+LKT1    = 1.842535E-09   WKT1    = 3.673162E-08   PKT1    = -7.952224E-14  
+KT2     = -0.03472884    LKT2    = -7.722492E-09  WKT2    = 1.067875E-08   
+PKT2    = -1.154516E-14  AT      = 1.879059E+04   LAT     = 0.02895249     
+WAT     = 1.756657E-03   PAT     = -3.515039E-08  UTE     = -1.000131      
+LUTE    = -9.854168E-08  WUTE    = 1.375149E-07   PUTE    = 1.38887E-13    
+UA1     = 8.861316E-10   LUA1    = -1.321159E-15  WUA1    = 6.70543E-16    
+PUA1    = 1.682571E-21   UB1     = -1.247807E-18  LUB1    = 1.854403E-24   
+WUB1    = -7.472166E-25  PUB1    = -2.547703E-30  UC1     = 2.117157E-11   
+LUC1    = 1.281554E-16   WUC1    = -5.474287E-17  PUC1    = -1.098816E-22  
+KT1L    = 0              PRT     = -1E-18         CJ      = cjp3           
+MJ      = 0.4812153      PB      = 0.9134669      CJSW    = cjswp3         
+MJSW    = 0.3237595      PBSW    = 0.9134669      CJSWG   = cjgatep3       
+MJSWG   = 0.3237595      PBSWG   = 0.9134669      CTA     = 8.3043E-4      
+CTP     = 4.30175E-4     PTA     = 1.3004E-3      PTP     = 1.3004E-3      
+JS      = 4E-07          JSW     = 1.5E-11        N       = 1         
+XTI     = 3              CGDO    = cgop3          CGSO    = cgop3 
+CAPMOD  = 0              NQSMOD  = 0              ELM     = 5         
+XPART   = 1              CGSL    = 0              CGDL    = 0          
+CKAPPA  = 0.6            CF      = 0              CLC     = 1E-07      
+CLE     = 0.6            ACM     = 12              )
*
.model p3.5          PMOS   (                    LMIN    = '6.1E-7-dxl3'
+LMAX    = '1.21E-6-dxl3' WMIN = '1.22E-6-dxw3'    WMAX    = '1.002E-5-dxw3' 
+LEVEL   = 49             VERSION = 3.1            LDIF    = 1.2E-07        
+HDIF    = hdifp3         RSH     = 3.5            RD      = 0              
+RS      = 0              TOX     = toxp3          XL      = '3E-8 + dxl3'   
+XW      = '0 + dxw3'     XJ      = 1E-07          NCH     = 3.5713E+17     
+LLN     = 1              LWN     = 1              WLN     = 1              
+WWN     = 1              LINT    = 1.508E-08      WINT    = 3.975E-09      
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0              
+DWB     = 0      VTH0    = 'dvthp3 - 0.7959896'   LVTH0   = -1.055195E-08  
+WVTH0   = 8.453827E-08   PVTH0   = -2.094355E-14  K1      = 0.7112885      
+LK1     = 7.45115E-08    WK1     = 1.288996E-07   PK1     = -1.401357E-13  
+K2      = 0.02622437     LK2     = -3.067989E-08  WK2     = -4.714721E-08  
+PK2     = 4.65539E-14    K3      = 0              DVT0    = 0              
+DVT1    = 0              DVT2    = 0              DVT0W   = 0              
+DVT1W   = 0              DVT2W   = 0              NLX     = 0              
+W0      = 0              K3B     = 0              VSAT    = 100967.2       
+LVSAT   = 2.459362E-03   UA      = 0              UB      = 6.367846E-19   
+LUB     = 5.307609E-25   WUB     = -5.822976E-26  PUB     = -3.855363E-32  
+UC      = -8.576691E-11  LUC     = 5.145232E-17   WUC     = -4.920009E-17  
+PUC     = 2.937346E-23   RDSW    = 1.098009E+03   PRWB    = 0              
+PRWG    = 0              WR      = 1.0108         U0      = 7.856577E-03   
+LU0     = 1.176832E-09   WU0     = 2.588536E-10   PU0     = -6.960769E-16  
+A0      = 1.184594       LA0     = -1.09227E-07   WA0     = 1.388557E-08   
+PA0     = -8.457553E-15  KETA    = -0.01439156    LKETA   = -6.469453E-09  
+WKETA   = -2.747229E-09  PKETA   = 1.67537E-15    A1      = 0              
+A2      = 1              AGS     = 0.1742576      LAGS    = 6.184669E-08   
+WAGS    = -2.784016E-08  PAGS    = 1.699857E-14   B0      = 0              
+B1      = 0              VOFF    = -0.1575021     LVOFF   = 1.179162E-08   
+WVOFF   = 5.788289E-08   PVOFF   = -2.991208E-14  NFACTOR = 0.6165309      
+LNFACTOR= 3.863086E-07   WNFACTOR= 2.494434E-07   PNFACTOR= -3.321682E-13  
+CIT     = -1.000000E-04  CDSC    = 0              CDSCB   = 0              
+CDSCD   = 0              ETA0    = -5.361982E-04  LETA0   = 6.487141E-10   
+WETA0   = 2.803209E-10   PETA0   = -3.391434E-16  ETAB    = 1.945475E-04   
+LETAB   = -3.183938E-10  WETAB   = -3.081267E-10  PETAB   = 3.561006E-16   
+DSUB    = 0              PCLM    = 1.717749       LPCLM   = -1.082386E-08  
+WPCLM   = 1.251261E-07   PPCLM   = -7.630679E-14  PDIBLC1 = 0              
+PDIBLC2 = 2.833799E-03   LPDIBLC2= -1.910928E-09  WPDIBLC2= -3.137604E-09  
+PPDIBLC2= 3.80434E-15    PDIBLCB = 1.52371        LPDIBLCB= -9.907519E-07  
+WPDIBLCB= -1.113349E-06  PPDIBLCB= 6.78965E-13    DROUT   = 0              
+PSCBE1  = 5.561107E+08   LPSCBE1 = 44.63015       WPSCBE1 = 114.9315       
+PPSCBE1 = -1.390488E-04  PSCBE2  = 1.042207E-05   LPSCBE2 = -3.056733E-12  
+WPSCBE2 = 8.234315E-12   PPSCBE2 = -7.462172E-18  PVAG    = 8.615787E-08   
+LPVAG   = -1.042372E-13  WPVAG   = -1.044276E-13  PPVAG   = 1.263408E-19   
+DELTA   = 0.01691317     LDELTA  = -3.826389E-09  WDELTA  = 2.839121E-09   
+PDELTA  = 3.22186E-15    ALPHA0  = 0              BETA0   = 30             
+KT1     = -0.2865496     LKT1    = -4.895061E-08  WKT1    = -9.311023E-08  
+PKT1    = 7.756564E-14   KT2     = -0.03687681    LKT2    = -5.123788E-09  
+WKT2    = -1.295893E-08  PKT2    = 1.705265E-14   AT      = 4.456219E+04   
+LAT     = -2.227032E-03  WAT     = -0.0886453     PAT     = 7.422153E-08   
+UTE     = -0.6937361     LUTE    = -4.692299E-07  WUTE    = -1.47484E-07   
+PUTE    = 4.836901E-13   UA1     = -9.669197E-10  LUA1    = 9.207365E-16   
+WUA1    = 3.269818E-15   PUA1    = -1.462136E-21  UB1     = 3.397643E-18   
+LUB1    = -3.76585E-24   WUB1    = -6.049514E-24  PUB1    = 3.86723E-30    
+UC1     = 3.139918E-10   LUC1    = -2.261103E-16  WUC1    = -2.59984E-16   
+PUC1    = 1.384274E-22   KT1L    = 0              PRT     = -1E-18         
+CJ      = cjp3           MJ      = 0.4812153      PB      = 0.9134669      
+CJSW    = cjswp3         MJSW    = 0.3237595      PBSW    = 0.9134669      
+CJSWG   = cjgatep3       MJSWG   = 0.3237595      PBSWG   = 0.9134669      
+CTA     = 8.3043E-4      CTP     = 4.30175E-4     PTA     = 1.3004E-3      
+PTP     = 1.3004E-3      JS      = 4E-07          JSW     = 1.5E-11        
+N       = 1              XTI     = 3              CGDO    = cgop3      
+CGSO    = cgop3          CAPMOD  = 0              NQSMOD  = 0              
+ELM     = 5              XPART   = 1              CGSL    = 0              
+CGDL    = 0              CKAPPA  = 0.6            CF      = 0              
+CLC     = 1E-07          CLE     = 0.6            ACM     = 12    )
*
.model p3.6          PMOS   (                    LMIN     = 3.0E-7
+LMAX    = '6.1E-7-dxl3'  WMIN = '1.22E-6-dxw3'    WMAX   = '1.002E-5-dxw3' 
+LEVEL   = 49             VERSION = 3.1            LDIF    = 1.2E-07        
+HDIF    = hdifp3         RSH     = 3.5            RD      = 0              
+RS      = 0              TOX     = toxp3          XL      = '3E-8 + dxl3'   
+XW      = '0 + dxw3'     XJ      = 1E-07          NCH     = 3.5713E+17     
+LLN     = 1              LWN     = 1              WLN     = 1              
+WWN     = 1              LINT    = 1.508E-08      WINT    = 3.975E-09      
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0              
+DWB     = 0        VTH0    = 'dvthp3-0.819592'    LVTH0   = 3.841725E-09   
+WVTH0   = 3.92202E-08    PVTH0   = 6.693215E-15   K1      = 0.8706061      
+LK1     = -2.264679E-08  WK1     = -1.778973E-07  PK1     = 4.696136E-14   
+K2      = -3.104115E-03  LK2     = -1.279421E-08  WK2     = 4.119749E-08   
+PK2     = -7.322229E-15  K3      = 0              DVT0    = 0              
+DVT1    = 0              DVT2    = 0              DVT0W   = 0              
+DVT1W   = 0              DVT2W   = 0              NLX     = 0              
+W0      = 0              K3B     = 0              VSAT    = 9.570480E+04   
+LVSAT   = 5.668584E-03   UA      = -1.17505E-10   LUA     = 7.165928E-17   
+WUA     = 1.42422E-16    PUA     = -8.685463E-23  UB      = 1.612172E-18   
+LUB     = -6.406956E-26  WUB     = -3.979593E-25  PUB     = 1.68627E-31    
+UC      = -1.806405E-12  LUC     = 2.498542E-19   WUC     = -2.102485E-18  
+PUC     = 6.514569E-25   RDSW    = 1.098009E+03   PRWB    = 0              
+PRWG    = 0              WR      = 1.0108         U0      = 8.543462E-03   
+LU0     = 7.579415E-10   WU0     = -1.116579E-09  PU0     = 1.427172E-16   
+A0      = 1.011152       LA0     = -3.455225E-09  WA0     = 3.475336E-11   
+PA0     = -1.076803E-17  KETA    = -0.02918284    LKETA   = 2.550863E-09   
+A1      = 0              A2      = 1              AGS     = 0.3650324      
+LAGS    = -5.44954E-08   WAGS    = 6.842664E-11   PAGS    = -2.119957E-17  
+B0      = 0              B1      = 0              VOFF    = -0.145021      
+LVOFF   = 4.180113E-09   WVOFF   = -8.705152E-09  PVOFF   = 1.069597E-14   
+NFACTOR = 1.184596       LNFACTOR= 3.987956E-08   WNFACTOR= 1.459106E-07   
+PNFACTOR= -2.690298E-13  CIT     = -9.025225E-05  LCIT    = -5.944534E-12  
+WCIT    = -1.388801E-09  PCIT    = 8.469461E-16   CDSC    = 0              
+CDSCB   = 0              CDSCD   = 0              ETA0    = -3.438132E-03  
+LETA0   = 2.41843E-09    WETA0   = 2.513394E-09   PETA0   = -1.700961E-15  
+ETAB    = 4.943232E-04   LETAB   = -5.012091E-10  WETAB   = 8.05038E-10    
+PETAB   = -3.227518E-16  DSUB    = 0              PCLM    = 1.575587       
+LPCLM   = 7.5872E-08     WPCLM   = -5.827693E-07  PPCLM   = 3.553961E-13   
+PDIBLC1 = 0              PDIBLC2 = -3.936144E-04  LPDIBLC2= 5.727767E-11   
+WPDIBLC2= 2.122867E-09   PPDIBLC2= 5.962956E-16   PDIBLCB = -0.2040397     
+LPDIBLCB= 6.289874E-08   WPDIBLCB= -3.70295E-10   PPDIBLCB= 2.258214E-16   
+DROUT   = 0              PSCBE1  = 6.090129E+08   LPSCBE1 = 12.36825       
+WPSCBE1 = -230.5753      PPSCBE1 = 7.165509E-05   PSCBE2  = -1.123225E-06  
+LPSCBE2 = 3.984048E-12   WPSCBE2 = -5.70334E-12   PPSCBE2 = 1.037566E-18   
+PVAG    = -0.05164019    LPVAG   = 3.14922E-08    DELTA   = -8.750087E-03  
+LDELTA  = 1.182409E-08   WDELTA  = 1.818436E-08   PDELTA  = -6.136279E-15  
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.3747727     
+LKT1    = 4.851371E-09   WKT1    = 7.510699E-08   PKT1    = -2.501994E-14  
+KT2     = -0.04159279    LKT2    = -2.247796E-09  WKT2    = 1.808515E-08   
+PKT2    = -1.879277E-15  AT      = 6.230534E+04   LAT     = -0.01304752    
+WAT     = 0.06715354     PAT     = -2.079083E-08  UTE     = -1.909328      
+LUTE    = 2.720863E-07   WUTE    = 1.644106E-06   PUTE    = -6.088935E-13  
+UA1     = 6.897726E-10   LUA1    = -8.958054E-17  WUA1    = 2.227084E-15   
+PUA1    = -8.262353E-22  UB1     = -3.945919E-18  LUB1    = 7.125484E-25   
+WUB1    = 6.369599E-25   PUB1    = -2.104496E-31  UC1     = -1.022409E-10  
+LUC1    = 2.772503E-17   WUC1    = -3.568694E-17  PUC1    = 1.642094E-24   
+KT1L    = 0              PRT     = -1E-18         CJ      = cjp3           
+MJ      = 0.4812153      PB      = 0.9134669      CJSW    = cjswp3         
+MJSW    = 0.3237595      PBSW    = 0.9134669      CJSWG   = cjgatep3       
+MJSWG   = 0.3237595      PBSWG   = 0.9134669      CTA     = 8.3043E-4      
+CTP     = 4.30175E-4     PTA     = 1.3004E-3      PTP     = 1.3004E-3      
+JS      = 4E-07          JSW     = 1.5E-11        N       = 1         
+XTI     = 3              CGDO    = cgop3          CGSO    = cgop3   
+CAPMOD  = 0              NQSMOD  = 0              ELM     = 5         
+XPART   = 1              CGSL    = 0              CGDL    = 0          
+CKAPPA  = 0.6            CF      = 0              CLC     = 1E-07      
+CLE     = 0.6            ACM     = 12              )
*
.model p3.7          PMOS   (                    LMIN    = '1.21E-6-dxl3' 
+LMAX    = '2.1E-5-dxl3'  WMIN  = '6.2E-7-dxw3'    WMAX    = '1.22E-6-dxw3' 
+LEVEL   = 49             VERSION = 3.1            LDIF    = 1.2E-07        
+HDIF    = hdifp3         RSH     = 3.5            RD      = 0              
+RS      = 0              TOX     = toxp3          XL      = '3E-8 + dxl3'   
+XW      = '0 + dxw3'     XJ      = 1E-07          NCH     = 3.5713E+17     
+LLN     = 1              LWN     = 1              WLN     = 1              
+WWN     = 1              LINT    = 1.508E-08      WINT    = 3.975E-09      
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0              
+DWB     = 0       VTH0    = 'dvthp3-0.7510185'    LVTH0   = -3.101654E-08  
+WVTH0   = 1.561961E-08   PVTH0   = 2.129609E-14   K1      = 0.7702026      
+LK1     = 3.045811E-08   WK1     = -2.083372E-09  PK1     = -1.466321E-14  
+K2      = 4.103410E-04   LK2     = -8.215712E-09  WK2     = -7.391349E-12  
+PK2     = 1.478998E-16   K3      = 0              DVT0    = 0              
+DVT1    = 0              DVT2    = 0              DVT0W   = 0              
+DVT1W   = 0              DVT2W   = 0              NLX     = 0              
+W0      = 0              K3B     = 0              VSAT    = 9.980694E+04   
+LVSAT   = 3.863092E-03   UA      = 0              UB      = 9.146453E-19   
+LUB     = 2.618486E-25   WUB     = -4.766568E-26  PUB     = -1.328507E-31  
+UC      = -7.762739E-11  LUC     = 3.755945E-17   WUC     = -3.838429E-18  
+PUC     = -2.060372E-23  RDSW    = 1.098009E+03   PRWB    = 0              
+PRWG    = 0              WR      = 1.0108         U0      = 8.021129E-03   
+LU0     = 8.991108E-10   WU0     = 2.934083E-10   PU0     = -6.425688E-16  
+A0      = 1.12495        LA0     = -2.05939E-08   WA0     = 3.634116E-10   
+PA0     = -1.206437E-14  KETA    = -1.179769E-03  LKETA   = -2.845762E-08  
+WKETA   = -2.98148E-10   PKETA   = 5.989546E-15   A1      = 4.608649E-03   
+LA1     = -5.575729E-09  A2      = 1              AGS     = 0.110507       
+LAGS    = 1.762511E-07   WAGS    = 3.839254E-09   PAGS    = -6.650924E-14  
+B0      = 0              B1      = 0              VOFF    = -0.1541273     
+LVOFF   = 4.979195E-08   WVOFF   = 5.913889E-09   PVOFF   = -1.804501E-14  
+NFACTOR = 1.23104        LNFACTOR= 2.737759E-07   WNFACTOR= -4.731722E-07  
+PNFACTOR= -2.226322E-13  CIT     = -1.141845E-03  LCIT    = 5.084295E-10   
+WCIT    = 1.330241E-09   PCIT    = -6.978733E-16  CDSC    = 0              
+CDSCB   = 0              CDSCD   = 0              ETA0    = 0              
+ETAB    = 5.148259E-06   LETAB   = -1.030158E-10  DSUB    = 0              
+PCLM    = 2.038702       LPCLM   = -1.137291E-08  WPCLM   = -5.119578E-07  
+PPCLM   = 2.244861E-13   PDIBLC1 = 0              PDIBLC2 = 2.535011E-05   
+LPDIBLC2= 1.493729E-09   PDIBLCB = 0.3025209      LPDIBLCB= -6.444924E-08  
+DROUT   = 0              PSCBE1  = 4.855003E+08   LPSCBE1 = 130.0574       
+PSCBE2  = 5.768303E-06   LPSCBE2 = 4.636224E-12   PVAG    = 0              
+DELTA   = 1.611263E-03   LDELTA  = 2.920755E-08   WDELTA  = 1.83226E-09    
+PDELTA  = -1.316028E-14  ALPHA0  = 0              BETA0   = 30             
+KT1     = -0.2554131     LKT1    = -1.594173E-07  WKT1    = -5.189339E-08  
+PKT1    = 1.159328E-13   KT2     = -0.01908976    LKT2    = -2.897392E-08  
+WKT2    = -8.276603E-09  PKT2    = 1.421263E-14   AT      = 2.024238E+04   
+LAT     = -9.754708E-05  WAT     = -2.983709E-06  PAT     = 5.970368E-11   
+UTE     = -0.7602648     LUTE    = 3.660924E-08   WUTE    = -1.532143E-07  
+PUTE    = -2.492275E-14  UA1     = 1.371046E-09   LUA1    = 1.237985E-15   
+WUA1    = 8.280238E-17   PUA1    = -1.419241E-21  UB1     = -1.415494E-18  
+LUB1    = -1.854057E-24  WUB1    = -5.439722E-25  PUB1    = 1.947137E-30   
+UC1     = 1.212391E-11   LUC1    = -6.19909E-18   WUC1    = -4.377665E-17  
+PUC1    = 5.296275E-23   KT1L    = 0              PRT     = -1E-18         
+CJ      = cjp3           MJ      = 0.4812153      PB      = 0.9134669      
+CJSW    = cjswp3         MJSW    = 0.3237595      PBSW    = 0.9134669      
+CJSWG   = cjgatep3       MJSWG   = 0.3237595      PBSWG   = 0.9134669      
+CTA     = 8.3043E-4      CTP     = 4.30175E-4     PTA     = 1.3004E-3      
+PTP     = 1.3004E-3      JS      = 4E-07          JSW     = 1.5E-11        
+N       = 1              XTI     = 3              CGDO    = cgop3      
+CGSO    = cgop3          CAPMOD  = 0              NQSMOD  = 0              
+ELM     = 5              XPART   = 1              CGSL    = 0              
+CGDL    = 0              CKAPPA  = 0.6            CF      = 0              
+CLC     = 1E-07          CLE     = 0.6            ACM     = 12      )
*
.model p3.8          PMOS   (                    LMIN    = '6.1E-7-dxl3'
+LMAX    = '1.21E-6-dxl3' WMIN = '6.2E-7-dxw3'     WMAX    = '1.22E-6-dxw3' 
+LEVEL   = 49             VERSION = 3.1            LDIF    = 1.2E-07        
+HDIF    = hdifp3         RSH     = 3.5            RD      = 0              
+RS      = 0              TOX     = toxp3          XL      = '3E-8 + dxl3'   
+XW      = '0 + dxw3'     XJ      = 1E-07          NCH     = 3.5713E+17     
+LLN     = 1              LWN     = 1              WLN     = 1              
+WWN     = 1              LINT    = 1.508E-08      WINT    = 3.975E-09      
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0              
+DWB     = 0        VTH0    = 'dvthp3-0.7287997'   LVTH0   = -5.789778E-08  
+WVTH0   = 3.100714E-09   PVTH0   = 3.644196E-14   K1      = 0.8219227      
+LK1     = -3.211485E-08  WK1     = -5.194562E-09  PK1     = -1.089917E-14  
+K2      = -0.01286564    LK2     = 7.846096E-09   WK2     = 2.318332E-10   
+PK2     = -1.415237E-16  K3      = 0              DVT0    = 0              
+DVT1    = 0              DVT2    = 0              DVT0W   = 0              
+DVT1W   = 0              DVT2W   = 0              NLX     = 0              
+W0      = 0              K3B     = 0              VSAT    = 100967.2       
+LVSAT   = 2.459363E-03   UA      = 0              UB      = 3.467359E-19   
+LUB     = 9.489283E-25   WUB     = 2.933238E-25   PUB     = -5.453934E-31  
+UC      = -1.673125E-10  LUC     = 1.460641E-16   WUC     = 4.96372E-17    
+PUC     = -8.530068E-23  RDSW    = 1.098009E+03   PRWB    = 0              
+PRWG    = 0              WR      = 1.0108         U0      = 7.510629E-03   
+LU0     = 1.516734E-09   WU0     = 6.781593E-10   PU0     = -1.108056E-15  
+A0      = 1.144124       LA0     = -4.379154E-08  WA0     = 6.293723E-08   
+PA0     = -8.776869E-14  KETA    = -0.02258383    LKETA   = -2.562129E-09  
+WKETA   = 7.18222E-09    PKETA   = -3.060503E-15  A1      = 0              
+A2      = 1              AGS     = 0.07492495     LAGS    = 2.192997E-07   
+WAGS    = 9.255601E-08   PAGS    = -1.738424E-13  B0      = 0              
+B1      = 0              VOFF    = -0.06866345    LVOFF   = -5.360564E-08  
+WVOFF   = -4.979402E-08  PVOFF   = 4.935266E-14   NFACTOR = 1.952897       
+LNFACTOR= -5.995556E-07  WNFACTOR= -1.3703E-06    PNFACTOR= 8.627486E-13   
+CIT     = -1.353394E-03  LCIT    = 7.643697E-10   WCIT    = 1.519176E-09   
+PCIT    = -9.264545E-16  CDSC    = 0              CDSCB   = 0              
+CDSCD   = 0              ETA0    = -4.086011E-04  LETA0   = 4.943421E-10   
+WETA0   = 1.256668E-10   PETA0   = -1.520368E-16  ETAB    = -5.9672E-05    
+LETAB   = -2.459362E-11  DSUB    = 0              PCLM    = 2.571367       
+LPCLM   = -6.558117E-07  WPCLM   = -9.095017E-07  PPCLM   = 7.054507E-13   
+PDIBLC1 = 0              PDIBLC2 = 1.335332E-03   LPDIBLC2= -9.113999E-11  
+WPDIBLC2= -1.321386E-09  PPDIBLC2= 1.598666E-15   PDIBLCB = 1.020075       
+LPDIBLCB= -9.325746E-07  WPDIBLCB= -5.029187E-07  PPDIBLCB= 6.084512E-13   
+DROUT   = 0              PSCBE1  = 6.509348E+08   LPSCBE1 = -70.09184      
+PSCBE2  = 1.721795E-05   LPSCBE2 = -9.216022E-12  WPSCBE2 = -2.639182E-15  
+PPSCBE2 = 3.193153E-21   PVAG    = 0              DELTA   = 0.03410684     
+LDELTA  = -1.010689E-08  WDELTA  = -1.800046E-08  PDELTA  = 1.083414E-14   
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.4408026     
+LKT1    = 6.487434E-08   WKT1    = 9.385207E-08   PKT1    = -6.03959E-14   
+KT2     = -0.0637809     LKT2    = 2.509522E-08   WKT2    = 1.965018E-08   
+PKT2    = -1.957431E-14  AT      = -7.836677E+04  LAT     = 0.1192037      
+WAT     = 0.06035074     PAT     = -7.295865E-08  UTE     = -0.3492924     
+LUTE    = -4.606017E-07  WUTE    = -5.64967E-07   PUTE    = 4.732323E-13   
+UA1     = 4.001703E-09   LUA1    = -1.944689E-15  WUA1    = -2.752402E-15  
+PUA1    = 2.010903E-21   UB1     = -3.230325E-18  LUB1    = 3.415976E-25   
+WUB1    = 1.983915E-24   PUB1    = -1.111202E-30  UC1     = 1.938424E-10   
+LUC1    = -2.260494E-16  WUC1    = -1.143569E-16  PUC1    = 1.383535E-22   
+KT1L    = 0              PRT     = -1E-18         CJ      = cjp3           
+MJ      = 0.4812153      PB      = 0.9134669      CJSW    = cjswp3         
+MJSW    = 0.3237595      PBSW    = 0.9134669      CJSWG   = cjgatep3       
+MJSWG   = 0.3237595      PBSWG   = 0.9134669      CTA     = 8.3043E-4      
+CTP     = 4.30175E-4     PTA     = 1.3004E-3      PTP     = 1.3004E-3      
+JS      = 4E-07          JSW     = 1.5E-11        N       = 1         
+XTI     = 3              CGDO    = cgop3          CGSO    = cgop3   
+CAPMOD  = 0              NQSMOD  = 0              ELM     = 5         
+XPART   = 1              CGSL    = 0              CGDL    = 0          
+CKAPPA  = 0.6            CF      = 0              CLC     = 1E-07      
+CLE     = 0.6            ACM     = 12             )
*
.model p3.9          PMOS   (                    LMIN    = 3.0E-7
+LMAX    = '6.1E-7-dxl3'  WMIN = '6.2E-7-dxw3'     WMAX    = '1.22E-6-dxw3' 
+LEVEL   = 49             VERSION = 3.1            LDIF    = 1.2E-07        
+HDIF    = hdifp3         RSH     = 3.5            RD      = 0              
+RS      = 0              TOX     = toxp3          XL      = '3E-8 + dxl3'   
+XW      = '0 + dxw3'     XJ      = 1E-07          NCH     = 3.5713E+17     
+LLN     = 1              LWN     = 1              WLN     = 1              
+WWN     = 1              LINT    = 1.508E-08      WINT    = 3.975E-09      
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0              
+DWB     = 0       VTH0    = 'dvthp3-0.8231277'    LVTH0   = -3.727549E-10  
+WVTH0   = 4.350571E-08   PVTH0   = 1.180138E-14   K1      = 0.7037677      
+LK1     = 3.994077E-08   WK1     = 2.43193E-08    PK1     = -2.88979E-14   
+K2      = 0.04723118     LK2     = -2.880335E-08  WK2     = -1.981142E-08  
+PK2     = 1.208165E-14   K3      = 0              DVT0    = 0              
+DVT1    = 0              DVT2    = 0              DVT0W   = 0              
+DVT1W   = 0              DVT2W   = 0              NLX     = 0              
+W0      = 0              K3B     = 0              VSAT    = 9.570480E+04   
+LVSAT   = 5.668584E-03   UA      = 0              UB      = 2.208989E-18   
+LUB     = -1.867483E-25  WUB     = -1.121331E-24  PUB     = 3.173199E-31   
+UC      = 1.478E-10      LUC     = -4.610416E-17  WUC     = -1.83433E-16   
+PUC     = 5.683485E-23   RDSW    = 1.098009E+03   PRWB    = 0              
+PRWG    = 0              WR      = 1.0108         U0      = 9.456248E-03   
+LU0     = 3.30218E-10    WU0     = -2.222922E-09  PU0     = 6.611395E-16   
+A0      = 1.147003       LA0     = -4.55473E-08   WA0     = -1.646235E-07  
+PA0     = 5.100694E-14   KETA    = -0.02180217    LKETA   = -3.038817E-09  
+WKETA   = -8.945741E-09  PKETA   = 6.774973E-15   A1      = 0              
+A2      = 1              AGS     = 0.6880049      LAGS    = -1.54581E-07   
+WAGS    = -3.913904E-07  PAGS    = 1.212876E-13   B0      = 0              
+B1      = 0              VOFF    = -0.1983031     LVOFF   = 2.545379E-08   
+WVOFF   = 5.587543E-08   PVOFF   = -1.50888E-14   NFACTOR = 1.317062       
+LNFACTOR= -2.117978E-07  WNFACTOR= -1.46442E-08   PNFACTOR= 3.60158E-14    
+CIT     = -2.098200E-03  LCIT    = 1.218583E-09   WCIT    = 1.044933E-09   
+PCIT    = -6.372423E-16  CDSC    = 0              CDSCB   = 0              
+CDSCD   = 0              ETA0    = -1.021823E-03  LETA0   = 8.683094E-10   
+WETA0   = -4.152935E-10  PETA0   = 1.778626E-16   ETAB    = 1.388770E-03   
+LETAB   = -9.079114E-10  WETAB   = -2.790762E-10  PETAB   = 1.701919E-16   
+DSUB    = 0              PCLM    = 0.125881       LPCLM   = 8.355433E-07   
+WPCLM   = 1.174347E-06   PPCLM   = -5.653636E-13  PDIBLC1 = 0              
+PDIBLC2 = -1.399557E-04  LPDIBLC2= 8.085496E-10   WPDIBLC2= 1.81542E-09    
+PPDIBLC2= -3.142837E-16  PDIBLCB = -1.034484      LPDIBLCB= 3.203773E-07   
+WPDIBLCB= 1.00617E-06    PPDIBLCB= -3.118512E-13  DROUT   = 0              
+PSCBE1  = 4.224645E+08   LPSCBE1 = 69.23847       WPSCBE1 = -4.469269      
+PPSCBE1 = 2.725538E-06   PSCBE2  = -6.140746E-06  LPSCBE2 = 5.029048E-12   
+WPSCBE2 = 3.781475E-13   PPSCBE2 = -2.29026E-19   PVAG    = -0.05164004    
+LPVAG   = 3.149216E-08   DELTA   = -2.935085E-03  LDELTA  = 1.248275E-08   
+WDELTA  = 1.113629E-08   PDELTA  = -6.934613E-15  ALPHA0  = 0              
+BETA0   = 30             KT1     = -0.277698      LKT1    = -3.459337E-08  
+WKT1    = -4.255248E-08  PKT1    = 2.278906E-14   KT2     = 5.578048E-04   
+LKT2    = -1.414109E-08  WKT2    = -3.300348E-08  PKT2    = 1.2536E-14     
+AT      = 217140.6       LAT     = -0.06100844    WAT     = -0.1205145     
+PAT     = 3.734022E-08   UTE     = -0.9997355     LUTE    = -6.393547E-08  
+WUTE    = 5.416355E-07   PUTE    = -2.016182E-13  UA1     = 1.791188E-09   
+LUA1    = -5.966282E-16  WUA1    = 8.921131E-16   PUA1    = -2.116681E-22  
+UB1     = -4.30027E-18   LUB1    = 9.940929E-25   WUB1    = 1.066451E-24   
+PUB1    = -5.516957E-31  UC1     = -3.59418E-10   LUC1    = 1.113509E-16   
+WUC1    = 2.760246E-16   PUC1    = -9.971669E-23  KT1L    = 0              
+PRT     = -1E-18         CJ      = cjp3           MJ      = 0.4812153    
+PB      = 0.9134669      CJSW    = cjswp3         MJSW    = 0.3237595    
+PBSW    = 0.9134669      CJSWG   = cjgatep3       MJSWG   = 0.3237595    
+PBSWG   = 0.9134669      CTA     = 8.3043E-4      CTP     = 4.30175E-4   
+PTA     = 1.3004E-3      PTP     = 1.3004E-3      JS      = 4E-07      
+JSW     = 1.5E-11        N       = 1              XTI     = 3          
+CGDO    = cgop3          CGSO    = cgop3          CAPMOD  = 0          
+NQSMOD  = 0              ELM     = 5              XPART   = 1          
+CGSL    = 0              CGDL    = 0              CKAPPA  = 0.6         
+CF      = 0              CLC     = 1E-07          CLE     = 0.6        
+ACM     = 12             )
*
.model p3.10          PMOS   (                   LMIN    = '1.21E-6-dxl3'
+LMAX    = '2.1E-5-dxl3'  WMIN    = 3E-7           WMAX    = '6.2E-7-dxw3'    
+LEVEL   = 49             VERSION = 3.1            LDIF    = 1.2E-07        
+HDIF    = hdifp3         RSH     = 3.5            RD      = 0              
+RS      = 0              TOX     = toxp3          XL      = '3E-8 + dxl3'   
+XW      = '0 + dxw3'     XJ      = 1E-07          NCH     = 3.5713E+17     
+LLN     = 1              LWN     = 1              WLN     = 1              
+WWN     = 1              LINT    = 1.508E-08      WINT    = 3.975E-09      
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0              
+DWB     = 0        VTH0    = 'dvthp3-0.7549086'   LVTH0   = -1.29914E-08   
+WVTH0   = 1.800059E-08   PVTH0   = 1.026381E-14   K1      = 0.7813262      
+LK1     = 2.952581E-08   WK1     = -8.891549E-09  PK1     = -1.409259E-14  
+K2      = 8.127961E-04   LK2     = -1.626875E-08  WK2     = -2.537134E-10  
+PK2     = 5.076759E-15   K3      = 0              DVT0    = 0              
+DVT1    = 0              DVT2    = 0              DVT0W   = 0              
+DVT1W   = 0              DVT2W   = 0              NLX     = 0              
+W0      = 0              K3B     = 0              VSAT    = 9.980694E+04   
+LVSAT   = 3.863092E-03   UA      = 0              UB      = 7.602362E-19   
+LUB     = 5.084309E-25   WUB     = 4.684038E-26   PUB     = -2.837713E-31  
+UC      = -8.576127E-11  LUC     = 3.229695E-17   WUC     = 1.139911E-18   
+PUC     = -1.738281E-23  RDSW    = 1.098009E+03   PRWB    = 0              
+PRWG    = 0              WR      = 1.0108         U0      = 8.274929E-03   
+LU0     = 8.951938E-10   WU0     = 1.380707E-10   PU0     = -6.401715E-16  
+A0      = 1.122715       LA0     = 1.629177E-08   WA0     = 1.731163E-09   
+PA0     = -3.464024E-14  KETA    = -1.250379E-03  LKETA   = -2.700609E-08  
+WKETA   = -2.549306E-10  PKETA   = 5.101133E-15   A1      = 4.608650E-03   
+LA1     = -5.575729E-09  A2      = 1              AGS     = 0.1124341      
+LAGS    = 1.545418E-07   WAGS    = 2.659801E-09   PAGS    = -5.322212E-14  
+B0      = 0              B1      = 0              VOFF    = -0.1533702     
+LVOFF   = 2.682115E-08   WVOFF   = 5.450527E-09   PVOFF   = -3.985739E-15  
+NFACTOR = 0.3918479      LNFACTOR= 2.302733E-07   WNFACTOR= 4.045555E-08   
+PNFACTOR= -1.960064E-13  CIT     = 1.066547E-03   LCIT    = -1.05992E-09   
+WCIT    = -2.140485E-11  PCIT    = 2.620349E-16   CDSC    = 0              
+CDSCB   = 0              CDSCD   = 0              ETA0    = 0              
+ETAB    = 5.148259E-06   LETAB   = -1.030158E-10  DSUB    = 0              
+PCLM    = 1.225801       LPCLM   = -1.160713E-07  WPCLM   = -1.442126E-08  
+PPCLM   = 2.885667E-13   PDIBLC1 = 0              PDIBLC2 = 2.535011E-05   
+LPDIBLC2= 1.493729E-09   PDIBLCB = 0.3025209      LPDIBLCB= -6.444924E-08  
+DROUT   = 0              PSCBE1  = 4.87485E+08    LPSCBE1 = 90.34364       
+WPSCBE1 = -1.214743      PPSCBE1 = 2.430681E-05   PSCBE2  = 5.768303E-06   
+LPSCBE2 = 4.636224E-12   PVAG    = 0              DELTA   = 3.149433E-03   
+LDELTA  = 4.632951E-09   WDELTA  = 8.90825E-10    PDELTA  = 1.880603E-15   
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.3417587     
+LKT1    = 6.120476E-08   WKT1    = 9.544786E-10   PKT1    = -1.909894E-14  
+KT2     = -0.03231348    LKT2    = -1.173619E-08  WKT2    = -1.830241E-10  
+PKT2    = 3.662278E-15   AT      = 2.023234E+04   LAT     = 1.033106E-04   
+WAT     = 3.160011E-06   PAT     = -6.323125E-11  UTE     = -1.195783      
+LUTE    = 2.704067E-07   WUTE    = 1.133445E-07   PUTE    = -1.680185E-13  
+UA1     = 9.428975E-10   LUA1    = -9.008473E-16  WUA1    = 3.448508E-16   
+PUA1    = -1.101685E-22  UB1     = -1.793045E-18  LUB1    = 1.460118E-24   
+WUB1    = -3.128918E-25  PUB1    = -8.130423E-32  UC1     = -4.384057E-11  
+LUC1    = 1.03284E-16    WUC1    = -9.523602E-18  PUC1    = -1.404637E-23  
+KT1L    = 0              PRT     = -1E-18         CJ      = cjp3           
+MJ      = 0.4812153      PB      = 0.9134669      CJSW    = cjswp3         
+MJSW    = 0.3237595      PBSW    = 0.9134669      CJSWG   = cjgatep3       
+MJSWG   = 0.3237595      PBSWG   = 0.9134669      CTA     = 8.3043E-4      
+CTP     = 4.30175E-4     PTA     = 1.3004E-3      PTP     = 1.3004E-3      
+JS      = 4E-07          JSW     = 1.5E-11        N       = 1         
+XTI     = 3              CGDO    = cgop3          CGSO    = cgop3   
+CAPMOD  = 0              NQSMOD  = 0              ELM     = 5         
+XPART   = 1              CGSL    = 0              CGDL    = 0          
+CKAPPA  = 0.6            CF      = 0              CLC     = 1E-07      
+CLE     = 0.6            ACM     = 12             )
*
.model p3.11          PMOS   (                   LMIN    = '6.1E-7-dxl3'
+LMAX    = '1.21E-6-dxl3' WMIN    = 3E-7           WMAX    = '6.2E-7-dxw3'    
+LEVEL   = 49             VERSION = 3.1            LDIF    = 1.2E-07        
+HDIF    = hdifp3         RSH     = 3.5            RD      = 0              
+RS      = 0              TOX     = toxp3          XL      = '3E-8 + dxl3'   
+XW      = '0 + dxw3'     XJ      = 1E-07          NCH     = 3.5713E+17     
+LLN     = 1              LWN     = 1              WLN     = 1              
+WWN     = 1              LINT    = 1.508E-08      WINT    = 3.975E-09      
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0              
+DWB     = 0       VTH0    = 'dvthp3-0.7975579'    LVTH0   = 3.860738E-08   
+WVTH0   = 4.51842E-08    PVTH0   = -2.262402E-14  K1      = 0.8543919      
+LK1     = -5.887207E-08  WK1     = -2.506739E-08  PK1     = 5.477592E-15   
+K2      = -0.02547546    LK2     = 1.553584E-08   WK2     = 7.949676E-09   
+PK2     = -4.84803E-15   K3      = 0              DVT0    = 0              
+DVT1    = 0              DVT2    = 0              DVT0W   = 0              
+DVT1W   = 0              DVT2W   = 0              NLX     = 0              
+W0      = 0              K3B     = 0              VSAT    = 100967.2       
+LVSAT   = 2.459362E-03   UA      = 0              UB      = 1.228049E-18   
+LUB     = -5.754732E-26  WUB     = -2.460837E-25  PUB     = 7.061995E-32   
+UC      = -6.561112E-11  LUC     = 7.918495E-18   WUC     = -1.26091E-17   
+PUC     = -7.486993E-25  RDSW    = 1.098009E+03   PRWB    = 0              
+PRWG    = 0              WR      = 1.0108         U0      = 9.709074E-03   
+LU0     = -8.398937E-10  WU0     = -6.673992E-10  PU0     = 3.343183E-16   
+A0      = 1.335579       LA0     = -2.412398E-07  WA0     = -5.424299E-08  
+PA0     = 3.307955E-14   KETA    = -0.0193247     LKETA   = -5.13905E-09   
+WKETA   = 5.187466E-09   PKETA   = -1.483298E-15  A1      = 0              
+A2      = 1              AGS     = 0.2988802      LAGS    = -7.10282E-08   
+WAGS    = -4.451581E-08  PAGS    = 3.852829E-15   B0      = 0              
+B1      = 0              VOFF    = -0.1808948     LVOFF   = 6.012144E-08   
+WVOFF   = 1.889714E-08   PVOFF   = -2.025399E-14  NFACTOR = 9.783612E-03   
+LNFACTOR= 6.9251E-07     WNFACTOR= -1.81017E-07   PNFACTOR= 7.193994E-14   
+CIT     = 4.856916E-04   LCIT    = -3.571781E-10  WCIT    = 3.93564E-10    
+PCIT    = -2.400111E-16  CDSC    = 0              CDSCB   = 0              
+CDSCD   = 0              ETA0    = 8.165084E-06   LETA0   = -9.878435E-12  
+WETA0   = -1.294149E-10  PETA0   = 1.565714E-16   ETAB    = -5.967201E-05  
+LETAB   = -2.459362E-11  DSUB    = 0              PCLM    = -0.2766705     
+LPCLM   = 1.701678E-06   WPCLM   = 8.336395E-07   PPCLM   = -7.374511E-13  
+PDIBLC1 = 0              PDIBLC2 = -8.259449E-04  LPDIBLC2= 2.52366E-09    
+WPDIBLC2= 1.423432E-12   PPDIBLC2= -1.722298E-18  PDIBLCB = -0.4887641     
+LPDIBLCB= 8.928791E-07   WPDIBLCB= 4.205661E-07   PPDIBLCB= -5.088177E-13  
+DROUT   = 0              PSCBE1  = 5.887471E+08   LPSCBE1 = -32.16734      
+WPSCBE1 = 38.06194       PPSCBE1 = -2.321169E-05  PSCBE2  = 1.721364E-05   
+LPSCBE2 = -9.210803E-12  PVAG    = 0              DELTA   = -3.264007E-03  
+LDELTA  = 1.239219E-08   WDELTA  = 4.87236E-09    PDELTA  = -2.936418E-15  
+ALPHA0  = 0              BETA0   = 30             KT1     = -0.2514489     
+LKT1    = -4.805565E-08  WKT1    = -2.204182E-08  PKT1    = 8.722905E-15   
+KT2     = -0.03619039    LKT2    = -7.045743E-09  WKT2    = 2.763405E-09   
+PKT2    = 9.757023E-17   AT      = 2.039927E+04   LAT     = -9.865599E-05  
+WAT     = -9.901354E-05  PAT     = 6.038241E-11   UTE     = -1.639615      
+LUTE    = 8.073725E-07   WUTE    = 2.247748E-07   PUTE    = -3.028314E-13  
+UA1     = -2.596232E-09  LUA1    = 3.380934E-15   WUA1    = 1.285864E-15   
+PUA1    = -1.248645E-21  UB1     = 2.025418E-18   LUB1    = -3.159612E-24  
+WUB1    = -1.232863E-24  PUB1    = 1.031713E-30   UC1     = 7.125604E-11   
+LUC1    = -3.596451E-17  WUC1    = -3.932791E-17  PUC1    = 2.201208E-23   
+KT1L    = 0              PRT     = -1E-18         CJ      = cjp3           
+MJ      = 0.4812153      PB      = 0.9134669      CJSW    = cjswp3         
+MJSW    = 0.3237595      PBSW    = 0.9134669      CJSWG   = cjgatep3       
+MJSWG   = 0.3237595      PBSWG   = 0.9134669      CTA     = 8.3043E-4      
+CTP     = 4.30175E-4     PTA     = 1.3004E-3      PTP     = 1.3004E-3      
+JS      = 4E-07          JSW     = 1.5E-11        N       = 1         
+XTI     = 3              CGDO    = cgop3          CGSO    = cgop3   
+CAPMOD  = 0              NQSMOD  = 0              ELM     = 5         
+XPART   = 1              CGSL    = 0              CGDL    = 0          
+CKAPPA  = 0.6            CF      = 0              CLC     = 1E-07      
+CLE     = 0.6            ACM     = 12             )
*
.model p3.12          PMOS   (                   LMIN    = 3.0E-7
+LMAX    = '6.1E-7-dxl3'  WMIN    = 3E-7           WMAX    = '6.2E-7-dxw3'   
+LEVEL   = 49             VERSION = 3.1            LDIF    = 1.2E-07        
+HDIF    = hdifp3         RSH     = 3.5            RD      = 0              
+RS      = 0              TOX     = toxp3          XL      = '3E-8 + dxl3'   
+XW      = '0 + dxw3'     XJ      = 1E-07          NCH     = 3.5713E+17     
+LLN     = 1              LWN     = 1              WLN     = 1              
+WWN     = 1              LINT    = 1.508E-08      WINT    = 3.975E-09      
+MOBMOD  = 1              BINUNIT = 2              DWG     = 0              
+DWB     = 0        VTH0    = 'dvthp3-0.7599265'   LVTH0   = 1.565825E-08   
+WVTH0   = 4.823419E-09   PVTH0   = 1.989598E-15   K1      = 0.7723792      
+LK1     = -8.857386E-09  WK1     = -1.767434E-08  PK1     = 9.690108E-16   
+K2      = 0.0234262      LK2     = -1.428635E-08  WK2     = -5.241576E-09  
+PK2     = 3.196523E-15   K3      = 0              DVT0    = 0              
+DVT1    = 0              DVT2    = 0              DVT0W   = 0              
+DVT1W   = 0              DVT2W   = 0              NLX     = 0              
+W0      = 0              K3B     = 0              VSAT    = 9.570480E+04   
+LVSAT   = 5.668585E-03   UA      = 0              UB      = 6.947468E-20   
+LUB     = 6.489974E-25   WUB     = 1.881585E-25   PUB     = -1.941983E-31  
+UC      = -1.906514E-10  LUC     = 8.417307E-17   WUC     = 2.37162E-17    
+PUC     = -2.290133E-23  RDSW    = 1.098009E+03   PRWB    = 0              
+PRWG    = 0              WR      = 1.0108         U0      = 5.128722E-03   
+LU0     = 1.953388E-09   WU0     = 4.2574E-10     PU0     = -3.323216E-16  
+A0      = 1.200317       LA0     = -1.587518E-07  WA0     = -1.972546E-07  
+PA0     = 1.202938E-13   KETA    = -0.05072558    LKETA   = 1.401046E-08   
+WKETA   = 8.756827E-09   PKETA   = -3.660038E-15  A1      = 0              
+A2      = 1              AGS     = 0.1332853      LAGS    = 2.995818E-08   
+WAGS    = -5.187436E-08  PAGS    = 8.340369E-15   B0      = 0              
+B1      = 0              VOFF    = -0.05026326    LVOFF   = -1.954286E-08  
+WVOFF   = -3.473233E-08  PVOFF   = 1.24514E-14    NFACTOR = 1.173939       
+LNFACTOR= -1.743855E-08  WNFACTOR= 7.295417E-08   PNFACTOR= -8.294182E-14  
+CIT     = 1.408905E-04   LCIT    = -1.469047E-10  WCIT    = -3.255022E-10  
+PCIT    = 1.985043E-16   CDSC    = 0              CDSCB   = 0              
+CDSCD   = 0              ETA0    = -1.607587E-03  LETA0   = 9.754714E-10   
+WETA0   = -5.677736E-11  PETA0   = 1.122741E-16   ETAB    = 5.030868E-04   
+LETAB   = -3.677864E-10  WETAB   = 2.630061E-10   PETAB   = -1.603917E-16  
+DSUB    = 0              PCLM    = 3.475284       LPCLM   = -5.864133E-07  
+WPCLM   = -8.75655E-07   PPCLM   = 3.049448E-13   PDIBLC1 = 0              
+PDIBLC2 = 4.637278E-03   LPDIBLC2= -8.080318E-10  WPDIBLC2= -1.108486E-09  
+PPDIBLC2= 6.751449E-16   PDIBLCB = 1.983737       LPDIBLCB= -6.149509E-07  
+WPDIBLCB= -8.411324E-07  PPDIBLCB= 2.606165E-13   DROUT   = 0              
+PSCBE1  = 3.79711E+08    LPSCBE1 = 95.31127       WPSCBE1 = 21.698         
+PPSCBE1 = -1.323232E-05  PSCBE2  = -7.478644E-06  LPSCBE2 = 5.847538E-12   
+WPSCBE2 = 1.197007E-12   PPSCBE2 = -7.299828E-19  PVAG    = -0.1053542     
+LPVAG   = 6.424921E-08   WPVAG   = 3.287577E-08   PPVAG   = -2.004896E-14  
+DELTA   = 0.02841229     LDELTA  = -6.925283E-09  WDELTA  = -8.049872E-09  
+PDELTA  = 4.944075E-15   ALPHA0  = 0              BETA0   = 30             
+KT1     = -0.3174393     LKT1    = -7.812106E-09  WKT1    = -1.822883E-08  
+PKT1    = 6.397589E-15   KT2     = -0.06565281    LKT2    = 1.092161E-08   
+WKT2    = 7.520721E-09   PKT2    = -2.803631E-15  AT      = 2.023750E+04   
+UTE     = 1.109414       LUTE    = -8.690954E-07  WUTE    = -7.492698E-07  
+PUTE    = 2.911799E-13   UA1     = 5.556E-09      LUA1    = -1.590623E-15  
+WUA1    = -1.41214E-15   PUA1    = 3.967063E-22   UB1     = -2.447667E-18  
+LUB1    = -4.317459E-25  WUB1    = -6.743478E-26  PUB1    = 3.20989E-31    
+UC1     = 2.389311E-10   LUC1    = -1.382195E-16  WUC1    = -9.0195E-17    
+PUC1    = 5.303287E-23   KT1L    = 0              PRT     = -1E-18         
+CJ      = cjp3           MJ      = 0.4812153      PB      = 0.9134669      
+CJSW    = cjswp3         MJSW    = 0.3237595      PBSW    = 0.9134669      
+CJSWG   = cjgatep3       MJSWG   = 0.3237595      PBSWG   = 0.9134669      
+CTA     = 8.3043E-4      CTP     = 4.30175E-4     PTA     = 1.3004E-3      
+PTP     = 1.3004E-3      JS      = 4E-07          JSW     = 1.5E-11        
+N       = 1              XTI     = 3              CGDO    = cgop3      
+CGSO    = cgop3          CAPMOD  = 0              NQSMOD  = 0              
+ELM     = 5              XPART   = 1              CGSL    = 0              
+CGDL    = 0              CKAPPA  = 0.6            CF      = 0              
+CLC     = 1E-07          CLE     = 0.6            ACM     = 12      )
*
***************************************************************
*               3.3V NMOS DEVICES MODEL                       *
*                  WITH ESD IMPLANT                           *
***************************************************************
*
.MODEL ech3 NMOS (                                 LEVEL   = 49                 
+VERSION = 3.1            LMIN    = 5E-7           LMAX    = 2E-6               
+WMIN    = 1.5E-5         WMAX    = 2E-4           XL      = '0.03E-6+dxl3'   
+XW      = '0+dxw3'       TNOM    = 25             TOX     = toxe3             
+XJ      = 1.5E-7         NCH     = 1.69E17        LLN     = 1                  
+LWN     = 1              WLN     = 1              WWN     = 1                  
+LINT    = 1.99E-8        WINT    = 1.88E-8        MOBMOD  = 1                  
+BINUNIT = 2              DWG     = 0              DWB     = 0                  
+VTH0    = 'dvthe3+0.538667' LVTH0 = -2.675774E-9  WVTH0   = 1.201026E-7        
+PVTH0   = -1.28983E-13   K1      = 0.4968983      LK1     = 1.770367E-8        
+WK1     = 3.077284E-8    PK1     = -1.63590E-13   K2      = 0.0300104          
+LK2     = -1.783164E-8   WK2     = 1.179027E-8    PK2     = 4.669794E-15       
+K3      = 0              DVT0    = 0              DVT1    = 0                  
+DVT2    = 0              DVT0W   = 0              DVT1W   = 0                  
+DVT2W   = 0              NLX     = 0              W0      = 0                  
+K3B     = 0              VSAT    = 1.04E5         UA      = -6.09396E-10       
+LUA     = -1.75579E-16   WUA     = -2.79729E-15   PUA     = 6.362498E-21       
+UB      = 1.526094E-18   LUB     = 3.894086E-25   WUB     = 2.318054E-24       
+PUB     = -5.38885E-30   UC      = 2.446888E-11   LUC     = 3.056293E-17       
+WUC     = 3.914042E-17   PUC     = -2.66895E-23   RDSW    = 121.98167          
+PRWB    = 2.91E-11       PRWG    = 2.91E-11       WR      = 0.73               
+U0      = 0.0315176      LU0     = -4.45912E-10   WU0     = -1.446996E-8       
+PU0     = 3.686383E-14   A0      = 1.7009453      LA0     = -6.640547E-7       
+WA0     = -4.15121E-6    PA0     = 3.642564E-12   KETA    = -7.859678E-3       
+LKETA   = 2.773914E-10   WKETA   = -3.895231E-8   PKETA   = -2.13182E-14       
+A1      = 0              A2      = 1.065825       LA2     = -2.339897E-7       
+WA2     = -2.376851E-7   PA2     = 4.801713E-13   AGS     = 0.3667209          
+LAGS    = -1.584547E-7   WAGS    = 1.034402E-7    PAGS    = -3.75730E-13       
+B0      = 0              B1      = 0              VOFF    = -0.1602946         
+LVOFF   = -1.151879E-8   WVOFF   = 9.268059E-8    PVOFF   = -1.39229E-13       
+NFACTOR = 2.1421781      LNFACTOR= -6.549162E-7   WNFACTOR= 6.269482E-7        
+PNFACTOR= -2.05297E-12   CIT     = -2.094649E-4   LCIT    = 3.34917E-10        
+WCIT    = -3.046879E-9   PCIT    = 5.195496E-15   CDSC    = 0                  
+CDSCB   = 0              CDSCD   = 2.91E-11       ETA0    = 1.113719E-5        
+LETA0   = -2.29736E-12   WETA0   = -1.13677E-10   PETA0   = 2.296493E-16       
+ETAB    = 1.554666E-4    LETAB   = -3.14074E-10   WETAB   = 1.372558E-9        
+PETAB   = -2.77284E-15   DSUB    = 0              PCLM    = 1.4412937          
+LPCLM   = 8.058956E-8    WPCLM   = -3.468443E-6   PPCLM   = 2.784211E-12       
+PDIBLC1 = 0              PDIBLC2 = 5.271764E-3    LPDIBLC2= -5.49016E-10       
+WPDIBLC2= -2.716612E-8   PPDIBLC2= 5.4881E-14     PDIBLCB = 0.1820228          
+LPDIBLCB= 9.351745E-9    WPDIBLCB= 1.790962E-7    PPDIBLCB= -9.31658E-14       
+DROUT   = 0              PSCBE1  = 3.484928E8     LPSCBE1 = -32.73701          
+WPSCBE1 = -721.8098      PPSCBE1 = 6.001474E-4    PSCBE2  = 5.987646E-6        
+LPSCBE2 = -2.33447E-12   WPSCBE2 = -4.47077E-11   PPSCBE2 = 2.325696E-17       
+PVAG    = 5.451575       LPVAG   = -2.597972E-6   WPVAG   = -5.563467E-5       
+PPVAG   = 2.855657E-11   DELTA   = -2.366685E-3   LDELTA  = 1.00553E-8         
+WDELTA  = 3.742707E-8    PDELTA  = -9.79640E-14   ALPHA0  = 0                  
+BETA0   = 30             KT1     = -0.333394      LKT1    = 1.660288E-9        
+WKT1    = -1.654576E-7   PKT1    = 2.581405E-13   KT2     = -0.0313848         
+LKT2    = 1.428912E-9    WKT2    = 5.129326E-8    PKT2    = -5.23984E-14       
+AT      = -670.4982      LAT     = -3.906036E-4   WAT     = -0.015951          
+PAT     = 4.728915E-9    UTE     = -1.0817207     LUTE    = -1.222841E-7       
+WUTE    = 1.080394E-7    PUTE    = -1.78303E-12   UA1     = 2.267406E-9        
+LUA1    = -2.76328E-16   WUA1    = 3.552807E-15   PUA1    = -1.17995E-20       
+UB1     = -1.94603E-18   LUB1    = -7.72466E-26   WUB1    = -5.59128E-24       
+PUB1    = 1.354413E-29   UC1     = -2.56681E-11   LUC1    = 7.655498E-18       
+WUC1    = -2.75498E-16   PUC1    = 3.285472E-22   KT1L    = 0                  
+PRT     = -0.1691113     LPRT    = 2.901957E-7    WPRT    = 1.160136E-6        
+PPRT    = -2.61814E-12   CJ      = cje3           MJ      = 0.376203           
+PB      = 0.8351256      CJSW    = cjswe3         MJSW    = 0.2945822          
+PBSW    = 0.8351256      CJSWG   = cjgatee3       MJSWG   = 0.2945822          
+PBSWG   = 0.8351256      HDIF    = hdife3         LDIF    = 1.2E-7             
+ACM     = 12             RS      = 0              RD      = 0                  
+RSH     = 60             CTA     = 9.368412E-4    CTP     = 5.837846E-4        
+PTA     = 1.743614E-3    PTP     = 1.743614E-3    CGDO    = cgoe3          
+CGSO    = cgoe3          CAPMOD  = 0              NQSMOD  = 0                  
+ELM     = 5              XPART   = 1              CGSL    = 0                  
+CGDL    = 0              CKAPPA  = 0.6            CF      = 0                  
+CLC     = 1E-7           CLE     = 0.6            TLEV    = 1                  
+TLEVC   = 1              JS      = 1.050984E-6    JSW     = 6.465319E-11    )
*
.ENDL MOS3
.LIB BIP
*
***************************************************************
*            MODEL OF P+/NW/PSUB VERTICAL BIPOLAR             *
*                 EMITTER AREA : 10 X 10 UM^2                 *
***************************************************************
.MODEL PNP10 PNP (                                  LEVEL  = 1                  
+ BF     = 2.1941657       NF     = 0.9925516       ISE    = 7.732726E-20       
+ NE     = 1.7564561       IBE    = 8.37043E-18     RB     = 105.4927285        
+ IRB    = 3.663633E-4     RBM    = 0.1             RE     = 1.001E-3           
+ IKF    = 1.825318E-3     NKF    = 0.4818924       VAF    = 626.9606502        
+ BR     = 0.6275311       NR     = 0.986091        IBC    = 8.616904E-18       
+ ISC    = 2.918982E-15    NC     = 1.0372162       RC     = 21.08              
+ IKR    = 6.865935E-4     VAR    = 13.9183647      XTI    = 3                  
+ EG     = 1.18            XTB    = 1.62            TRB1   = 1.498198E-3        
+ TIRB1  = 8.286864E-7     TRM1   = 9.44068E-6      TRE1   = 3.021132E-4        
+ TIKF1  = -3.425766E-3    TIKR1  = -3.925072E-3    TRC1   = 8E-5               
+ TNE1   = 8.25298E-5      TBF1   = 5.456497E-3     TNF1   = -8E-5              
+ TVAF1  = -4.002763E-5    TBR1   = 9E-4            TNC1   = 4E-4               
+ TNR1   = 9.2E-4          CJE    = 1.931092E-13    VJE    = 0.9134669          
+ MJE    = 0.4881215       FC     = 0.5             CJC    = 2.761147E-14       
+ VJC    = 0.6810191       MJC    = 0.4503098       TLEVC  = 1                  
+ CTE    = 8.288678E-4     CTC    = 2.666699E-3     TVJE   = 1.286639E-3        
+ TVJC   = 1.810191E-3     TREF   = 25              SUBS   = 1               )  
.ENDL BIP
*
***************************************************************
*                      MODEL OF N+/PW DIODE                   *
***************************************************************
.LIB DIO    
.MODEL NDIO D (                                     IS     = 1.0769E-4          
+ RS     = 1.801971E-7     N      = 1.5016888       BV     = 7                  
+ IBV    = 1E-3            IK     = 4.5781E5        IKR    = 3.5E-3             
+ JSW    = 2.4029E-9       AREA   = 7.5E-8          PJ     = 1.1E-3             
+ CJ     = 2.024128E-3     PB     = 0.9173808       MJ     = 0.4960069          
+ FC     = 0.5             CJSW   = 2.751528E-10    PHP    = 0.9173808          
+ MJSW   = 0.443145        CTA    = 7.707813E-4     CTP    = 5.512283E-4        
+ TLEV   = 1               EG     = 1.17            XTI    = 3                  
+ TRS    = 3.2236E-3       TLEVC  = 1               TPB    = 1.167715E-3        
+ TCV    = -3E-4           TPHP   = 1.167715E-3     TREF   = 25                 
+ LEVEL  = 3               )                                                    
*
***************************************************************
*                      MODEL OF P+/NW DIODE                   *
***************************************************************
.MODEL PDIO D (                                     IS     = 1.9281E-4          
+ RS     = 1.955033E-7     N      = 1.4816888       BV     = 6.8                
+ IBV    = 1E-3            IK     = 4.5781E5        IKR    = 1E-3               
+ JSW    = 6.59E-9         AREA   = 7.5E-8          PJ     = 1.1E-3             
+ CJ     = 1.931092E-3     PB     = 0.9134669       MJ     = 0.4812153          
+ FC     = 0.5             CJSW   = 2.232277E-10    PHP    = 0.9134669          
+ MJSW   = 0.3237595       CTA    = 8.304317E-4     CTP    = 4.301751E-4        
+ TLEV   = 1               EG     = 1.17            XTI    = 3                  
+ TRS    = 3.5943E-3       TLEVC  = 1               TPB    = 1.30037E-3         
+ TCV    = -5E-4           TPHP   = 1.30037E-3      TREF   = 25                 
+ LEVEL  = 3               )                                                    
*                                                                               
***************************************************************
*                      MODEL OF NW/PSUB DIODE                 *
***************************************************************
.MODEL NW_DIO D (                                   LEVEL  = 3                  
+ IS     = 4.1296E-6       RS     = 1.504067E-7     N      = 1.2645946          
+ BV     = 18.5            IBV    = 0.03            IK     = 4.5781E5           
+ IKR    = 65              JSW    = 1.4088E-10      AREA   = 7.56614E-8         
+ PJ     = 1.1048E-3       CJ     = 1.153705E-4     PB     = 0.7147275          
+ MJ     = 0.4204926       CJSW   = 4.222814E-10    PHP    = 0.7147275          
+ MJSW   = 0.2589437       TLEV   = 1               EG     = 1.17               
+ XTI    = 3               TCV    = -8.4E-4         TRS    = 2.78E-3            
+ TLEVC  = 1               CTA    = 2.875348E-3     CTP    = 1.629489E-3        
+ TPB    = 3.402024E-3     TPHP   = 3.402024E-3     TREF   = 25                 
+ FC     = 0.5             )                                                    
*                                                                               
.ENDL DIO                                                                       
