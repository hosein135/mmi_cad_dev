*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OAI21A in0 in1 in2 out
C_1 vdd gnd 1.87324fF
C_2 in0 gnd 0.75647fF
C_3 out gnd 1.15047fF
C_4 in1 gnd 0.798775fF
C_5 in2 gnd 0.81103fF
C_6 net_2 gnd 0.59971fF
C_7 gnd gnd 1.08322fF
Mp_1 vdd in0 out vdd p W=0.77U L=0.15U AD=0.30415P PD=2.06667U AS=0.225867P 
+ PS=1.61333U
Mp_2 out in1 net_1 vdd p W=1.54U L=0.15U AD=0.451733P PD=3.22667U 
+ AS=0.2464P PS=1.86U
Mp_3 net_1 in2 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.6083P 
+ PS=4.13333U
Mn_1 out in0 net_2 gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.214317P 
+ PS=1.58333U
Mn_2 net_2 in1 gnd gnd n W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.1694P PS=1.21U
Mn_3 gnd in2 net_2 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.214317P 
+ PS=1.58333U
.ENDS	$ MMI_OAI21A

.GLOBAL gnd vdd

