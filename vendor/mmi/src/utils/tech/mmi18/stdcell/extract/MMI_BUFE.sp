*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_BUFE in out
C_1 vdd gnd 5.06099fF
C_2 in gnd 1.29709fF
C_3 net_1 gnd 4.01434fF
C_4 out gnd 3.70746fF
C_5 gnd gnd 4.30868fF
Mp_1 vdd in net_1 vdd p W=2.48U L=0.18U AD=0.81316P PD=3.88563U AS=0.6696P 
+ PS=3.02U
Mp_2 net_1 in vdd vdd p W=2.48U L=0.18U AD=0.6696P PD=3.02U AS=0.81316P 
+ PS=3.88563U
Mp_3 vdd net_1 out vdd p W=2.455U L=0.18U AD=0.804963P PD=3.84646U 
+ AS=0.66285P PS=2.995U
Mp_4 out net_1 vdd vdd p W=2.455U L=0.18U AD=0.66285P PD=2.995U 
+ AS=0.804963P PS=3.84646U
Mp_5 vdd net_1 out vdd p W=2.455U L=0.18U AD=0.804963P PD=3.84646U 
+ AS=0.66285P PS=2.995U
Mp_6 out net_1 vdd vdd p W=2.455U L=0.18U AD=0.66285P PD=2.995U 
+ AS=0.804963P PS=3.84646U
Mp_7 vdd net_1 out vdd p W=2.455U L=0.18U AD=0.804963P PD=3.84646U 
+ AS=0.66285P PS=2.995U
Mp_8 out net_1 vdd vdd p W=2.455U L=0.18U AD=0.66285P PD=2.995U 
+ AS=0.804963P PS=3.84646U
Mn_1 gnd in net_1 gnd n W=1.24U L=0.18U AD=0.438436P PD=2.34894U AS=0.3348P 
+ PS=1.78U
Mn_2 net_1 in gnd gnd n W=1.24U L=0.18U AD=0.3348P PD=1.78U AS=0.438436P 
+ PS=2.34894U
Mn_3 gnd net_1 out gnd n W=1.84U L=0.18U AD=0.650582P PD=3.48553U 
+ AS=0.4968P PS=2.38U
Mn_4 out net_1 gnd gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.650582P 
+ PS=3.48553U
Mn_5 gnd net_1 out gnd n W=1.84U L=0.18U AD=0.650582P PD=3.48553U 
+ AS=0.4968P PS=2.38U
Mn_6 out net_1 gnd gnd n W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.650582P 
+ PS=3.48553U
.ENDS	$ MMI_BUFE

.GLOBAL gnd vdd

