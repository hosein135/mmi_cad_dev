*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AND2C in0 in1 out
C_1 vdd gnd 2.38904fF
C_2 in0 gnd 0.685355fF
C_3 net_1 gnd 1.77127fF
C_4 in1 gnd 0.688515fF
C_5 out gnd 1.09157fF
C_6 gnd gnd 1.50668fF
Mp_1 vdd in0 net_1 vdd p W=1.04U L=0.15U AD=0.350012P PD=2.34U AS=0.2288P 
+ PS=1.48U
Mp_2 net_1 in1 vdd vdd p W=1.04U L=0.15U AD=0.2288P PD=1.48U AS=0.350012P 
+ PS=2.34U
Mp_3 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.518288P PD=3.465U AS=0.3388P 
+ PS=1.98U
Mp_4 out net_1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.518288P 
+ PS=3.465U
Mn_1 net_1 in0 net_2 gnd n W=1.04U L=0.15U AD=0.4108P PD=2.87U AS=0.1664P 
+ PS=1.36U
Mn_2 net_2 in1 gnd gnd n W=1.04U L=0.15U AD=0.1664P PD=1.36U AS=0.285385P 
+ PS=2.17674U
Mn_3 gnd net_1 out gnd n W=1.54U L=0.15U AD=0.42259P PD=3.22326U AS=0.6083P 
+ PS=3.87U
.ENDS	$ MMI_AND2C

.GLOBAL gnd vdd

