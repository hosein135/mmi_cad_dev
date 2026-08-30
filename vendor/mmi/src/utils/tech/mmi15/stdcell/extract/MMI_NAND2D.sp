*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND2D in0 in1 out
C_1 vdd gnd 3.66678fF
C_2 in0 gnd 1.90135fF
C_3 out gnd 3.38064fF
C_4 in1 gnd 2.4137fF
C_5 gnd gnd 3.21534fF
Mp_1 vdd in0 out vdd p W=1.54U L=0.15U AD=0.406175P PD=2.4525U AS=0.3388P 
+ PS=1.98U
Mp_2 out in0 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.406175P 
+ PS=2.4525U
Mp_3 vdd in0 out vdd p W=1.54U L=0.15U AD=0.406175P PD=2.4525U AS=0.3388P 
+ PS=1.98U
Mp_4 out in0 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.406175P 
+ PS=2.4525U
Mp_5 vdd in1 out vdd p W=1.54U L=0.15U AD=0.406175P PD=2.4525U AS=0.3388P 
+ PS=1.98U
Mp_6 out in1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.406175P 
+ PS=2.4525U
Mp_7 vdd in1 out vdd p W=1.54U L=0.15U AD=0.406175P PD=2.4525U AS=0.3388P 
+ PS=1.98U
Mp_8 out in1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.406175P 
+ PS=2.4525U
Mn_1 gnd in1 net_1 gnd n W=1.54U L=0.15U AD=0.47355P PD=2.925U AS=0.2464P 
+ PS=1.86U
Mn_2 net_1 in0 out gnd n W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.3388P 
+ PS=1.98U
Mn_3 out in0 net_2 gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.2464P 
+ PS=1.86U
Mn_4 net_2 in1 gnd gnd n W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.47355P 
+ PS=2.925U
Mn_5 gnd in1 net_3 gnd n W=1.54U L=0.15U AD=0.47355P PD=2.925U AS=0.2464P 
+ PS=1.86U
Mn_6 net_3 in0 out gnd n W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.3388P 
+ PS=1.98U
Mn_7 out in0 net_4 gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.2464P 
+ PS=1.86U
Mn_8 net_4 in1 gnd gnd n W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.47355P 
+ PS=2.925U
.ENDS	$ MMI_NAND2D

.GLOBAL gnd vdd

