********************** begin header *****************************

* Header file for TSMC 2.5V 0.25 um logic process

.OPTIONS post ACCT OPTS lvltim=2

.option gmindc=   10.0p       

.options ADM_V_SUPPLY=2.5
*.options ADM_ACCURACY=10
*.options ADM_MODE=exp
.options ADM_MODE=acs
*.options ADM_MAXSTEP=10p
.options ignore_meas=0
*.param temper = 105

**################################################
* Corners are TT, SS, FF, SF, FS
.lib '/volume/cad/mmi/mmi_local.dev/sue/tech/tsmc25.l' TT
**################################################

.param  arean(w,sdd) = '(w*sdd*1p)'
.param  areap(w,sdd) = '(w*sdd*1p)'
.param  perin(w,sdd) = '(2u*(w+sdd))'
.param  perip(w,sdd) = '(2u*(w+sdd))'

.param ln_min   =  0.24u
.param lp_min   =  0.24u

* used in source/drain area/perimeter calculation
.param sdd        =  0.68

.PARAM vddp=2.25		$ VDD voltage

VDD vdd 0 DC vddp 

.TEMP 110
.TRAN 10p 16n
*********************** end header ******************************
