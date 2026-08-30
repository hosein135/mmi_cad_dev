*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AOI21B in0 in1 in2 out
C_1 net_1 gnd 2.51726fF
C_2 in0 gnd 1.31336fF
C_3 out gnd 1.6309fF
C_4 in1 gnd 1.04965fF
C_5 vdd gnd 2.6315fF
C_6 in2 gnd 0.95087fF
C_7 gnd gnd 2.81051fF
Mp_1 net_1 in0 out vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.4968P 
+ PS=2.38U
Mp_2 out in0 net_1 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mp_3 net_1 in1 vdd vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.4968P 
+ PS=2.38U
Mp_4 vdd in1 net_1 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mp_5 net_1 in2 vdd vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.4968P 
+ PS=2.38U
Mp_6 vdd in2 net_1 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mn_1 gnd in0 out gnd n W=0.92U L=0.18U AD=0.4416P PD=2.48U AS=0.328133P 
+ PS=2.26U
Mn_2 out in1 net_2 gnd n W=1.84U L=0.18U AD=0.656267P PD=4.52U AS=0.3588P 
+ PS=2.23U
Mn_3 net_2 in2 gnd gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.8832P 
+ PS=4.96U
.ENDS	$ MMI_AOI21B

.GLOBAL gnd vdd

