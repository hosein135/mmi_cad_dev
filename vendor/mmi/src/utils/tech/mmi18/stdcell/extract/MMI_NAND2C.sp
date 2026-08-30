*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND2C in0 in1 out
C_1 vdd gnd 2.85791fF
C_2 in0 gnd 1.21594fF
C_3 out gnd 1.96567fF
C_4 in1 gnd 1.47756fF
C_5 gnd gnd 2.58062fF
Mp_1 vdd in0 out vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.4968P 
+ PS=2.38U
Mp_2 out in0 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.69P 
+ PS=3.51U
Mp_3 vdd in1 out vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.4968P 
+ PS=2.38U
Mp_4 out in1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.69P 
+ PS=3.51U
Mn_1 gnd in1 net_1 gnd n W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.3588P 
+ PS=2.23U
Mn_2 net_1 in0 out gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mn_3 out in0 net_2 gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.3588P 
+ PS=2.23U
Mn_4 net_2 in1 gnd gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.8832P 
+ PS=4.64U
.ENDS	$ MMI_NAND2C

.GLOBAL gnd vdd

