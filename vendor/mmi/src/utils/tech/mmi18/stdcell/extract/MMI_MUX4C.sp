*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUX4C in0 in1 in2 in3 out sel0 sel1
C_1 net_1 gnd 2.6899fF
C_2 in1 gnd 0.89198fF
C_3 vdd gnd 6.18734fF
C_4 in0 gnd 0.90978fF
C_5 net_2 gnd 0.7308fF
C_6 sel0 gnd 2.92851fF
C_7 net_3 gnd 3.16457fF
C_8 net_4 gnd 4.45367fF
C_9 in2 gnd 0.81468fF
C_10 net_5 gnd 0.7586fF
C_11 net_6 gnd 3.17118fF
C_12 net_7 gnd 0.7586fF
C_13 in3 gnd 0.76868fF
C_14 sel1 gnd 2.29473fF
C_15 net_8 gnd 3.2421fF
C_16 net_9 gnd 1.77634fF
C_17 out gnd 1.11515fF
C_18 gnd gnd 6.57437fF
Mp_1 net_1 in1 vdd vdd p W=1.84U L=0.18U AD=0.7696P PD=5.28U AS=0.661062P 
+ PS=3.57406U
Mp_2 vdd in0 net_2 vdd p W=1.84U L=0.18U AD=0.661062P PD=3.57406U 
+ AS=0.50655P PS=3.215U
Mp_3 net_2 sel0 net_3 vdd p W=1.84U L=0.18U AD=0.50655P PD=3.215U 
+ AS=0.6256P PS=3.13333U
Mp_4 net_3 net_4 net_1 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U 
+ AS=0.7696P PS=5.28U
Mp_5 net_4 sel0 vdd vdd p W=1.24U L=0.18U AD=0.464P PD=4.72U AS=0.445498P 
+ PS=2.40861U
Mp_6 vdd in2 net_5 vdd p W=1.84U L=0.18U AD=0.661062P PD=3.57406U 
+ AS=0.4968P PS=2.38U
Mp_7 net_5 sel0 net_6 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mp_8 net_6 net_4 net_7 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U 
+ AS=0.4968P PS=2.38U
Mp_9 net_7 in3 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.661062P 
+ PS=3.57406U
Mp_10 net_3 sel1 net_8 vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U 
+ AS=0.4968P PS=2.38U
Mp_11 net_8 net_9 net_6 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U 
+ AS=0.6256P PS=3.13333U
Mp_12 net_9 sel1 vdd vdd p W=0.92U L=0.18U AD=0.3616P PD=4.08U AS=0.330531P 
+ PS=1.78703U
Mp_13 vdd net_8 out vdd p W=1.84U L=0.18U AD=0.661062P PD=3.57406U 
+ AS=0.4968P PS=2.38U
Mp_14 out net_8 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.661062P 
+ PS=3.57406U
Mn_1 net_1 in1 gnd gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.371819P 
+ PS=2.57879U
Mn_2 gnd in0 net_2 gnd n W=0.92U L=0.18U AD=0.371819P PD=2.57879U 
+ AS=0.2484P PS=1.46U
Mn_3 net_2 net_4 net_3 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.3128P 
+ PS=1.90667U
Mn_4 net_3 sel0 net_1 gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U 
+ AS=0.4416P PS=2.8U
Mn_5 net_4 sel0 gnd gnd n W=0.62U L=0.18U AD=0.2976P PD=2.2U AS=0.250574P 
+ PS=1.73788U
Mn_6 gnd in2 net_5 gnd n W=0.92U L=0.18U AD=0.371819P PD=2.57879U 
+ AS=0.2484P PS=1.46U
Mn_7 net_5 net_4 net_6 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.3128P 
+ PS=1.90667U
Mn_8 net_6 sel0 net_7 gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U 
+ AS=0.2484P PS=1.46U
Mn_9 net_7 in3 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.371819P 
+ PS=2.57879U
Mn_10 net_3 net_9 net_8 gnd n W=0.92U L=0.18U AD=0.3128P PD=1.90667U 
+ AS=0.2484P PS=1.46U
Mn_11 net_8 sel1 net_6 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.3128P 
+ PS=1.90667U
Mn_12 net_9 sel1 gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.18591P 
+ PS=1.28939U
Mn_13 gnd net_8 out gnd n W=0.92U L=0.18U AD=0.371819P PD=2.57879U 
+ AS=0.2484P PS=1.46U
Mn_14 out net_8 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.371819P 
+ PS=2.57879U
.ENDS	$ MMI_MUX4C

.GLOBAL gnd vdd

