*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_BUFB in out
C_1 net_1 gnd 1.70487fF
C_2 in gnd 0.87268fF
C_3 vdd gnd 1.4978fF
C_4 out gnd 1.19161fF
C_5 gnd gnd 1.27082fF
Mp_1 net_1 in vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.325067P 
+ PS=1.93333U
Mp_2 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.650133P PD=3.86667U 
+ AS=0.8832P PS=4.64U
Mn_1 net_1 in gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.162533P 
+ PS=1.32U
Mn_2 gnd net_1 out gnd n W=0.92U L=0.18U AD=0.325067P PD=2.64U AS=0.4416P 
+ PS=2.8U
.ENDS	$ MMI_BUFB

.GLOBAL gnd vdd

