*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NOR3B in0 in1 in2 out
C_1 out gnd 2.33878fF
C_2 in0 gnd 2.00443fF
C_3 in1 gnd 1.88422fF
C_4 in2 gnd 2.47384fF
C_5 vdd gnd 2.52056fF
C_6 gnd gnd 2.1854fF
Mp_1 out in0 net_1 vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.24255P 
+ PS=1.855U
Mp_2 net_1 in1 net_2 vdd p W=1.54U L=0.15U AD=0.24255P PD=1.855U AS=0.2464P 
+ PS=1.86U
Mp_3 net_2 in2 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.433767P 
+ PS=2.61667U
Mp_4 vdd in2 net_3 vdd p W=1.54U L=0.15U AD=0.433767P PD=2.61667U 
+ AS=0.2464P PS=1.86U
Mp_5 net_3 in1 net_4 vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.2464P 
+ PS=1.86U
Mp_6 net_4 in0 out vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.428633P 
+ PS=2.61U
Mp_7 out in0 net_5 vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.2464P 
+ PS=1.86U
Mp_8 net_5 in1 net_6 vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.2464P 
+ PS=1.86U
Mp_9 net_6 in2 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.433767P 
+ PS=2.61667U
Mn_1 out in0 gnd gnd n W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.218167P PS=1.59333U
Mn_2 gnd in1 out gnd n W=0.77U L=0.15U AD=0.218167P PD=1.59333U 
+ AS=0.214317P PS=1.58333U
Mn_3 out in2 gnd gnd n W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.218167P PS=1.59333U
.ENDS	$ MMI_NOR3B

.GLOBAL gnd vdd

