*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUX2B in0 in1 out sel
C_1 net_1 gnd 2.52136fF
C_2 sel gnd 2.63125fF
C_3 vdd gnd 2.82572fF
C_4 in0 gnd 1.06024fF
C_5 net_2 gnd 1.40085fF
C_6 net_3 gnd 2.43827fF
C_7 net_4 gnd 1.26705fF
C_8 in1 gnd 1.19963fF
C_9 out gnd 1.32095fF
C_10 gnd gnd 2.37644fF
Mp_1 net_1 sel vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.281257P 
+ PS=1.50857U
Mp_2 vdd in0 net_2 vdd p W=1.84U L=0.18U AD=0.562514P PD=3.01714U 
+ AS=0.5336P PS=2.42U
Mp_3 net_2 sel net_3 vdd p W=1.84U L=0.18U AD=0.5336P PD=2.42U AS=0.5336P 
+ PS=2.42U
Mp_4 net_3 net_1 net_4 vdd p W=1.84U L=0.18U AD=0.5336P PD=2.42U AS=0.5336P 
+ PS=2.42U
Mp_5 net_4 in1 vdd vdd p W=1.84U L=0.18U AD=0.5336P PD=2.42U AS=0.562514P 
+ PS=3.01714U
Mp_6 vdd net_3 out vdd p W=1.84U L=0.18U AD=0.562514P PD=3.01714U 
+ AS=0.8832P PS=4.64U
Mn_1 net_1 sel gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.135371P 
+ PS=0.948571U
Mn_2 gnd in0 net_2 gnd n W=0.92U L=0.18U AD=0.270743P PD=1.89714U 
+ AS=0.2668P PS=1.5U
Mn_3 net_2 net_1 net_3 gnd n W=0.92U L=0.18U AD=0.2668P PD=1.5U AS=0.2668P 
+ PS=1.5U
Mn_4 net_3 sel net_4 gnd n W=0.92U L=0.18U AD=0.2668P PD=1.5U AS=0.2484P 
+ PS=1.46U
Mn_5 net_4 in1 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.270743P 
+ PS=1.89714U
Mn_6 gnd net_3 out gnd n W=0.92U L=0.18U AD=0.270743P PD=1.89714U 
+ AS=0.4416P PS=2.8U
.ENDS	$ MMI_MUX2B

.GLOBAL gnd vdd

