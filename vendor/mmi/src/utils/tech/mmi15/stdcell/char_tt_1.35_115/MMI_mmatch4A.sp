*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_mmatch4A in0 in1 in2 in3 mm_out
C_1 vdd gnd 3.72876fF
C_2 in3 gnd 2.54075fF
C_3 in2 gnd 2.86753fF
C_4 net_2 gnd 0.85232fF
C_5 in1 gnd 1.87427fF
C_6 net_3 gnd 3.87464fF
C_7 in0 gnd 3.17535fF
C_8 net_5 gnd 0.96158fF
C_9 mm_out gnd 0.637968fF
C_10 gnd gnd 3.14508fF
C_11 net_6 gnd 0.60965fF
C_12 net_7 gnd 0.60527fF
C_13 net_8 gnd 0.60527fF
Mp_1 vdd in3 net_1 vdd p W=1.2U L=0.15U AD=0.474P PD=3.29716U AS=0.132P 
+ PS=1.42U
Mp_2 net_1 in2 net_2 vdd p W=1.2U L=0.15U AD=0.132P PD=1.42U AS=0.334P 
+ PS=2.15667U
Mp_3 net_2 in1 net_3 vdd p W=1.2U L=0.15U AD=0.334P PD=2.15667U AS=0.264P 
+ PS=1.64U
Mp_4 net_3 in0 net_2 vdd p W=1.2U L=0.15U AD=0.264P PD=1.64U AS=0.334P 
+ PS=2.15667U
Mp_5 vdd in0 net_4 vdd p W=1.2U L=0.15U AD=0.474P PD=3.29716U AS=0.132P 
+ PS=1.42U
Mp_6 net_4 in1 net_5 vdd p W=1.2U L=0.15U AD=0.132P PD=1.42U AS=0.334P 
+ PS=2.15667U
Mp_7 net_5 in3 net_3 vdd p W=1.2U L=0.15U AD=0.334P PD=2.15667U AS=0.264P 
+ PS=1.64U
Mp_8 net_3 in2 net_5 vdd p W=1.2U L=0.15U AD=0.264P PD=1.64U AS=0.334P 
+ PS=2.15667U
Mp_9 vdd net_3 mm_out vdd p W=0.77U L=0.15U AD=0.30415P PD=2.11568U 
+ AS=0.30415P PS=2.33U
Mn_1 mm_out net_3 gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.094325P PS=0.93U
Mn_2 net_6 in3 gnd gnd n W=0.385U L=0.15U AD=0.107158P PD=1.07U 
+ AS=0.094325P PS=0.93U
Mn_3 gnd in2 net_6 gnd n W=0.385U L=0.15U AD=0.094325P PD=0.93U 
+ AS=0.107158P PS=1.07U
Mn_4 net_6 in1 net_3 gnd n W=0.385U L=0.15U AD=0.107158P PD=1.07U 
+ AS=0.107158P PS=1.07U
Mn_5 net_7 in1 gnd gnd n W=0.385U L=0.15U AD=0.107158P PD=1.07U 
+ AS=0.094325P PS=0.93U
Mn_6 gnd in2 net_7 gnd n W=0.385U L=0.15U AD=0.094325P PD=0.93U 
+ AS=0.107158P PS=1.07U
Mn_7 net_7 in0 net_3 gnd n W=0.385U L=0.15U AD=0.107158P PD=1.07U 
+ AS=0.107158P PS=1.07U
Mn_8 net_3 in3 net_8 gnd n W=0.385U L=0.15U AD=0.107158P PD=1.07U 
+ AS=0.107158P PS=1.07U
Mn_9 net_8 in2 gnd gnd n W=0.385U L=0.15U AD=0.107158P PD=1.07U 
+ AS=0.094325P PS=0.93U
Mn_10 gnd in0 net_8 gnd n W=0.385U L=0.15U AD=0.094325P PD=0.93U 
+ AS=0.107158P PS=1.07U
.ENDS	$ MMI_mmatch4A

.GLOBAL gnd vdd

