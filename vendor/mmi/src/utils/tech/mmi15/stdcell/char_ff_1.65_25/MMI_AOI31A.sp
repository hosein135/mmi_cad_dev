*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AOI31A in0 in1 in2 in3 out
C_1 out gnd 1.17931fF
C_2 in0 gnd 0.720457fF
C_3 net_1 gnd 0.94142fF
C_4 in1 gnd 0.77056fF
C_5 vdd gnd 1.85324fF
C_6 in2 gnd 0.701455fF
C_7 in3 gnd 0.74009fF
C_8 gnd gnd 1.82588fF
Mp_1 out in0 net_1 vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.3388P 
+ PS=1.98U
Mp_2 net_1 in1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.428633P 
+ PS=2.61U
Mp_3 vdd in2 net_1 vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.3388P 
+ PS=1.98U
Mp_4 net_1 in3 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.428633P 
+ PS=2.61U
Mn_1 gnd in0 out gnd n W=0.385U L=0.15U AD=0.152075P PD=1.165U AS=0.122238P 
+ PS=1.015U
Mn_2 out in1 net_2 gnd n W=1.155U L=0.15U AD=0.366712P PD=3.045U AS=0.1848P 
+ PS=1.475U
Mn_3 net_2 in2 net_3 gnd n W=1.155U L=0.15U AD=0.1848P PD=1.475U AS=0.1848P 
+ PS=1.475U
Mn_4 net_3 in3 gnd gnd n W=1.155U L=0.15U AD=0.1848P PD=1.475U AS=0.456225P 
+ PS=3.495U
.ENDS	$ MMI_AOI31A

.GLOBAL gnd vdd

