*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_XNOR2C in0 in1 out
C_1 vdd gnd 3.82172fF
C_2 net_1 gnd 3.4394fF
C_3 out gnd 2.48911fF
C_4 in0 gnd 2.82582fF
C_5 in1 gnd 3.10463fF
C_6 net_6 gnd 2.04468fF
C_7 gnd gnd 3.15482fF
Mp_1 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.406175P PD=2.4525U AS=0.3388P 
+ PS=1.98U
Mp_2 out net_1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.406175P 
+ PS=2.4525U
Mp_3 vdd in0 net_2 vdd p W=1.54U L=0.15U AD=0.406175P PD=2.4525U 
+ AS=0.23485P PS=1.845U
Mp_4 net_2 in1 out vdd p W=1.54U L=0.15U AD=0.23485P PD=1.845U AS=0.3388P 
+ PS=1.98U
Mp_5 out in1 net_3 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.24255P 
+ PS=1.855U
Mp_6 net_3 in0 vdd vdd p W=1.54U L=0.15U AD=0.24255P PD=1.855U AS=0.406175P 
+ PS=2.4525U
Mp_7 vdd in0 net_4 vdd p W=1.54U L=0.15U AD=0.406175P PD=2.4525U AS=0.2464P 
+ PS=1.86U
Mp_8 net_4 in1 out vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.3388P 
+ PS=1.98U
Mp_9 out in1 net_5 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.2464P 
+ PS=1.86U
Mp_10 net_5 in0 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.406175P 
+ PS=2.4525U
Mp_11 vdd in0 net_1 vdd p W=1.54U L=0.15U AD=0.406175P PD=2.4525U 
+ AS=0.3388P PS=1.98U
Mp_12 net_1 in1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.406175P 
+ PS=2.4525U
Mn_1 net_6 net_1 out gnd n W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.3388P 
+ PS=1.98U
Mn_2 out net_1 net_6 gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.428633P 
+ PS=2.61U
Mn_3 net_6 in1 gnd gnd n W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.39732P 
+ PS=2.364U
Mn_4 gnd in1 net_6 gnd n W=1.54U L=0.15U AD=0.39732P PD=2.364U AS=0.428633P 
+ PS=2.61U
Mn_5 net_6 in0 gnd gnd n W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.39732P 
+ PS=2.364U
Mn_6 gnd in0 net_6 gnd n W=1.54U L=0.15U AD=0.39732P PD=2.364U AS=0.428633P 
+ PS=2.61U
Mn_7 net_1 in0 net_7 gnd n W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.2464P 
+ PS=1.86U
Mn_8 net_7 in1 gnd gnd n W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.39732P 
+ PS=2.364U
.ENDS	$ MMI_XNOR2C

.GLOBAL gnd vdd

