*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND2A in0 in1 out
C_1 vdd gnd 1.73364fF
C_2 in0 gnd 0.64714fF
C_3 out gnd 0.766405fF
C_4 in1 gnd 0.611235fF
C_5 gnd gnd 1.14312fF
Mp_1 vdd in0 out vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.1694P 
+ PS=1.21U
Mp_2 out in1 vdd vdd p W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.30415P 
+ PS=2.33U
Mn_1 out in0 net_1 gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.1232P 
+ PS=1.09U
Mn_2 net_1 in1 gnd gnd n W=0.77U L=0.15U AD=0.1232P PD=1.09U AS=0.30415P 
+ PS=2.33U
.ENDS	$ MMI_NAND2A

.GLOBAL gnd vdd

