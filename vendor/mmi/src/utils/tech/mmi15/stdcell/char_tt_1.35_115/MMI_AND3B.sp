*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AND3B in0 in1 in2 out
C_1 net_1 gnd 2.18628fF
C_2 in0 gnd 0.761017fF
C_3 vdd gnd 1.74608fF
C_4 in1 gnd 0.716635fF
C_5 in2 gnd 0.83759fF
C_6 out gnd 1.04714fF
C_7 gnd gnd 1.5101fF
Mp_1 net_1 in0 vdd vdd p W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.2079P PS=1.464U
Mp_2 vdd in1 net_1 vdd p W=0.77U L=0.15U AD=0.2079P PD=1.464U AS=0.214317P 
+ PS=1.58333U
Mp_3 net_1 in2 vdd vdd p W=0.77U L=0.15U AD=0.214317P PD=1.58333U 
+ AS=0.2079P PS=1.464U
Mp_4 vdd net_1 out vdd p W=1.54U L=0.15U AD=0.4158P PD=2.928U AS=0.6083P 
+ PS=3.87U
Mn_1 net_1 in0 net_2 gnd n W=1.155U L=0.15U AD=0.456225P PD=3.1U AS=0.1848P 
+ PS=1.475U
Mn_2 net_2 in1 net_3 gnd n W=1.155U L=0.15U AD=0.1848P PD=1.475U AS=0.1848P 
+ PS=1.475U
Mn_3 net_3 in2 gnd gnd n W=1.155U L=0.15U AD=0.1848P PD=1.475U AS=0.315315P 
+ PS=2.442U
Mn_4 gnd net_1 out gnd n W=0.77U L=0.15U AD=0.21021P PD=1.628U AS=0.30415P 
+ PS=2.33U
.ENDS	$ MMI_AND3B

.GLOBAL gnd vdd

