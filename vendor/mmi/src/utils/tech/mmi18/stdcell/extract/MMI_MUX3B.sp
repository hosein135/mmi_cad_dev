*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUX3B in0 in1 in2 out sel0 sel1
C_1 net_1 gnd 2.6309fF
C_2 in0 gnd 0.8135fF
C_3 vdd gnd 4.7822fF
C_4 in1 gnd 0.79514fF
C_5 net_2 gnd 0.799855fF
C_6 net_3 gnd 1.8182fF
C_7 net_4 gnd 2.69161fF
C_8 sel0 gnd 2.29811fF
C_9 sel1 gnd 3.20573fF
C_10 net_5 gnd 3.10756fF
C_11 net_6 gnd 2.31509fF
C_12 net_7 gnd 1.44098fF
C_13 in2 gnd 1.23543fF
C_14 out gnd 1.27544fF
C_15 gnd gnd 4.86644fF
Mp_1 net_1 in0 vdd vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.65872P 
+ PS=3.6U
Mp_2 vdd in1 net_2 vdd p W=1.84U L=0.18U AD=0.65872P PD=3.6U AS=0.4968P 
+ PS=2.38U
Mp_3 net_2 net_3 net_4 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mp_4 net_4 sel0 net_1 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U 
+ AS=0.8832P PS=4.64U
Mp_5 net_3 sel0 vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.32936P 
+ PS=1.8U
Mp_6 net_4 sel1 net_5 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U 
+ AS=0.4968P PS=2.38U
Mp_7 net_5 net_6 net_7 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_8 net_7 in2 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.65872P 
+ PS=3.6U
Mp_9 vdd sel1 net_6 vdd p W=0.92U L=0.18U AD=0.32936P PD=1.8U AS=0.3616P 
+ PS=4.08U
Mp_10 vdd net_5 out vdd p W=1.84U L=0.18U AD=0.65872P PD=3.6U AS=0.8832P 
+ PS=4.64U
Mn_1 net_1 in0 gnd gnd n W=0.92U L=0.18U AD=0.4016P PD=3.44U AS=0.36752P 
+ PS=2.66U
Mn_2 gnd in1 net_2 gnd n W=0.92U L=0.18U AD=0.36752P PD=2.66U AS=0.2484P 
+ PS=1.46U
Mn_3 net_2 sel0 net_4 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.3128P 
+ PS=1.90667U
Mn_4 net_4 net_3 net_1 gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U 
+ AS=0.4016P PS=3.44U
Mn_5 net_3 sel0 gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.18376P 
+ PS=1.33U
Mn_6 net_4 net_6 net_5 gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U 
+ AS=0.2484P PS=1.46U
Mn_7 net_5 sel1 net_7 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2484P 
+ PS=1.46U
Mn_8 net_7 in2 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.36752P 
+ PS=2.66U
Mn_9 gnd sel1 net_6 gnd n W=0.46U L=0.18U AD=0.18376P PD=1.33U AS=0.2208P 
+ PS=1.88U
Mn_10 gnd net_5 out gnd n W=0.92U L=0.18U AD=0.36752P PD=2.66U AS=0.4416P 
+ PS=2.8U
.ENDS	$ MMI_MUX3B

.GLOBAL gnd vdd

