*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AO31B in0 in1 in2 in3 out
C_1 net_1 gnd 2.59634fF
C_2 in0 gnd 0.757545fF
C_3 net_2 gnd 0.94087fF
C_4 in1 gnd 0.766875fF
C_5 vdd gnd 2.03388fF
C_6 in2 gnd 0.931648fF
C_7 in3 gnd 0.864295fF
C_8 out gnd 1.0966fF
C_9 gnd gnd 1.93356fF
Mp_1 net_1 in0 net_2 vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.359975P 
+ PS=2.0075U
Mp_2 net_2 in1 vdd vdd p W=1.54U L=0.15U AD=0.359975P PD=2.0075U AS=0.3388P 
+ PS=1.98U
Mp_3 vdd in2 net_2 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.359975P 
+ PS=2.0075U
Mp_4 net_2 in3 vdd vdd p W=1.54U L=0.15U AD=0.359975P PD=2.0075U AS=0.3388P 
+ PS=1.98U
Mp_5 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.6083P 
+ PS=3.87U
Mn_1 gnd in0 net_1 gnd n W=0.385U L=0.15U AD=0.112292P PD=0.936667U 
+ AS=0.122237P PS=1.015U
Mn_2 net_1 in1 net_3 gnd n W=1.155U L=0.15U AD=0.366713P PD=3.045U 
+ AS=0.1848P PS=1.475U
Mn_3 net_3 in2 net_4 gnd n W=1.155U L=0.15U AD=0.1848P PD=1.475U AS=0.1848P 
+ PS=1.475U
Mn_4 net_4 in3 gnd gnd n W=1.155U L=0.15U AD=0.1848P PD=1.475U AS=0.336875P 
+ PS=2.81U
Mn_5 gnd net_1 out gnd n W=0.77U L=0.15U AD=0.224583P PD=1.87333U 
+ AS=0.30415P PS=2.33U
.ENDS	$ MMI_AO31B

.GLOBAL gnd vdd

