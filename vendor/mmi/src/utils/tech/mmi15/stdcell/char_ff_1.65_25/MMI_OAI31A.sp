*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OAI31A in0 in1 in2 in3 out
C_1 vdd gnd 2.10404fF
C_2 in0 gnd 0.731462fF
C_3 out gnd 1.20492fF
C_4 in1 gnd 0.69588fF
C_5 in2 gnd 0.70956fF
C_6 in3 gnd 0.761637fF
C_7 net_3 gnd 0.597965fF
C_8 gnd gnd 1.57166fF
Mp_1 vdd in0 out vdd p W=0.77U L=0.15U AD=0.30415P PD=1.93436U AS=0.245533P 
+ PS=1.79209U
Mp_2 out in1 net_1 vdd p W=2.315U L=0.15U AD=0.738192P PD=5.38791U 
+ AS=0.25465P PS=2.535U
Mp_3 net_1 in2 net_2 vdd p W=2.315U L=0.15U AD=0.25465P PD=2.535U 
+ AS=0.25465P PS=2.535U
Mp_4 net_2 in3 vdd vdd p W=2.315U L=0.15U AD=0.25465P PD=2.535U 
+ AS=0.914425P PS=5.81564U
Mn_1 out in0 net_3 gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.1694P 
+ PS=1.21U
Mn_2 net_3 in1 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.214317P 
+ PS=1.58333U
Mn_3 gnd in2 net_3 gnd n W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.1694P PS=1.21U
Mn_4 net_3 in3 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.214317P 
+ PS=1.58333U
.ENDS	$ MMI_OAI31A

.GLOBAL gnd vdd

