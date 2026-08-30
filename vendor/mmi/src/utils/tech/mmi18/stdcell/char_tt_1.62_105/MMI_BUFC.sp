*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_BUFC in out
C_1 net_1 gnd 1.89169fF
C_2 in gnd 0.7942fF
C_3 vdd gnd 2.19716fF
C_4 out gnd 1.50836fF
C_5 gnd gnd 1.65428fF
Mp_1 net_1 in vdd vdd p W=1.24U L=0.18U AD=0.5952P PD=3.44U AS=0.476442P 
+ PS=2.63122U
Mp_2 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.706979P PD=3.90439U 
+ AS=0.4968P PS=2.38U
Mp_3 out net_1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.706979P 
+ PS=3.90439U
Mn_1 net_1 in gnd gnd n W=0.62U L=0.18U AD=0.2976P PD=2.2U AS=0.238221P 
+ PS=1.46179U
Mn_2 gnd net_1 out gnd n W=1.84U L=0.18U AD=0.706979P PD=4.33821U 
+ AS=0.8832P PS=4.64U
.ENDS	$ MMI_BUFC

.GLOBAL gnd vdd

