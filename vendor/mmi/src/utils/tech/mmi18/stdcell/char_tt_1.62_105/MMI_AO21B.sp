*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AO21B in0 in1 in2 out
C_1 net_1 gnd 2.71352fF
C_2 in0 gnd 0.93917fF
C_3 net_2 gnd 1.15898fF
C_4 in1 gnd 0.940345fF
C_5 vdd gnd 2.59553fF
C_6 in2 gnd 0.91332fF
C_7 out gnd 1.18463fF
C_8 gnd gnd 2.77805fF
Mp_1 net_1 in0 net_2 vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.6256P 
+ PS=3.13333U
Mp_2 net_2 in1 vdd vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.6256P 
+ PS=3.13333U
Mp_3 vdd in2 net_2 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.6256P 
+ PS=3.13333U
Mp_4 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.8832P 
+ PS=4.64U
Mn_1 gnd in0 net_1 gnd n W=0.46U L=0.18U AD=0.2208P PD=1.496U AS=0.162533P 
+ PS=1.32U
Mn_2 net_1 in1 net_3 gnd n W=0.92U L=0.18U AD=0.325067P PD=2.64U AS=0.1794P 
+ PS=1.31U
Mn_3 net_3 in2 gnd gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.4416P 
+ PS=2.992U
Mn_4 gnd net_1 out gnd n W=0.92U L=0.18U AD=0.4416P PD=2.992U AS=0.4416P 
+ PS=2.8U
.ENDS	$ MMI_AO21B

.GLOBAL gnd vdd

