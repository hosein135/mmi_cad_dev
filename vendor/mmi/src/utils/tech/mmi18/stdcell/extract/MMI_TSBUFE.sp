*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_TSBUFE en enb in out
C_1 net_1 gnd 4.36413fF
C_2 enb gnd 0.87548fF
C_3 net_2 gnd 4.11281fF
C_4 in gnd 1.31457fF
C_5 vdd gnd 5.32685fF
C_6 en gnd 0.84644fF
C_7 out gnd 3.99239fF
C_8 gnd gnd 5.7404fF
Mp_1 net_1 enb net_2 vdd p W=2.0U L=0.18U AD=0.96P PD=4.96U AS=0.54P 
+ PS=2.54U
Mp_2 net_2 in vdd vdd p W=2.0U L=0.18U AD=0.54P PD=2.54U AS=0.606676P 
+ PS=2.8905U
Mp_3 vdd in net_2 vdd p W=2.0U L=0.18U AD=0.606676P PD=2.8905U AS=0.54P 
+ PS=2.54U
Mp_4 net_2 en vdd vdd p W=2.0U L=0.18U AD=0.54P PD=2.54U AS=0.606676P 
+ PS=2.8905U
Mp_5 vdd net_2 out vdd p W=2.455U L=0.18U AD=0.744695P PD=3.54808U 
+ AS=0.66285P PS=2.995U
Mp_6 out net_2 vdd vdd p W=2.455U L=0.18U AD=0.66285P PD=2.995U 
+ AS=0.744695P PS=3.54808U
Mp_7 vdd net_2 out vdd p W=2.455U L=0.18U AD=0.744695P PD=3.54808U 
+ AS=0.66285P PS=2.995U
Mp_8 out net_2 vdd vdd p W=2.455U L=0.18U AD=0.66285P PD=2.995U 
+ AS=0.744695P PS=3.54808U
Mp_9 vdd net_2 out vdd p W=2.455U L=0.18U AD=0.744695P PD=3.54808U 
+ AS=0.66285P PS=2.995U
Mp_10 out net_2 vdd vdd p W=2.455U L=0.18U AD=0.66285P PD=2.995U 
+ AS=0.744695P PS=3.54808U
Mn_1 gnd enb net_1 gnd n W=1.24U L=0.18U AD=0.4216P PD=2.33886U AS=0.3348P 
+ PS=1.78U
Mn_2 net_1 in gnd gnd n W=1.24U L=0.18U AD=0.3348P PD=1.78U AS=0.4216P 
+ PS=2.33886U
Mn_3 gnd in net_1 gnd n W=1.24U L=0.18U AD=0.4216P PD=2.33886U AS=0.3348P 
+ PS=1.78U
Mn_4 net_1 en net_2 gnd n W=1.24U L=0.18U AD=0.3348P PD=1.78U AS=0.5952P 
+ PS=3.44U
Mn_5 gnd net_1 out gnd n W=1.225U L=0.18U AD=0.4165P PD=2.31057U 
+ AS=0.33075P PS=1.765U
Mn_6 out net_1 gnd gnd n W=1.225U L=0.18U AD=0.33075P PD=1.765U AS=0.4165P 
+ PS=2.31057U
Mn_7 gnd net_1 out gnd n W=1.225U L=0.18U AD=0.4165P PD=2.31057U 
+ AS=0.33075P PS=1.765U
Mn_8 out net_1 gnd gnd n W=1.225U L=0.18U AD=0.33075P PD=1.765U AS=0.4165P 
+ PS=2.31057U
Mn_9 gnd net_1 out gnd n W=1.225U L=0.18U AD=0.4165P PD=2.31057U 
+ AS=0.33075P PS=1.765U
Mn_10 out net_1 gnd gnd n W=1.225U L=0.18U AD=0.33075P PD=1.765U AS=0.4165P 
+ PS=2.31057U
.ENDS	$ MMI_TSBUFE

.GLOBAL gnd vdd

