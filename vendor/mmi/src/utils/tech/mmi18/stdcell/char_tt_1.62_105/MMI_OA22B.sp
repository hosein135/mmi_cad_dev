*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OA22B in0 in1 in2 in3 out
C_1 out gnd 1.38785fF
C_2 net_1 gnd 2.70942fF
C_3 vdd gnd 2.3978fF
C_4 in3 gnd 1.0545fF
C_5 in2 gnd 1.51481fF
C_6 in0 gnd 1.14601fF
C_7 in1 gnd 1.86145fF
C_8 gnd gnd 2.22962fF
C_9 net_4 gnd 0.72842fF
Mp_1 out net_1 vdd vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.6256P 
+ PS=3.13333U
Mp_2 vdd in3 net_2 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.3588P 
+ PS=2.23U
Mp_3 net_2 in2 net_1 vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.5014P 
+ PS=2.385U
Mp_4 net_1 in0 net_3 vdd p W=1.84U L=0.18U AD=0.5014P PD=2.385U AS=0.3588P 
+ PS=2.23U
Mp_5 net_3 in1 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.6256P 
+ PS=3.13333U
Mn_1 out net_1 gnd gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.3496P 
+ PS=1.98667U
Mn_2 gnd in3 net_4 gnd n W=0.92U L=0.18U AD=0.3496P PD=1.98667U AS=0.2484P 
+ PS=1.46U
Mn_3 net_4 in1 net_1 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2484P 
+ PS=1.46U
Mn_4 net_1 in0 net_4 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2484P 
+ PS=1.46U
Mn_5 net_4 in2 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.3496P 
+ PS=1.98667U
.ENDS	$ MMI_OA22B

.GLOBAL gnd vdd

