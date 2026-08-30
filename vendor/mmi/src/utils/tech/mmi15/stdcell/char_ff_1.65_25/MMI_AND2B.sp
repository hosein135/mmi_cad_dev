*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AND2B in0 in1 out
C_1 vdd gnd 1.80028fF
C_2 in0 gnd 0.83713fF
C_3 net_1 gnd 1.85883fF
C_4 in1 gnd 0.866265fF
C_5 out gnd 1.14062fF
C_6 gnd gnd 1.12996fF
Mp_1 vdd in0 net_1 vdd p W=0.77U L=0.15U AD=0.248325P PD=1.8U AS=0.1694P 
+ PS=1.21U
Mp_2 net_1 in1 vdd vdd p W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.248325P 
+ PS=1.8U
Mp_3 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.49665P PD=3.6U AS=0.6083P 
+ PS=3.87U
Mn_1 net_1 in0 net_2 gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.1232P 
+ PS=1.09U
Mn_2 net_2 in1 gnd gnd n W=0.77U L=0.15U AD=0.1232P PD=1.09U AS=0.1694P 
+ PS=1.21U
Mn_3 gnd net_1 out gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.30415P 
+ PS=2.33U
.ENDS	$ MMI_AND2B

.GLOBAL gnd vdd

