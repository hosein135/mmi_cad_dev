*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_XOR2B in0 in1 out
C_1 net_1 gnd 2.15767fF
C_2 net_2 gnd 2.19644fF
C_3 out gnd 1.30764fF
C_4 in1 gnd 3.16626fF
C_5 vdd gnd 3.29794fF
C_6 in0 gnd 1.7349fF
C_7 gnd gnd 3.52252fF
C_8 net_4 gnd 0.635642fF
Mp_1 net_1 net_2 out vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.3388P 
+ PS=1.98U
Mp_2 out net_2 net_1 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.428633P 
+ PS=2.61U
Mp_3 net_1 in1 vdd vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.3927P 
+ PS=2.358U
Mp_4 vdd in1 net_1 vdd p W=1.54U L=0.15U AD=0.3927P PD=2.358U AS=0.428633P 
+ PS=2.61U
Mp_5 net_1 in0 vdd vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.3927P 
+ PS=2.358U
Mp_6 vdd in0 net_1 vdd p W=1.54U L=0.15U AD=0.3927P PD=2.358U AS=0.428633P 
+ PS=2.61U
Mp_7 net_2 in0 net_3 vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.2464P 
+ PS=1.86U
Mp_8 net_3 in1 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.3927P 
+ PS=2.358U
Mn_1 gnd net_2 out gnd n W=0.77U L=0.15U AD=0.276238P PD=2.585U 
+ AS=0.214317P PS=1.58333U
Mn_2 out in1 net_4 gnd n W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.1694P PS=1.21U
Mn_3 net_4 in1 out gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.214317P 
+ PS=1.58333U
Mn_4 gnd in0 net_4 gnd n W=0.77U L=0.15U AD=0.276238P PD=2.585U AS=0.1694P 
+ PS=1.21U
Mn_5 net_4 in0 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.276238P 
+ PS=2.585U
Mn_6 gnd in0 net_2 gnd n W=0.385U L=0.15U AD=0.138119P PD=1.2925U 
+ AS=0.0847P PS=0.825U
Mn_7 net_2 in1 gnd gnd n W=0.385U L=0.15U AD=0.0847P PD=0.825U AS=0.138119P 
+ PS=1.2925U
.ENDS	$ MMI_XOR2B

.GLOBAL gnd vdd

