*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NOR2A in0 in1 out
C_1 out gnd 0.99354fF
C_2 in0 gnd 0.692202fF
C_3 in1 gnd 0.67474fF
C_4 vdd gnd 1.14768fF
C_5 gnd gnd 1.59684fF
Mp_1 out in0 net_1 vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.2464P 
+ PS=1.86U
Mp_2 net_1 in1 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.6083P 
+ PS=3.87U
Mn_1 gnd in0 out gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U AS=0.0847P 
+ PS=0.825U
Mn_2 out in1 gnd gnd n W=0.385U L=0.15U AD=0.0847P PD=0.825U AS=0.152075P 
+ PS=1.56U
.ENDS	$ MMI_NOR2A

.GLOBAL gnd vdd

