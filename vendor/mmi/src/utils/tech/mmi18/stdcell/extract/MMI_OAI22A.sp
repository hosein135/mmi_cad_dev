*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OAI22A in0 in1 in2 in3 out
C_1 vdd gnd 2.4917fF
C_2 in3 gnd 1.01002fF
C_3 in2 gnd 1.54276fF
C_4 out gnd 1.79267fF
C_5 in0 gnd 1.0089fF
C_6 in1 gnd 1.01298fF
C_7 gnd gnd 1.7897fF
C_8 net_3 gnd 0.49442fF
Mp_1 vdd in3 net_1 vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.3588P 
+ PS=2.23U
Mp_2 net_1 in2 out vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mp_3 out in0 net_2 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.3588P 
+ PS=2.23U
Mp_4 net_2 in1 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.8832P 
+ PS=4.64U
Mn_1 gnd in3 net_3 gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.2484P 
+ PS=1.46U
Mn_2 net_3 in0 out gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2484P 
+ PS=1.46U
Mn_3 out in1 net_3 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2484P 
+ PS=1.46U
Mn_4 net_3 in2 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.4416P 
+ PS=2.8U
.ENDS	$ MMI_OAI22A

.GLOBAL gnd vdd

