*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AO22C in0 in1 in2 in3 out
C_1 net_1 gnd 2.2874fF
C_2 in1 gnd 0.91778fF
C_3 net_2 gnd 2.97395fF
C_4 in0 gnd 0.83812fF
C_5 in2 gnd 0.84849fF
C_6 vdd gnd 3.72632fF
C_7 in3 gnd 0.93805fF
C_8 out gnd 1.19614fF
C_9 gnd gnd 3.70058fF
Mp_1 net_1 in1 net_2 vdd p W=2.48U L=0.18U AD=0.93P PD=4.47U AS=0.6696P 
+ PS=3.02U
Mp_2 net_2 in0 net_1 vdd p W=2.48U L=0.18U AD=0.6696P PD=3.02U AS=0.93P 
+ PS=4.47U
Mp_3 net_1 in2 vdd vdd p W=2.48U L=0.18U AD=0.93P PD=4.47U AS=0.891422P 
+ PS=4.39741U
Mp_4 vdd in3 net_1 vdd p W=2.48U L=0.18U AD=0.891422P PD=4.39741U AS=0.93P 
+ PS=4.47U
Mp_5 vdd net_2 out vdd p W=1.84U L=0.18U AD=0.661378P PD=3.26259U 
+ AS=0.4968P PS=2.38U
Mp_6 out net_2 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.661378P 
+ PS=3.26259U
Mn_1 gnd in1 net_3 gnd n W=1.24U L=0.18U AD=0.5952P PD=3.58222U AS=0.2418P 
+ PS=1.63U
Mn_2 net_3 in0 net_2 gnd n W=1.24U L=0.18U AD=0.2418P PD=1.63U AS=0.3348P 
+ PS=1.78U
Mn_3 net_2 in2 net_4 gnd n W=1.24U L=0.18U AD=0.3348P PD=1.78U AS=0.2418P 
+ PS=1.63U
Mn_4 net_4 in3 gnd gnd n W=1.24U L=0.18U AD=0.2418P PD=1.63U AS=0.5952P 
+ PS=3.58222U
Mn_5 gnd net_2 out gnd n W=0.92U L=0.18U AD=0.4416P PD=2.65778U AS=0.2484P 
+ PS=1.46U
Mn_6 out net_2 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.4416P 
+ PS=2.65778U
.ENDS	$ MMI_AO22C

.GLOBAL gnd vdd

