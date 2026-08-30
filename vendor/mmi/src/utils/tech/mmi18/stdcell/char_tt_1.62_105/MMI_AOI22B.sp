*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AOI22B in0 in1 in2 in3 out
C_1 vdd gnd 3.92843fF
C_2 in2 gnd 2.29551fF
C_3 net_1 gnd 2.5212fF
C_4 in0 gnd 1.45384fF
C_5 out gnd 3.28379fF
C_6 in3 gnd 1.91189fF
C_7 in1 gnd 2.50672fF
C_8 gnd gnd 3.25217fF
Mp_1 vdd in2 net_1 vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.4968P 
+ PS=2.38U
Mp_2 net_1 in0 out vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_3 out in0 net_1 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_4 net_1 in2 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.69P 
+ PS=3.51U
Mp_5 vdd in3 net_1 vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.4968P 
+ PS=2.38U
Mp_6 net_1 in1 out vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_7 out in1 net_1 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_8 net_1 in3 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.69P 
+ PS=3.51U
Mn_1 gnd in1 net_2 gnd n W=0.92U L=0.18U AD=0.345P PD=2.13U AS=0.1794P 
+ PS=1.31U
Mn_2 net_2 in0 out gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.345P 
+ PS=2.13U
Mn_3 out in0 net_3 gnd n W=0.92U L=0.18U AD=0.345P PD=2.13U AS=0.1794P 
+ PS=1.31U
Mn_4 net_3 in1 gnd gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.345P 
+ PS=2.13U
Mn_5 out in2 net_4 gnd n W=0.92U L=0.18U AD=0.345P PD=2.13U AS=0.1794P 
+ PS=1.31U
Mn_6 net_4 in3 gnd gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.345P 
+ PS=2.13U
Mn_7 gnd in3 net_5 gnd n W=0.92U L=0.18U AD=0.345P PD=2.13U AS=0.1794P 
+ PS=1.31U
Mn_8 net_5 in2 out gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.345P 
+ PS=2.13U
.ENDS	$ MMI_AOI22B

.GLOBAL gnd vdd

