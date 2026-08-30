*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OA21B in0 in1 in2 out
C_1 vdd gnd 2.59248fF
C_2 in0 gnd 0.97104fF
C_3 net_1 gnd 2.27597fF
C_4 in1 gnd 1.13015fF
C_5 in2 gnd 1.2653fF
C_6 out gnd 1.10126fF
C_7 gnd gnd 1.74204fF
C_8 net_3 gnd 0.597433fF
Mp_1 vdd in0 net_1 vdd p W=0.77U L=0.15U AD=0.30415P PD=2.014U AS=0.225867P 
+ PS=1.61333U
Mp_2 net_1 in1 net_2 vdd p W=1.54U L=0.15U AD=0.451733P PD=3.22667U 
+ AS=0.2464P PS=1.86U
Mp_3 net_2 in2 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.6083P 
+ PS=4.028U
Mp_4 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.6083P PD=4.028U AS=0.6083P 
+ PS=3.87U
Mn_1 gnd in2 net_3 gnd n W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.214317P PS=1.58333U
Mn_2 net_3 in0 net_1 gnd n W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.30415P PS=2.33U
Mn_3 net_3 in1 gnd gnd n W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.214317P PS=1.58333U
Mn_4 gnd net_1 out gnd n W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.30415P PS=2.33U
.ENDS	$ MMI_OA21B

.GLOBAL gnd vdd

