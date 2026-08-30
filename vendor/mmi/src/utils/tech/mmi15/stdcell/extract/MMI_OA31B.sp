*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OA31B in0 in1 in2 in3 out
C_1 out gnd 0.929175fF
C_2 net_1 gnd 2.49802fF
C_3 vdd gnd 2.26292fF
C_4 in0 gnd 0.85563fF
C_5 in1 gnd 1.50944fF
C_6 in2 gnd 1.20299fF
C_7 in3 gnd 1.31282fF
C_8 gnd gnd 2.6471fF
C_9 net_6 gnd 0.59971fF
Mp_1 out net_1 vdd vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.395267P 
+ PS=2.67667U
Mp_2 vdd in0 net_1 vdd p W=0.77U L=0.15U AD=0.197633P PD=1.33833U 
+ AS=0.2464P PS=1.795U
Mp_3 net_1 in1 net_2 vdd p W=1.155U L=0.15U AD=0.3696P PD=2.6925U 
+ AS=0.1848P PS=1.475U
Mp_4 net_2 in2 net_3 vdd p W=1.155U L=0.15U AD=0.1848P PD=1.475U AS=0.1848P 
+ PS=1.475U
Mp_5 net_3 in3 vdd vdd p W=1.155U L=0.15U AD=0.1848P PD=1.475U AS=0.29645P 
+ PS=2.0075U
Mp_6 vdd in3 net_4 vdd p W=1.155U L=0.15U AD=0.29645P PD=2.0075U AS=0.1848P 
+ PS=1.475U
Mp_7 net_4 in2 net_5 vdd p W=1.155U L=0.15U AD=0.1848P PD=1.475U AS=0.1848P 
+ PS=1.475U
Mp_8 net_5 in1 net_1 vdd p W=1.155U L=0.15U AD=0.1848P PD=1.475U AS=0.3696P 
+ PS=2.6925U
Mn_1 out net_1 gnd gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.236775P 
+ PS=1.77U
Mn_2 net_1 in0 net_6 gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.1694P 
+ PS=1.21U
Mn_3 net_6 in1 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.236775P 
+ PS=1.77U
Mn_4 gnd in2 net_6 gnd n W=0.77U L=0.15U AD=0.236775P PD=1.77U AS=0.1694P 
+ PS=1.21U
Mn_5 net_6 in3 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.236775P 
+ PS=1.77U
.ENDS	$ MMI_OA31B

.GLOBAL gnd vdd

