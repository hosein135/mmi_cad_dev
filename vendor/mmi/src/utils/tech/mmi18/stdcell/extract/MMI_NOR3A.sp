*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NOR3A in0 in1 in2 out
C_1 vdd gnd 2.00498fF
C_2 in2 gnd 1.09366fF
C_3 in1 gnd 1.01954fF
C_4 in0 gnd 1.09458fF
C_5 out gnd 1.92609fF
C_6 gnd gnd 1.83182fF
Mp_1 vdd in2 net_1 vdd p W=2.76U L=0.18U AD=1.3248P PD=6.48U AS=0.345P 
+ PS=3.01U
Mp_2 net_1 in1 net_2 vdd p W=2.76U L=0.18U AD=0.345P PD=3.01U AS=0.345P 
+ PS=3.01U
Mp_3 net_2 in0 out vdd p W=2.76U L=0.18U AD=0.345P PD=3.01U AS=1.3248P 
+ PS=6.48U
Mn_1 gnd in2 out gnd n W=0.46U L=0.18U AD=0.1564P PD=1.29333U AS=0.1564P 
+ PS=1.29333U
Mn_2 out in1 gnd gnd n W=0.46U L=0.18U AD=0.1564P PD=1.29333U AS=0.1564P 
+ PS=1.29333U
Mn_3 gnd in0 out gnd n W=0.46U L=0.18U AD=0.1564P PD=1.29333U AS=0.1564P 
+ PS=1.29333U
.ENDS	$ MMI_NOR3A

.GLOBAL gnd vdd

