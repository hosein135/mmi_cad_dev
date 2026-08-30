*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AO22B in0 in1 in2 in3 out
C_1 vdd gnd 2.25504fF
C_2 in2 gnd 1.25761fF
C_3 net_1 gnd 0.849628fF
C_4 in1 gnd 1.03068fF
C_5 net_2 gnd 2.13475fF
C_6 in0 gnd 0.940845fF
C_7 in3 gnd 0.886582fF
C_8 out gnd 1.12086fF
C_9 gnd gnd 1.56876fF
Mp_1 vdd in2 net_1 vdd p W=1.54U L=0.15U AD=0.456867P PD=2.64667U 
+ AS=0.3388P PS=1.98U
Mp_2 net_1 in1 net_2 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.3388P 
+ PS=1.98U
Mp_3 net_2 in0 net_1 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.3388P 
+ PS=1.98U
Mp_4 net_1 in3 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.456867P 
+ PS=2.64667U
Mp_5 vdd net_2 out vdd p W=1.54U L=0.15U AD=0.456867P PD=2.64667U 
+ AS=0.6083P PS=3.87U
Mn_1 gnd in1 net_3 gnd n W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.1232P PS=1.09U
Mn_2 net_3 in0 net_2 gnd n W=0.77U L=0.15U AD=0.1232P PD=1.09U AS=0.1771P 
+ PS=1.23U
Mn_3 net_2 in2 net_4 gnd n W=0.77U L=0.15U AD=0.1771P PD=1.23U AS=0.105875P 
+ PS=1.045U
Mn_4 net_4 in3 gnd gnd n W=0.77U L=0.15U AD=0.105875P PD=1.045U 
+ AS=0.214317P PS=1.58333U
Mn_5 gnd net_2 out gnd n W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.30415P PS=2.33U
.ENDS	$ MMI_AO22B

.GLOBAL gnd vdd

