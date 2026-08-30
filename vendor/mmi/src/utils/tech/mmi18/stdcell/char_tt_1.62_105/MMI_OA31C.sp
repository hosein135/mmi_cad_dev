*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OA31C in0 in1 in2 in3 out
C_1 vdd gnd 3.89684fF
C_2 net_1 gnd 3.47665fF
C_3 out gnd 1.46153fF
C_4 in0 gnd 0.942748fF
C_5 in1 gnd 1.89829fF
C_6 in2 gnd 1.67712fF
C_7 in3 gnd 1.18083fF
C_8 gnd gnd 3.32354fF
C_9 net_6 gnd 0.87818fF
Mp_1 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.616485P PD=3.24556U 
+ AS=0.4968P PS=2.38U
Mp_2 out net_1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.616485P 
+ PS=3.24556U
Mp_3 vdd in0 net_1 vdd p W=1.24U L=0.18U AD=0.415457P PD=2.18722U 
+ AS=0.4774P PS=2.87U
Mp_4 net_1 in1 net_2 vdd p W=1.86U L=0.18U AD=0.7161P PD=4.305U AS=0.3627P 
+ PS=2.25U
Mp_5 net_2 in2 net_3 vdd p W=1.86U L=0.18U AD=0.3627P PD=2.25U AS=0.3627P 
+ PS=2.25U
Mp_6 net_3 in3 vdd vdd p W=1.86U L=0.18U AD=0.3627P PD=2.25U AS=0.623186P 
+ PS=3.28083U
Mp_7 vdd in3 net_4 vdd p W=1.86U L=0.18U AD=0.623186P PD=3.28083U 
+ AS=0.3627P PS=2.25U
Mp_8 net_4 in2 net_5 vdd p W=1.86U L=0.18U AD=0.3627P PD=2.25U AS=0.3627P 
+ PS=2.25U
Mp_9 net_5 in1 net_1 vdd p W=1.86U L=0.18U AD=0.3627P PD=2.25U AS=0.7161P 
+ PS=4.305U
Mn_1 gnd net_1 out gnd n W=1.84U L=0.18U AD=0.710849P PD=3.85209U 
+ AS=0.8832P PS=4.64U
Mn_2 net_1 in0 net_6 gnd n W=1.24U L=0.18U AD=0.5952P PD=3.44U AS=0.3348P 
+ PS=1.78U
Mn_3 net_6 in1 gnd gnd n W=1.24U L=0.18U AD=0.3348P PD=1.78U AS=0.47905P 
+ PS=2.59597U
Mn_4 gnd in2 net_6 gnd n W=1.24U L=0.18U AD=0.47905P PD=2.59597U AS=0.3348P 
+ PS=1.78U
Mn_5 net_6 in3 gnd gnd n W=1.24U L=0.18U AD=0.3348P PD=1.78U AS=0.47905P 
+ PS=2.59597U
.ENDS	$ MMI_OA31C

.GLOBAL gnd vdd

