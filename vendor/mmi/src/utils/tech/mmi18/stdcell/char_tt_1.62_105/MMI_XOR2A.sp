*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_XOR2A in0 in1 out
C_1 out gnd 1.36332fF
C_2 net_1 gnd 2.25257fF
C_3 net_2 gnd 1.15898fF
C_4 in1 gnd 2.8435fF
C_5 vdd gnd 2.9123fF
C_6 in0 gnd 1.52445fF
C_7 gnd gnd 2.89475fF
Mp_1 out net_1 net_2 vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.6256P 
+ PS=3.13333U
Mp_2 net_2 in1 vdd vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.6256P 
+ PS=3.13333U
Mp_3 vdd in0 net_2 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.6256P 
+ PS=3.13333U
Mp_4 net_1 in0 net_3 vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.3588P 
+ PS=2.23U
Mp_5 net_3 in1 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.6256P 
+ PS=3.13333U
Mn_1 gnd net_1 out gnd n W=0.46U L=0.18U AD=0.18584P PD=1.544U AS=0.162533P 
+ PS=1.32U
Mn_2 out in1 net_4 gnd n W=0.92U L=0.18U AD=0.325067P PD=2.64U AS=0.1794P 
+ PS=1.31U
Mn_3 net_4 in0 gnd gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.37168P 
+ PS=3.088U
Mn_4 gnd in0 net_1 gnd n W=0.46U L=0.18U AD=0.18584P PD=1.544U AS=0.1242P 
+ PS=1U
Mn_5 net_1 in1 gnd gnd n W=0.46U L=0.18U AD=0.1242P PD=1U AS=0.18584P 
+ PS=1.544U
.ENDS	$ MMI_XOR2A

.GLOBAL gnd vdd

