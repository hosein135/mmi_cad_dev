*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND4A in0 in1 in2 in3 out
C_1 vdd gnd 1.87262fF
C_2 in0 gnd 0.84182fF
C_3 out gnd 1.75085fF
C_4 in1 gnd 0.83637fF
C_5 in2 gnd 0.871997fF
C_6 in3 gnd 0.921725fF
C_7 gnd gnd 1.44626fF
Mp_1 vdd in0 out vdd p W=0.77U L=0.15U AD=0.236775P PD=1.77U AS=0.1694P 
+ PS=1.21U
Mp_2 out in1 vdd vdd p W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.236775P 
+ PS=1.77U
Mp_3 vdd in2 out vdd p W=0.77U L=0.15U AD=0.236775P PD=1.77U AS=0.1694P 
+ PS=1.21U
Mp_4 out in3 vdd vdd p W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.236775P 
+ PS=1.77U
Mn_1 out in0 net_1 gnd n W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.2464P 
+ PS=1.86U
Mn_2 net_1 in1 net_2 gnd n W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.2464P 
+ PS=1.86U
Mn_3 net_2 in2 net_3 gnd n W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.2464P 
+ PS=1.86U
Mn_4 net_3 in3 gnd gnd n W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.6083P 
+ PS=3.87U
.ENDS	$ MMI_NAND4A

.GLOBAL gnd vdd

