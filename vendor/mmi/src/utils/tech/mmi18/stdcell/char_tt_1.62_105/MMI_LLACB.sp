*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_LLACB clk clrb d q
C_1 net_1 gnd 2.4165fF
C_2 clk gnd 2.96928fF
C_3 vdd gnd 5.61554fF
C_4 d gnd 1.3305fF
C_5 net_2 gnd 1.54626fF
C_6 net_3 gnd 2.48229fF
C_7 net_5 gnd 3.10975fF
C_8 net_6 gnd 2.73551fF
C_9 net_8 gnd 1.36512fF
C_10 q gnd 0.970442fF
C_11 clrb gnd 0.735293fF
C_12 gnd gnd 5.38622fF
Mp_1 net_1 clk vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.379918P 
+ PS=2.37508U
Mp_2 vdd d net_2 vdd p W=1.84U L=0.18U AD=0.759835P PD=4.75016U AS=0.4968P 
+ PS=2.38U
Mp_3 net_2 net_1 net_3 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U 
+ AS=0.75326P PS=4.72212U
Mp_4 net_3 clk net_4 vdd p W=0.42U L=0.18U AD=0.17194P PD=1.07788U 
+ AS=0.0819P PS=0.81U
Mp_5 net_4 net_5 vdd vdd p W=0.42U L=0.18U AD=0.0819P PD=0.81U AS=0.173441P 
+ PS=1.08428U
Mp_6 vdd net_6 net_7 vdd p W=1.84U L=0.18U AD=0.759835P PD=4.75016U 
+ AS=0.23P PS=2.09U
Mp_7 net_7 net_3 net_5 vdd p W=1.84U L=0.18U AD=0.23P PD=2.09U AS=0.8832P 
+ PS=4.64U
Mp_8 net_8 net_5 vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.379918P 
+ PS=2.37508U
Mp_9 vdd net_8 q vdd p W=1.84U L=0.18U AD=0.759835P PD=4.75016U AS=0.8832P 
+ PS=4.64U
Mp_10 net_6 clrb vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.379918P 
+ PS=2.37508U
Mn_1 net_8 net_5 gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.209146P 
+ PS=1.91969U
Mn_2 net_1 clk gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.209146P 
+ PS=1.91969U
Mn_3 gnd d net_2 gnd n W=0.92U L=0.18U AD=0.418292P PD=3.83939U AS=0.2484P 
+ PS=1.46U
Mn_4 net_2 clk net_3 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.332024P 
+ PS=2.71881U
Mn_5 net_3 net_1 net_9 gnd n W=0.42U L=0.18U AD=0.151576P PD=1.24119U 
+ AS=0.0819P PS=0.81U
Mn_6 net_9 net_5 gnd gnd n W=0.42U L=0.18U AD=0.0819P PD=0.81U AS=0.19096P 
+ PS=1.75276U
Mn_7 gnd net_6 net_5 gnd n W=0.46U L=0.18U AD=0.209146P PD=1.91969U 
+ AS=0.1242P PS=1U
Mn_8 net_5 net_3 gnd gnd n W=0.46U L=0.18U AD=0.1242P PD=1U AS=0.209146P 
+ PS=1.91969U
Mn_9 gnd net_8 q gnd n W=0.92U L=0.18U AD=0.418292P PD=3.83939U AS=0.4416P 
+ PS=2.8U
Mn_10 net_6 clrb gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.209146P 
+ PS=1.91969U
.ENDS	$ MMI_LLACB

.GLOBAL gnd vdd

