*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NOR3B in0 in1 in2 out
C_1 out gnd 2.8554fF
C_2 in0 gnd 2.42887fF
C_3 in1 gnd 2.36822fF
C_4 in2 gnd 2.98314fF
C_5 vdd gnd 3.13664fF
C_6 gnd gnd 2.7248fF
Mp_1 out in0 net_1 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.3588P 
+ PS=2.23U
Mp_2 net_1 in1 net_2 vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.3588P 
+ PS=2.23U
Mp_3 net_2 in2 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.6256P 
+ PS=3.13333U
Mp_4 vdd in2 net_3 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.3588P 
+ PS=2.23U
Mp_5 net_3 in1 net_4 vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.3588P 
+ PS=2.23U
Mp_6 net_4 in0 out vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.6256P 
+ PS=3.13333U
Mp_7 out in0 net_5 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.3588P 
+ PS=2.23U
Mp_8 net_5 in1 net_6 vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.3588P 
+ PS=2.23U
Mp_9 net_6 in2 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.6256P 
+ PS=3.13333U
Mn_1 out in0 gnd gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.3128P 
+ PS=1.90667U
Mn_2 gnd in1 out gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.3128P 
+ PS=1.90667U
Mn_3 out in2 gnd gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.3128P 
+ PS=1.90667U
.ENDS	$ MMI_NOR3B

.GLOBAL gnd vdd

