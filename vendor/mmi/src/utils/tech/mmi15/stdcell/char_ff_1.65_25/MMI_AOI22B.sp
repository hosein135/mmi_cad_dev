*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AOI22B in0 in1 in2 in3 out
C_1 vdd gnd 3.16062fF
C_2 in2 gnd 1.91845fF
C_3 net_1 gnd 2.05178fF
C_4 in0 gnd 1.20238fF
C_5 out gnd 2.70001fF
C_6 in3 gnd 1.5788fF
C_7 in1 gnd 2.07407fF
C_8 gnd gnd 2.61114fF
Mp_1 vdd in2 net_1 vdd p W=1.54U L=0.15U AD=0.479325P PD=2.9325U AS=0.3465P 
+ PS=1.99U
Mp_2 net_1 in0 out vdd p W=1.54U L=0.15U AD=0.3465P PD=1.99U AS=0.3388P 
+ PS=1.98U
Mp_3 out in0 net_1 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.3465P 
+ PS=1.99U
Mp_4 net_1 in2 vdd vdd p W=1.54U L=0.15U AD=0.3465P PD=1.99U AS=0.479325P 
+ PS=2.9325U
Mp_5 vdd in3 net_1 vdd p W=1.54U L=0.15U AD=0.479325P PD=2.9325U AS=0.3465P 
+ PS=1.99U
Mp_6 net_1 in1 out vdd p W=1.54U L=0.15U AD=0.3465P PD=1.99U AS=0.3388P 
+ PS=1.98U
Mp_7 out in1 net_1 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.3465P 
+ PS=1.99U
Mp_8 net_1 in3 vdd vdd p W=1.54U L=0.15U AD=0.3465P PD=1.99U AS=0.479325P 
+ PS=2.9325U
Mn_1 gnd in1 net_2 gnd n W=0.77U L=0.15U AD=0.236775P PD=1.77U AS=0.1232P 
+ PS=1.09U
Mn_2 net_2 in0 out gnd n W=0.77U L=0.15U AD=0.1232P PD=1.09U AS=0.236775P 
+ PS=1.77U
Mn_3 out in0 net_3 gnd n W=0.77U L=0.15U AD=0.236775P PD=1.77U AS=0.1232P 
+ PS=1.09U
Mn_4 net_3 in1 gnd gnd n W=0.77U L=0.15U AD=0.1232P PD=1.09U AS=0.236775P 
+ PS=1.77U
Mn_5 out in2 net_4 gnd n W=0.77U L=0.15U AD=0.236775P PD=1.77U AS=0.1232P 
+ PS=1.09U
Mn_6 net_4 in3 gnd gnd n W=0.77U L=0.15U AD=0.1232P PD=1.09U AS=0.236775P 
+ PS=1.77U
Mn_7 gnd in3 net_5 gnd n W=0.77U L=0.15U AD=0.236775P PD=1.77U AS=0.1232P 
+ PS=1.09U
Mn_8 net_5 in2 out gnd n W=0.77U L=0.15U AD=0.1232P PD=1.09U AS=0.236775P 
+ PS=1.77U
.ENDS	$ MMI_AOI22B

.GLOBAL gnd vdd

