*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUXI3C in0 in1 in2 out sel0 sel1
C_1 net_1 gnd 2.52711fF
C_2 sel0 gnd 2.00815fF
C_3 vdd gnd 4.5306fF
C_4 in1 gnd 0.661425fF
C_5 net_2 gnd 0.874265fF
C_6 net_3 gnd 1.85491fF
C_7 net_4 gnd 0.602945fF
C_8 in0 gnd 0.66078fF
C_9 net_5 gnd 0.873962fF
C_10 sel1 gnd 3.12519fF
C_11 net_6 gnd 2.6517fF
C_12 net_7 gnd 3.06371fF
C_13 net_8 gnd 0.602643fF
C_14 net_9 gnd 1.17975fF
C_15 in2 gnd 0.65666fF
C_16 out gnd 0.860368fF
C_17 gnd gnd 4.88166fF
Mp_1 net_1 sel0 vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.231238P 
+ PS=1.624U
Mp_2 vdd in1 net_2 vdd p W=1.54U L=0.15U AD=0.462477P PD=3.248U AS=0.3773P 
+ PS=2.03U
Mp_3 net_2 net_1 net_3 vdd p W=1.54U L=0.15U AD=0.3773P PD=2.03U AS=0.3388P 
+ PS=1.98U
Mp_4 net_3 sel0 net_4 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.3388P 
+ PS=1.98U
Mp_5 net_4 in0 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.462477P 
+ PS=3.248U
Mp_6 vdd net_3 net_5 vdd p W=1.54U L=0.15U AD=0.462477P PD=3.248U 
+ AS=0.34265P PS=1.985U
Mp_7 net_5 sel1 net_6 vdd p W=1.54U L=0.15U AD=0.34265P PD=1.985U 
+ AS=0.3465P PS=1.99U
Mp_8 net_6 net_7 net_8 vdd p W=1.54U L=0.15U AD=0.3465P PD=1.99U AS=0.385P 
+ PS=2.04U
Mp_9 net_8 net_9 vdd vdd p W=1.54U L=0.15U AD=0.385P PD=2.04U AS=0.462477P 
+ PS=3.248U
Mp_10 vdd in2 net_9 vdd p W=0.77U L=0.15U AD=0.231238P PD=1.624U 
+ AS=0.30415P PS=2.33U
Mp_11 vdd net_6 out vdd p W=1.54U L=0.15U AD=0.462477P PD=3.248U AS=0.3388P 
+ PS=1.98U
Mp_12 out net_6 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.462477P 
+ PS=3.248U
Mp_13 vdd sel1 net_7 vdd p W=0.77U L=0.15U AD=0.231238P PD=1.624U 
+ AS=0.30415P PS=2.33U
Mn_1 net_1 sel0 gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.11296P PS=1.03937U
Mn_2 gnd in1 net_2 gnd n W=0.765U L=0.15U AD=0.224453P PD=2.06523U 
+ AS=0.190851P PS=1.95362U
Mn_3 net_2 sel0 net_3 gnd n W=0.77U L=0.15U AD=0.192099P PD=1.96638U 
+ AS=0.1694P PS=1.21U
Mn_4 net_3 net_1 net_4 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.1694P 
+ PS=1.21U
Mn_5 net_4 in0 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.22592P 
+ PS=2.07873U
Mn_6 gnd net_3 net_5 gnd n W=0.77U L=0.15U AD=0.22592P PD=2.07873U 
+ AS=0.171325P PS=1.215U
Mn_7 net_5 net_7 net_6 gnd n W=0.77U L=0.15U AD=0.171325P PD=1.215U 
+ AS=0.17325P PS=1.22U
Mn_8 net_6 sel1 net_8 gnd n W=0.77U L=0.15U AD=0.17325P PD=1.22U 
+ AS=0.194562P PS=1.96U
Mn_9 net_8 net_9 gnd gnd n W=0.77U L=0.15U AD=0.194562P PD=1.96U 
+ AS=0.22592P PS=2.07873U
Mn_10 gnd in2 net_9 gnd n W=0.385U L=0.15U AD=0.11296P PD=1.03937U 
+ AS=0.152075P PS=1.56U
Mn_11 gnd net_6 out gnd n W=0.765U L=0.15U AD=0.224453P PD=2.06523U 
+ AS=0.1683P PS=1.205U
Mn_12 out net_6 gnd gnd n W=0.765U L=0.15U AD=0.1683P PD=1.205U 
+ AS=0.224453P PS=2.06523U
Mn_13 gnd sel1 net_7 gnd n W=0.385U L=0.15U AD=0.11296P PD=1.03937U 
+ AS=0.152075P PS=1.56U
.ENDS	$ MMI_MUXI3C

.GLOBAL gnd vdd

