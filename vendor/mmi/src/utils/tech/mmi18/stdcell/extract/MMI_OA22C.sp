*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_OA22C in0 in1 in2 in3 out
C_1 vdd gnd 3.98168fF
C_2 net_1 gnd 2.70502fF
C_3 out gnd 1.47602fF
C_4 in1 gnd 0.8966fF
C_5 in0 gnd 0.8325fF
C_6 in2 gnd 0.85895fF
C_7 in3 gnd 0.90473fF
C_8 gnd gnd 2.50514fF
C_9 net_4 gnd 1.41692fF
Mp_1 vdd net_1 out vdd p W=1.84U L=0.18U AD=0.8832P PD=4.49778U AS=0.4968P 
+ PS=2.38U
Mp_2 out net_1 vdd vdd p W=1.84U L=0.18U AD=0.4968P PD=2.38U AS=0.8832P 
+ PS=4.49778U
Mp_3 vdd in1 net_2 vdd p W=2.48U L=0.18U AD=1.1904P PD=6.06222U AS=0.4836P 
+ PS=2.87U
Mp_4 net_2 in0 net_1 vdd p W=2.48U L=0.18U AD=0.4836P PD=2.87U AS=0.6696P 
+ PS=3.02U
Mp_5 net_1 in2 net_3 vdd p W=2.48U L=0.18U AD=0.6696P PD=3.02U AS=0.4836P 
+ PS=2.87U
Mp_6 net_3 in3 vdd vdd p W=2.48U L=0.18U AD=0.4836P PD=2.87U AS=1.1904P 
+ PS=6.06222U
Mn_1 gnd net_1 out gnd n W=1.84U L=0.18U AD=0.661378P PD=3.49259U 
+ AS=0.8832P PS=4.64U
Mn_2 net_4 in1 net_1 gnd n W=1.24U L=0.18U AD=0.465P PD=2.61U AS=0.3348P 
+ PS=1.78U
Mn_3 net_1 in0 net_4 gnd n W=1.24U L=0.18U AD=0.3348P PD=1.78U AS=0.465P 
+ PS=2.61U
Mn_4 net_4 in2 gnd gnd n W=1.24U L=0.18U AD=0.465P PD=2.61U AS=0.445711P 
+ PS=2.3537U
Mn_5 gnd in3 net_4 gnd n W=1.24U L=0.18U AD=0.445711P PD=2.3537U AS=0.465P 
+ PS=2.61U
.ENDS	$ MMI_OA22C

.GLOBAL gnd vdd

