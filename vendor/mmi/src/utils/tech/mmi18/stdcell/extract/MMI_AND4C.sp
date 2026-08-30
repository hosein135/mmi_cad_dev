*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AND4C in0 in1 in2 in3 out
C_1 vdd gnd 3.39638fF
C_2 in3 gnd 2.26439fF
C_3 net_1 gnd 3.45989fF
C_4 in2 gnd 1.93782fF
C_5 in1 gnd 1.7873fF
C_6 in0 gnd 1.42337fF
C_7 out gnd 1.64182fF
C_8 gnd gnd 2.90732fF
Mp_1 vdd in3 net_1 vdd p W=1.24U L=0.18U AD=0.45283P PD=2.64074U AS=0.3348P 
+ PS=1.78U
Mp_2 net_1 in2 vdd vdd p W=1.24U L=0.18U AD=0.3348P PD=1.78U AS=0.45283P 
+ PS=2.64074U
Mp_3 vdd in1 net_1 vdd p W=1.24U L=0.18U AD=0.45283P PD=2.64074U AS=0.3348P 
+ PS=1.78U
Mp_4 net_1 in0 vdd vdd p W=1.24U L=0.18U AD=0.3348P PD=1.78U AS=0.45283P 
+ PS=2.64074U
Mp_5 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.671941P PD=3.91852U 
+ AS=0.4968P PS=2.38U
Mp_6 out net_1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.671941P 
+ PS=3.91852U
Mn_1 gnd in3 net_2 gnd n W=1.24U L=0.18U AD=0.459948P PD=2.65222U 
+ AS=0.2418P PS=1.63U
Mn_2 net_2 in2 net_3 gnd n W=1.24U L=0.18U AD=0.2418P PD=1.63U AS=0.2418P 
+ PS=1.63U
Mn_3 net_3 in1 net_4 gnd n W=1.24U L=0.18U AD=0.2418P PD=1.63U AS=0.2418P 
+ PS=1.63U
Mn_4 net_4 in0 net_1 gnd n W=1.24U L=0.18U AD=0.2418P PD=1.63U AS=0.3348P 
+ PS=1.78U
Mn_5 net_1 in0 net_5 gnd n W=1.24U L=0.18U AD=0.3348P PD=1.78U AS=0.2418P 
+ PS=1.63U
Mn_6 net_5 in1 net_6 gnd n W=1.24U L=0.18U AD=0.2418P PD=1.63U AS=0.2418P 
+ PS=1.63U
Mn_7 net_6 in2 net_7 gnd n W=1.24U L=0.18U AD=0.2418P PD=1.63U AS=0.2418P 
+ PS=1.63U
Mn_8 net_7 in3 gnd gnd n W=1.24U L=0.18U AD=0.2418P PD=1.63U AS=0.459948P 
+ PS=2.65222U
Mn_9 gnd net_1 out gnd n W=1.84U L=0.18U AD=0.682504P PD=3.93556U 
+ AS=0.8832P PS=4.64U
.ENDS	$ MMI_AND4C

.GLOBAL gnd vdd

