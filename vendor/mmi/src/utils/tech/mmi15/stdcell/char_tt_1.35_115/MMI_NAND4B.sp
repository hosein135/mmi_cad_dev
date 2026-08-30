*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND4B in0 in1 in2 in3 out
C_1 vdd gnd 2.89676fF
C_2 in1 gnd 0.979815fF
C_3 out gnd 2.4094fF
C_4 in0 gnd 0.87124fF
C_5 in2 gnd 1.09976fF
C_6 in3 gnd 1.21103fF
C_7 gnd gnd 1.83993fF
Mp_1 vdd in1 out vdd p W=1.54U L=0.15U AD=0.5855P PD=4.145U AS=0.35035P 
+ PS=1.995U
Mp_2 out in0 vdd vdd p W=1.54U L=0.15U AD=0.35035P PD=1.995U AS=0.5855P 
+ PS=4.145U
Mp_3 vdd in2 out vdd p W=1.54U L=0.15U AD=0.5855P PD=4.145U AS=0.35035P 
+ PS=1.995U
Mp_4 out in3 vdd vdd p W=1.54U L=0.15U AD=0.35035P PD=1.995U AS=0.5855P 
+ PS=4.145U
Mn_1 out in0 net_1 gnd n W=3.085U L=0.15U AD=1.21857P PD=6.96U AS=0.33935P 
+ PS=3.305U
Mn_2 net_1 in1 net_2 gnd n W=3.085U L=0.15U AD=0.33935P PD=3.305U 
+ AS=0.33935P PS=3.305U
Mn_3 net_2 in2 net_3 gnd n W=3.085U L=0.15U AD=0.33935P PD=3.305U 
+ AS=0.33935P PS=3.305U
Mn_4 net_3 in3 gnd gnd n W=3.085U L=0.15U AD=0.33935P PD=3.305U AS=1.21857P 
+ PS=6.96U
.ENDS	$ MMI_NAND4B

.GLOBAL gnd vdd

