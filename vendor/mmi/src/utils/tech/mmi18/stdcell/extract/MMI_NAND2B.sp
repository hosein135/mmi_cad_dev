*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND2B in0 in1 out
C_1 vdd gnd 1.97048fF
C_2 in0 gnd 0.87586fF
C_3 out gnd 1.54961fF
C_4 in1 gnd 0.97219fF
C_5 gnd gnd 1.34336fF
Mp_1 vdd in0 out vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.4968P 
+ PS=2.38U
Mp_2 out in1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.8832P 
+ PS=4.64U
Mn_1 out in0 net_1 gnd n W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.3588P 
+ PS=2.23U
Mn_2 net_1 in1 gnd gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.8832P 
+ PS=4.64U
.ENDS	$ MMI_NAND2B

.GLOBAL gnd vdd

