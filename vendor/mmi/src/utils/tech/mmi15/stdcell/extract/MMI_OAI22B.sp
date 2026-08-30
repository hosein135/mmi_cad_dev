*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OAI22B in0 in1 in2 in3 out
C_1 out gnd 3.14905fF
C_2 in0 gnd 1.51753fF
C_3 in1 gnd 1.63511fF
C_4 vdd gnd 2.57124fF
C_5 in2 gnd 1.88819fF
C_6 in3 gnd 1.67872fF
C_7 gnd gnd 2.67498fF
C_8 net_5 gnd 1.78206fF
Mp_1 out in0 net_1 vdd p W=1.54U L=0.15U AD=0.47355P PD=2.925U AS=0.2464P 
+ PS=1.86U
Mp_2 net_1 in1 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.3388P 
+ PS=1.98U
Mp_3 vdd in1 net_2 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.24255P 
+ PS=1.855U
Mp_4 net_2 in0 out vdd p W=1.54U L=0.15U AD=0.24255P PD=1.855U AS=0.47355P 
+ PS=2.925U
Mp_5 out in2 net_3 vdd p W=1.54U L=0.15U AD=0.47355P PD=2.925U AS=0.2464P 
+ PS=1.86U
Mp_6 net_3 in3 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.3388P 
+ PS=1.98U
Mp_7 vdd in3 net_4 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.2464P 
+ PS=1.86U
Mp_8 net_4 in2 out vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.47355P 
+ PS=2.925U
Mn_1 gnd in2 net_5 gnd n W=0.77U L=0.15U AD=0.236775P PD=1.77U AS=0.194769P 
+ PS=1.74U
Mn_2 net_5 in0 out gnd n W=0.77U L=0.15U AD=0.194769P PD=1.74U AS=0.1694P 
+ PS=1.21U
Mn_3 out in0 net_5 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.194769P 
+ PS=1.74U
Mn_4 net_5 in2 gnd gnd n W=0.77U L=0.15U AD=0.194769P PD=1.74U AS=0.236775P 
+ PS=1.77U
Mn_5 gnd in3 net_5 gnd n W=0.77U L=0.15U AD=0.236775P PD=1.77U AS=0.194769P 
+ PS=1.74U
Mn_6 net_5 in1 out gnd n W=0.77U L=0.15U AD=0.194769P PD=1.74U AS=0.1694P 
+ PS=1.21U
Mn_7 out in1 net_5 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.194769P 
+ PS=1.74U
Mn_8 net_5 in3 gnd gnd n W=0.77U L=0.15U AD=0.194769P PD=1.74U AS=0.236775P 
+ PS=1.77U
.ENDS	$ MMI_OAI22B

.GLOBAL gnd vdd

