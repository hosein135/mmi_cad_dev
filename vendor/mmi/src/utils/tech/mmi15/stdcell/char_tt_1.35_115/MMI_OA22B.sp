*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OA22B in0 in1 in2 in3 out
C_1 out gnd 1.1364fF
C_2 net_1 gnd 2.2079fF
C_3 vdd gnd 1.929fF
C_4 in3 gnd 0.88244fF
C_5 in2 gnd 1.24936fF
C_6 in0 gnd 0.95456fF
C_7 in1 gnd 1.54756fF
C_8 gnd gnd 1.7808fF
C_9 net_4 gnd 0.5903fF
Mp_1 out net_1 vdd vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.436333P 
+ PS=2.62U
Mp_2 vdd in3 net_2 vdd p W=1.54U L=0.15U AD=0.436333P PD=2.62U AS=0.2464P 
+ PS=1.86U
Mp_3 net_2 in2 net_1 vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.35035P 
+ PS=1.995U
Mp_4 net_1 in0 net_3 vdd p W=1.54U L=0.15U AD=0.35035P PD=1.995U AS=0.2464P 
+ PS=1.86U
Mp_5 net_3 in1 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.436333P 
+ PS=2.62U
Mn_1 out net_1 gnd gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.243833P 
+ PS=1.66U
Mn_2 gnd in3 net_4 gnd n W=0.77U L=0.15U AD=0.243833P PD=1.66U AS=0.1694P 
+ PS=1.21U
Mn_3 net_4 in1 net_1 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.1694P 
+ PS=1.21U
Mn_4 net_1 in0 net_4 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.1694P 
+ PS=1.21U
Mn_5 net_4 in2 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.243833P 
+ PS=1.66U
.ENDS	$ MMI_OA22B

.GLOBAL gnd vdd

