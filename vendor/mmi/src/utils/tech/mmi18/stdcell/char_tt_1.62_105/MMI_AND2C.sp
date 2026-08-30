*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AND2C in0 in1 out
C_1 vdd gnd 2.95619fF
C_2 in0 gnd 0.8676fF
C_3 net_1 gnd 2.14975fF
C_4 in1 gnd 0.82938fF
C_5 out gnd 1.33186fF
C_6 gnd gnd 1.87277fF
Mp_1 vdd in0 net_1 vdd p W=1.24U L=0.18U AD=0.500348P PD=2.79403U 
+ AS=0.3348P PS=1.78U
Mp_2 net_1 in1 vdd vdd p W=1.24U L=0.18U AD=0.3348P PD=1.78U AS=0.500348P 
+ PS=2.79403U
Mp_3 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.742452P PD=4.14597U 
+ AS=0.4968P PS=2.38U
Mp_4 out net_1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.742452P 
+ PS=4.14597U
Mn_1 net_1 in0 net_2 gnd n W=1.24U L=0.18U AD=0.5952P PD=3.44U AS=0.2418P 
+ PS=1.63U
Mn_2 net_2 in1 gnd gnd n W=1.24U L=0.18U AD=0.2418P PD=1.63U AS=0.405496P 
+ PS=2.33506U
Mn_3 gnd net_1 out gnd n W=1.84U L=0.18U AD=0.601704P PD=3.46494U 
+ AS=0.8832P PS=4.64U
.ENDS	$ MMI_AND2C

.GLOBAL gnd vdd

