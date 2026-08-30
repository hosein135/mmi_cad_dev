*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AND3C in0 in1 in2 out
C_1 net_1 gnd 3.09277fF
C_2 in0 gnd 0.98916fF
C_3 vdd gnd 2.77571fF
C_4 in1 gnd 0.85007fF
C_5 in2 gnd 0.93715fF
C_6 out gnd 1.44333fF
C_7 gnd gnd 2.09828fF
Mp_1 net_1 in0 vdd vdd p W=1.24U L=0.18U AD=0.4216P PD=2.33333U 
+ AS=0.428973P PS=2.34595U
Mp_2 vdd in1 net_1 vdd p W=1.24U L=0.18U AD=0.428973P PD=2.34595U 
+ AS=0.4216P PS=2.33333U
Mp_3 net_1 in2 vdd vdd p W=1.24U L=0.18U AD=0.4216P PD=2.33333U 
+ AS=0.428973P PS=2.34595U
Mp_4 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.636541P PD=3.48108U 
+ AS=0.4968P PS=2.38U
Mp_5 out net_1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.636541P 
+ PS=3.48108U
Mn_1 net_1 in0 net_2 gnd n W=1.86U L=0.18U AD=0.8928P PD=4.68U AS=0.3627P 
+ PS=2.25U
Mn_2 net_2 in1 net_3 gnd n W=1.86U L=0.18U AD=0.3627P PD=2.25U AS=0.3627P 
+ PS=2.25U
Mn_3 net_3 in2 gnd gnd n W=1.86U L=0.18U AD=0.3627P PD=2.25U AS=0.54131P 
+ PS=2.93578U
Mn_4 gnd net_1 out gnd n W=1.84U L=0.18U AD=0.53549P PD=2.90422U AS=0.8832P 
+ PS=4.64U
.ENDS	$ MMI_AND3C

.GLOBAL gnd vdd

