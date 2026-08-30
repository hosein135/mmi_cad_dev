*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AO22B in0 in1 in2 in3 out
C_1 vdd gnd 2.7956fF
C_2 in2 gnd 1.54019fF
C_3 net_1 gnd 1.04666fF
C_4 in1 gnd 1.26053fF
C_5 net_2 gnd 2.58178fF
C_6 in0 gnd 1.1145fF
C_7 in3 gnd 1.05929fF
C_8 out gnd 1.3658fF
C_9 gnd gnd 1.95554fF
Mp_1 vdd in2 net_1 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.4968P 
+ PS=2.38U
Mp_2 net_1 in1 net_2 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_3 net_2 in0 net_1 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_4 net_1 in3 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mp_5 vdd net_2 out vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.8832P 
+ PS=4.64U
Mn_1 gnd in1 net_3 gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.1794P 
+ PS=1.31U
Mn_2 net_3 in0 net_2 gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.253P 
+ PS=1.47U
Mn_3 net_2 in2 net_4 gnd n W=0.92U L=0.18U AD=0.253P PD=1.47U AS=0.1794P 
+ PS=1.31U
Mn_4 net_4 in3 gnd gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.3128P 
+ PS=1.90667U
Mn_5 gnd net_2 out gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.4416P 
+ PS=2.8U
.ENDS	$ MMI_AO22B

.GLOBAL gnd vdd

