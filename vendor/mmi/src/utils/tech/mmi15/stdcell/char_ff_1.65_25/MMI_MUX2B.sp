*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUX2B in0 in1 out sel
C_1 net_1 gnd 2.12262fF
C_2 sel gnd 2.18684fF
C_3 vdd gnd 2.2966fF
C_4 in0 gnd 0.878235fF
C_5 net_2 gnd 1.1324fF
C_6 net_3 gnd 1.98676fF
C_7 net_4 gnd 1.02647fF
C_8 in1 gnd 0.97398fF
C_9 out gnd 1.07055fF
C_10 gnd gnd 1.90786fF
Mp_1 net_1 sel vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.1958P 
+ PS=1.37286U
Mp_2 vdd in0 net_2 vdd p W=1.54U L=0.15U AD=0.3916P PD=2.74571U AS=0.3773P 
+ PS=2.03U
Mp_3 net_2 sel net_3 vdd p W=1.54U L=0.15U AD=0.3773P PD=2.03U AS=0.37345P 
+ PS=2.025U
Mp_4 net_3 net_1 net_4 vdd p W=1.54U L=0.15U AD=0.37345P PD=2.025U 
+ AS=0.3773P PS=2.03U
Mp_5 net_4 in1 vdd vdd p W=1.54U L=0.15U AD=0.3773P PD=2.03U AS=0.3916P 
+ PS=2.74571U
Mp_6 vdd net_3 out vdd p W=1.54U L=0.15U AD=0.3916P PD=2.74571U AS=0.6083P 
+ PS=3.87U
Mn_1 net_1 sel gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.094875P PS=0.794286U
Mn_2 gnd in0 net_2 gnd n W=0.77U L=0.15U AD=0.18975P PD=1.58857U 
+ AS=0.18865P PS=1.26U
Mn_3 net_2 net_1 net_3 gnd n W=0.77U L=0.15U AD=0.18865P PD=1.26U 
+ AS=0.186725P PS=1.255U
Mn_4 net_3 sel net_4 gnd n W=0.77U L=0.15U AD=0.186725P PD=1.255U 
+ AS=0.175175P PS=1.225U
Mn_5 net_4 in1 gnd gnd n W=0.77U L=0.15U AD=0.175175P PD=1.225U AS=0.18975P 
+ PS=1.58857U
Mn_6 gnd net_3 out gnd n W=0.77U L=0.15U AD=0.18975P PD=1.58857U 
+ AS=0.30415P PS=2.33U
.ENDS	$ MMI_MUX2B

.GLOBAL gnd vdd

