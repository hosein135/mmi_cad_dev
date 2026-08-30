*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INOR2A in0 in1 out
C_1 net_1 gnd 2.13856fF
C_2 in1 gnd 0.95265fF
C_3 vdd gnd 1.59227fF
C_4 in0 gnd 1.01808fF
C_5 out gnd 1.34882fF
C_6 gnd gnd 1.95146fF
Mp_1 net_1 in1 vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.325067P 
+ PS=1.93333U
Mp_2 vdd in0 net_2 vdd p W=1.84U L=0.18U AD=0.650133P PD=3.86667U 
+ AS=0.3588P PS=2.23U
Mp_3 net_2 net_1 out vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.8832P 
+ PS=4.64U
Mn_1 net_1 in1 gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.1564P 
+ PS=1.29333U
Mn_2 gnd in0 out gnd n W=0.46U L=0.18U AD=0.1564P PD=1.29333U AS=0.1242P 
+ PS=1U
Mn_3 out net_1 gnd gnd n W=0.46U L=0.18U AD=0.1242P PD=1U AS=0.1564P 
+ PS=1.29333U
.ENDS	$ MMI_INOR2A

.GLOBAL gnd vdd

