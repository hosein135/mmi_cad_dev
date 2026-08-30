*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUXI2A in0 in1 out sel
C_1 net_1 gnd 3.09289fF
C_2 sel gnd 2.42787fF
C_3 vdd gnd 2.6084fF
C_4 in1 gnd 0.80296fF
C_5 net_2 gnd 1.08419fF
C_6 out gnd 1.08419fF
C_7 net_3 gnd 1.08419fF
C_8 in0 gnd 0.81059fF
C_9 gnd gnd 2.65052fF
Mp_1 net_1 sel vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.37168P 
+ PS=2.088U
Mp_2 vdd in1 net_2 vdd p W=1.84U L=0.18U AD=0.74336P PD=4.176U AS=0.5336P 
+ PS=2.42U
Mp_3 net_2 net_1 out vdd p W=1.84U L=0.18U AD=0.5336P PD=2.42U AS=0.4968P 
+ PS=2.38U
Mp_4 out sel net_3 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_5 net_3 in0 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.74336P 
+ PS=4.176U
Mn_1 net_1 sel gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.185687P 
+ PS=1.35389U
Mn_2 gnd in1 net_2 gnd n W=0.91U L=0.18U AD=0.367338P PD=2.67834U 
+ AS=0.269221P PS=2.32721U
Mn_3 net_2 sel out gnd n W=0.92U L=0.18U AD=0.272179P PD=2.35279U 
+ AS=0.2484P PS=1.46U
Mn_4 out net_1 net_3 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2484P 
+ PS=1.46U
Mn_5 net_3 in0 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.371375P 
+ PS=2.70777U
.ENDS	$ MMI_MUXI2A

.GLOBAL gnd vdd

