*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OA31C in0 in1 in2 in3 out
C_1 vdd gnd 3.12186fF
C_2 net_1 gnd 2.88234fF
C_3 out gnd 1.18442fF
C_4 in0 gnd 0.78077fF
C_5 in1 gnd 1.59204fF
C_6 in2 gnd 1.41252fF
C_7 in3 gnd 1.00536fF
C_8 gnd gnd 2.65674fF
C_9 net_6 gnd 0.71287fF
Mp_1 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.428009P PD=2.70989U 
+ AS=0.3388P PS=1.98U
Mp_2 out net_1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.428009P 
+ PS=2.70989U
Mp_3 vdd in0 net_1 vdd p W=1.04U L=0.15U AD=0.289045P PD=1.83006U 
+ AS=0.3315P PS=2.395U
Mp_4 net_1 in1 net_2 vdd p W=1.56U L=0.15U AD=0.49725P PD=3.5925U 
+ AS=0.2496P PS=1.88U
Mp_5 net_2 in2 net_3 vdd p W=1.56U L=0.15U AD=0.2496P PD=1.88U AS=0.2496P 
+ PS=1.88U
Mp_6 net_3 in3 vdd vdd p W=1.56U L=0.15U AD=0.2496P PD=1.88U AS=0.433568P 
+ PS=2.74508U
Mp_7 vdd in3 net_4 vdd p W=1.56U L=0.15U AD=0.433568P PD=2.74508U 
+ AS=0.2457P PS=1.875U
Mp_8 net_4 in2 net_5 vdd p W=1.56U L=0.15U AD=0.2457P PD=1.875U AS=0.2496P 
+ PS=1.88U
Mp_9 net_5 in1 net_1 vdd p W=1.56U L=0.15U AD=0.2496P PD=1.88U AS=0.49725P 
+ PS=3.5925U
Mn_1 gnd net_1 out gnd n W=1.54U L=0.15U AD=0.488008P PD=3.20558U 
+ AS=0.6083P PS=3.87U
Mn_2 net_1 in0 net_6 gnd n W=1.04U L=0.15U AD=0.4108P PD=2.87U AS=0.2288P 
+ PS=1.48U
Mn_3 net_6 in1 gnd gnd n W=1.04U L=0.15U AD=0.2288P PD=1.48U AS=0.329564P 
+ PS=2.16481U
Mn_4 gnd in2 net_6 gnd n W=1.04U L=0.15U AD=0.329564P PD=2.16481U 
+ AS=0.2288P PS=1.48U
Mn_5 net_6 in3 gnd gnd n W=1.04U L=0.15U AD=0.2288P PD=1.48U AS=0.329564P 
+ PS=2.16481U
.ENDS	$ MMI_OA31C

.GLOBAL gnd vdd

