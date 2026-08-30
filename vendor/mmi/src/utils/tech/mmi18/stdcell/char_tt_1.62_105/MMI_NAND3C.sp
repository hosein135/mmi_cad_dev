*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND3C in0 in1 in2 out
C_1 vdd gnd 4.6664fF
C_2 in0 gnd 1.41819fF
C_3 out gnd 3.59901fF
C_4 in1 gnd 1.36347fF
C_5 in2 gnd 1.39311fF
C_6 net_1 gnd 1.61348fF
C_7 net_2 gnd 1.7258fF
C_8 gnd gnd 3.4145fF
Mp_1 vdd in0 out vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.4968P 
+ PS=2.38U
Mp_2 out in0 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mp_3 vdd in1 out vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.4968P 
+ PS=2.38U
Mp_4 out in1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mp_5 vdd in2 out vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.4968P 
+ PS=2.38U
Mp_6 out in2 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mn_1 out in0 net_1 gnd n W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.4968P 
+ PS=2.38U
Mn_2 net_1 in0 out gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mn_3 out in0 net_1 gnd n W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.4968P 
+ PS=2.38U
Mn_4 net_1 in1 net_2 gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mn_5 net_2 in1 net_1 gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mn_6 net_1 in1 net_2 gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mn_7 net_2 in2 gnd gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mn_8 gnd in2 net_2 gnd n W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.4968P 
+ PS=2.38U
Mn_9 net_2 in2 gnd gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
.ENDS	$ MMI_NAND3C

.GLOBAL gnd vdd

