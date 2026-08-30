*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NOR2C in0 in1 out
C_1 vdd gnd 3.03926fF
C_2 in1 gnd 2.21757fF
C_3 in0 gnd 1.7407fF
C_4 out gnd 2.50259fF
C_5 gnd gnd 2.53082fF
Mp_1 vdd in1 net_1 vdd p W=1.54U L=0.15U AD=0.47355P PD=2.925U AS=0.2464P 
+ PS=1.86U
Mp_2 net_1 in0 out vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.3388P 
+ PS=1.98U
Mp_3 out in0 net_2 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.2464P 
+ PS=1.86U
Mp_4 net_2 in1 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.47355P 
+ PS=2.925U
Mp_5 vdd in1 net_3 vdd p W=1.54U L=0.15U AD=0.47355P PD=2.925U AS=0.2464P 
+ PS=1.86U
Mp_6 net_3 in0 out vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.3388P 
+ PS=1.98U
Mp_7 out in0 net_4 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.2464P 
+ PS=1.86U
Mp_8 net_4 in1 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.47355P 
+ PS=2.925U
Mn_1 gnd in0 out gnd n W=0.77U L=0.15U AD=0.239663P PD=1.7775U AS=0.172288P 
+ PS=1.2175U
Mn_2 out in0 gnd gnd n W=0.77U L=0.15U AD=0.172288P PD=1.2175U AS=0.239663P 
+ PS=1.7775U
Mn_3 gnd in1 out gnd n W=0.77U L=0.15U AD=0.239663P PD=1.7775U AS=0.172288P 
+ PS=1.2175U
Mn_4 out in1 gnd gnd n W=0.77U L=0.15U AD=0.172288P PD=1.2175U AS=0.239663P 
+ PS=1.7775U
.ENDS	$ MMI_NOR2C

.GLOBAL gnd vdd

