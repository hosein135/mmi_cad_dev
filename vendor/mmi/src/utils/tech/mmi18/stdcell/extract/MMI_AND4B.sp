*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AND4B in0 in1 in2 in3 out
C_1 vdd gnd 2.88218fF
C_2 in0 gnd 0.8815fF
C_3 net_1 gnd 2.88266fF
C_4 in1 gnd 0.8279fF
C_5 in2 gnd 0.84388fF
C_6 in3 gnd 1.04206fF
C_7 out gnd 1.18604fF
C_8 gnd gnd 2.69615fF
Mp_1 vdd in0 net_1 vdd p W=0.92U L=0.18U AD=0.318933P PD=1.92U AS=0.2484P 
+ PS=1.46U
Mp_2 net_1 in1 vdd vdd p W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.318933P 
+ PS=1.92U
Mp_3 vdd in2 net_1 vdd p W=0.92U L=0.18U AD=0.318933P PD=1.92U AS=0.2484P 
+ PS=1.46U
Mp_4 net_1 in3 vdd vdd p W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.318933P 
+ PS=1.92U
Mp_5 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.637867P PD=3.84U AS=0.8832P 
+ PS=4.64U
Mn_1 net_1 in0 net_2 gnd n W=1.84U L=0.18U AD=0.8832P PD=4.64U AS=0.3588P 
+ PS=2.23U
Mn_2 net_2 in1 net_3 gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.3588P 
+ PS=2.23U
Mn_3 net_3 in2 net_4 gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.3588P 
+ PS=2.23U
Mn_4 net_4 in3 gnd gnd n W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.8832P 
+ PS=4.96U
Mn_5 gnd net_1 out gnd n W=0.92U L=0.18U AD=0.4416P PD=2.48U AS=0.4416P 
+ PS=2.8U
.ENDS	$ MMI_AND4B

.GLOBAL gnd vdd

