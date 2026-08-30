*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OA21C in0 in1 in2 out
C_1 vdd gnd 3.3221fF
C_2 net_1 gnd 2.41379fF
C_3 out gnd 1.38461fF
C_4 in0 gnd 0.82946fF
C_5 in1 gnd 0.824728fF
C_6 in2 gnd 0.92638fF
C_7 gnd gnd 2.5265fF
C_8 net_3 gnd 1.0878fF
Mp_1 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.766037P PD=4.06789U 
+ AS=0.4968P PS=2.38U
Mp_2 out net_1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.766037P 
+ PS=4.06789U
Mp_3 vdd in0 net_1 vdd p W=1.24U L=0.18U AD=0.516242P PD=2.74141U 
+ AS=0.4526P PS=2.38333U
Mp_4 net_1 in1 net_2 vdd p W=2.48U L=0.18U AD=0.9052P PD=4.76667U 
+ AS=0.4836P PS=2.87U
Mp_5 net_2 in2 vdd vdd p W=2.48U L=0.18U AD=0.4836P PD=2.87U AS=1.03248P 
+ PS=5.48281U
Mn_1 out net_1 gnd gnd n W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.661378P 
+ PS=3.49259U
Mn_2 net_1 in0 net_3 gnd n W=1.24U L=0.18U AD=0.5952P PD=3.44U AS=0.4216P 
+ PS=2.33333U
Mn_3 net_3 in1 gnd gnd n W=1.24U L=0.18U AD=0.4216P PD=2.33333U 
+ AS=0.445711P PS=2.3537U
Mn_4 gnd in2 net_3 gnd n W=1.24U L=0.18U AD=0.445711P PD=2.3537U AS=0.4216P 
+ PS=2.33333U
.ENDS	$ MMI_OA21C

.GLOBAL gnd vdd

