*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AND3C in0 in1 in2 out
C_1 net_1 gnd 2.54347fF
C_2 in0 gnd 0.795015fF
C_3 vdd gnd 2.2368fF
C_4 in1 gnd 0.697445fF
C_5 in2 gnd 0.777195fF
C_6 out gnd 1.18294fF
C_7 gnd gnd 1.68618fF
Mp_1 net_1 in0 vdd vdd p W=1.04U L=0.15U AD=0.289467P PD=1.94333U 
+ AS=0.301768P PS=1.96761U
Mp_2 vdd in1 net_1 vdd p W=1.04U L=0.15U AD=0.301768P PD=1.96761U 
+ AS=0.289467P PS=1.94333U
Mp_3 net_1 in2 vdd vdd p W=1.04U L=0.15U AD=0.289467P PD=1.94333U 
+ AS=0.301768P PS=1.96761U
Mp_4 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.446848P PD=2.91358U 
+ AS=0.3388P PS=1.98U
Mp_5 out net_1 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.446848P 
+ PS=2.91358U
Mn_1 net_1 in0 net_2 gnd n W=1.56U L=0.15U AD=0.6162P PD=3.91U AS=0.2496P 
+ PS=1.88U
Mn_2 net_2 in1 net_3 gnd n W=1.56U L=0.15U AD=0.2496P PD=1.88U AS=0.2496P 
+ PS=1.88U
Mn_3 net_3 in2 gnd gnd n W=1.56U L=0.15U AD=0.2496P PD=1.88U AS=0.379835P 
+ PS=2.45574U
Mn_4 gnd net_1 out gnd n W=1.54U L=0.15U AD=0.374965P PD=2.42426U 
+ AS=0.6083P PS=3.87U
.ENDS	$ MMI_AND3C

.GLOBAL gnd vdd

