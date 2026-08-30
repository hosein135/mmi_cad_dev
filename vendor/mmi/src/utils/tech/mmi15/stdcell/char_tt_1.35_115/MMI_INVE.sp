*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INVE in out
C_1 vdd gnd 3.23368fF
C_2 in gnd 2.12412fF
C_3 out gnd 2.99684fF
C_4 gnd gnd 2.62378fF
Mp_1 vdd in out vdd p W=2.055U L=0.15U AD=0.571975P PD=3.29667U AS=0.4521P 
+ PS=2.495U
Mp_2 out in vdd vdd p W=2.055U L=0.15U AD=0.4521P PD=2.495U AS=0.571975P 
+ PS=3.29667U
Mp_3 vdd in out vdd p W=2.055U L=0.15U AD=0.571975P PD=3.29667U AS=0.4521P 
+ PS=2.495U
Mp_4 out in vdd vdd p W=2.055U L=0.15U AD=0.4521P PD=2.495U AS=0.571975P 
+ PS=3.29667U
Mp_5 vdd in out vdd p W=2.055U L=0.15U AD=0.571975P PD=3.29667U AS=0.4521P 
+ PS=2.495U
Mp_6 out in vdd vdd p W=2.055U L=0.15U AD=0.4521P PD=2.495U AS=0.571975P 
+ PS=3.29667U
Mn_1 gnd in out gnd n W=1.54U L=0.15U AD=0.47355P PD=2.925U AS=0.3388P 
+ PS=1.98U
Mn_2 out in gnd gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.47355P 
+ PS=2.925U
Mn_3 gnd in out gnd n W=1.54U L=0.15U AD=0.47355P PD=2.925U AS=0.3388P 
+ PS=1.98U
Mn_4 out in gnd gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.47355P 
+ PS=2.925U
.ENDS	$ MMI_INVE

.GLOBAL gnd vdd

