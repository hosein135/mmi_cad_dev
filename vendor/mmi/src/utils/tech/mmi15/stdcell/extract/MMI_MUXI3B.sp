*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUXI3B in0 in1 in2 out sel0 sel1
C_1 net_1 gnd 2.52483fF
C_2 sel0 gnd 2.006fF
C_3 vdd gnd 3.9065fF
C_4 in1 gnd 0.658985fF
C_5 net_2 gnd 0.874265fF
C_6 net_3 gnd 1.85609fF
C_7 net_4 gnd 0.602945fF
C_8 in0 gnd 0.66078fF
C_9 net_5 gnd 0.873962fF
C_10 sel1 gnd 2.88068fF
C_11 net_6 gnd 2.17977fF
C_12 net_7 gnd 2.92803fF
C_13 net_8 gnd 0.602643fF
C_14 net_9 gnd 1.21248fF
C_15 in2 gnd 0.67171fF
C_16 out gnd 0.860403fF
C_17 gnd gnd 4.39912fF
Mp_1 net_1 sel0 vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.220388P 
+ PS=1.57692U
Mp_2 vdd in1 net_2 vdd p W=1.54U L=0.15U AD=0.440777P PD=3.15385U 
+ AS=0.3773P PS=2.03U
Mp_3 net_2 net_1 net_3 vdd p W=1.54U L=0.15U AD=0.3773P PD=2.03U AS=0.3388P 
+ PS=1.98U
Mp_4 net_3 sel0 net_4 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.3388P 
+ PS=1.98U
Mp_5 net_4 in0 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.440777P 
+ PS=3.15385U
Mp_6 vdd net_3 net_5 vdd p W=1.54U L=0.15U AD=0.440777P PD=3.15385U 
+ AS=0.3388P PS=1.98U
Mp_7 net_5 sel1 net_6 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.3388P 
+ PS=1.98U
Mp_8 net_6 net_7 net_8 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.385P 
+ PS=2.04U
Mp_9 net_8 net_9 vdd vdd p W=1.54U L=0.15U AD=0.385P PD=2.04U AS=0.440777P 
+ PS=3.15385U
Mp_10 vdd in2 net_9 vdd p W=0.77U L=0.15U AD=0.220388P PD=1.57692U 
+ AS=0.30415P PS=2.33U
Mp_11 out net_6 vdd vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.440777P 
+ PS=3.15385U
Mp_12 vdd sel1 net_7 vdd p W=0.77U L=0.15U AD=0.220388P PD=1.57692U 
+ AS=0.30415P PS=2.33U
Mn_1 net_1 sel0 gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.107118P PS=1.01973U
Mn_2 gnd in1 net_2 gnd n W=0.765U L=0.15U AD=0.212845P PD=2.02622U 
+ AS=0.191287P PS=1.9586U
Mn_3 net_2 sel0 net_3 gnd n W=0.77U L=0.15U AD=0.192538P PD=1.9714U 
+ AS=0.1694P PS=1.21U
Mn_4 net_3 net_1 net_4 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.1694P 
+ PS=1.21U
Mn_5 net_4 in0 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.214236P 
+ PS=2.03946U
Mn_6 gnd net_3 net_5 gnd n W=0.77U L=0.15U AD=0.214236P PD=2.03946U 
+ AS=0.1694P PS=1.21U
Mn_7 net_5 net_7 net_6 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.1694P 
+ PS=1.21U
Mn_8 net_6 sel1 net_8 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U 
+ AS=0.196212P PS=1.98U
Mn_9 net_8 net_9 gnd gnd n W=0.77U L=0.15U AD=0.196213P PD=1.98U 
+ AS=0.214236P PS=2.03946U
Mn_10 gnd in2 net_9 gnd n W=0.385U L=0.15U AD=0.107118P PD=1.01973U 
+ AS=0.152075P PS=1.56U
Mn_11 out net_6 gnd gnd n W=0.765U L=0.15U AD=0.302175P PD=2.32U 
+ AS=0.212845P PS=2.02622U
Mn_12 gnd sel1 net_7 gnd n W=0.385U L=0.15U AD=0.107118P PD=1.01973U 
+ AS=0.152075P PS=1.56U
.ENDS	$ MMI_MUXI3B

.GLOBAL gnd vdd

