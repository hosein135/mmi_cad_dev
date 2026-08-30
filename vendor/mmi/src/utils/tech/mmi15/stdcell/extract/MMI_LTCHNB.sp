*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_LTCHNB clk d q
C_1 net_1 gnd 2.05169fF
C_2 clk gnd 2.2929fF
C_3 vdd gnd 3.03522fF
C_4 d gnd 0.89816fF
C_5 net_2 gnd 1.42989fF
C_6 net_3 gnd 2.73683fF
C_7 net_5 gnd 1.61526fF
C_8 q gnd 0.903195fF
C_9 gnd gnd 2.7981fF
Mp_1 net_1 clk vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.231976P 
+ PS=1.73211U
Mp_2 vdd d net_2 vdd p W=1.54U L=0.15U AD=0.463952P PD=3.46423U AS=0.3388P 
+ PS=1.98U
Mp_3 net_2 clk net_3 vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.527022P 
+ PS=3.9763U
Mp_4 net_3 net_1 net_4 vdd p W=0.35U L=0.15U AD=0.119778P PD=0.903704U 
+ AS=0.056P PS=0.67U
Mp_5 net_4 net_5 vdd vdd p W=0.35U L=0.15U AD=0.056P PD=0.67U AS=0.105444P 
+ PS=0.787324U
Mp_6 net_5 net_3 vdd vdd p W=0.77U L=0.15U AD=0.30415P PD=2.33U 
+ AS=0.231976P PS=1.73211U
Mp_7 vdd net_3 q vdd p W=1.54U L=0.15U AD=0.463952P PD=3.46423U AS=0.6083P 
+ PS=3.87U
Mn_1 net_1 clk gnd gnd n W=0.385U L=0.15U AD=0.152075P PD=1.56U 
+ AS=0.131294P PS=1.37066U
Mn_2 gnd d net_2 gnd n W=0.77U L=0.15U AD=0.262589P PD=2.74132U AS=0.1694P 
+ PS=1.21U
Mn_3 net_2 net_1 net_3 gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U 
+ AS=0.234369P PS=2.8325U
Mn_4 net_3 clk net_6 gnd n W=0.35U L=0.15U AD=0.106531P PD=1.2875U 
+ AS=0.055125P PS=0.665U
Mn_5 net_6 net_5 gnd gnd n W=0.35U L=0.15U AD=0.055125P PD=0.665U 
+ AS=0.119359P PS=1.24605U
Mn_6 gnd net_3 net_5 gnd n W=0.385U L=0.15U AD=0.131294P PD=1.37066U 
+ AS=0.152075P PS=1.56U
Mn_7 gnd net_3 q gnd n W=0.77U L=0.15U AD=0.262589P PD=2.74132U AS=0.30415P 
+ PS=2.33U
.ENDS	$ MMI_LTCHNB

.GLOBAL gnd vdd

