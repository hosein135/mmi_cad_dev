*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OR3B in0 in1 in2 out
C_1 net_1 gnd 2.02626fF
C_2 in0 gnd 0.814463fF
C_3 in1 gnd 0.7394fF
C_4 in2 gnd 0.672735fF
C_5 vdd gnd 1.5671fF
C_6 out gnd 0.96219fF
C_7 gnd gnd 1.73012fF
Mp_1 net_1 in0 net_2 vdd p W=2.315U L=0.15U AD=0.914425P PD=5.42U 
+ AS=0.25465P PS=2.535U
Mp_2 net_2 in1 net_3 vdd p W=2.315U L=0.15U AD=0.25465P PD=2.535U 
+ AS=0.25465P PS=2.535U
Mp_3 net_3 in2 vdd vdd p W=2.315U L=0.15U AD=0.25465P PD=2.535U AS=0.53257P 
+ PS=3.95742U
Mp_4 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.35428P PD=2.63258U AS=0.6083P 
+ PS=3.87U
Mn_1 net_1 in0 gnd gnd n W=0.385U L=0.15U AD=0.110367P PD=1.08667U 
+ AS=0.10164P PS=0.99U
Mn_2 gnd in1 net_1 gnd n W=0.385U L=0.15U AD=0.10164P PD=0.99U AS=0.110367P 
+ PS=1.08667U
Mn_3 net_1 in2 gnd gnd n W=0.385U L=0.15U AD=0.110367P PD=1.08667U 
+ AS=0.10164P PS=0.99U
Mn_4 gnd net_1 out gnd n W=0.77U L=0.15U AD=0.20328P PD=1.98U AS=0.30415P 
+ PS=2.33U
.ENDS	$ MMI_OR3B

.GLOBAL gnd vdd

