*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUX2C in0 in1 out sel
C_1 net_1 gnd 2.66441fF
C_2 sel gnd 2.43005fF
C_3 vdd gnd 3.78248fF
C_4 in1 gnd 0.80296fF
C_5 net_2 gnd 1.08196fF
C_6 net_3 gnd 2.54074fF
C_7 net_4 gnd 1.08196fF
C_8 in0 gnd 0.80841fF
C_9 out gnd 1.20581fF
C_10 gnd gnd 3.09686fF
Mp_1 net_1 sel vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.336678P 
+ PS=1.96889U
Mp_2 vdd in1 net_2 vdd p W=1.84U L=0.18U AD=0.673356P PD=3.93778U 
+ AS=0.5336P PS=2.42U
Mp_3 net_2 net_1 net_3 vdd p W=1.84U L=0.18U AD=0.5336P PD=2.42U AS=0.4968P 
+ PS=2.38U
Mp_4 net_3 sel net_4 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_5 net_4 in0 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.673356P 
+ PS=3.93778U
Mp_6 vdd net_3 out vdd p W=1.84U L=0.18U AD=0.673356P PD=3.93778U 
+ AS=0.4968P PS=2.38U
Mp_7 out net_3 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.673356P 
+ PS=3.93778U
Mn_1 net_1 sel gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.163417P 
+ PS=1.08707U
Mn_2 gnd in1 net_2 gnd n W=0.91U L=0.18U AD=0.323281P PD=2.15051U 
+ AS=0.268127P PS=2.31727U
Mn_3 net_2 sel net_3 gnd n W=0.92U L=0.18U AD=0.271073P PD=2.34273U 
+ AS=0.2484P PS=1.46U
Mn_4 net_3 net_1 net_4 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2484P 
+ PS=1.46U
Mn_5 net_4 in0 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.326834P 
+ PS=2.17414U
Mn_6 gnd net_3 out gnd n W=1.84U L=0.18U AD=0.653668P PD=4.34828U 
+ AS=0.8832P PS=4.64U
.ENDS	$ MMI_MUX2C

.GLOBAL gnd vdd

