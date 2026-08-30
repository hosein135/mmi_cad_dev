*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OAI31B in0 in1 in2 in3 out
C_1 out gnd 3.06613fF
C_2 in0 gnd 1.22234fF
C_3 vdd gnd 3.91964fF
C_4 in3 gnd 3.51015fF
C_5 in2 gnd 3.52941fF
C_6 in1 gnd 3.25336fF
C_7 net_9 gnd 2.12fF
C_8 gnd gnd 3.6248fF
Mp_1 out in0 vdd vdd p W=1.84U L=0.18U AD=0.5934P PD=3.08U AS=0.6072P 
+ PS=3.34U
Mp_2 vdd in3 net_1 vdd p W=1.38U L=0.18U AD=0.4554P PD=2.505U AS=0.2691P 
+ PS=1.77U
Mp_3 net_1 in2 net_2 vdd p W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.2691P 
+ PS=1.77U
Mp_4 net_2 in1 out vdd p W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.44505P 
+ PS=2.31U
Mp_5 out in1 net_3 vdd p W=1.38U L=0.18U AD=0.44505P PD=2.31U AS=0.2691P 
+ PS=1.77U
Mp_6 net_3 in2 net_4 vdd p W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.2691P 
+ PS=1.77U
Mp_7 net_4 in3 vdd vdd p W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.4554P 
+ PS=2.505U
Mp_8 vdd in3 net_5 vdd p W=1.38U L=0.18U AD=0.4554P PD=2.505U AS=0.2691P 
+ PS=1.77U
Mp_9 net_5 in2 net_6 vdd p W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.2691P 
+ PS=1.77U
Mp_10 net_6 in1 out vdd p W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.44505P 
+ PS=2.31U
Mp_11 out in1 net_7 vdd p W=1.38U L=0.18U AD=0.44505P PD=2.31U AS=0.2691P 
+ PS=1.77U
Mp_12 net_7 in2 net_8 vdd p W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.2691P 
+ PS=1.77U
Mp_13 net_8 in3 vdd vdd p W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.4554P 
+ PS=2.505U
Mn_1 net_9 in0 out gnd n W=0.92U L=0.18U AD=0.2967P PD=1.795U AS=0.2484P 
+ PS=1.46U
Mn_2 out in0 net_9 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2967P 
+ PS=1.795U
Mn_3 net_9 in1 gnd gnd n W=0.92U L=0.18U AD=0.2967P PD=1.795U AS=0.2484P 
+ PS=1.46U
Mn_4 gnd in1 net_9 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2967P 
+ PS=1.795U
Mn_5 net_9 in2 gnd gnd n W=0.92U L=0.18U AD=0.2967P PD=1.795U AS=0.2484P 
+ PS=1.46U
Mn_6 gnd in2 net_9 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2967P 
+ PS=1.795U
Mn_7 net_9 in3 gnd gnd n W=0.92U L=0.18U AD=0.2967P PD=1.795U AS=0.2484P 
+ PS=1.46U
Mn_8 gnd in3 net_9 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2967P 
+ PS=1.795U
.ENDS	$ MMI_OAI31B

.GLOBAL gnd vdd

