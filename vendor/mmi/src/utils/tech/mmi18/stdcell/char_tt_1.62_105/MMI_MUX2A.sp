*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUX2A in0 in1 out sel
C_1 net_1 gnd 2.61091fF
C_2 sel gnd 2.32823fF
C_3 vdd gnd 2.8304fF
C_4 in0 gnd 1.14178fF
C_5 net_2 gnd 1.22511fF
C_6 net_3 gnd 2.71894fF
C_7 net_4 gnd 1.37409fF
C_8 in1 gnd 1.31682fF
C_9 out gnd 1.1063fF
C_10 gnd gnd 2.25476fF
Mp_1 net_1 sel vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.2484P 
+ PS=1.46U
Mp_2 vdd in0 net_2 vdd p W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2484P 
+ PS=1.46U
Mp_3 net_2 sel net_3 vdd p W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.325067P 
+ PS=1.93333U
Mp_4 net_3 net_1 net_4 vdd p W=1.84U L=0.18U AD=0.650133P PD=3.86667U 
+ AS=0.650133P PS=3.86667U
Mp_5 net_4 in1 vdd vdd p W=0.92U L=0.18U AD=0.325067P PD=1.93333U 
+ AS=0.2484P PS=1.46U
Mp_6 vdd net_3 out vdd p W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.4416P 
+ PS=2.8U
Mn_1 net_1 sel gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.1242P 
+ PS=1U
Mn_2 gnd in0 net_2 gnd n W=0.46U L=0.18U AD=0.1242P PD=1U AS=0.1242P PS=1U
Mn_3 net_2 net_1 net_3 gnd n W=0.46U L=0.18U AD=0.1242P PD=1U AS=0.162533P 
+ PS=1.32U
Mn_4 net_3 sel net_4 gnd n W=0.92U L=0.18U AD=0.325067P PD=2.64U 
+ AS=0.325067P PS=2.64U
Mn_5 net_4 in1 gnd gnd n W=0.46U L=0.18U AD=0.162533P PD=1.32U AS=0.1242P 
+ PS=1U
Mn_6 gnd net_3 out gnd n W=0.46U L=0.18U AD=0.1242P PD=1U AS=0.2208P 
+ PS=1.88U
.ENDS	$ MMI_MUX2A

.GLOBAL gnd vdd

