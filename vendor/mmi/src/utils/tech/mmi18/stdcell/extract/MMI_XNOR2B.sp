*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_XNOR2B in0 in1 out
C_1 out gnd 2.28227fF
C_2 net_1 gnd 2.59306fF
C_3 vdd gnd 3.26066fF
C_4 in0 gnd 2.52075fF
C_5 in1 gnd 2.57491fF
C_6 net_4 gnd 1.15898fF
C_7 gnd gnd 2.795fF
Mp_1 out net_1 vdd vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.6026P 
+ PS=3.34U
Mp_2 vdd in0 net_2 vdd p W=1.84U L=0.18U AD=0.6026P PD=3.34U AS=0.3588P 
+ PS=2.23U
Mp_3 net_2 in1 out vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.6256P 
+ PS=3.13333U
Mp_4 out in1 net_3 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.3588P 
+ PS=2.23U
Mp_5 net_3 in0 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.6026P 
+ PS=3.34U
Mp_6 vdd in0 net_1 vdd p W=0.92U L=0.18U AD=0.3013P PD=1.67U AS=0.2484P 
+ PS=1.46U
Mp_7 net_1 in1 vdd vdd p W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.3013P 
+ PS=1.67U
Mn_1 out net_1 net_4 gnd n W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.6256P 
+ PS=3.13333U
Mn_2 net_4 in1 gnd gnd n W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.57408P 
+ PS=3.024U
Mn_3 gnd in0 net_4 gnd n W=1.84U L=0.18U AD=0.57408P PD=3.024U AS=0.6256P 
+ PS=3.13333U
Mn_4 net_1 in0 net_5 gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.1794P 
+ PS=1.31U
Mn_5 net_5 in1 gnd gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.28704P 
+ PS=1.512U
.ENDS	$ MMI_XNOR2B

.GLOBAL gnd vdd

