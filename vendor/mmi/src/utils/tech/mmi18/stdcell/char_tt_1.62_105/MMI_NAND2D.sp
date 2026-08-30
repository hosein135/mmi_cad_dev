*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND2D in0 in1 out
C_1 vdd gnd 4.55204fF
C_2 in0 gnd 2.2979fF
C_3 out gnd 4.13454fF
C_4 in1 gnd 2.89565fF
C_5 gnd gnd 3.99512fF
Mp_1 vdd in0 out vdd p W=1.84U L=0.18U AD=0.5934P PD=2.945U AS=0.4968P 
+ PS=2.38U
Mp_2 out in0 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.5934P 
+ PS=2.945U
Mp_3 vdd in0 out vdd p W=1.84U L=0.18U AD=0.5934P PD=2.945U AS=0.4968P 
+ PS=2.38U
Mp_4 out in0 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.5934P 
+ PS=2.945U
Mp_5 vdd in1 out vdd p W=1.84U L=0.18U AD=0.5934P PD=2.945U AS=0.4968P 
+ PS=2.38U
Mp_6 out in1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.5934P 
+ PS=2.945U
Mp_7 vdd in1 out vdd p W=1.84U L=0.18U AD=0.5934P PD=2.945U AS=0.4968P 
+ PS=2.38U
Mp_8 out in1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.5934P 
+ PS=2.945U
Mn_1 gnd in1 net_1 gnd n W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.3588P 
+ PS=2.23U
Mn_2 net_1 in0 out gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mn_3 out in0 net_2 gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.3588P 
+ PS=2.23U
Mn_4 net_2 in1 gnd gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.69P 
+ PS=3.51U
Mn_5 gnd in1 net_3 gnd n W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.3588P 
+ PS=2.23U
Mn_6 net_3 in0 out gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mn_7 out in0 net_4 gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.3588P 
+ PS=2.23U
Mn_8 net_4 in1 gnd gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.69P 
+ PS=3.51U
.ENDS	$ MMI_NAND2D

.GLOBAL gnd vdd

