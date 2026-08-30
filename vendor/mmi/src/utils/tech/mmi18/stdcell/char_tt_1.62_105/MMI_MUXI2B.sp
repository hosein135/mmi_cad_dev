*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUXI2B in0 in1 out sel
C_1 net_1 gnd 3.8535fF
C_2 sel gnd 3.86839fF
C_3 vdd gnd 3.78626fF
C_4 in0 gnd 1.38324fF
C_5 net_2 gnd 3.59976fF
C_6 in1 gnd 1.3767fF
C_7 net_3 gnd 2.39456fF
C_8 out gnd 3.62242fF
C_9 gnd gnd 3.9758fF
Mp_1 net_1 sel vdd vdd p W=1.24U L=0.18U AD=0.5952P PD=3.44U AS=0.415833P 
+ PS=2.19163U
Mp_2 vdd in0 net_2 vdd p W=1.84U L=0.18U AD=0.617042P PD=3.25209U 
+ AS=0.4968P PS=2.38U
Mp_3 net_2 in0 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.617042P 
+ PS=3.25209U
Mp_4 vdd in1 net_3 vdd p W=1.84U L=0.18U AD=0.617042P PD=3.25209U 
+ AS=0.4968P PS=2.38U
Mp_5 net_3 in1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.617042P 
+ PS=3.25209U
Mp_6 out net_1 net_3 vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.4968P 
+ PS=2.38U
Mp_7 net_3 net_1 out vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.69P 
+ PS=3.51U
Mp_8 out sel net_2 vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.4968P 
+ PS=2.38U
Mp_9 net_2 sel out vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.69P 
+ PS=3.51U
Mn_1 net_1 sel gnd gnd n W=0.62U L=0.18U AD=0.2976P PD=2.2U AS=0.207916P 
+ PS=1.39572U
Mn_2 gnd in0 net_2 gnd n W=0.92U L=0.18U AD=0.308521P PD=2.07107U 
+ AS=0.2484P PS=1.46U
Mn_3 net_2 in0 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.308521P 
+ PS=2.07107U
Mn_4 gnd in1 net_3 gnd n W=0.92U L=0.18U AD=0.308521P PD=2.07107U 
+ AS=0.2484P PS=1.46U
Mn_5 net_3 in1 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.308521P 
+ PS=2.07107U
Mn_6 out sel net_3 gnd n W=0.92U L=0.18U AD=0.345P PD=2.13U AS=0.2484P 
+ PS=1.46U
Mn_7 net_3 sel out gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.345P 
+ PS=2.13U
Mn_8 out net_1 net_2 gnd n W=0.92U L=0.18U AD=0.345P PD=2.13U AS=0.2484P 
+ PS=1.46U
Mn_9 net_2 net_1 out gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.345P 
+ PS=2.13U
.ENDS	$ MMI_MUXI2B

.GLOBAL gnd vdd

