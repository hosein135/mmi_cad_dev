*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AOI21A in0 in1 in2 out
C_1 out gnd 1.39342fF
C_2 in0 gnd 0.90429fF
C_3 net_1 gnd 1.15898fF
C_4 in1 gnd 0.904745fF
C_5 vdd gnd 1.53143fF
C_6 in2 gnd 0.97174fF
C_7 gnd gnd 1.98188fF
Mp_1 out in0 net_1 vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.6256P 
+ PS=3.13333U
Mp_2 net_1 in1 vdd vdd p W=1.84U L=0.18U AD=0.6256P PD=3.13333U AS=0.4968P 
+ PS=2.38U
Mp_3 vdd in2 net_1 vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.6256P 
+ PS=3.13333U
Mn_1 gnd in0 out gnd n W=0.46U L=0.18U AD=0.2208P PD=1.56U AS=0.162533P 
+ PS=1.32U
Mn_2 out in1 net_2 gnd n W=0.92U L=0.18U AD=0.325067P PD=2.64U AS=0.1794P 
+ PS=1.31U
Mn_3 net_2 in2 gnd gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.4416P 
+ PS=3.12U
.ENDS	$ MMI_AOI21A

.GLOBAL gnd vdd

