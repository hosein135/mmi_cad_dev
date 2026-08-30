*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INAND2C in0 in1 out
C_1 net_1 gnd 2.0489fF
C_2 in1 gnd 0.675985fF
C_3 vdd gnd 2.48532fF
C_4 out gnd 1.70713fF
C_5 in0 gnd 1.36423fF
C_6 gnd gnd 2.10684fF
Mp_1 net_1 in1 vdd vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.3927P 
+ PS=2.358U
Mp_2 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.3927P PD=2.358U AS=0.3388P 
+ PS=1.98U
Mp_3 out net_1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.3927P 
+ PS=2.358U
Mp_4 vdd in0 out vdd p W=1.54U L=0.15U AD=0.3927P PD=2.358U AS=0.3388P 
+ PS=1.98U
Mp_5 out in0 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.3927P 
+ PS=2.358U
Mn_1 net_1 in1 gnd gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.25718P 
+ PS=1.742U
Mn_2 gnd in0 net_2 gnd n W=1.54U L=0.15U AD=0.51436P PD=3.484U AS=0.24255P 
+ PS=1.855U
Mn_3 net_2 net_1 out gnd n W=1.54U L=0.15U AD=0.24255P PD=1.855U AS=0.3388P 
+ PS=1.98U
Mn_4 out net_1 net_3 gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.2464P 
+ PS=1.86U
Mn_5 net_3 in0 gnd gnd n W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.51436P 
+ PS=3.484U
.ENDS	$ MMI_INAND2C

.GLOBAL gnd vdd

