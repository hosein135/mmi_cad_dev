*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_TSBUFC en enb in out
C_1 net_1 gnd 2.05535fF
C_2 enb gnd 0.770445fF
C_3 net_2 gnd 1.97766fF
C_4 in gnd 0.768005fF
C_5 vdd gnd 2.79364fF
C_6 en gnd 0.993252fF
C_7 out gnd 0.958905fF
C_8 gnd gnd 2.52574fF
Mp_1 net_1 enb net_2 vdd p W=0.705U L=0.15U AD=0.278475P PD=2.2U 
+ AS=0.224719P PS=1.695U
Mp_2 net_2 in vdd vdd p W=1.41U L=0.15U AD=0.449438P PD=3.39U AS=0.499546P 
+ PS=3.34654U
Mp_3 vdd en net_2 vdd p W=0.705U L=0.15U AD=0.249773P PD=1.67327U 
+ AS=0.224719P PS=1.695U
Mp_4 vdd net_2 out vdd p W=1.54U L=0.15U AD=0.545603P PD=3.65509U 
+ AS=0.3388P PS=1.98U
Mp_5 out net_2 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.545603P 
+ PS=3.65509U
Mn_1 net_1 enb gnd gnd n W=0.35U L=0.15U AD=0.112311P PD=1.30036U 
+ AS=0.123852P PS=1.05607U
Mn_2 gnd in net_1 gnd n W=0.705U L=0.15U AD=0.249474P PD=2.12723U 
+ AS=0.226227P PS=2.61929U
Mn_3 net_1 en net_2 gnd n W=0.35U L=0.15U AD=0.112311P PD=1.30036U 
+ AS=0.13825P PS=1.49U
Mn_4 gnd net_1 out gnd n W=0.77U L=0.15U AD=0.272475P PD=2.32335U 
+ AS=0.1694P PS=1.21U
Mn_5 out net_1 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.272475P 
+ PS=2.32335U
.ENDS	$ MMI_TSBUFC

.GLOBAL gnd vdd

