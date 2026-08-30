*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND2A in0 in1 out
C_1 vdd gnd 2.13896fF
C_2 in0 gnd 0.779657fF
C_3 out gnd 0.93181fF
C_4 in1 gnd 0.73529fF
C_5 gnd gnd 1.41473fF
Mp_1 vdd in0 out vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.2484P 
+ PS=1.46U
Mp_2 out in1 vdd vdd p W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.4416P 
+ PS=2.8U
Mn_1 out in0 net_1 gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.1794P 
+ PS=1.31U
Mn_2 net_1 in1 gnd gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.4416P 
+ PS=2.8U
.ENDS	$ MMI_NAND2A

.GLOBAL gnd vdd

