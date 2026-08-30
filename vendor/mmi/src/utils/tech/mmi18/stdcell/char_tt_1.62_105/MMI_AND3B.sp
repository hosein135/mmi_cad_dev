*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AND3B in0 in1 in2 out
C_1 net_1 gnd 2.66085fF
C_2 in0 gnd 0.92995fF
C_3 vdd gnd 2.16644fF
C_4 in1 gnd 0.8715fF
C_5 in2 gnd 1.01434fF
C_6 out gnd 1.28204fF
C_7 gnd gnd 1.87628fF
Mp_1 net_1 in0 vdd vdd p W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.2944P 
+ PS=1.744U
Mp_2 vdd in1 net_1 vdd p W=0.92U L=0.18U AD=0.2944P PD=1.744U AS=0.3128P 
+ PS=1.90667U
Mp_3 net_1 in2 vdd vdd p W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.2944P 
+ PS=1.744U
Mp_4 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.5888P PD=3.488U AS=0.8832P 
+ PS=4.64U
Mn_1 net_1 in0 net_2 gnd n W=1.38U L=0.18U AD=0.6624P PD=3.72U AS=0.2691P 
+ PS=1.77U
Mn_2 net_2 in1 net_3 gnd n W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.2691P 
+ PS=1.77U
Mn_3 net_3 in2 gnd gnd n W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.45264P 
+ PS=2.928U
Mn_4 gnd net_1 out gnd n W=0.92U L=0.18U AD=0.30176P PD=1.952U AS=0.4416P 
+ PS=2.8U
.ENDS	$ MMI_AND3B

.GLOBAL gnd vdd

