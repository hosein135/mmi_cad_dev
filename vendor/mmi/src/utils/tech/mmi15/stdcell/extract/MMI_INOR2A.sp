*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INOR2A in0 in1 out
C_1 net_1 gnd 1.76944fF
C_2 in1 gnd 0.802852fF
C_3 vdd gnd 1.28158fF
C_4 in0 gnd 0.849078fF
C_5 out gnd 1.11246fF
C_6 gnd gnd 1.56772fF
Mp_1 net_1 in1 vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.225867P 
+ PS=1.61333U
Mp_2 vdd in0 net_2 vdd p W=1.54U L=0.15U AD=0.451733P PD=3.22667U 
+ AS=0.2387P PS=1.85U
Mp_3 net_2 net_1 out vdd p W=1.54U L=0.15U AD=0.2387P PD=1.85U AS=0.6083P 
+ PS=3.87U
Mn_1 net_1 in1 gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.107158P PS=1.07U
Mn_2 gnd in0 out gnd n W=0.385U L=0.15U AD=0.107158P PD=1.07U AS=0.0847P 
+ PS=0.825U
Mn_3 out net_1 gnd gnd n W=0.385U L=0.15U AD=0.0847P PD=0.825U AS=0.107158P 
+ PS=1.07U
.ENDS	$ MMI_INOR2A

.GLOBAL gnd vdd

