*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OAI22B in0 in1 in2 in3 out
C_1 out gnd 3.8388fF
C_2 in0 gnd 1.81848fF
C_3 in1 gnd 2.01606fF
C_4 vdd gnd 3.20654fF
C_5 in2 gnd 2.26941fF
C_6 in3 gnd 2.02485fF
C_7 gnd gnd 3.32939fF
C_8 net_5 gnd 2.1759fF
Mp_1 out in0 net_1 vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.3588P 
+ PS=2.23U
Mp_2 net_1 in1 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mp_3 vdd in1 net_2 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.3588P 
+ PS=2.23U
Mp_4 net_2 in0 out vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.69P 
+ PS=3.51U
Mp_5 out in2 net_3 vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.3588P 
+ PS=2.23U
Mp_6 net_3 in3 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mp_7 vdd in3 net_4 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.3588P 
+ PS=2.23U
Mp_8 net_4 in2 out vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.69P 
+ PS=3.51U
Mn_1 gnd in2 net_5 gnd n W=0.92U L=0.18U AD=0.345P PD=2.13U AS=0.2796P 
+ PS=2.08U
Mn_2 net_5 in0 out gnd n W=0.92U L=0.18U AD=0.2796P PD=2.08U AS=0.2484P 
+ PS=1.46U
Mn_3 out in0 net_5 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2796P 
+ PS=2.08U
Mn_4 net_5 in2 gnd gnd n W=0.92U L=0.18U AD=0.2796P PD=2.08U AS=0.345P 
+ PS=2.13U
Mn_5 gnd in3 net_5 gnd n W=0.92U L=0.18U AD=0.345P PD=2.13U AS=0.2796P 
+ PS=2.08U
Mn_6 net_5 in1 out gnd n W=0.92U L=0.18U AD=0.2796P PD=2.08U AS=0.2484P 
+ PS=1.46U
Mn_7 out in1 net_5 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2796P 
+ PS=2.08U
Mn_8 net_5 in3 gnd gnd n W=0.92U L=0.18U AD=0.2796P PD=2.08U AS=0.345P 
+ PS=2.13U
.ENDS	$ MMI_OAI22B

.GLOBAL gnd vdd

