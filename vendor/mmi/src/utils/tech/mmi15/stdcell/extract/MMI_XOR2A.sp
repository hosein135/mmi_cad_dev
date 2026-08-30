*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_XOR2A in0 in1 out
C_1 out gnd 1.11877fF
C_2 net_1 gnd 1.84161fF
C_3 net_2 gnd 0.94315fF
C_4 in1 gnd 2.37106fF
C_5 vdd gnd 2.3422fF
C_6 in0 gnd 1.26292fF
C_7 gnd gnd 2.3308fF
Mp_1 out net_1 net_2 vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.428633P 
+ PS=2.61U
Mp_2 net_2 in1 vdd vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.428633P 
+ PS=2.61U
Mp_3 vdd in0 net_2 vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.428633P 
+ PS=2.61U
Mp_4 net_1 in0 net_3 vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.2464P 
+ PS=1.86U
Mp_5 net_3 in1 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.428633P 
+ PS=2.61U
Mn_1 gnd net_1 out gnd n W=0.385U L=0.15U AD=0.128205P PD=1.282U 
+ AS=0.112933P PS=1.1U
Mn_2 out in1 net_4 gnd n W=0.77U L=0.15U AD=0.225867P PD=2.2U AS=0.1232P 
+ PS=1.09U
Mn_3 net_4 in0 gnd gnd n W=0.77U L=0.15U AD=0.1232P PD=1.09U AS=0.25641P 
+ PS=2.564U
Mn_4 gnd in0 net_1 gnd n W=0.385U L=0.15U AD=0.128205P PD=1.282U AS=0.0847P 
+ PS=0.825U
Mn_5 net_1 in1 gnd gnd n W=0.385U L=0.15U AD=0.0847P PD=0.825U AS=0.128205P 
+ PS=1.282U
.ENDS	$ MMI_XOR2A

.GLOBAL gnd vdd

