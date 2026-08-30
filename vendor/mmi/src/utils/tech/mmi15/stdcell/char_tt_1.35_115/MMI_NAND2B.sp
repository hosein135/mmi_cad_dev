*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND2B in0 in1 out
C_1 vdd gnd 1.59684fF
C_2 in0 gnd 0.727385fF
C_3 out gnd 1.2694fF
C_4 in1 gnd 0.80737fF
C_5 gnd gnd 1.08498fF
Mp_1 vdd in0 out vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.3388P 
+ PS=1.98U
Mp_2 out in1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.6083P 
+ PS=3.87U
Mn_1 out in0 net_1 gnd n W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.2387P 
+ PS=1.85U
Mn_2 net_1 in1 gnd gnd n W=1.54U L=0.15U AD=0.2387P PD=1.85U AS=0.6083P 
+ PS=3.87U
.ENDS	$ MMI_NAND2B

.GLOBAL gnd vdd

