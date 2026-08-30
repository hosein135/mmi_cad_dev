*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INVC in out
C_1 vdd gnd 2.13428fF
C_2 in gnd 0.96568fF
C_3 out gnd 1.20056fF
C_4 gnd gnd 1.42058fF
Mp_1 vdd in out vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.4968P 
+ PS=2.38U
Mp_2 out in vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.8832P 
+ PS=4.64U
Mn_1 out in gnd gnd n W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.8832P 
+ PS=4.64U
.ENDS	$ MMI_INVC

.GLOBAL gnd vdd

