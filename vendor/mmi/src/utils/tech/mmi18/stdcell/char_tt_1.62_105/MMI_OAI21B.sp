*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OAI21B in0 in1 in2 out
C_1 out gnd 2.13562fF
C_2 in0 gnd 0.73258fF
C_3 vdd gnd 2.69264fF
C_4 in2 gnd 1.40575fF
C_5 in1 gnd 0.91869fF
C_6 net_3 gnd 1.15898fF
C_7 gnd gnd 1.97331fF
Mp_1 out in0 vdd vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.6256P 
+ PS=3.13333U
Mp_2 vdd in2 net_1 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.3588P 
+ PS=2.23U
Mp_3 net_1 in1 out vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.6256P 
+ PS=3.13333U
Mp_4 out in1 net_2 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.3588P 
+ PS=2.23U
Mp_5 net_2 in2 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.6256P 
+ PS=3.13333U
Mn_1 out in0 net_3 gnd n W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.6256P 
+ PS=3.13333U
Mn_2 net_3 in1 gnd gnd n W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.4968P 
+ PS=2.38U
Mn_3 gnd in2 net_3 gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
.ENDS	$ MMI_OAI21B

.GLOBAL gnd vdd

