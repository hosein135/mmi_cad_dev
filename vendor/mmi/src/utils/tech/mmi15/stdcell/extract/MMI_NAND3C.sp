*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND3C in0 in1 in2 out
C_1 vdd gnd 3.74824fF
C_2 in0 gnd 1.18399fF
C_3 out gnd 2.93294fF
C_4 in1 gnd 1.1424fF
C_5 in2 gnd 1.16389fF
C_6 net_1 gnd 1.30645fF
C_7 net_2 gnd 1.40272fF
C_8 gnd gnd 2.73592fF
Mp_1 vdd in0 out vdd p W=1.54U L=0.15U AD=0.432483P PD=2.615U AS=0.341367P 
+ PS=1.98333U
Mp_2 out in0 vdd vdd p W=1.54U L=0.15U AD=0.341367P PD=1.98333U 
+ AS=0.432483P PS=2.615U
Mp_3 vdd in1 out vdd p W=1.54U L=0.15U AD=0.432483P PD=2.615U AS=0.341367P 
+ PS=1.98333U
Mp_4 out in1 vdd vdd p W=1.54U L=0.15U AD=0.341367P PD=1.98333U 
+ AS=0.432483P PS=2.615U
Mp_5 vdd in2 out vdd p W=1.54U L=0.15U AD=0.432483P PD=2.615U AS=0.341367P 
+ PS=1.98333U
Mp_6 out in2 vdd vdd p W=1.54U L=0.15U AD=0.341367P PD=1.98333U 
+ AS=0.432483P PS=2.615U
Mn_1 out in0 net_1 gnd n W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.3388P 
+ PS=1.98U
Mn_2 net_1 in0 out gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.428633P 
+ PS=2.61U
Mn_3 out in0 net_1 gnd n W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.3388P 
+ PS=1.98U
Mn_4 net_1 in1 net_2 gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.3388P 
+ PS=1.98U
Mn_5 net_2 in1 net_1 gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.3388P 
+ PS=1.98U
Mn_6 net_1 in1 net_2 gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.3388P 
+ PS=1.98U
Mn_7 net_2 in2 gnd gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.428633P 
+ PS=2.61U
Mn_8 gnd in2 net_2 gnd n W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.3388P 
+ PS=1.98U
Mn_9 net_2 in2 gnd gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.428633P 
+ PS=2.61U
.ENDS	$ MMI_NAND3C

.GLOBAL gnd vdd

