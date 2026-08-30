*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AOI31B in0 in1 in2 in3 out
C_1 net_1 gnd 3.1964fF
C_2 in1 gnd 2.17837fF
C_3 vdd gnd 3.32822fF
C_4 in0 gnd 1.98874fF
C_5 out gnd 2.03967fF
C_6 in2 gnd 1.86904fF
C_7 in3 gnd 1.99031fF
C_8 gnd gnd 3.0404fF
Mp_1 net_1 in1 vdd vdd p W=1.84U L=0.18U AD=0.5934P PD=2.945U AS=0.4968P 
+ PS=2.38U
Mp_2 vdd in1 net_1 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.5934P 
+ PS=2.945U
Mp_3 net_1 in0 out vdd p W=1.84U L=0.18U AD=0.5934P PD=2.945U AS=0.4968P 
+ PS=2.38U
Mp_4 out in0 net_1 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.5934P 
+ PS=2.945U
Mp_5 net_1 in2 vdd vdd p W=1.84U L=0.18U AD=0.5934P PD=2.945U AS=0.4968P 
+ PS=2.38U
Mp_6 vdd in2 net_1 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.5934P 
+ PS=2.945U
Mp_7 net_1 in3 vdd vdd p W=1.84U L=0.18U AD=0.5934P PD=2.945U AS=0.4968P 
+ PS=2.38U
Mp_8 vdd in3 net_1 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.5934P 
+ PS=2.945U
Mn_1 out in0 gnd gnd n W=0.92U L=0.18U AD=0.2967P PD=1.66U AS=0.35535P 
+ PS=2.1525U
Mn_2 gnd in3 net_2 gnd n W=1.38U L=0.18U AD=0.533025P PD=3.22875U 
+ AS=0.2691P PS=1.77U
Mn_3 net_2 in2 net_3 gnd n W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.2691P 
+ PS=1.77U
Mn_4 net_3 in1 out gnd n W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.44505P 
+ PS=2.49U
Mn_5 out in1 net_4 gnd n W=1.38U L=0.18U AD=0.44505P PD=2.49U AS=0.2691P 
+ PS=1.77U
Mn_6 net_4 in2 net_5 gnd n W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.2691P 
+ PS=1.77U
Mn_7 net_5 in3 gnd gnd n W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.533025P 
+ PS=3.22875U
.ENDS	$ MMI_AOI31B

.GLOBAL gnd vdd

