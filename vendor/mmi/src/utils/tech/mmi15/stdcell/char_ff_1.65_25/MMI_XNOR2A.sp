*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_XNOR2A in0 in1 out
C_1 vdd gnd 2.66658fF
C_2 in0 gnd 2.09097fF
C_3 net_1 gnd 1.78823fF
C_4 in1 gnd 1.77677fF
C_5 out gnd 0.759737fF
C_6 net_3 gnd 0.6131fF
C_7 gnd gnd 1.91472fF
Mp_1 vdd in0 net_1 vdd p W=0.77U L=0.15U AD=0.25256P PD=1.73U AS=0.1694P 
+ PS=1.21U
Mp_2 net_1 in1 vdd vdd p W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.25256P 
+ PS=1.73U
Mp_3 vdd net_1 out vdd p W=0.77U L=0.15U AD=0.25256P PD=1.73U AS=0.22715P 
+ PS=1.88U
Mp_4 out in1 net_2 vdd p W=1.54U L=0.15U AD=0.4543P PD=3.76U AS=0.24255P 
+ PS=1.855U
Mp_5 net_2 in0 vdd vdd p W=1.54U L=0.15U AD=0.24255P PD=1.855U AS=0.50512P 
+ PS=3.46U
Mn_1 out net_1 net_3 gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U 
+ AS=0.214317P PS=1.58333U
Mn_2 net_1 in0 net_4 gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.1232P 
+ PS=1.09U
Mn_3 net_4 in1 gnd gnd n W=0.77U L=0.15U AD=0.1232P PD=1.09U AS=0.214317P 
+ PS=1.58333U
Mn_4 net_3 in1 gnd gnd n W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.214317P PS=1.58333U
Mn_5 gnd in0 net_3 gnd n W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.214317P PS=1.58333U
.ENDS	$ MMI_XNOR2A

.GLOBAL gnd vdd

