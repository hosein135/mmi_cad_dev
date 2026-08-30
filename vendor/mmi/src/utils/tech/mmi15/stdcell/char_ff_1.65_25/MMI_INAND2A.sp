*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INAND2A in0 in1 out
C_1 vdd gnd 1.76836fF
C_2 net_1 gnd 1.64532fF
C_3 out gnd 1.01451fF
C_4 in0 gnd 0.777345fF
C_5 in1 gnd 0.759145fF
C_6 gnd gnd 1.20634fF
Mp_1 vdd net_1 out vdd p W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.1694P PS=1.21U
Mp_2 out in0 vdd vdd p W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.214317P 
+ PS=1.58333U
Mp_3 vdd in1 net_1 vdd p W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.30415P PS=2.33U
Mn_1 out net_1 net_2 gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U 
+ AS=0.121275P PS=1.085U
Mn_2 net_2 in0 gnd gnd n W=0.77U L=0.15U AD=0.121275P PD=1.085U 
+ AS=0.226467P PS=2.56667U
Mn_3 gnd in1 net_1 gnd n W=0.385U L=0.15U AD=0.113233P PD=1.28333U 
+ AS=0.152075P PS=1.56U
.ENDS	$ MMI_INAND2A

.GLOBAL gnd vdd

