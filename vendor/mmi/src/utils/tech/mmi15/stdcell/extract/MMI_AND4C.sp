*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AND4C in0 in1 in2 in3 out
C_1 vdd gnd 2.7346fF
C_2 in3 gnd 1.88549fF
C_3 net_1 gnd 2.84403fF
C_4 in2 gnd 1.58346fF
C_5 in1 gnd 1.46892fF
C_6 in0 gnd 1.15658fF
C_7 out gnd 1.34983fF
C_8 gnd gnd 2.345fF
Mp_1 vdd in3 net_1 vdd p W=1.04U L=0.15U AD=0.318924P PD=2.21359U 
+ AS=0.2288P PS=1.48U
Mp_2 net_1 in2 vdd vdd p W=1.04U L=0.15U AD=0.2288P PD=1.48U AS=0.318924P 
+ PS=2.21359U
Mp_3 vdd in1 net_1 vdd p W=1.04U L=0.15U AD=0.318924P PD=2.21359U 
+ AS=0.2288P PS=1.48U
Mp_4 net_1 in0 vdd vdd p W=1.04U L=0.15U AD=0.2288P PD=1.48U AS=0.318924P 
+ PS=2.21359U
Mp_5 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.472252P PD=3.27782U 
+ AS=0.3388P PS=1.98U
Mp_6 out net_1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.472252P 
+ PS=3.27782U
Mn_1 gnd in3 net_2 gnd n W=1.04U L=0.15U AD=0.318177P PD=2.21215U 
+ AS=0.1664P PS=1.36U
Mn_2 net_2 in2 net_3 gnd n W=1.04U L=0.15U AD=0.1664P PD=1.36U AS=0.1664P 
+ PS=1.36U
Mn_3 net_3 in1 net_4 gnd n W=1.04U L=0.15U AD=0.1664P PD=1.36U AS=0.1664P 
+ PS=1.36U
Mn_4 net_4 in0 net_1 gnd n W=1.04U L=0.15U AD=0.1664P PD=1.36U AS=0.2288P 
+ PS=1.48U
Mn_5 net_1 in0 net_5 gnd n W=1.04U L=0.15U AD=0.2288P PD=1.48U AS=0.1664P 
+ PS=1.36U
Mn_6 net_5 in1 net_6 gnd n W=1.04U L=0.15U AD=0.1664P PD=1.36U AS=0.1664P 
+ PS=1.36U
Mn_7 net_6 in2 net_7 gnd n W=1.04U L=0.15U AD=0.1664P PD=1.36U AS=0.1664P 
+ PS=1.36U
Mn_8 net_7 in3 gnd gnd n W=1.04U L=0.15U AD=0.1664P PD=1.36U AS=0.318177P 
+ PS=2.21215U
Mn_9 gnd net_1 out gnd n W=1.54U L=0.15U AD=0.471146P PD=3.27569U 
+ AS=0.6083P PS=3.87U
.ENDS	$ MMI_AND4C

.GLOBAL gnd vdd

