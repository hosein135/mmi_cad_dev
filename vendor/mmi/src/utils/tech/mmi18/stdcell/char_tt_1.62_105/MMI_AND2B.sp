*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AND2B in0 in1 out
C_1 vdd gnd 2.22758fF
C_2 in0 gnd 1.01329fF
C_3 net_1 gnd 2.25763fF
C_4 in1 gnd 1.06761fF
C_5 out gnd 1.38567fF
C_6 gnd gnd 1.4039fF
Mp_1 vdd in0 net_1 vdd p W=0.92U L=0.18U AD=0.3542P PD=2.15U AS=0.2484P 
+ PS=1.46U
Mp_2 net_1 in1 vdd vdd p W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.3542P 
+ PS=2.15U
Mp_3 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.7084P PD=4.3U AS=0.8832P 
+ PS=4.64U
Mn_1 net_1 in0 net_2 gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.1794P 
+ PS=1.31U
Mn_2 net_2 in1 gnd gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.2484P 
+ PS=1.46U
Mn_3 gnd net_1 out gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.4416P 
+ PS=2.8U
.ENDS	$ MMI_AND2B

.GLOBAL gnd vdd

