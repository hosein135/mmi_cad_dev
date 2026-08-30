*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AO21C in0 in1 in2 out
C_1 net_1 gnd 3.53827fF
C_2 in0 gnd 0.87486fF
C_3 net_2 gnd 1.4585fF
C_4 in2 gnd 0.87538fF
C_5 vdd gnd 3.44816fF
C_6 in1 gnd 0.96187fF
C_7 out gnd 1.2443fF
C_8 gnd gnd 3.01058fF
Mp_1 net_1 in0 net_2 vdd p W=2.48U L=0.18U AD=1.1904P PD=5.92U AS=0.8432P 
+ PS=3.98667U
Mp_2 net_2 in2 vdd vdd p W=2.48U L=0.18U AD=0.8432P PD=3.98667U 
+ AS=0.891422P PS=4.39741U
Mp_3 vdd in1 net_2 vdd p W=2.48U L=0.18U AD=0.891422P PD=4.39741U 
+ AS=0.8432P PS=3.98667U
Mp_4 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.661378P PD=3.26259U 
+ AS=0.4968P PS=2.38U
Mp_5 out net_1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.661378P 
+ PS=3.26259U
Mn_1 net_1 in0 gnd gnd n W=0.62U L=0.18U AD=0.2976P PD=1.88U AS=0.258121P 
+ PS=1.70919U
Mn_2 gnd in2 net_3 gnd n W=1.24U L=0.18U AD=0.516242P PD=3.41838U 
+ AS=0.2418P PS=1.63U
Mn_3 net_3 in1 net_1 gnd n W=1.24U L=0.18U AD=0.2418P PD=1.63U AS=0.5952P 
+ PS=3.76U
Mn_4 gnd net_1 out gnd n W=0.92U L=0.18U AD=0.383018P PD=2.53622U 
+ AS=0.2484P PS=1.46U
Mn_5 out net_1 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.383018P 
+ PS=2.53622U
.ENDS	$ MMI_AO21C

.GLOBAL gnd vdd

