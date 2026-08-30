*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INVD in out
C_1 out gnd 2.16285fF
C_2 in gnd 1.41176fF
C_3 vdd gnd 2.21822fF
C_4 gnd gnd 2.1995fF
Mp_1 out in vdd vdd p W=2.455U L=0.18U AD=0.8347P PD=3.95333U AS=0.8347P 
+ PS=3.95333U
Mp_2 vdd in out vdd p W=2.455U L=0.18U AD=0.8347P PD=3.95333U AS=0.8347P 
+ PS=3.95333U
Mp_3 out in vdd vdd p W=2.455U L=0.18U AD=0.8347P PD=3.95333U AS=0.8347P 
+ PS=3.95333U
Mn_1 gnd in out gnd n W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.4968P 
+ PS=2.38U
Mn_2 out in gnd gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.8832P 
+ PS=4.64U
.ENDS	$ MMI_INVD

.GLOBAL gnd vdd

