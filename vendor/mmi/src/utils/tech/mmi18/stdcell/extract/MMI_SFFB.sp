*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_SFFB clk d q s_en s_in s_out
C_1 net_1 gnd 2.885fF
C_2 s_en gnd 6.78508fF
C_3 vdd gnd 8.65155fF
C_4 d gnd 1.12842fF
C_5 net_3 gnd 2.92294fF
C_6 s_in gnd 1.19031fF
C_7 clk gnd 4.09363fF
C_8 net_5 gnd 4.16127fF
C_9 net_6 gnd 6.75288fF
C_10 net_7 gnd 2.4892fF
C_11 net_8 gnd 3.26177fF
C_12 net_10 gnd 4.82112fF
C_13 s_out gnd 1.28343fF
C_14 q gnd 1.52524fF
C_15 gnd gnd 6.79016fF
Mp_1 net_1 s_en vdd vdd p W=1.2U L=0.18U AD=0.576P PD=3.36U AS=0.474758P 
+ PS=3.07581U
Mp_2 vdd s_en net_2 vdd p W=1.84U L=0.18U AD=0.727962P PD=4.71625U 
+ AS=0.3588P PS=2.23U
Mp_3 net_2 d net_3 vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.7084P 
+ PS=4.78U
Mp_4 net_3 net_1 net_4 vdd p W=0.92U L=0.18U AD=0.3542P PD=2.39U AS=0.1794P 
+ PS=1.31U
Mp_5 net_4 s_in vdd vdd p W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.363981P 
+ PS=2.35812U
Mp_6 net_3 clk net_5 vdd p W=0.92U L=0.18U AD=0.3542P PD=2.39U AS=0.4416P 
+ PS=3.15821U
Mp_7 net_6 clk vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.363981P 
+ PS=2.35812U
Mp_8 vdd net_5 net_7 vdd p W=0.92U L=0.18U AD=0.363981P PD=2.35812U 
+ AS=0.35605P PS=2.93U
Mp_9 net_7 net_6 net_8 vdd p W=0.92U L=0.18U AD=0.35605P PD=2.93U 
+ AS=0.332024P PS=2.71881U
Mp_10 net_8 clk net_9 vdd p W=0.42U L=0.18U AD=0.151576P PD=1.24119U 
+ AS=0.0819P PS=0.81U
Mp_11 net_9 net_10 vdd vdd p W=0.42U L=0.18U AD=0.0819P PD=0.81U 
+ AS=0.166165P PS=1.07653U
Mp_12 vdd net_8 net_10 vdd p W=0.92U L=0.18U AD=0.363981P PD=2.35812U 
+ AS=0.4416P PS=2.8U
Mp_13 vdd net_10 s_out vdd p W=0.84U L=0.18U AD=0.332331P PD=2.15307U 
+ AS=0.2268P PS=1.38U
Mp_14 s_out s_en vdd vdd p W=0.84U L=0.18U AD=0.2268P PD=1.38U AS=0.332331P 
+ PS=2.15307U
Mp_15 vdd net_10 q vdd p W=1.84U L=0.18U AD=0.727962P PD=4.71625U 
+ AS=0.8832P PS=4.64U
Mp_16 vdd net_7 net_11 vdd p W=0.42U L=0.18U AD=0.166165P PD=1.07653U 
+ AS=0.0819P PS=0.81U
Mp_17 net_11 net_6 net_5 vdd p W=0.42U L=0.18U AD=0.0819P PD=0.81U 
+ AS=0.2016P PS=1.44179U
Mn_1 gnd s_en net_1 gnd n W=0.6U L=0.18U AD=0.223196P PD=1.83333U AS=0.288P 
+ PS=2.16U
Mn_2 gnd net_1 net_12 gnd n W=0.92U L=0.18U AD=0.342234P PD=2.81111U 
+ AS=0.1794P PS=1.31U
Mn_3 net_12 d net_3 gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.352258P 
+ PS=2.944U
Mn_4 net_3 s_en net_13 gnd n W=0.46U L=0.18U AD=0.176129P PD=1.472U 
+ AS=0.0897P PS=0.85U
Mn_5 net_13 s_in gnd gnd n W=0.46U L=0.18U AD=0.0897P PD=0.85U AS=0.171117P 
+ PS=1.40556U
Mn_6 gnd clk net_6 gnd n W=0.46U L=0.18U AD=0.171117P PD=1.40556U 
+ AS=0.2208P PS=1.88U
Mn_7 net_3 net_6 net_5 gnd n W=0.42U L=0.18U AD=0.160813P PD=1.344U 
+ AS=0.1134P PS=0.96U
Mn_8 net_5 clk net_14 gnd n W=0.42U L=0.18U AD=0.1134P PD=0.96U AS=0.0819P 
+ PS=0.81U
Mn_9 net_14 net_7 gnd gnd n W=0.42U L=0.18U AD=0.0819P PD=0.81U 
+ AS=0.156237P PS=1.28333U
Mn_10 gnd net_5 net_7 gnd n W=0.46U L=0.18U AD=0.171117P PD=1.40556U 
+ AS=0.137373P PS=1.58909U
Mn_11 net_7 clk net_8 gnd n W=0.42U L=0.18U AD=0.125427P PD=1.45091U 
+ AS=0.2016P PS=1.8U
Mn_12 gnd net_10 net_15 gnd n W=0.42U L=0.18U AD=0.156237P PD=1.28333U 
+ AS=0.0819P PS=0.81U
Mn_13 net_15 net_6 net_8 gnd n W=0.42U L=0.18U AD=0.0819P PD=0.81U 
+ AS=0.2016P PS=1.8U
Mn_14 net_10 net_8 gnd gnd n W=0.62U L=0.18U AD=0.2976P PD=2.2U 
+ AS=0.230636P PS=1.89444U
Mn_15 s_out net_10 net_16 gnd n W=0.84U L=0.18U AD=0.4032P PD=2.64U 
+ AS=0.1638P PS=1.23U
Mn_16 net_16 s_en gnd gnd n W=0.84U L=0.18U AD=0.1638P PD=1.23U 
+ AS=0.312475P PS=2.56667U
Mn_17 gnd net_10 q gnd n W=0.92U L=0.18U AD=0.342234P PD=2.81111U 
+ AS=0.4416P PS=2.8U
.ENDS	$ MMI_SFFB

.GLOBAL gnd vdd

