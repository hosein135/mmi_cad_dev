*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_BUFD in out
C_1 net_1 gnd 2.1593fF
C_2 in gnd 0.60747fF
C_3 vdd gnd 1.93304fF
C_4 out gnd 1.86159fF
C_5 gnd gnd 2.3993fF
Mp_1 net_1 in vdd vdd p W=2.08U L=0.15U AD=0.8216P PD=4.95U AS=0.482033P 
+ PS=2.75231U
Mp_2 vdd net_1 out vdd p W=2.055U L=0.15U AD=0.476239P PD=2.71923U 
+ AS=0.571975P PS=3.29667U
Mp_3 out net_1 vdd vdd p W=2.055U L=0.15U AD=0.571975P PD=3.29667U 
+ AS=0.476239P PS=2.71923U
Mp_4 vdd net_1 out vdd p W=2.055U L=0.15U AD=0.476239P PD=2.71923U 
+ AS=0.571975P PS=3.29667U
Mn_1 gnd in net_1 gnd n W=1.04U L=0.15U AD=0.4108P PD=2.67825U AS=0.4108P 
+ PS=2.87U
Mn_2 gnd net_1 out gnd n W=1.54U L=0.15U AD=0.6083P PD=3.96587U AS=0.3388P 
+ PS=1.98U
Mn_3 out net_1 gnd gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.6083P 
+ PS=3.96587U
.ENDS	$ MMI_BUFD

.GLOBAL gnd vdd

