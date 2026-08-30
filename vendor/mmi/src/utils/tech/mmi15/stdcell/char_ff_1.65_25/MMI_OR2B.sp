*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OR2B in0 in1 out
C_1 net_1 gnd 1.8417fF
C_2 in0 gnd 0.78657fF
C_3 in1 gnd 0.774455fF
C_4 vdd gnd 1.32148fF
C_5 out gnd 1.08547fF
C_6 gnd gnd 1.5244fF
Mp_1 net_1 in0 net_2 vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.24255P 
+ PS=1.855U
Mp_2 net_2 in1 vdd vdd p W=1.54U L=0.15U AD=0.24255P PD=1.855U AS=0.3388P 
+ PS=1.98U
Mp_3 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.6083P 
+ PS=3.87U
Mn_1 gnd in0 net_1 gnd n W=0.385U L=0.15U AD=0.124162P PD=1.2225U 
+ AS=0.0847P PS=0.825U
Mn_2 net_1 in1 gnd gnd n W=0.385U L=0.15U AD=0.0847P PD=0.825U AS=0.124162P 
+ PS=1.2225U
Mn_3 gnd net_1 out gnd n W=0.77U L=0.15U AD=0.248325P PD=2.445U AS=0.30415P 
+ PS=2.33U
.ENDS	$ MMI_OR2B

.GLOBAL gnd vdd

