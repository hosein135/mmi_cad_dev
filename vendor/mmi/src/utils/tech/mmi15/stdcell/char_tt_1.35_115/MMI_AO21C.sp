*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AO21C in0 in1 in2 out
C_1 net_1 gnd 2.91237fF
C_2 in0 gnd 0.71992fF
C_3 net_2 gnd 1.19532fF
C_4 in2 gnd 0.7272fF
C_5 vdd gnd 2.77996fF
C_6 in1 gnd 0.805075fF
C_7 out gnd 1.01831fF
C_8 gnd gnd 2.42428fF
Mp_1 net_1 in0 net_2 vdd p W=2.08U L=0.15U AD=0.8216P PD=4.95U AS=0.578933P 
+ PS=3.33U
Mp_2 net_2 in2 vdd vdd p W=2.08U L=0.15U AD=0.578933P PD=3.33U AS=0.612451P 
+ PS=3.6716U
Mp_3 vdd in1 net_2 vdd p W=2.08U L=0.15U AD=0.612451P PD=3.6716U 
+ AS=0.578933P PS=3.33U
Mp_4 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.453449P PD=2.7184U AS=0.3388P 
+ PS=1.98U
Mp_5 out net_1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.453449P 
+ PS=2.7184U
Mn_1 net_1 in0 gnd gnd n W=0.52U L=0.15U AD=0.2054P PD=1.56667U 
+ AS=0.178796P PS=1.42581U
Mn_2 gnd in2 net_3 gnd n W=1.04U L=0.15U AD=0.357592P PD=2.85161U 
+ AS=0.1664P PS=1.36U
Mn_3 net_3 in1 net_1 gnd n W=1.04U L=0.15U AD=0.1664P PD=1.36U AS=0.4108P 
+ PS=3.13333U
Mn_4 gnd net_1 out gnd n W=0.77U L=0.15U AD=0.264756P PD=2.11129U 
+ AS=0.1694P PS=1.21U
Mn_5 out net_1 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.264756P 
+ PS=2.11129U
.ENDS	$ MMI_AO21C

.GLOBAL gnd vdd

