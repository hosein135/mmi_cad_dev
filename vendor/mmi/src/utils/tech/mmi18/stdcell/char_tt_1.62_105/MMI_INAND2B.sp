*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_INAND2B in0 in1 out
C_1 vdd gnd 2.11058fF
C_2 net_1 gnd 1.86197fF
C_3 out gnd 1.53734fF
C_4 in0 gnd 0.827078fF
C_5 in1 gnd 0.82879fF
C_6 gnd gnd 1.58408fF
Mp_1 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.74336P PD=4.176U AS=0.4968P 
+ PS=2.38U
Mp_2 out in0 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.74336P 
+ PS=4.176U
Mp_3 vdd in1 net_1 vdd p W=0.92U L=0.18U AD=0.37168P PD=2.088U AS=0.4416P 
+ PS=2.8U
Mn_1 out net_1 net_2 gnd n W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.3588P 
+ PS=2.23U
Mn_2 net_2 in0 gnd gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.74336P 
+ PS=4.64U
Mn_3 gnd in1 net_1 gnd n W=0.46U L=0.18U AD=0.18584P PD=1.16U AS=0.2208P 
+ PS=1.88U
.ENDS	$ MMI_INAND2B

.GLOBAL gnd vdd

