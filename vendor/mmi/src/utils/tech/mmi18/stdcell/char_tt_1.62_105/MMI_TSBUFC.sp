*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_TSBUFC en enb in out
C_1 net_1 gnd 2.49272fF
C_2 enb gnd 0.93263fF
C_3 net_2 gnd 2.40773fF
C_4 in gnd 0.92443fF
C_5 vdd gnd 3.46454fF
C_6 en gnd 1.20025fF
C_7 out gnd 1.1594fF
C_8 gnd gnd 3.13343fF
Mp_1 net_1 enb net_2 vdd p W=0.84U L=0.18U AD=0.4032P PD=2.64U AS=0.3234P 
+ PS=2.03U
Mp_2 net_2 in vdd vdd p W=1.68U L=0.18U AD=0.6468P PD=4.06U AS=0.719907P 
+ PS=3.99948U
Mp_3 vdd en net_2 vdd p W=0.84U L=0.18U AD=0.359954P PD=1.99974U AS=0.3234P 
+ PS=2.03U
Mp_4 vdd net_2 out vdd p W=1.84U L=0.18U AD=0.78847P PD=4.38039U AS=0.4968P 
+ PS=2.38U
Mp_5 out net_2 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.78847P 
+ PS=4.38039U
Mn_1 net_1 enb gnd gnd n W=0.42U L=0.18U AD=0.1617P PD=1.4U AS=0.179977P 
+ PS=1.27355U
Mn_2 gnd in net_1 gnd n W=0.84U L=0.18U AD=0.359954P PD=2.5471U AS=0.3234P 
+ PS=2.8U
Mn_3 net_1 en net_2 gnd n W=0.42U L=0.18U AD=0.1617P PD=1.4U AS=0.2016P 
+ PS=1.8U
Mn_4 gnd net_1 out gnd n W=0.92U L=0.18U AD=0.394235P PD=2.78968U 
+ AS=0.2484P PS=1.46U
Mn_5 out net_1 gnd gnd n W=0.92U L=0.18U AD=0.2484P PD=1.46U AS=0.394235P 
+ PS=2.78968U
.ENDS	$ MMI_TSBUFC

.GLOBAL gnd vdd

