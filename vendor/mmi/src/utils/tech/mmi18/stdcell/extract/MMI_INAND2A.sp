*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INAND2A in0 in1 out
C_1 vdd gnd 2.1878fF
C_2 net_1 gnd 1.99478fF
C_3 out gnd 1.23779fF
C_4 in0 gnd 0.934625fF
C_5 in1 gnd 0.91465fF
C_6 gnd gnd 1.49867fF
Mp_1 vdd net_1 out vdd p W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.2484P 
+ PS=1.46U
Mp_2 out in0 vdd vdd p W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.3128P 
+ PS=1.90667U
Mp_3 vdd in1 net_1 vdd p W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.4416P 
+ PS=2.8U
Mn_1 out net_1 net_2 gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.1794P 
+ PS=1.31U
Mn_2 net_2 in0 gnd gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.325067P 
+ PS=2.64U
Mn_3 gnd in1 net_1 gnd n W=0.46U L=0.18U AD=0.162533P PD=1.32U AS=0.2208P 
+ PS=1.88U
.ENDS	$ MMI_INAND2A

.GLOBAL gnd vdd

