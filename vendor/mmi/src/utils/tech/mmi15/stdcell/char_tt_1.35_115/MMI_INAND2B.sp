*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INAND2B in0 in1 out
C_1 vdd gnd 1.6954fF
C_2 net_1 gnd 1.55212fF
C_3 out gnd 1.26228fF
C_4 in0 gnd 0.69085fF
C_5 in1 gnd 0.692335fF
C_6 gnd gnd 1.27588fF
Mp_1 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.51898P PD=3.496U AS=0.3388P 
+ PS=1.98U
Mp_2 out in0 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.51898P 
+ PS=3.496U
Mp_3 vdd in1 net_1 vdd p W=0.77U L=0.15U AD=0.25949P PD=1.748U AS=0.30415P 
+ PS=2.33U
Mn_1 out net_1 net_2 gnd n W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.2464P 
+ PS=1.86U
Mn_2 net_2 in0 gnd gnd n W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.51508P 
+ PS=4.312U
Mn_3 gnd in1 net_1 gnd n W=0.385U L=0.15U AD=0.12877P PD=1.078U 
+ AS=0.152075P PS=1.56U
.ENDS	$ MMI_INAND2B

.GLOBAL gnd vdd

