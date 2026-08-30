*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AOI31B in0 in1 in2 in3 out
C_1 net_1 gnd 2.60161fF
C_2 in1 gnd 1.76459fF
C_3 vdd gnd 2.66928fF
C_4 in0 gnd 1.62383fF
C_5 out gnd 1.66922fF
C_6 in2 gnd 1.53501fF
C_7 in3 gnd 1.65801fF
C_8 gnd gnd 2.43786fF
Mp_1 net_1 in1 vdd vdd p W=1.54U L=0.15U AD=0.413875P PD=2.4625U AS=0.3388P 
+ PS=1.98U
Mp_2 vdd in1 net_1 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.413875P 
+ PS=2.4625U
Mp_3 net_1 in0 out vdd p W=1.54U L=0.15U AD=0.413875P PD=2.4625U AS=0.3388P 
+ PS=1.98U
Mp_4 out in0 net_1 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.413875P 
+ PS=2.4625U
Mp_5 net_1 in2 vdd vdd p W=1.54U L=0.15U AD=0.413875P PD=2.4625U AS=0.3388P 
+ PS=1.98U
Mp_6 vdd in2 net_1 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.413875P 
+ PS=2.4625U
Mp_7 net_1 in3 vdd vdd p W=1.54U L=0.15U AD=0.413875P PD=2.4625U AS=0.3388P 
+ PS=1.98U
Mp_8 vdd in3 net_1 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.413875P 
+ PS=2.4625U
Mn_1 out in0 gnd gnd n W=0.77U L=0.15U AD=0.203088P PD=1.38U AS=0.2464P 
+ PS=1.795U
Mn_2 gnd in3 net_2 gnd n W=1.155U L=0.15U AD=0.3696P PD=2.6925U AS=0.1848P 
+ PS=1.475U
Mn_3 net_2 in2 net_3 gnd n W=1.155U L=0.15U AD=0.1848P PD=1.475U AS=0.1848P 
+ PS=1.475U
Mn_4 net_3 in1 out gnd n W=1.155U L=0.15U AD=0.1848P PD=1.475U AS=0.304631P 
+ PS=2.07U
Mn_5 out in1 net_4 gnd n W=1.155U L=0.15U AD=0.304631P PD=2.07U 
+ AS=0.181913P PS=1.47U
Mn_6 net_4 in2 net_5 gnd n W=1.155U L=0.15U AD=0.181913P PD=1.47U 
+ AS=0.1848P PS=1.475U
Mn_7 net_5 in3 gnd gnd n W=1.155U L=0.15U AD=0.1848P PD=1.475U AS=0.3696P 
+ PS=2.6925U
.ENDS	$ MMI_AOI31B

.GLOBAL gnd vdd

