*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OR2C in0 in1 out
C_1 net_1 gnd 2.39139fF
C_2 in0 gnd 0.89758fF
C_3 in1 gnd 0.91171fF
C_4 vdd gnd 2.38172fF
C_5 out gnd 1.3989fF
C_6 gnd gnd 2.246fF
Mp_1 net_1 in0 net_2 vdd p W=2.48U L=0.18U AD=1.1904P PD=5.92U AS=0.31P 
+ PS=2.73U
Mp_2 net_2 in1 vdd vdd p W=2.48U L=0.18U AD=0.31P PD=2.73U AS=0.845455P 
+ PS=4.82312U
Mp_3 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.627273P PD=3.57844U 
+ AS=0.4968P PS=2.38U
Mp_4 out net_1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.627273P 
+ PS=3.57844U
Mn_1 gnd in0 net_1 gnd n W=0.62U L=0.18U AD=0.251422P PD=1.61442U 
+ AS=0.1674P PS=1.16U
Mn_2 net_1 in1 gnd gnd n W=0.62U L=0.18U AD=0.1674P PD=1.16U AS=0.251422P 
+ PS=1.61442U
Mn_3 gnd net_1 out gnd n W=1.84U L=0.18U AD=0.746156P PD=4.79117U 
+ AS=0.8832P PS=4.64U
.ENDS	$ MMI_OR2C

.GLOBAL gnd vdd

