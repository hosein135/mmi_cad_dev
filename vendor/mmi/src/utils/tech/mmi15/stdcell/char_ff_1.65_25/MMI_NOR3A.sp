*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NOR3A in0 in1 in2 out
C_1 vdd gnd 1.61524fF
C_2 in2 gnd 0.90769fF
C_3 in1 gnd 0.84754fF
C_4 in0 gnd 0.904367fF
C_5 out gnd 1.56837fF
C_6 gnd gnd 1.47749fF
Mp_1 vdd in2 net_1 vdd p W=2.315U L=0.15U AD=0.914425P PD=5.42U AS=0.25465P 
+ PS=2.535U
Mp_2 net_1 in1 net_2 vdd p W=2.315U L=0.15U AD=0.25465P PD=2.535U 
+ AS=0.25465P PS=2.535U
Mp_3 net_2 in0 out vdd p W=2.315U L=0.15U AD=0.25465P PD=2.535U 
+ AS=0.914425P PS=5.42U
Mn_1 gnd in2 out gnd n W=0.385U L=0.15U AD=0.107158P PD=1.07U AS=0.107158P 
+ PS=1.07U
Mn_2 out in1 gnd gnd n W=0.385U L=0.15U AD=0.107158P PD=1.07U AS=0.107158P 
+ PS=1.07U
Mn_3 gnd in0 out gnd n W=0.385U L=0.15U AD=0.107158P PD=1.07U AS=0.107158P 
+ PS=1.07U
.ENDS	$ MMI_NOR3A

.GLOBAL gnd vdd

