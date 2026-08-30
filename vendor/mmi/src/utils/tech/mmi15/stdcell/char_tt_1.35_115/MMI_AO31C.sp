*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AO31C in0 in1 in2 in3 out
C_1 net_1 gnd 2.50516fF
C_2 in0 gnd 0.81104fF
C_3 net_2 gnd 1.19314fF
C_4 in1 gnd 0.702705fF
C_5 vdd gnd 2.82898fF
C_6 in2 gnd 0.68253fF
C_7 in3 gnd 0.72114fF
C_8 out gnd 1.31146fF
C_9 gnd gnd 1.9945fF
Mp_1 net_1 in0 net_2 vdd p W=2.08U L=0.15U AD=0.8216P PD=4.95U AS=0.4732P 
+ PS=2.535U
Mp_2 net_2 in1 vdd vdd p W=2.08U L=0.15U AD=0.4732P PD=2.535U AS=0.558944P 
+ PS=3.31416U
Mp_3 vdd in2 net_2 vdd p W=2.08U L=0.15U AD=0.558944P PD=3.31416U 
+ AS=0.4732P PS=2.535U
Mp_4 net_2 in3 vdd vdd p W=2.08U L=0.15U AD=0.4732P PD=2.535U AS=0.558944P 
+ PS=3.31416U
Mp_5 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.413834P PD=2.45376U 
+ AS=0.35035P PS=1.995U
Mp_6 out net_1 vdd vdd p W=1.54U L=0.15U AD=0.35035P PD=1.995U AS=0.413834P 
+ PS=2.45376U
Mn_1 gnd in0 net_1 gnd n W=0.52U L=0.15U AD=0.137929P PD=1.07735U 
+ AS=0.16575P PS=1.4175U
Mn_2 net_1 in1 net_3 gnd n W=1.56U L=0.15U AD=0.49725P PD=4.2525U 
+ AS=0.2496P PS=1.88U
Mn_3 net_3 in2 net_4 gnd n W=1.56U L=0.15U AD=0.2496P PD=1.88U AS=0.2496P 
+ PS=1.88U
Mn_4 net_4 in3 gnd gnd n W=1.56U L=0.15U AD=0.2496P PD=1.88U AS=0.413788P 
+ PS=3.23204U
Mn_5 gnd net_1 out gnd n W=1.54U L=0.15U AD=0.408483P PD=3.19061U 
+ AS=0.6083P PS=3.87U
.ENDS	$ MMI_AO31C

.GLOBAL gnd vdd

