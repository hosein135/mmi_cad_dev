*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OAI22A in0 in1 in2 in3 out
C_1 vdd gnd 2.01056fF
C_2 in3 gnd 0.82312fF
C_3 in2 gnd 1.27076fF
C_4 out gnd 1.46236fF
C_5 in0 gnd 0.82446fF
C_6 in1 gnd 0.830932fF
C_7 gnd gnd 1.46336fF
C_8 net_3 gnd 0.403718fF
Mp_1 vdd in3 net_1 vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.2464P 
+ PS=1.86U
Mp_2 net_1 in2 out vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.3388P 
+ PS=1.98U
Mp_3 out in0 net_2 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.2464P 
+ PS=1.86U
Mp_4 net_2 in1 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.6083P 
+ PS=3.87U
Mn_1 gnd in3 net_3 gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.175175P 
+ PS=1.225U
Mn_2 net_3 in0 out gnd n W=0.77U L=0.15U AD=0.175175P PD=1.225U AS=0.17325P 
+ PS=1.22U
Mn_3 out in1 net_3 gnd n W=0.77U L=0.15U AD=0.17325P PD=1.22U AS=0.175175P 
+ PS=1.225U
Mn_4 net_3 in2 gnd gnd n W=0.77U L=0.15U AD=0.175175P PD=1.225U AS=0.30415P 
+ PS=2.33U
.ENDS	$ MMI_OAI22A

.GLOBAL gnd vdd

