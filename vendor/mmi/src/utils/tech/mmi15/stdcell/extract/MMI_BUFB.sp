*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_BUFB in out
C_1 net_1 gnd 1.40114fF
C_2 in gnd 0.720995fF
C_3 vdd gnd 1.2129fF
C_4 out gnd 0.976425fF
C_5 gnd gnd 1.0257fF
Mp_1 net_1 in vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.225867P 
+ PS=1.61333U
Mp_2 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.451733P PD=3.22667U 
+ AS=0.6083P PS=3.87U
Mn_1 net_1 in gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U AS=0.112933P 
+ PS=1.1U
Mn_2 gnd net_1 out gnd n W=0.77U L=0.15U AD=0.225867P PD=2.2U AS=0.30415P 
+ PS=2.33U
.ENDS	$ MMI_BUFB

.GLOBAL gnd vdd

