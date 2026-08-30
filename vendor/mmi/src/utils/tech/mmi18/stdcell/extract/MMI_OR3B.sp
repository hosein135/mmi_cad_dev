*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OR3B in0 in1 in2 out
C_1 net_1 gnd 2.56739fF
C_2 in0 gnd 0.98221fF
C_3 in1 gnd 0.891013fF
C_4 in2 gnd 0.8095fF
C_5 vdd gnd 1.94648fF
C_6 out gnd 1.14074fF
C_7 gnd gnd 2.14772fF
Mp_1 net_1 in0 net_2 vdd p W=2.76U L=0.18U AD=1.3248P PD=6.48U AS=0.345P 
+ PS=3.01U
Mp_2 net_2 in1 net_3 vdd p W=2.76U L=0.18U AD=0.345P PD=3.01U AS=0.345P 
+ PS=3.01U
Mp_3 net_3 in2 vdd vdd p W=2.76U L=0.18U AD=0.345P PD=3.01U AS=0.7728P 
+ PS=4.728U
Mp_4 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.5152P PD=3.152U AS=0.8832P 
+ PS=4.64U
Mn_1 net_1 in0 gnd gnd n W=0.46U L=0.18U AD=0.1564P PD=1.29333U AS=0.1472P 
+ PS=1.192U
Mn_2 gnd in1 net_1 gnd n W=0.46U L=0.18U AD=0.1472P PD=1.192U AS=0.1564P 
+ PS=1.29333U
Mn_3 net_1 in2 gnd gnd n W=0.46U L=0.18U AD=0.1564P PD=1.29333U AS=0.1472P 
+ PS=1.192U
Mn_4 gnd net_1 out gnd n W=0.92U L=0.18U AD=0.2944P PD=2.384U AS=0.4416P 
+ PS=2.8U
.ENDS	$ MMI_OR3B

.GLOBAL gnd vdd

