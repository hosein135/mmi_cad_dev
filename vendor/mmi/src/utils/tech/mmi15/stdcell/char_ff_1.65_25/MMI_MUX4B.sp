*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUX4B in0 in1 in2 in3 out sel0 sel1
C_1 net_1 gnd 2.06676fF
C_2 in1 gnd 0.740345fF
C_3 vdd gnd 4.30424fF
C_4 in0 gnd 0.7546fF
C_5 net_2 gnd 0.597505fF
C_6 sel0 gnd 2.46473fF
C_7 net_3 gnd 2.51258fF
C_8 net_4 gnd 3.64234fF
C_9 in2 gnd 0.677145fF
C_10 net_5 gnd 0.621298fF
C_11 net_6 gnd 2.6933fF
C_12 net_7 gnd 0.620203fF
C_13 in3 gnd 0.637755fF
C_14 sel1 gnd 1.82496fF
C_15 net_8 gnd 2.35052fF
C_16 net_9 gnd 1.3827fF
C_17 out gnd 0.94488fF
C_18 gnd gnd 4.70027fF
Mp_1 net_1 in1 vdd vdd p W=1.54U L=0.15U AD=0.5348P PD=4.415U AS=0.440131P 
+ PS=2.85167U
Mp_2 vdd in0 net_2 vdd p W=1.54U L=0.15U AD=0.440131P PD=2.85167U 
+ AS=0.3537P PS=2.69U
Mp_3 net_2 sel0 net_3 vdd p W=1.54U L=0.15U AD=0.3537P PD=2.69U 
+ AS=0.436333P PS=2.62U
Mp_4 net_3 net_4 net_1 vdd p W=1.54U L=0.15U AD=0.436333P PD=2.62U 
+ AS=0.5348P PS=4.415U
Mp_5 net_4 sel0 vdd vdd p W=1.04U L=0.15U AD=0.3263P PD=3.96U AS=0.297231P 
+ PS=1.9258U
Mp_6 vdd in2 net_5 vdd p W=1.54U L=0.15U AD=0.440131P PD=2.85167U 
+ AS=0.3465P PS=1.99U
Mp_7 net_5 sel0 net_6 vdd p W=1.54U L=0.15U AD=0.3465P PD=1.99U 
+ AS=0.436333P PS=2.62U
Mp_8 net_6 net_4 net_7 vdd p W=1.54U L=0.15U AD=0.436333P PD=2.62U 
+ AS=0.35035P PS=1.995U
Mp_9 net_7 in3 vdd vdd p W=1.54U L=0.15U AD=0.35035P PD=1.995U AS=0.440131P 
+ PS=2.85167U
Mp_10 net_3 sel1 net_8 vdd p W=1.54U L=0.15U AD=0.436333P PD=2.62U 
+ AS=0.3388P PS=1.98U
Mp_11 net_8 net_9 net_6 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U 
+ AS=0.436333P PS=2.62U
Mp_12 net_9 sel1 vdd vdd p W=0.77U L=0.15U AD=0.2534P PD=3.42U AS=0.220065P 
+ PS=1.42584U
Mp_13 vdd net_8 out vdd p W=1.54U L=0.15U AD=0.440131P PD=2.85167U 
+ AS=0.6083P PS=3.87U
Mn_1 net_1 in1 gnd gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.25259P 
+ PS=2.12944U
Mn_2 gnd in0 net_2 gnd n W=0.77U L=0.15U AD=0.25259P PD=2.12944U 
+ AS=0.175175P PS=1.225U
Mn_3 net_2 net_4 net_3 gnd n W=0.77U L=0.15U AD=0.175175P PD=1.225U 
+ AS=0.216883P PS=1.59U
Mn_4 net_3 sel0 net_1 gnd n W=0.77U L=0.15U AD=0.216883P PD=1.59U 
+ AS=0.30415P PS=2.33U
Mn_5 net_4 sel0 gnd gnd n W=0.52U L=0.15U AD=0.2054P PD=1.83U AS=0.17058P 
+ PS=1.43807U
Mn_6 gnd in2 net_5 gnd n W=0.77U L=0.15U AD=0.25259P PD=2.12944U 
+ AS=0.17325P PS=1.22U
Mn_7 net_5 net_4 net_6 gnd n W=0.77U L=0.15U AD=0.17325P PD=1.22U 
+ AS=0.2156P PS=1.58667U
Mn_8 net_6 sel0 net_7 gnd n W=0.77U L=0.15U AD=0.2156P PD=1.58667U 
+ AS=0.179025P PS=1.235U
Mn_9 net_7 in3 gnd gnd n W=0.77U L=0.15U AD=0.179025P PD=1.235U AS=0.25259P 
+ PS=2.12944U
Mn_10 net_3 net_9 net_8 gnd n W=0.77U L=0.15U AD=0.216883P PD=1.59U 
+ AS=0.1694P PS=1.21U
Mn_11 net_8 sel1 net_6 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.2156P 
+ PS=1.58667U
Mn_12 net_9 sel1 gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.126295P PS=1.06472U
Mn_13 gnd net_8 out gnd n W=0.77U L=0.15U AD=0.25259P PD=2.12944U 
+ AS=0.30415P PS=2.33U
.ENDS	$ MMI_MUX4B

.GLOBAL gnd vdd

