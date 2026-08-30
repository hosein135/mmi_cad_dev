*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INOR2B in0 in1 out
C_1 net_1 gnd 1.7302fF
C_2 in1 gnd 0.69956fF
C_3 vdd gnd 2.25732fF
C_4 in0 gnd 1.21927fF
C_5 out gnd 1.1058fF
C_6 gnd gnd 2.24022fF
Mp_1 net_1 in1 vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.25641P 
+ PS=1.74U
Mp_2 vdd in0 net_2 vdd p W=1.54U L=0.15U AD=0.51282P PD=3.48U AS=0.2464P 
+ PS=1.86U
Mp_3 net_2 net_1 out vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.3388P 
+ PS=1.98U
Mp_4 out net_1 net_3 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.24255P 
+ PS=1.855U
Mp_5 net_3 in0 vdd vdd p W=1.54U L=0.15U AD=0.24255P PD=1.855U AS=0.51282P 
+ PS=3.48U
Mn_1 net_1 in1 gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.152075P PS=1.244U
Mn_2 gnd net_1 out gnd n W=0.77U L=0.15U AD=0.30415P PD=2.488U AS=0.1694P 
+ PS=1.21U
Mn_3 out in0 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.30415P 
+ PS=2.488U
.ENDS	$ MMI_INOR2B

.GLOBAL gnd vdd

