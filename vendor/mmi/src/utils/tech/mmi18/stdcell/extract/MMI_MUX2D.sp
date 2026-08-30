*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUX2D in0 in1 out sel
C_1 vdd gnd 5.94956fF
C_2 in0 gnd 1.3044fF
C_3 net_1 gnd 3.20616fF
C_4 in1 gnd 1.34161fF
C_5 net_2 gnd 2.02326fF
C_6 net_3 gnd 5.32659fF
C_7 net_4 gnd 2.50789fF
C_8 sel gnd 2.3935fF
C_9 out gnd 2.2338fF
C_10 gnd gnd 6.43979fF
Mp_1 vdd in0 net_1 vdd p W=1.84U L=0.18U AD=0.621117P PD=3.19364U 
+ AS=0.4968P PS=2.38U
Mp_2 net_1 in0 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.621117P 
+ PS=3.19364U
Mp_3 vdd in1 net_2 vdd p W=1.84U L=0.18U AD=0.621117P PD=3.19364U 
+ AS=0.4968P PS=2.38U
Mp_4 net_2 in1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.621117P 
+ PS=3.19364U
Mp_5 net_3 net_4 net_2 vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.4968P 
+ PS=2.38U
Mp_6 net_2 net_4 net_3 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.69P 
+ PS=3.51U
Mp_7 net_3 sel net_1 vdd p W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.4968P 
+ PS=2.38U
Mp_8 net_1 sel net_3 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.69P 
+ PS=3.51U
Mp_9 net_4 sel vdd vdd p W=1.24U L=0.18U AD=0.5952P PD=3.44U AS=0.418579P 
+ PS=2.15223U
Mp_10 vdd net_3 out vdd p W=2.455U L=0.18U AD=0.828718P PD=4.26107U 
+ AS=0.8347P PS=3.95333U
Mp_11 out net_3 vdd vdd p W=2.455U L=0.18U AD=0.8347P PD=3.95333U 
+ AS=0.828718P PS=4.26107U
Mp_12 vdd net_3 out vdd p W=2.455U L=0.18U AD=0.828718P PD=4.26107U 
+ AS=0.8347P PS=3.95333U
Mn_1 gnd in0 net_1 gnd n W=0.92U L=0.18U AD=0.369891P PD=2.29654U 
+ AS=0.2484P PS=1.46U
Mn_2 net_1 in0 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.369891P 
+ PS=2.29654U
Mn_3 gnd in1 net_2 gnd n W=0.92U L=0.18U AD=0.369891P PD=2.29654U 
+ AS=0.2484P PS=1.46U
Mn_4 net_2 in1 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.369891P 
+ PS=2.29654U
Mn_5 net_3 sel net_2 gnd n W=0.92U L=0.18U AD=0.345P PD=2.13U AS=0.2484P 
+ PS=1.46U
Mn_6 net_2 sel net_3 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.345P 
+ PS=2.13U
Mn_7 net_3 net_4 net_1 gnd n W=0.92U L=0.18U AD=0.345P PD=2.13U AS=0.2484P 
+ PS=1.46U
Mn_8 net_1 net_4 net_3 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.345P 
+ PS=2.13U
Mn_9 net_4 sel gnd gnd n W=0.62U L=0.18U AD=0.2976P PD=2.2U AS=0.249274P 
+ PS=1.54767U
Mn_10 gnd net_3 out gnd n W=1.84U L=0.18U AD=0.739781P PD=4.59308U 
+ AS=0.4968P PS=2.38U
Mn_11 out net_3 gnd gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.739781P 
+ PS=4.59308U
.ENDS	$ MMI_MUX2D

.GLOBAL gnd vdd

