*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INOR2B in0 in1 out
C_1 net_1 gnd 2.0942fF
C_2 in1 gnd 0.84434fF
C_3 vdd gnd 2.80028fF
C_4 in0 gnd 1.4934fF
C_5 out gnd 1.34598fF
C_6 gnd gnd 2.77922fF
Mp_1 net_1 in1 vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.37168P 
+ PS=2.088U
Mp_2 vdd in0 net_2 vdd p W=1.84U L=0.18U AD=0.74336P PD=4.176U AS=0.3588P 
+ PS=2.23U
Mp_3 net_2 net_1 out vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.4968P 
+ PS=2.38U
Mp_4 out net_1 net_3 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.3588P 
+ PS=2.23U
Mp_5 net_3 in0 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.74336P 
+ PS=4.176U
Mn_1 net_1 in1 gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.2208P 
+ PS=1.496U
Mn_2 gnd net_1 out gnd n W=0.92U L=0.18U AD=0.4416P PD=2.992U AS=0.2484P 
+ PS=1.46U
Mn_3 out in0 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.4416P 
+ PS=2.992U
.ENDS	$ MMI_INOR2B

.GLOBAL gnd vdd

