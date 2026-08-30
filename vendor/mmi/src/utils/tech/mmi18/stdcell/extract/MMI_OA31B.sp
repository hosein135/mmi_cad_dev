*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OA31B in0 in1 in2 in3 out
C_1 out gnd 1.10921fF
C_2 net_1 gnd 3.01964fF
C_3 vdd gnd 2.82074fF
C_4 in0 gnd 1.03081fF
C_5 in1 gnd 1.80886fF
C_6 in2 gnd 1.44641fF
C_7 in3 gnd 1.57859fF
C_8 gnd gnd 3.30746fF
C_9 net_6 gnd 0.72842fF
Mp_1 out net_1 vdd vdd p W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.573467P 
+ PS=3.21333U
Mp_2 vdd in0 net_1 vdd p W=0.92U L=0.18U AD=0.286733P PD=1.60667U 
+ AS=0.3542P PS=2.15U
Mp_3 net_1 in1 net_2 vdd p W=1.38U L=0.18U AD=0.5313P PD=3.225U AS=0.2691P 
+ PS=1.77U
Mp_4 net_2 in2 net_3 vdd p W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.2691P 
+ PS=1.77U
Mp_5 net_3 in3 vdd vdd p W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.4301P 
+ PS=2.41U
Mp_6 vdd in3 net_4 vdd p W=1.38U L=0.18U AD=0.4301P PD=2.41U AS=0.2691P 
+ PS=1.77U
Mp_7 net_4 in2 net_5 vdd p W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.2691P 
+ PS=1.77U
Mp_8 net_5 in1 net_1 vdd p W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.5313P 
+ PS=3.225U
Mn_1 out net_1 gnd gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.345P 
+ PS=2.13U
Mn_2 net_1 in0 net_6 gnd n W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.2484P 
+ PS=1.46U
Mn_3 net_6 in1 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.345P 
+ PS=2.13U
Mn_4 gnd in2 net_6 gnd n W=0.92U L=0.18U AD=0.345P PD=2.13U AS=0.2484P 
+ PS=1.46U
Mn_5 net_6 in3 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.345P 
+ PS=2.13U
.ENDS	$ MMI_OA31B

.GLOBAL gnd vdd

