*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AOI21A in0 in1 in2 out
C_1 out gnd 1.15046fF
C_2 in0 gnd 0.755395fF
C_3 net_1 gnd 0.948553fF
C_4 in1 gnd 0.76163fF
C_5 vdd gnd 1.22686fF
C_6 in2 gnd 0.81335fF
C_7 gnd gnd 1.59166fF
Mp_1 out in0 net_1 vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.428633P 
+ PS=2.61U
Mp_2 net_1 in1 vdd vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.3388P 
+ PS=1.98U
Mp_3 vdd in2 net_1 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.428633P 
+ PS=2.61U
Mn_1 gnd in0 out gnd n W=0.385U L=0.15U AD=0.152075P PD=1.29667U 
+ AS=0.113233P PS=1.28333U
Mn_2 out in1 net_2 gnd n W=0.77U L=0.15U AD=0.226467P PD=2.56667U 
+ AS=0.1232P PS=1.09U
Mn_3 net_2 in2 gnd gnd n W=0.77U L=0.15U AD=0.1232P PD=1.09U AS=0.30415P 
+ PS=2.59333U
.ENDS	$ MMI_AOI21A

.GLOBAL gnd vdd

