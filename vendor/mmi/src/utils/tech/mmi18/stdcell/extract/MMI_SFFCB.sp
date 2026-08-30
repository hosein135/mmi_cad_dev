*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_SFFCB clk clrb d q s_en s_in s_out
C_1 net_1 gnd 2.56288fF
C_2 s_en gnd 5.88644fF
C_3 vdd gnd 9.24041fF
C_4 d gnd 0.98212fF
C_5 net_3 gnd 2.64085fF
C_6 s_in gnd 1.1792fF
C_7 clk gnd 5.76531fF
C_8 net_5 gnd 4.77606fF
C_9 net_6 gnd 3.01659fF
C_10 clrb gnd 4.59234fF
C_11 net_7 gnd 4.66596fF
C_12 net_9 gnd 4.40623fF
C_13 net_11 gnd 2.11522fF
C_14 net_13 gnd 4.78376fF
C_15 s_out gnd 1.30323fF
C_16 q gnd 1.47599fF
C_17 gnd gnd 8.11019fF
Mp_1 net_1 s_en vdd vdd p W=1.2U L=0.18U AD=0.576P PD=3.36U AS=0.43981P 
+ PS=2.88357U
Mp_2 vdd s_en net_2 vdd p W=1.84U L=0.18U AD=0.674376P PD=4.42147U 
+ AS=0.3588P PS=2.23U
Mp_3 net_2 d net_3 vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.7084P 
+ PS=4.3U
Mp_4 net_3 net_1 net_4 vdd p W=0.92U L=0.18U AD=0.3542P PD=2.15U AS=0.1794P 
+ PS=1.31U
Mp_5 net_4 s_in vdd vdd p W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.337188P 
+ PS=2.21074U
Mp_6 net_3 clk net_5 vdd p W=0.92U L=0.18U AD=0.3542P PD=2.15U AS=0.4416P 
+ PS=3.15821U
Mp_7 net_6 clrb vdd vdd p W=1.2U L=0.18U AD=0.576P PD=3.36U AS=0.43981P 
+ PS=2.88357U
Mp_8 vdd clk net_7 vdd p W=0.92U L=0.18U AD=0.337188P PD=2.21074U 
+ AS=0.4416P PS=2.8U
Mp_9 vdd net_6 net_8 vdd p W=1.84U L=0.18U AD=0.674376P PD=4.42147U 
+ AS=0.3588P PS=2.23U
Mp_10 net_8 net_5 net_9 vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U 
+ AS=0.8832P PS=4.96U
Mp_11 net_5 net_7 net_10 vdd p W=0.42U L=0.18U AD=0.2016P PD=1.44179U 
+ AS=0.0819P PS=0.81U
Mp_12 net_10 net_9 vdd vdd p W=0.42U L=0.18U AD=0.0819P PD=0.81U 
+ AS=0.153934P PS=1.00925U
Mp_13 net_9 net_7 net_11 vdd p W=0.92U L=0.18U AD=0.4416P PD=2.48U 
+ AS=0.333466P PS=2.72567U
Mp_14 net_11 clk net_12 vdd p W=0.42U L=0.18U AD=0.152234P PD=1.24433U 
+ AS=0.0819P PS=0.81U
Mp_15 net_12 net_13 vdd vdd p W=0.42U L=0.18U AD=0.0819P PD=0.81U 
+ AS=0.153934P PS=1.00925U
Mp_16 vdd clrb net_13 vdd p W=0.92U L=0.18U AD=0.337188P PD=2.21074U 
+ AS=0.2484P PS=1.46U
Mp_17 net_13 net_11 vdd vdd p W=0.92U L=0.18U AD=0.2484P PD=1.46U 
+ AS=0.337188P PS=2.21074U
Mp_18 vdd net_13 s_out vdd p W=0.84U L=0.18U AD=0.307867P PD=2.0185U 
+ AS=0.2268P PS=1.38U
Mp_19 s_out s_en vdd vdd p W=0.84U L=0.18U AD=0.2268P PD=1.38U AS=0.307867P 
+ PS=2.0185U
Mp_20 vdd net_13 q vdd p W=1.84U L=0.18U AD=0.674376P PD=4.42147U 
+ AS=0.8832P PS=4.64U
Mn_1 net_3 net_7 net_5 gnd n W=0.42U L=0.18U AD=0.160813P PD=1.344U 
+ AS=0.2016P PS=1.8U
Mn_2 net_1 s_en gnd gnd n W=0.6U L=0.18U AD=0.288P PD=2.16U AS=0.210592P 
+ PS=1.86692U
Mn_3 gnd net_1 net_14 gnd n W=0.92U L=0.18U AD=0.322908P PD=2.86262U 
+ AS=0.1794P PS=1.31U
Mn_4 net_14 d net_3 gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.352258P 
+ PS=2.944U
Mn_5 net_7 clk gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.161454P 
+ PS=1.43131U
Mn_6 net_9 net_6 gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.90866U 
+ AS=0.161454P PS=1.43131U
Mn_7 net_9 clk net_11 gnd n W=0.42U L=0.18U AD=0.2016P PD=1.74269U 
+ AS=0.1134P PS=0.96U
Mn_8 net_11 net_7 net_15 gnd n W=0.42U L=0.18U AD=0.1134P PD=0.96U 
+ AS=0.08085P PS=0.805U
Mn_9 net_15 net_13 gnd gnd n W=0.42U L=0.18U AD=0.08085P PD=0.805U 
+ AS=0.147415P PS=1.30685U
Mn_10 net_3 s_en net_16 gnd n W=0.46U L=0.18U AD=0.176129P PD=1.472U 
+ AS=0.0897P PS=0.85U
Mn_11 net_16 s_in gnd gnd n W=0.46U L=0.18U AD=0.0897P PD=0.85U 
+ AS=0.161454P PS=1.43131U
Mn_12 gnd clrb net_6 gnd n W=0.6U L=0.18U AD=0.210592P PD=1.86692U 
+ AS=0.288P PS=2.16U
Mn_13 gnd net_5 net_9 gnd n W=0.46U L=0.18U AD=0.161454P PD=1.43131U 
+ AS=0.2208P PS=1.90866U
Mn_14 net_5 clk net_17 gnd n W=0.42U L=0.18U AD=0.2016P PD=1.8U AS=0.0819P 
+ PS=0.81U
Mn_15 net_17 net_9 gnd gnd n W=0.42U L=0.18U AD=0.0819P PD=0.81U 
+ AS=0.147415P PS=1.30685U
Mn_16 gnd clrb net_18 gnd n W=1.24U L=0.18U AD=0.435224P PD=3.85831U 
+ AS=0.2418P PS=1.63U
Mn_17 net_18 net_11 net_13 gnd n W=1.24U L=0.18U AD=0.2418P PD=1.63U 
+ AS=0.5952P PS=3.44U
Mn_18 s_out net_13 net_19 gnd n W=0.84U L=0.18U AD=0.4032P PD=2.64U 
+ AS=0.1638P PS=1.23U
Mn_19 net_19 s_en gnd gnd n W=0.84U L=0.18U AD=0.1638P PD=1.23U 
+ AS=0.294829P PS=2.61369U
Mn_20 gnd net_13 q gnd n W=0.92U L=0.18U AD=0.322908P PD=2.86262U 
+ AS=0.4416P PS=2.8U
.ENDS	$ MMI_SFFCB

.GLOBAL gnd vdd

