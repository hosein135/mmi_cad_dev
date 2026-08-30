*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AOI31A in0 in1 in2 in3 out
C_1 out gnd 1.44106fF
C_2 in0 gnd 0.86654fF
C_3 net_1 gnd 1.15898fF
C_4 in1 gnd 0.93197fF
C_5 vdd gnd 2.29982fF
C_6 in2 gnd 0.85459fF
C_7 in3 gnd 0.88838fF
C_8 gnd gnd 2.26472fF
Mp_1 out in0 net_1 vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.4968P 
+ PS=2.38U
Mp_2 net_1 in1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mp_3 vdd in2 net_1 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.4968P 
+ PS=2.38U
Mp_4 net_1 in3 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mn_1 gnd in0 out gnd n W=0.46U L=0.18U AD=0.2208P PD=1.4U AS=0.1771P 
+ PS=1.22U
Mn_2 out in1 net_2 gnd n W=1.38U L=0.18U AD=0.5313P PD=3.66U AS=0.2691P 
+ PS=1.77U
Mn_3 net_2 in2 net_3 gnd n W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.2691P 
+ PS=1.77U
Mn_4 net_3 in3 gnd gnd n W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.6624P 
+ PS=4.2U
.ENDS	$ MMI_AOI31A

.GLOBAL gnd vdd

