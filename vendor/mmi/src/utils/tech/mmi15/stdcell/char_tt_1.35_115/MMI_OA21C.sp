*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OA21C in0 in1 in2 out
C_1 vdd gnd 2.68151fF
C_2 net_1 gnd 1.99137fF
C_3 out gnd 1.1383fF
C_4 in0 gnd 0.691207fF
C_5 in1 gnd 0.688052fF
C_6 in2 gnd 0.773465fF
C_7 gnd gnd 2.03274fF
C_8 net_3 gnd 0.889367fF
Mp_1 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.529512P PD=3.39297U 
+ AS=0.3388P PS=1.98U
Mp_2 out net_1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.529512P 
+ PS=3.39297U
Mp_3 vdd in0 net_1 vdd p W=1.04U L=0.15U AD=0.357592P PD=2.29135U 
+ AS=0.315467P PS=1.99333U
Mp_4 net_1 in1 net_2 vdd p W=2.08U L=0.15U AD=0.630933P PD=3.98667U 
+ AS=0.3328P PS=2.4U
Mp_5 net_2 in2 vdd vdd p W=2.08U L=0.15U AD=0.3328P PD=2.4U AS=0.715185P 
+ PS=4.58271U
Mn_1 out net_1 gnd gnd n W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.453449P 
+ PS=2.90558U
Mn_2 net_1 in0 net_3 gnd n W=1.04U L=0.15U AD=0.4108P PD=2.87U AS=0.289467P 
+ PS=1.94333U
Mn_3 net_3 in1 gnd gnd n W=1.04U L=0.15U AD=0.289467P PD=1.94333U 
+ AS=0.306225P PS=1.96221U
Mn_4 gnd in2 net_3 gnd n W=1.04U L=0.15U AD=0.306225P PD=1.96221U 
+ AS=0.289467P PS=1.94333U
.ENDS	$ MMI_OA21C

.GLOBAL gnd vdd

