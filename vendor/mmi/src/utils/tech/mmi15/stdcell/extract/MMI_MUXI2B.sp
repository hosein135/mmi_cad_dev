*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUXI2B in0 in1 out sel
C_1 net_1 gnd 3.18551fF
C_2 sel gnd 3.19179fF
C_3 vdd gnd 3.03512fF
C_4 in0 gnd 1.1447fF
C_5 net_2 gnd 2.84928fF
C_6 in1 gnd 1.14148fF
C_7 net_3 gnd 1.95772fF
C_8 out gnd 2.97136fF
C_9 gnd gnd 3.19244fF
Mp_1 net_1 sel vdd vdd p W=1.04U L=0.15U AD=0.4108P PD=2.87U AS=0.289351P 
+ PS=1.833U
Mp_2 vdd in0 net_2 vdd p W=1.54U L=0.15U AD=0.428462P PD=2.71425U 
+ AS=0.3388P PS=1.98U
Mp_3 net_2 in0 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.428462P 
+ PS=2.71425U
Mp_4 vdd in1 net_3 vdd p W=1.54U L=0.15U AD=0.428462P PD=2.71425U 
+ AS=0.348425P PS=1.9925U
Mp_5 net_3 in1 vdd vdd p W=1.54U L=0.15U AD=0.348425P PD=1.9925U 
+ AS=0.428462P PS=2.71425U
Mp_6 out net_1 net_3 vdd p W=1.54U L=0.15U AD=0.479325P PD=2.9325U 
+ AS=0.348425P PS=1.9925U
Mp_7 net_3 net_1 out vdd p W=1.54U L=0.15U AD=0.348425P PD=1.9925U 
+ AS=0.479325P PS=2.9325U
Mp_8 out sel net_2 vdd p W=1.54U L=0.15U AD=0.479325P PD=2.9325U AS=0.3388P 
+ PS=1.98U
Mp_9 net_2 sel out vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.479325P 
+ PS=2.9325U
Mn_1 net_1 sel gnd gnd n W=0.52U L=0.15U AD=0.2054P PD=1.83U AS=0.143563P 
+ PS=1.16278U
Mn_2 gnd in0 net_2 gnd n W=0.77U L=0.15U AD=0.212584P PD=1.72181U 
+ AS=0.1694P PS=1.21U
Mn_3 net_2 in0 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.212584P 
+ PS=1.72181U
Mn_4 gnd in1 net_3 gnd n W=0.77U L=0.15U AD=0.212584P PD=1.72181U 
+ AS=0.1694P PS=1.21U
Mn_5 net_3 in1 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.212584P 
+ PS=1.72181U
Mn_6 out sel net_3 gnd n W=0.77U L=0.15U AD=0.236775P PD=1.77U AS=0.1694P 
+ PS=1.21U
Mn_7 net_3 sel out gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.236775P 
+ PS=1.77U
Mn_8 out net_1 net_2 gnd n W=0.77U L=0.15U AD=0.236775P PD=1.77U AS=0.1694P 
+ PS=1.21U
Mn_9 net_2 net_1 out gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.236775P 
+ PS=1.77U
.ENDS	$ MMI_MUXI2B

.GLOBAL gnd vdd

