*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OA22C in0 in1 in2 in3 out
C_1 vdd gnd 3.21088fF
C_2 net_1 gnd 2.23051fF
C_3 out gnd 1.19746fF
C_4 in1 gnd 0.741195fF
C_5 in0 gnd 0.69436fF
C_6 in2 gnd 0.72084fF
C_7 in3 gnd 0.75944fF
C_8 gnd gnd 2.0116fF
C_9 net_4 gnd 1.15461fF
Mp_1 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.6083P PD=3.75215U AS=0.3388P 
+ PS=1.98U
Mp_2 out net_1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.6083P 
+ PS=3.75215U
Mp_3 vdd in1 net_2 vdd p W=2.08U L=0.15U AD=0.8216P PD=5.06785U AS=0.3328P 
+ PS=2.4U
Mp_4 net_2 in0 net_1 vdd p W=2.08U L=0.15U AD=0.3328P PD=2.4U AS=0.468P 
+ PS=2.53U
Mp_5 net_1 in2 net_3 vdd p W=2.08U L=0.15U AD=0.468P PD=2.53U AS=0.3328P 
+ PS=2.4U
Mp_6 net_3 in3 vdd vdd p W=2.08U L=0.15U AD=0.3328P PD=2.4U AS=0.8216P 
+ PS=5.06785U
Mn_1 gnd net_1 out gnd n W=1.54U L=0.15U AD=0.460086P PD=2.91834U 
+ AS=0.6083P PS=3.87U
Mn_2 net_4 in1 net_1 gnd n W=1.04U L=0.15U AD=0.3198P PD=2.175U AS=0.2288P 
+ PS=1.48U
Mn_3 net_1 in0 net_4 gnd n W=1.04U L=0.15U AD=0.2288P PD=1.48U AS=0.3198P 
+ PS=2.175U
Mn_4 net_4 in2 gnd gnd n W=1.04U L=0.15U AD=0.3198P PD=2.175U AS=0.310707P 
+ PS=1.97083U
Mn_5 gnd in3 net_4 gnd n W=1.04U L=0.15U AD=0.310707P PD=1.97083U 
+ AS=0.3198P PS=2.175U
.ENDS	$ MMI_OA22C

.GLOBAL gnd vdd

