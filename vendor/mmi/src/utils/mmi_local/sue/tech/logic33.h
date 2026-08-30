********************** begin header *****************************

* Header file for TSMC 3.3V 0.35 um logic process

.OPTIONS post ACCT OPTS lvltim=2
.OP

.option gmindc=   10.0p       

.options ADM_V_SUPPLY=3.3
*.options ADM_ACCURACY=10
*.options ADM_MODE=exp
.options ADM_MODE=acs
*.options ADM_MAXSTEP=10p
.options ignore_meas=0
*.param temper = 105

**################################################
* Corners are TT, SS, FF, SF, FS
*.lib '/home/tavrow/tech/tsmc33.mod' TT
.lib '/home/cad/mmi_local/sue/tech/tsmc33.mod' TT
**################################################

.param  arean(w,sdd) = '(w*sdd*1p)'
.param  areap(w,sdd) = '(w*sdd*1p)'
.param  perin(w,sdd) = '(2u*(w+sdd))'
.param  perip(w,sdd) = '(2u*(w+sdd))'

.param ln_min   =  0.35u
.param lp_min   =  0.35u

* used in source/drain area/perimeter calculation
.param sdd        =  0.95

.PARAM vddp=3.0		$ VDD voltage

VDD vdd 0 DC vddp 

.TEMP 105
.TRAN 10p 16n
*********************** end header ******************************
