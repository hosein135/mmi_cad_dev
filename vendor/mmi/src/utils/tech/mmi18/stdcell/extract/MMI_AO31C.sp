*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AO31C in0 in1 in2 in3 out
C_1 net_1 gnd 3.16197fF
C_2 in0 gnd 0.97994fF
C_3 net_2 gnd 1.4585fF
C_4 in1 gnd 0.90497fF
C_5 vdd gnd 3.51134fF
C_6 in2 gnd 0.82022fF
C_7 in3 gnd 0.87009fF
C_8 out gnd 1.59524fF
C_9 gnd gnd 2.48525fF
Mp_1 net_1 in0 net_2 vdd p W=2.48U L=0.18U AD=1.1904P PD=5.92U AS=0.6696P 
+ PS=3.02U
Mp_2 net_2 in1 vdd vdd p W=2.48U L=0.18U AD=0.6696P PD=3.02U AS=0.802164P 
+ PS=3.96086U
Mp_3 vdd in2 net_2 vdd p W=2.48U L=0.18U AD=0.802164P PD=3.96086U 
+ AS=0.6696P PS=3.02U
Mp_4 net_2 in3 vdd vdd p W=2.48U L=0.18U AD=0.6696P PD=3.02U AS=0.802164P 
+ PS=3.96086U
Mp_5 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.595154P PD=2.93871U 
+ AS=0.4968P PS=2.38U
Mp_6 out net_1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.595154P 
+ PS=2.93871U
Mn_1 gnd in0 net_1 gnd n W=0.62U L=0.18U AD=0.197252P PD=1.15389U 
+ AS=0.2387P PS=1.7U
Mn_2 net_1 in1 net_3 gnd n W=1.86U L=0.18U AD=0.7161P PD=5.1U AS=0.3627P 
+ PS=2.25U
Mn_3 net_3 in2 net_4 gnd n W=1.86U L=0.18U AD=0.3627P PD=2.25U AS=0.3627P 
+ PS=2.25U
Mn_4 net_4 in3 gnd gnd n W=1.86U L=0.18U AD=0.3627P PD=2.25U AS=0.591756P 
+ PS=3.46167U
Mn_5 gnd net_1 out gnd n W=1.84U L=0.18U AD=0.585393P PD=3.42444U 
+ AS=0.8832P PS=4.64U
.ENDS	$ MMI_AO31C

.GLOBAL gnd vdd

