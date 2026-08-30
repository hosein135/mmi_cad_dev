*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_BUFD in out
C_1 net_1 gnd 2.76471fF
C_2 in gnd 0.76103fF
C_3 vdd gnd 2.38991fF
C_4 out gnd 2.25946fF
C_5 gnd gnd 2.96672fF
Mp_1 net_1 in vdd vdd p W=2.48U L=0.18U AD=1.1904P PD=5.92U AS=0.69566P 
+ PS=3.29239U
Mp_2 vdd net_1 out vdd p W=2.455U L=0.18U AD=0.688647P PD=3.2592U 
+ AS=0.8347P PS=3.95333U
Mp_3 out net_1 vdd vdd p W=2.455U L=0.18U AD=0.8347P PD=3.95333U 
+ AS=0.688647P PS=3.2592U
Mp_4 vdd net_1 out vdd p W=2.455U L=0.18U AD=0.688647P PD=3.2592U 
+ AS=0.8347P PS=3.95333U
Mn_1 net_1 in gnd gnd n W=1.24U L=0.18U AD=0.5952P PD=3.44U AS=0.5952P 
+ PS=3.20585U
Mn_2 gnd net_1 out gnd n W=1.84U L=0.18U AD=0.8832P PD=4.75707U AS=0.4968P 
+ PS=2.38U
Mn_3 out net_1 gnd gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.8832P 
+ PS=4.75707U
.ENDS	$ MMI_BUFD

.GLOBAL gnd vdd

