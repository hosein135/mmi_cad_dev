*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND4A in0 in1 in2 in3 out
C_1 vdd gnd 2.32322fF
C_2 in0 gnd 1.0494fF
C_3 out gnd 2.1628fF
C_4 in1 gnd 1.03158fF
C_5 in2 gnd 1.08388fF
C_6 in3 gnd 1.14876fF
C_7 gnd gnd 1.77566fF
Mp_1 vdd in0 out vdd p W=0.92U L=0.18U AD=0.345P PD=2.13U AS=0.2484P 
+ PS=1.46U
Mp_2 out in1 vdd vdd p W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.345P 
+ PS=2.13U
Mp_3 vdd in2 out vdd p W=0.92U L=0.18U AD=0.345P PD=2.13U AS=0.2484P 
+ PS=1.46U
Mp_4 out in3 vdd vdd p W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.345P 
+ PS=2.13U
Mn_1 out in0 net_1 gnd n W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.3588P 
+ PS=2.23U
Mn_2 net_1 in1 net_2 gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.3588P 
+ PS=2.23U
Mn_3 net_2 in2 net_3 gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.3588P 
+ PS=2.23U
Mn_4 net_3 in3 gnd gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.8832P 
+ PS=4.64U
.ENDS	$ MMI_NAND4A

.GLOBAL gnd vdd

