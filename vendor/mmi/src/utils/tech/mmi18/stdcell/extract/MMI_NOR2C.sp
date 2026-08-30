*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NOR2C in0 in1 out
C_1 vdd gnd 3.77312fF
C_2 in1 gnd 2.6611fF
C_3 in0 gnd 2.09508fF
C_4 out gnd 3.04932fF
C_5 gnd gnd 3.14834fF
Mp_1 vdd in1 net_1 vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.3588P 
+ PS=2.23U
Mp_2 net_1 in0 out vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mp_3 out in0 net_2 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.3588P 
+ PS=2.23U
Mp_4 net_2 in1 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.69P 
+ PS=3.51U
Mp_5 vdd in1 net_3 vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.3588P 
+ PS=2.23U
Mp_6 net_3 in0 out vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mp_7 out in0 net_4 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.3588P 
+ PS=2.23U
Mp_8 net_4 in1 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.69P 
+ PS=3.51U
Mn_1 gnd in0 out gnd n W=0.92U L=0.18U AD=0.345P PD=2.13U AS=0.2484P 
+ PS=1.46U
Mn_2 out in0 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.345P 
+ PS=2.13U
Mn_3 gnd in1 out gnd n W=0.92U L=0.18U AD=0.345P PD=2.13U AS=0.2484P 
+ PS=1.46U
Mn_4 out in1 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.345P 
+ PS=2.13U
.ENDS	$ MMI_NOR2C

.GLOBAL gnd vdd

