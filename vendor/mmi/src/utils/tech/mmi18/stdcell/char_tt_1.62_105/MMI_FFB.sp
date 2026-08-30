*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_FFB clk d q
C_1 net_1 gnd 2.24768fF
C_2 d gnd 0.89242fF
C_3 vdd gnd 5.24122fF
C_4 clk gnd 5.03936fF
C_5 net_2 gnd 5.24972fF
C_6 net_3 gnd 2.04575fF
C_7 net_5 gnd 2.39222fF
C_8 net_6 gnd 2.42894fF
C_9 net_8 gnd 2.82906fF
C_10 q gnd 0.98177fF
C_11 gnd gnd 4.74111fF
Mp_1 net_1 d vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.327352P 
+ PS=2.19006U
Mp_2 vdd clk net_2 vdd p W=0.92U L=0.18U AD=0.327352P PD=2.19006U 
+ AS=0.4416P PS=2.8U
Mp_3 net_1 clk net_3 vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.332779P 
+ PS=3.16507U
Mp_4 net_3 net_2 net_4 vdd p W=0.42U L=0.18U AD=0.151921P PD=1.44493U 
+ AS=0.0819P PS=0.81U
Mp_5 net_4 net_5 vdd vdd p W=0.42U L=0.18U AD=0.0819P PD=0.81U AS=0.149443P 
+ PS=0.999811U
Mp_6 vdd net_3 net_5 vdd p W=0.92U L=0.18U AD=0.327352P PD=2.19006U 
+ AS=0.2484P PS=1.46U
Mp_7 net_5 net_2 net_6 vdd p W=0.92U L=0.18U AD=0.2484P PD=1.46U 
+ AS=0.334907P PS=2.73254U
Mp_8 net_6 clk net_7 vdd p W=0.42U L=0.18U AD=0.152893P PD=1.24746U 
+ AS=0.0819P PS=0.81U
Mp_9 net_7 net_8 vdd vdd p W=0.42U L=0.18U AD=0.0819P PD=0.81U AS=0.149443P 
+ PS=0.999811U
Mp_10 vdd net_6 net_8 vdd p W=0.92U L=0.18U AD=0.327352P PD=2.19006U 
+ AS=0.4416P PS=2.8U
Mp_11 vdd net_8 q vdd p W=1.84U L=0.18U AD=0.654704P PD=4.38013U AS=0.8832P 
+ PS=4.64U
Mn_1 net_6 net_2 net_9 gnd n W=0.42U L=0.18U AD=0.2016P PD=1.8U AS=0.0819P 
+ PS=0.81U
Mn_2 net_9 net_8 gnd gnd n W=0.42U L=0.18U AD=0.0819P PD=0.81U AS=0.150932P 
+ PS=1.28234U
Mn_3 net_1 d gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.92364U AS=0.165306P 
+ PS=1.40447U
Mn_4 gnd clk net_2 gnd n W=0.46U L=0.18U AD=0.165306P PD=1.40447U 
+ AS=0.2208P PS=1.88U
Mn_5 net_1 net_2 net_3 gnd n W=0.42U L=0.18U AD=0.2016P PD=1.75636U 
+ AS=0.1134P PS=0.96U
Mn_6 net_3 clk net_10 gnd n W=0.42U L=0.18U AD=0.1134P PD=0.96U AS=0.0819P 
+ PS=0.81U
Mn_7 net_10 net_5 gnd gnd n W=0.42U L=0.18U AD=0.0819P PD=0.81U 
+ AS=0.150932P PS=1.28234U
Mn_8 gnd net_3 net_5 gnd n W=0.46U L=0.18U AD=0.165306P PD=1.40447U 
+ AS=0.137373P PS=1.58909U
Mn_9 net_5 clk net_6 gnd n W=0.42U L=0.18U AD=0.125427P PD=1.45091U 
+ AS=0.2016P PS=1.8U
Mn_10 gnd net_8 q gnd n W=0.92U L=0.18U AD=0.330613P PD=2.80894U AS=0.4416P 
+ PS=2.8U
Mn_11 gnd net_6 net_8 gnd n W=0.62U L=0.18U AD=0.222804P PD=1.89298U 
+ AS=0.2976P PS=2.2U
.ENDS	$ MMI_FFB

.GLOBAL gnd vdd

