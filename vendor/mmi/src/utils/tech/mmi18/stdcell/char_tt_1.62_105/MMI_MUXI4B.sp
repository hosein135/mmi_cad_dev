*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUXI4B in0 in1 in2 in3 out sel0 sel1
C_1 vdd gnd 7.47233fF
C_2 in0 gnd 0.92678fF
C_3 net_1 gnd 1.2113fF
C_4 sel0 gnd 4.12059fF
C_5 net_2 gnd 4.15596fF
C_6 net_3 gnd 4.22387fF
C_7 net_4 gnd 1.10686fF
C_8 in1 gnd 1.18781fF
C_9 in2 gnd 1.63461fF
C_10 net_5 gnd 1.48185fF
C_11 net_6 gnd 3.14202fF
C_12 net_7 gnd 1.39959fF
C_13 in3 gnd 1.43473fF
C_14 net_8 gnd 1.44911fF
C_15 sel1 gnd 2.81353fF
C_16 net_9 gnd 3.02658fF
C_17 net_10 gnd 2.86308fF
C_18 net_11 gnd 1.10762fF
C_19 out gnd 1.33656fF
C_20 gnd gnd 6.10661fF
Mp_1 vdd in0 net_1 vdd p W=1.84U L=0.18U AD=0.716518P PD=3.50118U 
+ AS=0.4968P PS=2.38U
Mp_2 net_1 sel0 net_2 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_3 net_2 net_3 net_4 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.4968P 
+ PS=2.38U
Mp_4 net_4 in1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.716518P 
+ PS=3.50118U
Mp_5 vdd sel0 net_3 vdd p W=1.84U L=0.18U AD=0.716518P PD=3.50118U 
+ AS=0.8832P PS=4.64U
Mp_6 vdd in2 net_5 vdd p W=1.84U L=0.18U AD=0.716518P PD=3.50118U 
+ AS=0.5043P PS=3.17U
Mp_7 net_5 sel0 net_6 vdd p W=1.84U L=0.18U AD=0.5043P PD=3.17U AS=0.4968P 
+ PS=2.38U
Mp_8 net_6 net_3 net_7 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.5566P 
+ PS=2.445U
Mp_9 net_7 in3 vdd vdd p W=1.84U L=0.18U AD=0.5566P PD=2.445U AS=0.716518P 
+ PS=3.50118U
Mp_10 vdd net_2 net_8 vdd p W=1.84U L=0.18U AD=0.716518P PD=3.50118U 
+ AS=0.4968P PS=2.38U
Mp_11 net_8 sel1 net_9 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.5053P 
+ PS=3.19U
Mp_12 net_9 net_10 net_11 vdd p W=1.84U L=0.18U AD=0.5053P PD=3.19U 
+ AS=0.5168P PS=3.42U
Mp_13 net_11 net_6 vdd vdd p W=1.84U L=0.18U AD=0.5168P PD=3.42U 
+ AS=0.716518P PS=3.50118U
Mp_14 net_10 sel1 vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.358259P 
+ PS=1.75059U
Mp_15 vdd net_9 out vdd p W=1.84U L=0.18U AD=0.716518P PD=3.50118U 
+ AS=0.8832P PS=4.64U
Mn_1 gnd in0 net_1 gnd n W=0.92U L=0.18U AD=0.339435P PD=2.53176U 
+ AS=0.2484P PS=1.46U
Mn_2 net_1 net_3 net_2 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2484P 
+ PS=1.46U
Mn_3 net_2 sel0 net_4 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2484P 
+ PS=1.46U
Mn_4 net_4 in1 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.339435P 
+ PS=2.53176U
Mn_5 gnd sel0 net_3 gnd n W=0.92U L=0.18U AD=0.339435P PD=2.53176U 
+ AS=0.3616P PS=3.44U
Mn_6 gnd in2 net_5 gnd n W=0.92U L=0.18U AD=0.339435P PD=2.53176U 
+ AS=0.26515P PS=2.435U
Mn_7 net_8 net_10 net_9 gnd n W=0.92U L=0.18U AD=0.4473P PD=3.21U 
+ AS=0.2504P PS=2.14U
Mn_8 net_5 net_3 net_6 gnd n W=0.92U L=0.18U AD=0.26515P PD=2.435U 
+ AS=0.2484P PS=1.46U
Mn_9 net_6 sel0 net_7 gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.2484P 
+ PS=1.46U
Mn_10 net_7 in3 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.339435P 
+ PS=2.53176U
Mn_11 gnd net_2 net_8 gnd n W=0.92U L=0.18U AD=0.339435P PD=2.53176U 
+ AS=0.4473P PS=3.21U
Mn_12 net_9 sel1 net_11 gnd n W=0.92U L=0.18U AD=0.2504P PD=2.14U 
+ AS=0.2484P PS=1.46U
Mn_13 net_11 net_6 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U 
+ AS=0.339435P PS=2.53176U
Mn_14 net_10 sel1 gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U 
+ AS=0.169718P PS=1.26588U
Mn_15 gnd net_9 out gnd n W=0.92U L=0.18U AD=0.339435P PD=2.53176U 
+ AS=0.4416P PS=2.8U
.ENDS	$ MMI_MUXI4B

.GLOBAL gnd vdd

