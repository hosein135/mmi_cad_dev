*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NOR2A in0 in1 out
C_1 out gnd 1.21331fF
C_2 in0 gnd 0.846838fF
C_3 in1 gnd 0.80916fF
C_4 vdd gnd 1.41941fF
C_5 gnd gnd 1.97048fF
Mp_1 out in0 net_1 vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.3588P 
+ PS=2.23U
Mp_2 net_1 in1 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.8832P 
+ PS=4.64U
Mn_1 gnd in0 out gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.1242P PS=1U
Mn_2 out in1 gnd gnd n W=0.46U L=0.18U AD=0.1242P PD=1U AS=0.2208P PS=1.88U
.ENDS	$ MMI_NOR2A

.GLOBAL gnd vdd

