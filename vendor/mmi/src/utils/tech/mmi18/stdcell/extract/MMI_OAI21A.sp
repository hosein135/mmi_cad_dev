*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OAI21A in0 in1 in2 out
C_1 vdd gnd 2.3165fF
C_2 in0 gnd 0.91519fF
C_3 out gnd 1.40458fF
C_4 in1 gnd 0.97309fF
C_5 in2 gnd 0.99559fF
C_6 net_2 gnd 0.72842fF
C_7 gnd gnd 1.34774fF
Mp_1 vdd in0 out vdd p W=0.92U L=0.18U AD=0.4416P PD=2.48U AS=0.325067P 
+ PS=1.93333U
Mp_2 out in1 net_1 vdd p W=1.84U L=0.18U AD=0.650133P PD=3.86667U 
+ AS=0.3588P PS=2.23U
Mp_3 net_1 in2 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.8832P 
+ PS=4.96U
Mn_1 out in0 net_2 gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.3128P 
+ PS=1.90667U
Mn_2 net_2 in1 gnd gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.2484P 
+ PS=1.46U
Mn_3 gnd in2 net_2 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.3128P 
+ PS=1.90667U
.ENDS	$ MMI_OAI21A

.GLOBAL gnd vdd

