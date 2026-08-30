*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AND4B in0 in1 in2 in3 out
C_1 vdd gnd 2.32572fF
C_2 in0 gnd 0.715365fF
C_3 net_1 gnd 2.36164fF
C_4 in1 gnd 0.680085fF
C_5 in2 gnd 0.695647fF
C_6 in3 gnd 0.857555fF
C_7 out gnd 0.969575fF
C_8 gnd gnd 2.1741fF
Mp_1 vdd in0 net_1 vdd p W=0.77U L=0.15U AD=0.225225P PD=1.61167U 
+ AS=0.1694P PS=1.21U
Mp_2 net_1 in1 vdd vdd p W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.225225P 
+ PS=1.61167U
Mp_3 vdd in2 net_1 vdd p W=0.77U L=0.15U AD=0.225225P PD=1.61167U 
+ AS=0.1694P PS=1.21U
Mp_4 net_1 in3 vdd vdd p W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.225225P 
+ PS=1.61167U
Mp_5 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.45045P PD=3.22333U AS=0.6083P 
+ PS=3.87U
Mn_1 net_1 in0 net_2 gnd n W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.2464P 
+ PS=1.86U
Mn_2 net_2 in1 net_3 gnd n W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.2464P 
+ PS=1.86U
Mn_3 net_3 in2 net_4 gnd n W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.2464P 
+ PS=1.86U
Mn_4 net_4 in3 gnd gnd n W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.6083P 
+ PS=4.13333U
Mn_5 gnd net_1 out gnd n W=0.77U L=0.15U AD=0.30415P PD=2.06667U 
+ AS=0.30415P PS=2.33U
.ENDS	$ MMI_AND4B

.GLOBAL gnd vdd

