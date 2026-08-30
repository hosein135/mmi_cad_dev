*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_XOR2B in0 in1 out
C_1 net_1 gnd 2.65766fF
C_2 net_2 gnd 2.66664fF
C_3 out gnd 1.60558fF
C_4 in1 gnd 3.79672fF
C_5 vdd gnd 4.1048fF
C_6 in0 gnd 2.08716fF
C_7 gnd gnd 4.37624fF
C_8 net_4 gnd 0.76752fF
Mp_1 net_1 net_2 out vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U 
+ AS=0.4968P PS=2.38U
Mp_2 out net_2 net_1 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mp_3 net_1 in1 vdd vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.57408P 
+ PS=2.832U
Mp_4 vdd in1 net_1 vdd p W=1.84U L=0.18U AD=0.57408P PD=2.832U AS=0.6256P 
+ PS=3.13333U
Mp_5 net_1 in0 vdd vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.57408P 
+ PS=2.832U
Mp_6 vdd in0 net_1 vdd p W=1.84U L=0.18U AD=0.57408P PD=2.832U AS=0.6256P 
+ PS=3.13333U
Mp_7 net_2 in0 net_3 vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.3588P 
+ PS=2.23U
Mp_8 net_3 in1 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.57408P 
+ PS=2.832U
Mn_1 gnd net_2 out gnd n W=0.92U L=0.18U AD=0.3979P PD=3.1U AS=0.3128P 
+ PS=1.90667U
Mn_2 out in1 net_4 gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.2484P 
+ PS=1.46U
Mn_3 net_4 in1 out gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.3128P 
+ PS=1.90667U
Mn_4 gnd in0 net_4 gnd n W=0.92U L=0.18U AD=0.3979P PD=3.1U AS=0.2484P 
+ PS=1.46U
Mn_5 net_4 in0 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.3979P 
+ PS=3.1U
Mn_6 gnd in0 net_2 gnd n W=0.46U L=0.18U AD=0.19895P PD=1.55U AS=0.1242P 
+ PS=1U
Mn_7 net_2 in1 gnd gnd n W=0.46U L=0.18U AD=0.1242P PD=1U AS=0.19895P 
+ PS=1.55U
.ENDS	$ MMI_XOR2B

.GLOBAL gnd vdd

