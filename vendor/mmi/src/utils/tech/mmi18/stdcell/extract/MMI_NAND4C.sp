*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND4C in0 in1 in2 in3 out
C_1 vdd gnd 5.44987fF
C_2 in1 gnd 1.39741fF
C_3 out gnd 5.33102fF
C_4 in0 gnd 1.43011fF
C_5 in2 gnd 1.68081fF
C_6 in3 gnd 1.67427fF
C_7 gnd gnd 3.70995fF
Mp_1 vdd in1 out vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.4968P 
+ PS=2.38U
Mp_2 out in1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.69P 
+ PS=3.51U
Mp_3 vdd in0 out vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.4968P 
+ PS=2.38U
Mp_4 out in0 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.69P 
+ PS=3.51U
Mp_5 vdd in2 out vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.4968P 
+ PS=2.38U
Mp_6 out in2 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.69P 
+ PS=3.51U
Mp_7 vdd in3 out vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.4968P 
+ PS=2.38U
Mp_8 out in3 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.69P 
+ PS=3.51U
Mn_1 out in0 net_1 gnd n W=7.36U L=0.18U AD=3.5328P PD=15.68U AS=0.92P 
+ PS=7.61U
Mn_2 net_1 in1 net_2 gnd n W=7.36U L=0.18U AD=0.92P PD=7.61U AS=0.92P 
+ PS=7.61U
Mn_3 net_2 in2 net_3 gnd n W=7.36U L=0.18U AD=0.92P PD=7.61U AS=0.92P 
+ PS=7.61U
Mn_4 net_3 in3 gnd gnd n W=7.36U L=0.18U AD=0.92P PD=7.61U AS=3.5328P 
+ PS=15.68U
.ENDS	$ MMI_NAND4C

.GLOBAL gnd vdd

