*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INVC in out
C_1 vdd gnd 1.72908fF
C_2 in gnd 0.80179fF
C_3 out gnd 0.984468fF
C_4 gnd gnd 1.14768fF
Mp_1 vdd in out vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.3388P 
+ PS=1.98U
Mp_2 out in vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.6083P 
+ PS=3.87U
Mn_1 out in gnd gnd n W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.6083P 
+ PS=3.87U
.ENDS	$ MMI_INVC

.GLOBAL gnd vdd

