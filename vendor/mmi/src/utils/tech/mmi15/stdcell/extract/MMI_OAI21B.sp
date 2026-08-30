*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OAI21B in0 in1 in2 out
C_1 out gnd 1.74835fF
C_2 in0 gnd 0.61306fF
C_3 vdd gnd 1.99342fF
C_4 in2 gnd 1.17633fF
C_5 in1 gnd 0.758625fF
C_6 net_3 gnd 0.94361fF
C_7 gnd gnd 1.40522fF
Mp_1 out in0 vdd vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.428633P 
+ PS=2.61U
Mp_2 vdd in2 net_1 vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.2464P 
+ PS=1.86U
Mp_3 net_1 in1 out vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.428633P 
+ PS=2.61U
Mp_4 out in1 net_2 vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.2464P 
+ PS=1.86U
Mp_5 net_2 in2 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.428633P 
+ PS=2.61U
Mn_1 out in0 net_3 gnd n W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.428633P 
+ PS=2.61U
Mn_2 net_3 in1 gnd gnd n W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.3465P 
+ PS=1.99U
Mn_3 gnd in2 net_3 gnd n W=1.54U L=0.15U AD=0.3465P PD=1.99U AS=0.428633P 
+ PS=2.61U
.ENDS	$ MMI_OAI21B

.GLOBAL gnd vdd

