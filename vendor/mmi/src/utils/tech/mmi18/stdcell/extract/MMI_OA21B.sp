*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OA21B in0 in1 in2 out
C_1 vdd gnd 3.20978fF
C_2 in0 gnd 1.17365fF
C_3 net_1 gnd 2.71766fF
C_4 in1 gnd 1.36129fF
C_5 in2 gnd 1.51924fF
C_6 out gnd 1.34325fF
C_7 gnd gnd 2.16848fF
C_8 net_3 gnd 0.72396fF
Mp_1 vdd in0 net_1 vdd p W=0.92U L=0.18U AD=0.4416P PD=2.416U AS=0.325067P 
+ PS=1.93333U
Mp_2 net_1 in1 net_2 vdd p W=1.84U L=0.18U AD=0.650133P PD=3.86667U 
+ AS=0.3588P PS=2.23U
Mp_3 net_2 in2 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.8832P 
+ PS=4.832U
Mp_4 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.8832P PD=4.832U AS=0.8832P 
+ PS=4.64U
Mn_1 gnd in2 net_3 gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.3128P 
+ PS=1.90667U
Mn_2 net_3 in0 net_1 gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U 
+ AS=0.4416P PS=2.8U
Mn_3 net_3 in1 gnd gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.3128P 
+ PS=1.90667U
Mn_4 gnd net_1 out gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.4416P 
+ PS=2.8U
.ENDS	$ MMI_OA21B

.GLOBAL gnd vdd

