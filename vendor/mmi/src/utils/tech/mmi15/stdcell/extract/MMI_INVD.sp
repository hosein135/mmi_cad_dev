*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INVD in out
C_1 out gnd 1.76405fF
C_2 in gnd 1.17684fF
C_3 vdd gnd 1.79116fF
C_4 gnd gnd 1.77292fF
Mp_1 out in vdd vdd p W=2.055U L=0.15U AD=0.571975P PD=3.29667U 
+ AS=0.571975P PS=3.29667U
Mp_2 vdd in out vdd p W=2.055U L=0.15U AD=0.571975P PD=3.29667U 
+ AS=0.571975P PS=3.29667U
Mp_3 out in vdd vdd p W=2.055U L=0.15U AD=0.571975P PD=3.29667U 
+ AS=0.571975P PS=3.29667U
Mn_1 gnd in out gnd n W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.3388P 
+ PS=1.98U
Mn_2 out in gnd gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.6083P 
+ PS=3.87U
.ENDS	$ MMI_INVD

.GLOBAL gnd vdd

