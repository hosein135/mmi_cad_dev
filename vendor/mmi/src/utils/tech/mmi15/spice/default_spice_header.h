 ********************** begin header *****************************

* Header file for TSMC 0.15 um CMOS (1.5V)

.OPTIONS post ACCT OPTS lvltim=2 NOMOD

.option gmindc=   10.0p       

**################################################
.options brief
.lib '/volume/mmi_proj/proj/tech/mmi15/spice/tsmc15.mod' TT
.options brief=0
* Allowed corners: TT, FF, SS, FS, SF

* Note: min W is 0.18 um 
**################################################

.param  arean(w,sdd) = '(w*sdd*1p)'
.param  areap(w,sdd) = '(w*sdd*1p)'
.param  perin(w,sdd) = '(2u*(w+sdd))'
.param  perip(w,sdd) = '(2u*(w+sdd))'

.param ln_min   =  0.15u
.param lp_min   =  0.15u

* used in source/drain area/perimeter calculation
.param sdd        =  0.395

.PARAM vddp=1.35		$ VDD voltage

VDD vdd 0 DC vddp 

.TEMP 105
.TRAN 10p 10n
*********************** end header ******************************
