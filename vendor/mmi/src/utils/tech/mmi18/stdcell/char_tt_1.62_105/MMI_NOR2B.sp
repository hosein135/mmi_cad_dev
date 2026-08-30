*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NOR2B in0 in1 out
C_1 vdd gnd 2.56892fF
C_2 in1 gnd 1.6376fF
C_3 in0 gnd 1.23179fF
C_4 out gnd 1.2794fF
C_5 gnd gnd 2.06348fF
Mp_1 vdd in1 net_1 vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.3588P 
+ PS=2.23U
Mp_2 net_1 in0 out vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mp_3 out in0 net_2 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.3588P 
+ PS=2.23U
Mp_4 net_2 in1 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.8832P 
+ PS=4.64U
Mn_1 gnd in0 out gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.2484P 
+ PS=1.46U
Mn_2 out in1 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.4416P 
+ PS=2.8U
.ENDS	$ MMI_NOR2B

.GLOBAL gnd vdd

