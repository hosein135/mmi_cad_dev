*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INOR2C in0 in1 out
C_1 net_1 gnd 3.94956fF
C_2 in1 gnd 1.01842fF
C_3 vdd gnd 3.83366fF
C_4 in0 gnd 2.94822fF
C_5 out gnd 2.7308fF
C_6 gnd gnd 3.04976fF
Mp_1 net_1 in1 vdd vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.57408P 
+ PS=2.832U
Mp_2 vdd in0 net_2 vdd p W=1.84U L=0.18U AD=0.57408P PD=2.832U AS=0.3588P 
+ PS=2.23U
Mp_3 net_2 net_1 out vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mp_4 out net_1 net_3 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.3588P 
+ PS=2.23U
Mp_5 net_3 in0 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.57408P 
+ PS=2.832U
Mp_6 vdd in0 net_4 vdd p W=1.84U L=0.18U AD=0.57408P PD=2.832U AS=0.3588P 
+ PS=2.23U
Mp_7 net_4 net_1 out vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mp_8 out net_1 net_5 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.3588P 
+ PS=2.23U
Mp_9 net_5 in0 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.57408P 
+ PS=2.832U
Mn_1 net_1 in1 gnd gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.28704P 
+ PS=1.728U
Mn_2 gnd in0 out gnd n W=0.92U L=0.18U AD=0.28704P PD=1.728U AS=0.2484P 
+ PS=1.46U
Mn_3 out in0 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.28704P 
+ PS=1.728U
Mn_4 gnd net_1 out gnd n W=0.92U L=0.18U AD=0.28704P PD=1.728U AS=0.2484P 
+ PS=1.46U
Mn_5 out net_1 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.28704P 
+ PS=1.728U
.ENDS	$ MMI_INOR2C

.GLOBAL gnd vdd

