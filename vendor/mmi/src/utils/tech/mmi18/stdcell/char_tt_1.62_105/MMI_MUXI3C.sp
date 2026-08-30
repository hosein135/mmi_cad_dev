*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUXI3C in0 in1 in2 out sel0 sel1
C_1 net_1 gnd 3.09072fF
C_2 sel0 gnd 2.43005fF
C_3 vdd gnd 5.62898fF
C_4 in1 gnd 0.80296fF
C_5 net_2 gnd 1.08196fF
C_6 net_3 gnd 2.28789fF
C_7 net_4 gnd 0.74968fF
C_8 in0 gnd 0.80797fF
C_9 net_5 gnd 1.08196fF
C_10 sel1 gnd 3.74241fF
C_11 net_6 gnd 3.24524fF
C_12 net_7 gnd 3.73595fF
C_13 net_8 gnd 0.74968fF
C_14 net_9 gnd 1.46095fF
C_15 in2 gnd 0.79695fF
C_16 out gnd 1.05899fF
C_17 gnd gnd 6.43615fF
Mp_1 net_1 sel0 vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.328133P 
+ PS=1.936U
Mp_2 vdd in1 net_2 vdd p W=1.84U L=0.18U AD=0.656267P PD=3.872U AS=0.5336P 
+ PS=2.42U
Mp_3 net_2 net_1 net_3 vdd p W=1.84U L=0.18U AD=0.5336P PD=2.42U AS=0.4968P 
+ PS=2.38U
Mp_4 net_3 sel0 net_4 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_5 net_4 in0 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.656267P 
+ PS=3.872U
Mp_6 vdd net_3 net_5 vdd p W=1.84U L=0.18U AD=0.656267P PD=3.872U 
+ AS=0.4968P PS=2.38U
Mp_7 net_5 sel1 net_6 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_8 net_6 net_7 net_8 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.5336P 
+ PS=2.42U
Mp_9 net_8 net_9 vdd vdd p W=1.84U L=0.18U AD=0.5336P PD=2.42U AS=0.656267P 
+ PS=3.872U
Mp_10 vdd in2 net_9 vdd p W=0.92U L=0.18U AD=0.328133P PD=1.936U AS=0.4416P 
+ PS=2.8U
Mp_11 vdd net_6 out vdd p W=1.84U L=0.18U AD=0.656267P PD=3.872U AS=0.4968P 
+ PS=2.38U
Mp_12 out net_6 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.656267P 
+ PS=3.872U
Mp_13 vdd sel1 net_7 vdd p W=0.92U L=0.18U AD=0.328133P PD=1.936U 
+ AS=0.4416P PS=2.8U
Mn_1 net_1 sel0 gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.160431P 
+ PS=1.17712U
Mn_2 gnd in1 net_2 gnd n W=0.91U L=0.18U AD=0.317374P PD=2.32865U 
+ AS=0.268127P PS=2.31727U
Mn_3 net_2 sel0 net_3 gnd n W=0.92U L=0.18U AD=0.271073P PD=2.34273U 
+ AS=0.2484P PS=1.46U
Mn_4 net_3 net_1 net_4 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2484P 
+ PS=1.46U
Mn_5 net_4 in0 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.320862P 
+ PS=2.35424U
Mn_6 gnd net_3 net_5 gnd n W=0.92U L=0.18U AD=0.320862P PD=2.35424U 
+ AS=0.2484P PS=1.46U
Mn_7 net_5 net_7 net_6 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2484P 
+ PS=1.46U
Mn_8 net_6 sel1 net_8 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2701P 
+ PS=2.33U
Mn_9 net_8 net_9 gnd gnd n W=0.92U L=0.18U AD=0.2701P PD=2.33U AS=0.320862P 
+ PS=2.35424U
Mn_10 gnd in2 net_9 gnd n W=0.46U L=0.18U AD=0.160431P PD=1.17712U 
+ AS=0.2208P PS=1.88U
Mn_11 gnd net_6 out gnd n W=0.91U L=0.18U AD=0.317374P PD=2.32865U 
+ AS=0.2457P PS=1.45U
Mn_12 out net_6 gnd gnd n W=0.91U L=0.18U AD=0.2457P PD=1.45U AS=0.317374P 
+ PS=2.32865U
Mn_13 gnd sel1 net_7 gnd n W=0.46U L=0.18U AD=0.160431P PD=1.17712U 
+ AS=0.2208P PS=1.88U
.ENDS	$ MMI_MUXI3C

.GLOBAL gnd vdd

