*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_LLCB clk clrb d q
C_1 net_1 gnd 2.33429fF
C_2 clk gnd 2.61499fF
C_3 vdd gnd 5.6249fF
C_4 d gnd 1.00942fF
C_5 net_2 gnd 1.66176fF
C_6 net_3 gnd 2.64582fF
C_7 net_5 gnd 3.09686fF
C_8 net_6 gnd 2.75197fF
C_9 net_8 gnd 1.37273fF
C_10 q gnd 0.97475fF
C_11 clrb gnd 0.747283fF
C_12 gnd gnd 5.3675fF
Mp_1 net_1 clk vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.378099P 
+ PS=2.36768U
Mp_2 vdd d net_2 vdd p W=1.84U L=0.18U AD=0.756198P PD=4.73536U AS=0.4968P 
+ PS=2.38U
Mp_3 net_2 clk net_3 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.75326P 
+ PS=4.72212U
Mp_4 net_3 net_1 net_4 vdd p W=0.42U L=0.18U AD=0.17194P PD=1.07788U 
+ AS=0.0819P PS=0.81U
Mp_5 net_4 net_5 vdd vdd p W=0.42U L=0.18U AD=0.0819P PD=0.81U AS=0.17261P 
+ PS=1.0809U
Mp_6 vdd net_6 net_7 vdd p W=1.84U L=0.18U AD=0.756198P PD=4.73536U 
+ AS=0.23P PS=2.09U
Mp_7 net_7 net_3 net_5 vdd p W=1.84U L=0.18U AD=0.23P PD=2.09U AS=0.8832P 
+ PS=4.64U
Mp_8 net_8 net_5 vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.378099P 
+ PS=2.36768U
Mp_9 vdd net_8 q vdd p W=1.84U L=0.18U AD=0.756198P PD=4.73536U AS=0.8832P 
+ PS=4.64U
Mp_10 net_6 clrb vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.378099P 
+ PS=2.36768U
Mn_1 net_8 net_5 gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.202917P 
+ PS=1.88136U
Mn_2 net_1 clk gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.202917P 
+ PS=1.88136U
Mn_3 gnd d net_2 gnd n W=0.92U L=0.18U AD=0.405834P PD=3.76272U AS=0.2484P 
+ PS=1.46U
Mn_4 net_2 net_1 net_3 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U 
+ AS=0.332024P PS=2.71881U
Mn_5 net_3 clk net_9 gnd n W=0.42U L=0.18U AD=0.151576P PD=1.24119U 
+ AS=0.0819P PS=0.81U
Mn_6 net_9 net_5 gnd gnd n W=0.42U L=0.18U AD=0.0819P PD=0.81U AS=0.185272P 
+ PS=1.71776U
Mn_7 gnd net_6 net_5 gnd n W=0.46U L=0.18U AD=0.202917P PD=1.88136U 
+ AS=0.1242P PS=1U
Mn_8 net_5 net_3 gnd gnd n W=0.46U L=0.18U AD=0.1242P PD=1U AS=0.202917P 
+ PS=1.88136U
Mn_9 gnd net_8 q gnd n W=0.92U L=0.18U AD=0.405834P PD=3.76272U AS=0.4416P 
+ PS=2.8U
Mn_10 net_6 clrb gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.202917P 
+ PS=1.88136U
.ENDS	$ MMI_LLCB

.GLOBAL gnd vdd

