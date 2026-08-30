*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_LLCB clk clrb d q
C_1 net_1 gnd 1.91806fF
C_2 clk gnd 2.16175fF
C_3 vdd gnd 4.52984fF
C_4 d gnd 0.83151fF
C_5 net_2 gnd 1.36234fF
C_6 net_3 gnd 2.19096fF
C_7 net_5 gnd 2.55012fF
C_8 net_6 gnd 2.26405fF
C_9 net_8 gnd 1.13185fF
C_10 q gnd 0.806485fF
C_11 clrb gnd 0.620785fF
C_12 gnd gnd 4.2856fF
Mp_1 net_1 clk vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.261914P 
+ PS=2.145U
Mp_2 vdd d net_2 vdd p W=1.54U L=0.15U AD=0.523827P PD=4.29U AS=0.3388P 
+ PS=1.98U
Mp_3 net_2 clk net_3 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.527022P 
+ PS=3.9763U
Mp_4 net_3 net_1 net_4 vdd p W=0.35U L=0.15U AD=0.119778P PD=0.903704U 
+ AS=0.055125P PS=0.665U
Mp_5 net_4 net_5 vdd vdd p W=0.35U L=0.15U AD=0.055125P PD=0.665U 
+ AS=0.119052P PS=0.975U
Mp_6 vdd net_6 net_7 vdd p W=1.54U L=0.15U AD=0.523827P PD=4.29U AS=0.1694P 
+ PS=1.76U
Mp_7 net_7 net_3 net_5 vdd p W=1.54U L=0.15U AD=0.1694P PD=1.76U AS=0.6083P 
+ PS=3.87U
Mp_8 net_8 net_5 vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U 
+ AS=0.261914P PS=2.145U
Mp_9 vdd net_8 q vdd p W=1.54U L=0.15U AD=0.523827P PD=4.29U AS=0.6083P 
+ PS=3.87U
Mp_10 net_6 clrb vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U 
+ AS=0.261914P PS=2.145U
Mn_1 net_8 net_5 gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.141446P PS=1.5733U
Mn_2 net_1 clk gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.141446P PS=1.5733U
Mn_3 gnd d net_2 gnd n W=0.77U L=0.15U AD=0.282892P PD=3.14661U AS=0.1694P 
+ PS=1.21U
Mn_4 net_2 net_1 net_3 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U 
+ AS=0.234369P PS=2.8325U
Mn_5 net_3 clk net_9 gnd n W=0.35U L=0.15U AD=0.106531P PD=1.2875U 
+ AS=0.05425P PS=0.66U
Mn_6 net_9 net_5 gnd gnd n W=0.35U L=0.15U AD=0.05425P PD=0.66U 
+ AS=0.128587P PS=1.43028U
Mn_7 gnd net_6 net_5 gnd n W=0.385U L=0.15U AD=0.141446P PD=1.5733U 
+ AS=0.0847P PS=0.825U
Mn_8 net_5 net_3 gnd gnd n W=0.385U L=0.15U AD=0.0847P PD=0.825U 
+ AS=0.141446P PS=1.5733U
Mn_9 gnd net_8 q gnd n W=0.77U L=0.15U AD=0.282892P PD=3.14661U AS=0.30415P 
+ PS=2.33U
Mn_10 net_6 clrb gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.141446P PS=1.5733U
.ENDS	$ MMI_LLCB

.GLOBAL gnd vdd

