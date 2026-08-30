*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_LTCHNB clk d q
C_1 net_1 gnd 2.49967fF
C_2 clk gnd 2.77849fF
C_3 vdd gnd 3.7658fF
C_4 d gnd 1.09117fF
C_5 net_2 gnd 1.74539fF
C_6 net_3 gnd 3.30332fF
C_7 net_5 gnd 1.96543fF
C_8 q gnd 1.10023fF
C_9 gnd gnd 3.47564fF
Mp_1 net_1 clk vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.333306P 
+ PS=2.07542U
Mp_2 vdd d net_2 vdd p W=1.84U L=0.18U AD=0.666613P PD=4.15084U AS=0.4968P 
+ PS=2.38U
Mp_3 net_2 clk net_3 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.75326P 
+ PS=4.72212U
Mp_4 net_3 net_1 net_4 vdd p W=0.42U L=0.18U AD=0.17194P PD=1.07788U 
+ AS=0.0819P PS=0.81U
Mp_5 net_4 net_5 vdd vdd p W=0.42U L=0.18U AD=0.0819P PD=0.81U AS=0.152162P 
+ PS=0.947475U
Mp_6 net_5 net_3 vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.333306P 
+ PS=2.07542U
Mp_7 vdd net_3 q vdd p W=1.84U L=0.18U AD=0.666613P PD=4.15084U AS=0.8832P 
+ PS=4.64U
Mn_1 net_1 clk gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.190177P 
+ PS=1.74308U
Mn_2 gnd d net_2 gnd n W=0.92U L=0.18U AD=0.380353P PD=3.48616U AS=0.2484P 
+ PS=1.46U
Mn_3 net_2 net_1 net_3 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U 
+ AS=0.332024P PS=2.71881U
Mn_4 net_3 clk net_6 gnd n W=0.42U L=0.18U AD=0.151576P PD=1.24119U 
+ AS=0.0819P PS=0.81U
Mn_5 net_6 net_5 gnd gnd n W=0.42U L=0.18U AD=0.0819P PD=0.81U AS=0.17364P 
+ PS=1.59151U
Mn_6 gnd net_3 net_5 gnd n W=0.46U L=0.18U AD=0.190177P PD=1.74308U 
+ AS=0.2208P PS=1.88U
Mn_7 gnd net_3 q gnd n W=0.92U L=0.18U AD=0.380353P PD=3.48616U AS=0.4416P 
+ PS=2.8U
.ENDS	$ MMI_LTCHNB

.GLOBAL gnd vdd

