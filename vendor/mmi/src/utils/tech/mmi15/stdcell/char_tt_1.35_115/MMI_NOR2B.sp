*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NOR2B in0 in1 out
C_1 vdd gnd 2.0744fF
C_2 in1 gnd 1.36115fF
C_3 in0 gnd 1.01099fF
C_4 out gnd 1.04681fF
C_5 gnd gnd 1.66172fF
Mp_1 vdd in1 net_1 vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.2464P 
+ PS=1.86U
Mp_2 net_1 in0 out vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.3388P 
+ PS=1.98U
Mp_3 out in0 net_2 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.2464P 
+ PS=1.86U
Mp_4 net_2 in1 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.6083P 
+ PS=3.87U
Mn_1 gnd in0 out gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.1694P 
+ PS=1.21U
Mn_2 out in1 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.30415P 
+ PS=2.33U
.ENDS	$ MMI_NOR2B

.GLOBAL gnd vdd

