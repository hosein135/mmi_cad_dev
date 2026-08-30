*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AOI22A in0 in1 in2 in3 out
C_1 vdd gnd 1.91252fF
C_2 in2 gnd 1.74048fF
C_3 net_1 gnd 0.951925fF
C_4 in1 gnd 0.982927fF
C_5 out gnd 0.996185fF
C_6 in0 gnd 0.90337fF
C_7 in3 gnd 0.821057fF
C_8 gnd gnd 1.66856fF
Mp_1 vdd in2 net_1 vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.35035P 
+ PS=1.995U
Mp_2 net_1 in1 out vdd p W=1.54U L=0.15U AD=0.35035P PD=1.995U AS=0.3465P 
+ PS=1.99U
Mp_3 out in0 net_1 vdd p W=1.54U L=0.15U AD=0.3465P PD=1.99U AS=0.35035P 
+ PS=1.995U
Mp_4 net_1 in3 vdd vdd p W=1.54U L=0.15U AD=0.35035P PD=1.995U AS=0.6083P 
+ PS=3.87U
Mn_1 gnd in1 net_2 gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.1232P 
+ PS=1.09U
Mn_2 net_2 in0 out gnd n W=0.77U L=0.15U AD=0.1232P PD=1.09U AS=0.175175P 
+ PS=1.225U
Mn_3 out in2 net_3 gnd n W=0.77U L=0.15U AD=0.175175P PD=1.225U AS=0.1232P 
+ PS=1.09U
Mn_4 net_3 in3 gnd gnd n W=0.77U L=0.15U AD=0.1232P PD=1.09U AS=0.30415P 
+ PS=2.33U
.ENDS	$ MMI_AOI22A

.GLOBAL gnd vdd

