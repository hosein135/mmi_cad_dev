*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_LLACB clk clrb d q
C_1 net_1 gnd 1.98253fF
C_2 clk gnd 2.45901fF
C_3 vdd gnd 4.52757fF
C_4 d gnd 1.10454fF
C_5 net_2 gnd 1.27113fF
C_6 net_3 gnd 2.05263fF
C_7 net_5 gnd 2.5619fF
C_8 net_6 gnd 2.26715fF
C_9 net_8 gnd 1.12819fF
C_10 q gnd 0.7913fF
C_11 clrb gnd 0.61321fF
C_12 gnd gnd 4.297fF
Mp_1 net_1 clk vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.264836P 
+ PS=1.98317U
Mp_2 vdd d net_2 vdd p W=1.54U L=0.15U AD=0.529671P PD=3.96635U AS=0.3388P 
+ PS=1.98U
Mp_3 net_2 net_1 net_3 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U 
+ AS=0.543461P PS=4.44889U
Mp_4 net_3 clk net_4 vdd p W=0.35U L=0.15U AD=0.123514P PD=1.01111U 
+ AS=0.056P PS=0.67U
Mp_5 net_4 net_5 vdd vdd p W=0.35U L=0.15U AD=0.056P PD=0.67U AS=0.12038P 
+ PS=0.901442U
Mp_6 vdd net_6 net_7 vdd p W=1.54U L=0.15U AD=0.529671P PD=3.96635U 
+ AS=0.1694P PS=1.76U
Mp_7 net_7 net_3 net_5 vdd p W=1.54U L=0.15U AD=0.1694P PD=1.76U AS=0.6083P 
+ PS=3.87U
Mp_8 net_8 net_5 vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U 
+ AS=0.264836P PS=1.98317U
Mp_9 vdd net_8 q vdd p W=1.54U L=0.15U AD=0.529671P PD=3.96635U AS=0.6083P 
+ PS=3.87U
Mp_10 net_6 clrb vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U 
+ AS=0.264836P PS=1.98317U
Mn_1 net_8 net_5 gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.145831P PS=1.60156U
Mn_2 net_1 clk gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.145831P PS=1.60156U
Mn_3 gnd d net_2 gnd n W=0.77U L=0.15U AD=0.291661P PD=3.20312U AS=0.1694P 
+ PS=1.21U
Mn_4 net_2 clk net_3 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.236036P 
+ PS=3.23813U
Mn_5 net_3 net_1 net_9 gnd n W=0.35U L=0.15U AD=0.107289P PD=1.47188U 
+ AS=0.055125P PS=0.665U
Mn_6 net_9 net_5 gnd gnd n W=0.35U L=0.15U AD=0.055125P PD=0.665U 
+ AS=0.132573P PS=1.45596U
Mn_7 gnd net_6 net_5 gnd n W=0.385U L=0.15U AD=0.145831P PD=1.60156U 
+ AS=0.0847P PS=0.825U
Mn_8 net_5 net_3 gnd gnd n W=0.385U L=0.15U AD=0.0847P PD=0.825U 
+ AS=0.145831P PS=1.60156U
Mn_9 gnd net_8 q gnd n W=0.77U L=0.15U AD=0.291661P PD=3.20312U AS=0.30415P 
+ PS=2.33U
Mn_10 net_6 clrb gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.145831P PS=1.60156U
.ENDS	$ MMI_LLACB

.GLOBAL gnd vdd

