*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND3B in0 in1 in2 out
C_1 out gnd 1.7526fF
C_2 in1 gnd 1.09412fF
C_3 vdd gnd 2.1684fF
C_4 in0 gnd 0.951345fF
C_5 in2 gnd 1.23304fF
C_6 gnd gnd 1.7101fF
Mp_1 out in1 vdd vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.436333P 
+ PS=2.62U
Mp_2 vdd in0 out vdd p W=1.54U L=0.15U AD=0.436333P PD=2.62U AS=0.428633P 
+ PS=2.61U
Mp_3 out in2 vdd vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.436333P 
+ PS=2.62U
Mn_1 out in0 net_1 gnd n W=2.305U L=0.15U AD=0.910475P PD=5.4U AS=0.25355P 
+ PS=2.525U
Mn_2 net_1 in1 net_2 gnd n W=2.305U L=0.15U AD=0.25355P PD=2.525U 
+ AS=0.25355P PS=2.525U
Mn_3 net_2 in2 gnd gnd n W=2.305U L=0.15U AD=0.25355P PD=2.525U 
+ AS=0.910475P PS=5.4U
.ENDS	$ MMI_NAND3B

.GLOBAL gnd vdd

