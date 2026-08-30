*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NOR2D in0 in1 out
C_1 vdd gnd 4.28353fF
C_2 in1 gnd 2.59047fF
C_3 in0 gnd 2.42687fF
C_4 out gnd 4.80366fF
C_5 gnd gnd 3.63944fF
Mp_1 vdd in1 net_1 vdd p W=4.9U L=0.18U AD=1.666P PD=7.21333U AS=0.6125P 
+ PS=5.15U
Mp_2 net_1 in0 out vdd p W=4.9U L=0.18U AD=0.6125P PD=5.15U AS=1.666P 
+ PS=7.21333U
Mp_3 out in0 net_2 vdd p W=4.9U L=0.18U AD=1.666P PD=7.21333U AS=0.6125P 
+ PS=5.15U
Mp_4 net_2 in1 vdd vdd p W=4.9U L=0.18U AD=0.6125P PD=5.15U AS=1.666P 
+ PS=7.21333U
Mp_5 vdd in1 net_3 vdd p W=4.9U L=0.18U AD=1.666P PD=7.21333U AS=0.6125P 
+ PS=5.15U
Mp_6 net_3 in0 out vdd p W=4.9U L=0.18U AD=0.6125P PD=5.15U AS=1.666P 
+ PS=7.21333U
Mn_1 gnd in1 out gnd n W=1.225U L=0.18U AD=0.4165P PD=2.31333U AS=0.33075P 
+ PS=1.765U
Mn_2 out in1 gnd gnd n W=1.225U L=0.18U AD=0.33075P PD=1.765U AS=0.4165P 
+ PS=2.31333U
Mn_3 gnd in1 out gnd n W=1.225U L=0.18U AD=0.4165P PD=2.31333U AS=0.33075P 
+ PS=1.765U
Mn_4 out in0 gnd gnd n W=1.225U L=0.18U AD=0.33075P PD=1.765U AS=0.4165P 
+ PS=2.31333U
Mn_5 gnd in0 out gnd n W=1.225U L=0.18U AD=0.4165P PD=2.31333U AS=0.33075P 
+ PS=1.765U
Mn_6 out in0 gnd gnd n W=1.225U L=0.18U AD=0.33075P PD=1.765U AS=0.4165P 
+ PS=2.31333U
.ENDS	$ MMI_NOR2D

.GLOBAL gnd vdd

