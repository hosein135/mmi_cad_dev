*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AO21B in0 in1 in2 out
C_1 net_1 gnd 2.23032fF
C_2 in0 gnd 0.775855fF
C_3 net_2 gnd 0.949085fF
C_4 in1 gnd 0.78101fF
C_5 vdd gnd 2.08974fF
C_6 in2 gnd 0.75644fF
C_7 out gnd 0.970732fF
C_8 gnd gnd 2.24022fF
Mp_1 net_1 in0 net_2 vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.428633P 
+ PS=2.61U
Mp_2 net_2 in1 vdd vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.428633P 
+ PS=2.61U
Mp_3 vdd in2 net_2 vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.428633P 
+ PS=2.61U
Mp_4 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.6083P 
+ PS=3.87U
Mn_1 gnd in0 net_1 gnd n W=0.385U L=0.15U AD=0.152075P PD=1.244U 
+ AS=0.112933P PS=1.1U
Mn_2 net_1 in1 net_3 gnd n W=0.77U L=0.15U AD=0.225867P PD=2.2U AS=0.1232P 
+ PS=1.09U
Mn_3 net_3 in2 gnd gnd n W=0.77U L=0.15U AD=0.1232P PD=1.09U AS=0.30415P 
+ PS=2.488U
Mn_4 gnd net_1 out gnd n W=0.77U L=0.15U AD=0.30415P PD=2.488U AS=0.30415P 
+ PS=2.33U
.ENDS	$ MMI_AO21B

.GLOBAL gnd vdd

