*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND3B in0 in1 in2 out
C_1 out gnd 2.13591fF
C_2 in1 gnd 1.30789fF
C_3 vdd gnd 2.69264fF
C_4 in0 gnd 1.14242fF
C_5 in2 gnd 1.45794fF
C_6 gnd gnd 2.13662fF
Mp_1 out in1 vdd vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.6256P 
+ PS=3.13333U
Mp_2 vdd in0 out vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.6256P 
+ PS=3.13333U
Mp_3 out in2 vdd vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.6256P 
+ PS=3.13333U
Mn_1 out in0 net_1 gnd n W=2.76U L=0.18U AD=1.3248P PD=6.48U AS=0.345P 
+ PS=3.01U
Mn_2 net_1 in1 net_2 gnd n W=2.76U L=0.18U AD=0.345P PD=3.01U AS=0.345P 
+ PS=3.01U
Mn_3 net_2 in2 gnd gnd n W=2.76U L=0.18U AD=0.345P PD=3.01U AS=1.3248P 
+ PS=6.48U
.ENDS	$ MMI_NAND3B

.GLOBAL gnd vdd

