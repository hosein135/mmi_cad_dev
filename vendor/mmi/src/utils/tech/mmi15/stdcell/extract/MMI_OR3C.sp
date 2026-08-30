*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OR3C in0 in1 in2 out
C_1 vdd gnd 3.03926fF
C_2 in2 gnd 1.44847fF
C_3 in1 gnd 1.3313fF
C_4 in0 gnd 1.2162fF
C_5 net_3 gnd 2.75556fF
C_6 out gnd 0.894648fF
C_7 gnd gnd 3.11336fF
Mp_1 vdd in2 net_1 vdd p W=1.56U L=0.15U AD=0.49608P PD=3.1829U AS=0.2496P 
+ PS=1.88U
Mp_2 net_1 in1 net_2 vdd p W=1.56U L=0.15U AD=0.2496P PD=1.88U AS=0.2496P 
+ PS=1.88U
Mp_3 net_2 in0 net_3 vdd p W=1.56U L=0.15U AD=0.2496P PD=1.88U AS=0.3432P 
+ PS=2U
Mp_4 net_3 in0 net_4 vdd p W=1.56U L=0.15U AD=0.3432P PD=2U AS=0.2496P 
+ PS=1.88U
Mp_5 net_4 in1 net_5 vdd p W=1.56U L=0.15U AD=0.2496P PD=1.88U AS=0.2496P 
+ PS=1.88U
Mp_6 net_5 in2 vdd vdd p W=1.56U L=0.15U AD=0.2496P PD=1.88U AS=0.49608P 
+ PS=3.1829U
Mp_7 vdd net_3 out vdd p W=1.54U L=0.15U AD=0.48972P PD=3.1421U AS=0.35035P 
+ PS=1.995U
Mp_8 out net_3 vdd vdd p W=1.54U L=0.15U AD=0.35035P PD=1.995U AS=0.48972P 
+ PS=3.1421U
Mn_1 net_3 in2 gnd gnd n W=0.52U L=0.15U AD=0.144733P PD=1.25U AS=0.174871P 
+ PS=1.41071U
Mn_2 gnd in1 net_3 gnd n W=0.52U L=0.15U AD=0.174871P PD=1.41071U 
+ AS=0.144733P PS=1.25U
Mn_3 net_3 in0 gnd gnd n W=0.52U L=0.15U AD=0.144733P PD=1.25U AS=0.174871P 
+ PS=1.41071U
Mn_4 gnd net_3 out gnd n W=0.77U L=0.15U AD=0.258944P PD=2.08894U 
+ AS=0.1694P PS=1.21U
Mn_5 out net_3 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.258944P 
+ PS=2.08894U
.ENDS	$ MMI_OR3C

.GLOBAL gnd vdd

