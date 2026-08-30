*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_KEEPW in
C_1 in gnd 1.95748fF
C_2 net_1 gnd 1.65528fF
C_3 vdd gnd 1.19281fF
C_4 gnd gnd 1.13242fF
Mp_1 in net_1 vdd vdd p W=0.35U L=0.15U AD=0.13825P PD=1.49U AS=0.077P 
+ PS=0.79U
Mp_2 vdd in net_1 vdd p W=0.35U L=0.15U AD=0.077P PD=0.79U AS=0.13825P 
+ PS=1.49U
Mn_1 net_1 in gnd gnd n W=0.35U L=0.3U AD=0.13825P PD=1.49U AS=0.077P 
+ PS=0.79U
Mn_2 gnd net_1 in gnd n W=0.35U L=0.3U AD=0.077P PD=0.79U AS=0.13825P 
+ PS=1.49U
.ENDS	$ MMI_KEEPW

.GLOBAL gnd vdd

