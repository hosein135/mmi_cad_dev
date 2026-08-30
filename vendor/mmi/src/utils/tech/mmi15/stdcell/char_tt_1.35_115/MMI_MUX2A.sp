*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUX2A in0 in1 out sel
C_1 net_1 gnd 2.14814fF
C_2 sel gnd 1.93409fF
C_3 vdd gnd 2.27836fF
C_4 in0 gnd 0.946105fF
C_5 net_2 gnd 1.0117fF
C_6 net_3 gnd 2.23471fF
C_7 net_4 gnd 1.12393fF
C_8 in1 gnd 1.08425fF
C_9 out gnd 0.905805fF
C_10 gnd gnd 1.81096fF
Mp_1 net_1 sel vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.17325P 
+ PS=1.22U
Mp_2 vdd in0 net_2 vdd p W=0.77U L=0.15U AD=0.17325P PD=1.22U AS=0.1694P 
+ PS=1.21U
Mp_3 net_2 sel net_3 vdd p W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.233567P 
+ PS=1.63333U
Mp_4 net_3 net_1 net_4 vdd p W=1.54U L=0.15U AD=0.467133P PD=3.26667U 
+ AS=0.451733P PS=3.22667U
Mp_5 net_4 in1 vdd vdd p W=0.77U L=0.15U AD=0.225867P PD=1.61333U 
+ AS=0.17325P PS=1.22U
Mp_6 vdd net_3 out vdd p W=0.77U L=0.15U AD=0.17325P PD=1.22U AS=0.30415P 
+ PS=2.33U
Mn_1 net_1 sel gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.086625P PS=0.835U
Mn_2 gnd in0 net_2 gnd n W=0.385U L=0.15U AD=0.086625P PD=0.835U AS=0.0847P 
+ PS=0.825U
Mn_3 net_2 net_1 net_3 gnd n W=0.385U L=0.15U AD=0.0847P PD=0.825U 
+ AS=0.116783P PS=1.12U
Mn_4 net_3 sel net_4 gnd n W=0.77U L=0.15U AD=0.233567P PD=2.24U 
+ AS=0.225867P PS=2.2U
Mn_5 net_4 in1 gnd gnd n W=0.385U L=0.15U AD=0.112933P PD=1.1U AS=0.086625P 
+ PS=0.835U
Mn_6 gnd net_3 out gnd n W=0.385U L=0.15U AD=0.086625P PD=0.835U 
+ AS=0.152075P PS=1.56U
.ENDS	$ MMI_MUX2A

.GLOBAL gnd vdd

