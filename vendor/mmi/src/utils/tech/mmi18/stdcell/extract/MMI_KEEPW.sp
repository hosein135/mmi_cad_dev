*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_KEEPW in
C_1 in gnd 2.41178fF
C_2 net_1 gnd 1.97958fF
C_3 vdd gnd 1.46374fF
C_4 gnd gnd 1.38346fF
Mp_1 in net_1 vdd vdd p W=0.42U L=0.18U AD=0.2016P PD=1.8U AS=0.1134P 
+ PS=0.96U
Mp_2 vdd in net_1 vdd p W=0.42U L=0.18U AD=0.1134P PD=0.96U AS=0.2016P 
+ PS=1.8U
Mn_1 net_1 in gnd gnd n W=0.42U L=0.36U AD=0.2016P PD=1.8U AS=0.1134P 
+ PS=0.96U
Mn_2 gnd net_1 in gnd n W=0.42U L=0.36U AD=0.1134P PD=0.96U AS=0.2016P 
+ PS=1.8U
.ENDS	$ MMI_KEEPW

.GLOBAL gnd vdd

