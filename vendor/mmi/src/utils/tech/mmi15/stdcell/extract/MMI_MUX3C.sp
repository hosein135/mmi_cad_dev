*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_MUX3C in0 in1 in2 out sel0 sel1
C_1 net_1 gnd 2.14256fF
C_2 in0 gnd 0.669075fF
C_3 vdd gnd 4.38924fF
C_4 in1 gnd 0.664585fF
C_5 net_2 gnd 0.64784fF
C_6 net_3 gnd 1.51929fF
C_7 net_4 gnd 2.20331fF
C_8 sel0 gnd 1.91999fF
C_9 sel1 gnd 2.65361fF
C_10 net_5 gnd 3.19373fF
C_11 net_6 gnd 1.89046fF
C_12 net_7 gnd 1.17842fF
C_13 in2 gnd 1.00996fF
C_14 out gnd 1.04212fF
C_15 gnd gnd 4.43187fF
Mp_1 net_1 in0 vdd vdd p W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.479967P 
+ PS=3.14667U
Mp_2 vdd in1 net_2 vdd p W=1.54U L=0.15U AD=0.479967P PD=3.14667U 
+ AS=0.3388P PS=1.98U
Mp_3 net_2 net_3 net_4 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.4389P 
+ PS=2.62333U
Mp_4 net_4 sel0 net_1 vdd p W=1.54U L=0.15U AD=0.4389P PD=2.62333U 
+ AS=0.6083P PS=3.87U
Mp_5 net_3 sel0 vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.239983P 
+ PS=1.57333U
Mp_6 net_4 sel1 net_5 vdd p W=1.54U L=0.15U AD=0.4389P PD=2.62333U 
+ AS=0.3388P PS=1.98U
Mp_7 net_5 net_6 net_7 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U 
+ AS=0.35035P PS=1.995U
Mp_8 net_7 in2 vdd vdd p W=1.54U L=0.15U AD=0.35035P PD=1.995U AS=0.479967P 
+ PS=3.14667U
Mp_9 vdd sel1 net_6 vdd p W=0.77U L=0.15U AD=0.239983P PD=1.57333U 
+ AS=0.25515P PS=3.43U
Mp_10 vdd net_5 out vdd p W=1.54U L=0.15U AD=0.479967P PD=3.14667U 
+ AS=0.3388P PS=1.98U
Mp_11 out net_5 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.479967P 
+ PS=3.14667U
Mn_1 net_1 in0 gnd gnd n W=0.77U L=0.15U AD=0.280525P PD=2.885U 
+ AS=0.260487P PS=2.225U
Mn_2 gnd in1 net_2 gnd n W=0.77U L=0.15U AD=0.260487P PD=2.225U AS=0.1694P 
+ PS=1.21U
Mn_3 net_2 sel0 net_4 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U 
+ AS=0.214317P PS=1.58333U
Mn_4 net_4 net_3 net_1 gnd n W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.280525P PS=2.885U
Mn_5 net_3 sel0 gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.130244P PS=1.1125U
Mn_6 net_4 net_6 net_5 gnd n W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.1694P PS=1.21U
Mn_7 net_5 sel1 net_7 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.1694P 
+ PS=1.21U
Mn_8 net_7 in2 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.260488P 
+ PS=2.225U
Mn_9 gnd sel1 net_6 gnd n W=0.385U L=0.15U AD=0.130244P PD=1.1125U 
+ AS=0.152075P PS=1.56U
Mn_10 gnd net_5 out gnd n W=0.77U L=0.15U AD=0.260487P PD=2.225U AS=0.1694P 
+ PS=1.21U
Mn_11 out net_5 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.260487P 
+ PS=2.225U
.ENDS	$ MMI_MUX3C

.GLOBAL gnd vdd

