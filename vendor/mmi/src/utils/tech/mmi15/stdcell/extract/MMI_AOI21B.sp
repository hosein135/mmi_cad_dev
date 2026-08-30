*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AOI21B in0 in1 in2 out
C_1 net_1 gnd 2.05791fF
C_2 in0 gnd 1.07705fF
C_3 out gnd 1.33448fF
C_4 in1 gnd 0.85908fF
C_5 vdd gnd 2.11192fF
C_6 in2 gnd 0.788165fF
C_7 gnd gnd 2.26126fF
Mp_1 net_1 in0 out vdd p W=1.54U L=0.15U AD=0.432483P PD=2.615U AS=0.3388P 
+ PS=1.98U
Mp_2 out in0 net_1 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.432483P 
+ PS=2.615U
Mp_3 net_1 in1 vdd vdd p W=1.54U L=0.15U AD=0.432483P PD=2.615U 
+ AS=0.348425P PS=1.9925U
Mp_4 vdd in1 net_1 vdd p W=1.54U L=0.15U AD=0.348425P PD=1.9925U 
+ AS=0.432483P PS=2.615U
Mp_5 net_1 in2 vdd vdd p W=1.54U L=0.15U AD=0.432483P PD=2.615U 
+ AS=0.348425P PS=1.9925U
Mp_6 vdd in2 net_1 vdd p W=1.54U L=0.15U AD=0.348425P PD=1.9925U 
+ AS=0.432483P PS=2.615U
Mn_1 gnd in0 out gnd n W=0.77U L=0.15U AD=0.30415P PD=2.06667U AS=0.229717P 
+ PS=1.88667U
Mn_2 out in1 net_2 gnd n W=1.54U L=0.15U AD=0.459433P PD=3.77333U 
+ AS=0.2464P PS=1.86U
Mn_3 net_2 in2 gnd gnd n W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.6083P 
+ PS=4.13333U
.ENDS	$ MMI_AOI21B

.GLOBAL gnd vdd

