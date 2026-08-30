*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_BUFE in out
C_1 vdd gnd 4.07946fF
C_2 in gnd 1.08171fF
C_3 net_1 gnd 3.30469fF
C_4 out gnd 3.0157fF
C_5 gnd gnd 3.465fF
Mp_1 vdd in net_1 vdd p W=2.08U L=0.15U AD=0.56498P PD=3.35146U AS=0.4576P 
+ PS=2.52U
Mp_2 net_1 in vdd vdd p W=2.08U L=0.15U AD=0.4576P PD=2.52U AS=0.56498P 
+ PS=3.35146U
Mp_3 vdd net_1 out vdd p W=2.055U L=0.15U AD=0.55819P PD=3.31118U 
+ AS=0.4521P PS=2.495U
Mp_4 out net_1 vdd vdd p W=2.055U L=0.15U AD=0.4521P PD=2.495U AS=0.55819P 
+ PS=3.31118U
Mp_5 vdd net_1 out vdd p W=2.055U L=0.15U AD=0.55819P PD=3.31118U 
+ AS=0.4521P PS=2.495U
Mp_6 out net_1 vdd vdd p W=2.055U L=0.15U AD=0.4521P PD=2.495U AS=0.55819P 
+ PS=3.31118U
Mp_7 vdd net_1 out vdd p W=2.055U L=0.15U AD=0.55819P PD=3.31118U 
+ AS=0.4521P PS=2.495U
Mp_8 out net_1 vdd vdd p W=2.055U L=0.15U AD=0.4521P PD=2.495U AS=0.55819P 
+ PS=3.31118U
Mn_1 gnd in net_1 gnd n W=1.04U L=0.15U AD=0.304705P PD=1.96515U AS=0.2496P 
+ PS=1.52U
Mn_2 net_1 in gnd gnd n W=1.04U L=0.15U AD=0.2496P PD=1.52U AS=0.304705P 
+ PS=1.96515U
Mn_3 gnd net_1 out gnd n W=1.54U L=0.15U AD=0.451198P PD=2.90993U 
+ AS=0.3388P PS=1.98U
Mn_4 out net_1 gnd gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.451198P 
+ PS=2.90993U
Mn_5 gnd net_1 out gnd n W=1.54U L=0.15U AD=0.451198P PD=2.90993U 
+ AS=0.3388P PS=1.98U
Mn_6 out net_1 gnd gnd n W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.451198P 
+ PS=2.90993U
.ENDS	$ MMI_BUFE

.GLOBAL gnd vdd

