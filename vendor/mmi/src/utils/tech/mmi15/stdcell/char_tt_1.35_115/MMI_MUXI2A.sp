*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUXI2A in0 in1 out sel
C_1 net_1 gnd 2.51954fF
C_2 sel gnd 2.01072fF
C_3 vdd gnd 2.11824fF
C_4 in1 gnd 0.648875fF
C_5 net_2 gnd 0.87098fF
C_6 out gnd 0.9147fF
C_7 net_3 gnd 0.87098fF
C_8 in0 gnd 0.662555fF
C_9 gnd gnd 1.986fF
Mp_1 net_1 sel vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.25718P 
+ PS=1.742U
Mp_2 vdd in1 net_2 vdd p W=1.54U L=0.15U AD=0.51436P PD=3.484U AS=0.3773P 
+ PS=2.03U
Mp_3 net_2 net_1 out vdd p W=1.54U L=0.15U AD=0.3773P PD=2.03U AS=0.3388P 
+ PS=1.98U
Mp_4 out sel net_3 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.3388P 
+ PS=1.98U
Mp_5 net_3 in0 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.51436P 
+ PS=3.484U
Mn_1 net_1 sel gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.128529P PS=1.28534U
Mn_2 gnd in1 net_2 gnd n W=0.765U L=0.15U AD=0.255388P PD=2.55398U 
+ AS=0.190851P PS=1.95362U
Mn_3 net_2 sel out gnd n W=0.77U L=0.15U AD=0.192099P PD=1.96638U 
+ AS=0.1694P PS=1.21U
Mn_4 out net_1 net_3 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.1694P 
+ PS=1.21U
Mn_5 net_3 in0 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.257058P 
+ PS=2.57068U
.ENDS	$ MMI_MUXI2A

.GLOBAL gnd vdd

