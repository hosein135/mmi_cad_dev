*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INOR2C in0 in1 out
C_1 net_1 gnd 3.25676fF
C_2 in1 gnd 0.84462fF
C_3 vdd gnd 3.08538fF
C_4 in0 gnd 2.44494fF
C_5 out gnd 2.23175fF
C_6 gnd gnd 2.44698fF
Mp_1 net_1 in1 vdd vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.3927P 
+ PS=2.358U
Mp_2 vdd in0 net_2 vdd p W=1.54U L=0.15U AD=0.3927P PD=2.358U AS=0.24255P 
+ PS=1.855U
Mp_3 net_2 net_1 out vdd p W=1.54U L=0.15U AD=0.24255P PD=1.855U AS=0.3388P 
+ PS=1.98U
Mp_4 out net_1 net_3 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.2464P 
+ PS=1.86U
Mp_5 net_3 in0 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.3927P 
+ PS=2.358U
Mp_6 vdd in0 net_4 vdd p W=1.54U L=0.15U AD=0.3927P PD=2.358U AS=0.24255P 
+ PS=1.855U
Mp_7 net_4 net_1 out vdd p W=1.54U L=0.15U AD=0.24255P PD=1.855U AS=0.3388P 
+ PS=1.98U
Mp_8 out net_1 net_5 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.2464P 
+ PS=1.86U
Mp_9 net_5 in0 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.3927P 
+ PS=2.358U
Mn_1 net_1 in1 gnd gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.19635P 
+ PS=1.434U
Mn_2 gnd in0 out gnd n W=0.77U L=0.15U AD=0.19635P PD=1.434U AS=0.1694P 
+ PS=1.21U
Mn_3 out in0 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.19635P 
+ PS=1.434U
Mn_4 gnd net_1 out gnd n W=0.77U L=0.15U AD=0.19635P PD=1.434U AS=0.1694P 
+ PS=1.21U
Mn_5 out net_1 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.19635P 
+ PS=1.434U
.ENDS	$ MMI_INOR2C

.GLOBAL gnd vdd

