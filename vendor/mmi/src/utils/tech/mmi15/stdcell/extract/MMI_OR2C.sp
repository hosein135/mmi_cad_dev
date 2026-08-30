*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OR2C in0 in1 out
C_1 net_1 gnd 1.96404fF
C_2 in0 gnd 0.74193fF
C_3 in1 gnd 0.75021fF
C_4 vdd gnd 1.9262fF
C_5 out gnd 1.15602fF
C_6 gnd gnd 1.81106fF
Mp_1 net_1 in0 net_2 vdd p W=2.08U L=0.15U AD=0.8216P PD=4.95U AS=0.2288P 
+ PS=2.3U
Mp_2 net_2 in1 vdd vdd p W=2.08U L=0.15U AD=0.2288P PD=2.3U AS=0.586431P 
+ PS=4.03907U
Mp_3 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.434184P PD=2.99047U 
+ AS=0.3388P PS=1.98U
Mp_4 out net_1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.434184P 
+ PS=2.99047U
Mn_1 gnd in0 net_1 gnd n W=0.52U L=0.15U AD=0.174653P PD=1.45922U 
+ AS=0.1144P PS=0.96U
Mn_2 net_1 in1 gnd gnd n W=0.52U L=0.15U AD=0.1144P PD=0.96U AS=0.174653P 
+ PS=1.45922U
Mn_3 gnd net_1 out gnd n W=1.54U L=0.15U AD=0.517243P PD=4.32155U 
+ AS=0.6083P PS=3.87U
.ENDS	$ MMI_OR2C

.GLOBAL gnd vdd

