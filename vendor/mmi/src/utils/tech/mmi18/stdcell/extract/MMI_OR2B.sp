*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OR2B in0 in1 out
C_1 net_1 gnd 2.23951fF
C_2 in0 gnd 0.95225fF
C_3 in1 gnd 0.958445fF
C_4 vdd gnd 1.63907fF
C_5 out gnd 1.32323fF
C_6 gnd gnd 1.88828fF
Mp_1 net_1 in0 net_2 vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.3588P 
+ PS=2.23U
Mp_2 net_2 in1 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mp_3 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.8832P 
+ PS=4.64U
Mn_1 gnd in0 net_1 gnd n W=0.46U L=0.18U AD=0.1771P PD=1.46U AS=0.1242P 
+ PS=1U
Mn_2 net_1 in1 gnd gnd n W=0.46U L=0.18U AD=0.1242P PD=1U AS=0.1771P 
+ PS=1.46U
Mn_3 gnd net_1 out gnd n W=0.92U L=0.18U AD=0.3542P PD=2.92U AS=0.4416P 
+ PS=2.8U
.ENDS	$ MMI_OR2B

.GLOBAL gnd vdd

