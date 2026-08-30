*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AOI22A in0 in1 in2 in3 out
C_1 vdd gnd 2.37002fF
C_2 in2 gnd 2.10752fF
C_3 net_1 gnd 1.15898fF
C_4 in1 gnd 1.20203fF
C_5 out gnd 1.22787fF
C_6 in0 gnd 1.10925fF
C_7 in3 gnd 1.00574fF
C_8 gnd gnd 2.04476fF
Mp_1 vdd in2 net_1 vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.4968P 
+ PS=2.38U
Mp_2 net_1 in1 out vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_3 out in0 net_1 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_4 net_1 in3 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.8832P 
+ PS=4.64U
Mn_1 gnd in1 net_2 gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.1794P 
+ PS=1.31U
Mn_2 net_2 in0 out gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.2484P 
+ PS=1.46U
Mn_3 out in2 net_3 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.1794P 
+ PS=1.31U
Mn_4 net_3 in3 gnd gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.4416P 
+ PS=2.8U
.ENDS	$ MMI_AOI22A

.GLOBAL gnd vdd

