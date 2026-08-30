*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUX2C in0 in1 out sel
C_1 net_1 gnd 2.19521fF
C_2 sel gnd 2.01496fF
C_3 vdd gnd 3.06206fF
C_4 in1 gnd 0.652275fF
C_5 net_2 gnd 0.87317fF
C_6 net_3 gnd 2.07419fF
C_7 net_4 gnd 0.87317fF
C_8 in0 gnd 0.66705fF
C_9 out gnd 1.00214fF
C_10 gnd gnd 2.32645fF
Mp_1 net_1 sel vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.237333P 
+ PS=1.64889U
Mp_2 vdd in1 net_2 vdd p W=1.54U L=0.15U AD=0.474667P PD=3.29778U 
+ AS=0.3773P PS=2.03U
Mp_3 net_2 net_1 net_3 vdd p W=1.54U L=0.15U AD=0.3773P PD=2.03U AS=0.3388P 
+ PS=1.98U
Mp_4 net_3 sel net_4 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.3388P 
+ PS=1.98U
Mp_5 net_4 in0 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.474667P 
+ PS=3.29778U
Mp_6 vdd net_3 out vdd p W=1.54U L=0.15U AD=0.474667P PD=3.29778U 
+ AS=0.3388P PS=1.98U
Mp_7 out net_3 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.474667P 
+ PS=3.29778U
Mn_1 net_1 sel gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.115876P PS=1.00033U
Mn_2 gnd in1 net_2 gnd n W=0.765U L=0.15U AD=0.230246P PD=1.98767U 
+ AS=0.190415P PS=1.94863U
Mn_3 net_2 sel net_3 gnd n W=0.77U L=0.15U AD=0.19166P PD=1.96137U 
+ AS=0.1694P PS=1.21U
Mn_4 net_3 net_1 net_4 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.1694P 
+ PS=1.21U
Mn_5 net_4 in0 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.231751P 
+ PS=2.00066U
Mn_6 gnd net_3 out gnd n W=1.54U L=0.15U AD=0.463502P PD=4.00133U 
+ AS=0.6083P PS=3.87U
.ENDS	$ MMI_MUX2C

.GLOBAL gnd vdd

