*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND2C in0 in1 out
C_1 vdd gnd 2.30924fF
C_2 in0 gnd 1.00795fF
C_3 out gnd 1.60698fF
C_4 in1 gnd 1.22692fF
C_5 gnd gnd 2.08352fF
Mp_1 vdd in0 out vdd p W=1.54U L=0.15U AD=0.47355P PD=2.925U AS=0.3388P 
+ PS=1.98U
Mp_2 out in0 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.47355P 
+ PS=2.925U
Mp_3 vdd in1 out vdd p W=1.54U L=0.15U AD=0.47355P PD=2.925U AS=0.3388P 
+ PS=1.98U
Mp_4 out in1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.47355P 
+ PS=2.925U
Mn_1 gnd in1 net_1 gnd n W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.24255P 
+ PS=1.855U
Mn_2 net_1 in0 out gnd n W=1.54U L=0.15U AD=0.24255P PD=1.855U AS=0.3388P 
+ PS=1.98U
Mn_3 out in0 net_2 gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.2464P 
+ PS=1.86U
Mn_4 net_2 in1 gnd gnd n W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.6083P 
+ PS=3.87U
.ENDS	$ MMI_NAND2C

.GLOBAL gnd vdd

