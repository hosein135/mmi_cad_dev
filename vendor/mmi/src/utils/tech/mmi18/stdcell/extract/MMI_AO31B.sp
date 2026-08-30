*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AO31B in0 in1 in2 in3 out
C_1 net_1 gnd 3.15277fF
C_2 in0 gnd 0.91628fF
C_3 net_2 gnd 1.15898fF
C_4 in1 gnd 0.93032fF
C_5 vdd gnd 2.52884fF
C_6 in2 gnd 1.12297fF
C_7 in3 gnd 1.0448fF
C_8 out gnd 1.33861fF
C_9 gnd gnd 2.40248fF
Mp_1 net_1 in0 net_2 vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.4968P 
+ PS=2.38U
Mp_2 net_2 in1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_3 vdd in2 net_2 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_4 net_2 in3 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_5 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.8832P 
+ PS=4.64U
Mn_1 gnd in0 net_1 gnd n W=0.46U L=0.18U AD=0.162533P PD=1.12667U 
+ AS=0.1771P PS=1.22U
Mn_2 net_1 in1 net_3 gnd n W=1.38U L=0.18U AD=0.5313P PD=3.66U AS=0.2691P 
+ PS=1.77U
Mn_3 net_3 in2 net_4 gnd n W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.2691P 
+ PS=1.77U
Mn_4 net_4 in3 gnd gnd n W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.4876P 
+ PS=3.38U
Mn_5 gnd net_1 out gnd n W=0.92U L=0.18U AD=0.325067P PD=2.25333U 
+ AS=0.4416P PS=2.8U
.ENDS	$ MMI_AO31B

.GLOBAL gnd vdd

