*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_XNOR2C in0 in1 out
C_1 vdd gnd 4.96766fF
C_2 net_1 gnd 4.20081fF
C_3 out gnd 3.04555fF
C_4 in0 gnd 3.40129fF
C_5 in1 gnd 3.77088fF
C_6 net_6 gnd 2.51837fF
C_7 gnd gnd 4.15451fF
Mp_1 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.5934P PD=2.945U AS=0.4968P 
+ PS=2.38U
Mp_2 out net_1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.5934P 
+ PS=2.945U
Mp_3 vdd in0 net_2 vdd p W=1.84U L=0.18U AD=0.5934P PD=2.945U AS=0.3588P 
+ PS=2.23U
Mp_4 net_2 in1 out vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mp_5 out in1 net_3 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.3588P 
+ PS=2.23U
Mp_6 net_3 in0 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.5934P 
+ PS=2.945U
Mp_7 vdd in0 net_4 vdd p W=1.84U L=0.18U AD=0.5934P PD=2.945U AS=0.3588P 
+ PS=2.23U
Mp_8 net_4 in1 out vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mp_9 out in1 net_5 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.3588P 
+ PS=2.23U
Mp_10 net_5 in0 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.5934P 
+ PS=2.945U
Mp_11 vdd in0 net_1 vdd p W=1.84U L=0.18U AD=0.5934P PD=2.945U AS=0.4968P 
+ PS=2.38U
Mp_12 net_1 in1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.5934P 
+ PS=2.945U
Mn_1 net_6 net_1 out gnd n W=1.84U L=0.18U AD=0.6256P PD=3.13333U 
+ AS=0.4968P PS=2.38U
Mn_2 out net_1 net_6 gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mn_3 net_6 in1 gnd gnd n W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.57592P 
+ PS=2.834U
Mn_4 gnd in1 net_6 gnd n W=1.84U L=0.18U AD=0.57592P PD=2.834U AS=0.6256P 
+ PS=3.13333U
Mn_5 net_6 in0 gnd gnd n W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.57592P 
+ PS=2.834U
Mn_6 gnd in0 net_6 gnd n W=1.84U L=0.18U AD=0.57592P PD=2.834U AS=0.6256P 
+ PS=3.13333U
Mn_7 net_1 in0 net_7 gnd n W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.3588P 
+ PS=2.23U
Mn_8 net_7 in1 gnd gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.57592P 
+ PS=2.834U
.ENDS	$ MMI_XNOR2C

.GLOBAL gnd vdd

