*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND3A in0 in1 in2 out
C_1 out gnd 1.28612fF
C_2 in0 gnd 0.740485fF
C_3 vdd gnd 1.39216fF
C_4 in1 gnd 0.79533fF
C_5 in2 gnd 0.854545fF
C_6 gnd gnd 1.38874fF
Mp_1 out in0 vdd vdd p W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.214317P PS=1.58333U
Mp_2 vdd in1 out vdd p W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.214317P PS=1.58333U
Mp_3 out in2 vdd vdd p W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.214317P PS=1.58333U
Mn_1 out in0 net_1 gnd n W=1.155U L=0.15U AD=0.456225P PD=3.1U AS=0.1848P 
+ PS=1.475U
Mn_2 net_1 in1 net_2 gnd n W=1.155U L=0.15U AD=0.1848P PD=1.475U AS=0.1848P 
+ PS=1.475U
Mn_3 net_2 in2 gnd gnd n W=1.155U L=0.15U AD=0.1848P PD=1.475U AS=0.456225P 
+ PS=3.1U
.ENDS	$ MMI_NAND3A

.GLOBAL gnd vdd

