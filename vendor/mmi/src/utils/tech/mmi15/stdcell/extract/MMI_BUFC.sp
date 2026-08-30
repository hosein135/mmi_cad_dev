*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_BUFC in out
C_1 net_1 gnd 1.55635fF
C_2 in gnd 0.65653fF
C_3 vdd gnd 1.7752fF
C_4 out gnd 1.23849fF
C_5 gnd gnd 1.33553fF
Mp_1 net_1 in vdd vdd p W=1.04U L=0.15U AD=0.4108P PD=2.87U AS=0.33073P 
+ PS=2.19864U
Mp_2 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.489735P PD=3.25568U 
+ AS=0.3388P PS=1.98U
Mp_3 out net_1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.489735P 
+ PS=3.25568U
Mn_1 net_1 in gnd gnd n W=0.52U L=0.15U AD=0.2054P PD=1.83U AS=0.165365P 
+ PS=1.22175U
Mn_2 gnd net_1 out gnd n W=1.54U L=0.15U AD=0.489735P PD=3.61825U 
+ AS=0.6083P PS=3.87U
.ENDS	$ MMI_BUFC

.GLOBAL gnd vdd

