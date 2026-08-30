*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OAI31A in0 in1 in2 in3 out
C_1 vdd gnd 2.60519fF
C_2 in0 gnd 0.88376fF
C_3 out gnd 1.58509fF
C_4 in1 gnd 0.83801fF
C_5 in2 gnd 0.85439fF
C_6 in3 gnd 0.922725fF
C_7 net_3 gnd 0.72842fF
C_8 gnd gnd 1.95116fF
Mp_1 vdd in0 out vdd p W=0.92U L=0.18U AD=0.4416P PD=2.32U AS=0.3542P 
+ PS=2.15U
Mp_2 out in1 net_1 vdd p W=2.76U L=0.18U AD=1.0626P PD=6.45U AS=0.345P 
+ PS=3.01U
Mp_3 net_1 in2 net_2 vdd p W=2.76U L=0.18U AD=0.345P PD=3.01U AS=0.345P 
+ PS=3.01U
Mp_4 net_2 in3 vdd vdd p W=2.76U L=0.18U AD=0.345P PD=3.01U AS=1.3248P 
+ PS=6.96U
Mn_1 out in0 net_3 gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.2484P 
+ PS=1.46U
Mn_2 net_3 in1 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.3128P 
+ PS=1.90667U
Mn_3 gnd in2 net_3 gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.2484P 
+ PS=1.46U
Mn_4 net_3 in3 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.3128P 
+ PS=1.90667U
.ENDS	$ MMI_OAI31A

.GLOBAL gnd vdd

