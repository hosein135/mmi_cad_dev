*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OR3C in0 in1 in2 out
C_1 vdd gnd 3.77312fF
C_2 in2 gnd 1.74805fF
C_3 in1 gnd 1.64574fF
C_4 in0 gnd 1.47261fF
C_5 net_3 gnd 3.34282fF
C_6 out gnd 1.10696fF
C_7 gnd gnd 3.86204fF
Mp_1 vdd in2 net_1 vdd p W=1.86U L=0.18U AD=0.719368P PD=3.813U AS=0.3627P 
+ PS=2.25U
Mp_2 net_1 in1 net_2 vdd p W=1.86U L=0.18U AD=0.3627P PD=2.25U AS=0.3627P 
+ PS=2.25U
Mp_3 net_2 in0 net_3 vdd p W=1.86U L=0.18U AD=0.3627P PD=2.25U AS=0.5022P 
+ PS=2.4U
Mp_4 net_3 in0 net_4 vdd p W=1.86U L=0.18U AD=0.5022P PD=2.4U AS=0.3627P 
+ PS=2.25U
Mp_5 net_4 in1 net_5 vdd p W=1.86U L=0.18U AD=0.3627P PD=2.25U AS=0.3627P 
+ PS=2.25U
Mp_6 net_5 in2 vdd vdd p W=1.86U L=0.18U AD=0.3627P PD=2.25U AS=0.719368P 
+ PS=3.813U
Mp_7 vdd net_3 out vdd p W=1.84U L=0.18U AD=0.711632P PD=3.772U AS=0.4968P 
+ PS=2.38U
Mp_8 out net_3 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.711632P 
+ PS=3.772U
Mn_1 net_3 in2 gnd gnd n W=0.62U L=0.18U AD=0.2108P PD=1.50667U 
+ AS=0.253965P PS=1.69578U
Mn_2 gnd in1 net_3 gnd n W=0.62U L=0.18U AD=0.253965P PD=1.69578U 
+ AS=0.2108P PS=1.50667U
Mn_3 net_3 in0 gnd gnd n W=0.62U L=0.18U AD=0.2108P PD=1.50667U 
+ AS=0.253965P PS=1.69578U
Mn_4 gnd net_3 out gnd n W=0.92U L=0.18U AD=0.376852P PD=2.51632U 
+ AS=0.2484P PS=1.46U
Mn_5 out net_3 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.376852P 
+ PS=2.51632U
.ENDS	$ MMI_OR3C

.GLOBAL gnd vdd

