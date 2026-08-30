*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INVE in out
C_1 vdd gnd 4.00976fF
C_2 in gnd 2.57651fF
C_3 out gnd 3.68153fF
C_4 gnd gnd 3.25628fF
Mp_1 vdd in out vdd p W=2.455U L=0.18U AD=0.8347P PD=3.95333U AS=0.66285P 
+ PS=2.995U
Mp_2 out in vdd vdd p W=2.455U L=0.18U AD=0.66285P PD=2.995U AS=0.8347P 
+ PS=3.95333U
Mp_3 vdd in out vdd p W=2.455U L=0.18U AD=0.8347P PD=3.95333U AS=0.66285P 
+ PS=2.995U
Mp_4 out in vdd vdd p W=2.455U L=0.18U AD=0.66285P PD=2.995U AS=0.8347P 
+ PS=3.95333U
Mp_5 vdd in out vdd p W=2.455U L=0.18U AD=0.8347P PD=3.95333U AS=0.66285P 
+ PS=2.995U
Mp_6 out in vdd vdd p W=2.455U L=0.18U AD=0.66285P PD=2.995U AS=0.8347P 
+ PS=3.95333U
Mn_1 gnd in out gnd n W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.4968P PS=2.38U
Mn_2 out in gnd gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.69P PS=3.51U
Mn_3 gnd in out gnd n W=1.84U L=0.18U AD=0.69P PD=3.51U AS=0.4968P PS=2.38U
Mn_4 out in gnd gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.69P PS=3.51U
.ENDS	$ MMI_INVE

.GLOBAL gnd vdd

