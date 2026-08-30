*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND4B in0 in1 in2 in3 out
C_1 vdd gnd 3.614fF
C_2 in1 gnd 1.16197fF
C_3 out gnd 2.93591fF
C_4 in0 gnd 1.03771fF
C_5 in2 gnd 1.29059fF
C_6 in3 gnd 1.43665fF
C_7 gnd gnd 2.3568fF
Mp_1 vdd in1 out vdd p W=1.84U L=0.18U AD=0.8448P PD=4.96U AS=0.4968P 
+ PS=2.38U
Mp_2 out in0 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.8448P 
+ PS=4.96U
Mp_3 vdd in2 out vdd p W=1.84U L=0.18U AD=0.8448P PD=4.96U AS=0.4968P 
+ PS=2.38U
Mp_4 out in3 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.8448P 
+ PS=4.96U
Mn_1 out in0 net_1 gnd n W=3.68U L=0.18U AD=1.7664P PD=8.32U AS=0.46P 
+ PS=3.93U
Mn_2 net_1 in1 net_2 gnd n W=3.68U L=0.18U AD=0.46P PD=3.93U AS=0.46P 
+ PS=3.93U
Mn_3 net_2 in2 net_3 gnd n W=3.68U L=0.18U AD=0.46P PD=3.93U AS=0.46P 
+ PS=3.93U
Mn_4 net_3 in3 gnd gnd n W=3.68U L=0.18U AD=0.46P PD=3.93U AS=1.7664P 
+ PS=8.32U
.ENDS	$ MMI_NAND4B

.GLOBAL gnd vdd

