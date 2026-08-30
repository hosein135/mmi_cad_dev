*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INAND2C in0 in1 out
C_1 net_1 gnd 2.47923fF
C_2 in1 gnd 0.81931fF
C_3 vdd gnd 3.07991fF
C_4 out gnd 2.08856fF
C_5 in0 gnd 1.63996fF
C_6 gnd gnd 2.60372fF
Mp_1 net_1 in1 vdd vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.57408P 
+ PS=2.832U
Mp_2 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.57408P PD=2.832U AS=0.4968P 
+ PS=2.38U
Mp_3 out net_1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.57408P 
+ PS=2.832U
Mp_4 vdd in0 out vdd p W=1.84U L=0.18U AD=0.57408P PD=2.832U AS=0.4968P 
+ PS=2.38U
Mp_5 out in0 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.57408P 
+ PS=2.832U
Mn_1 net_1 in1 gnd gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.37168P 
+ PS=2.088U
Mn_2 gnd in0 net_2 gnd n W=1.84U L=0.18U AD=0.74336P PD=4.176U AS=0.3588P 
+ PS=2.23U
Mn_3 net_2 net_1 out gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mn_4 out net_1 net_3 gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.3588P 
+ PS=2.23U
Mn_5 net_3 in0 gnd gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.74336P 
+ PS=4.176U
.ENDS	$ MMI_INAND2C

.GLOBAL gnd vdd

