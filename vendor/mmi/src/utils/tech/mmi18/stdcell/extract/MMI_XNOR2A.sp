*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_XNOR2A in0 in1 out
C_1 vdd gnd 3.30104fF
C_2 in0 gnd 2.50019fF
C_3 net_1 gnd 2.16083fF
C_4 in1 gnd 2.11657fF
C_5 out gnd 0.91025fF
C_6 net_3 gnd 0.72842fF
C_7 gnd gnd 2.39429fF
Mp_1 vdd in0 net_1 vdd p W=0.92U L=0.18U AD=0.36432P PD=2.072U AS=0.2484P 
+ PS=1.46U
Mp_2 net_1 in1 vdd vdd p W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.36432P 
+ PS=2.072U
Mp_3 vdd net_1 out vdd p W=0.92U L=0.18U AD=0.36432P PD=2.072U AS=0.325067P 
+ PS=2.25333U
Mp_4 out in1 net_2 vdd p W=1.84U L=0.18U AD=0.650133P PD=4.50667U 
+ AS=0.3588P PS=2.23U
Mp_5 net_2 in0 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.72864P 
+ PS=4.144U
Mn_1 out net_1 net_3 gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.3128P 
+ PS=1.90667U
Mn_2 net_1 in0 net_4 gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.1794P 
+ PS=1.31U
Mn_3 net_4 in1 gnd gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.3128P 
+ PS=1.90667U
Mn_4 net_3 in1 gnd gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.3128P 
+ PS=1.90667U
Mn_5 gnd in0 net_3 gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.3128P 
+ PS=1.90667U
.ENDS	$ MMI_XNOR2A

.GLOBAL gnd vdd

