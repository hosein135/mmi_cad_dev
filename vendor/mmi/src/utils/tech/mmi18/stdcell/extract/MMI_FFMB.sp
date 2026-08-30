*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_FFMB clk d0 d1 q sel
C_1 net_1 gnd 2.51894fF
C_2 sel gnd 2.68788fF
C_3 vdd gnd 7.1558fF
C_4 d0 gnd 0.9489fF
C_5 net_3 gnd 2.48281fF
C_6 d1 gnd 1.03895fF
C_7 clk gnd 4.67258fF
C_8 net_5 gnd 3.53454fF
C_9 net_6 gnd 5.26764fF
C_10 net_8 gnd 2.56827fF
C_11 net_9 gnd 2.77635fF
C_12 net_10 gnd 2.79679fF
C_13 q gnd 1.07537fF
C_14 gnd gnd 6.56123fF
Mp_1 net_1 sel vdd vdd p W=0.92U L=0.18U AD=0.4416P PD=2.8U AS=0.380316P 
+ PS=2.36414U
Mp_2 vdd sel net_2 vdd p W=1.84U L=0.18U AD=0.760631P PD=4.72829U 
+ AS=0.3588P PS=2.23U
Mp_3 net_2 d0 net_3 vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.57408P 
+ PS=3.024U
Mp_4 net_3 d1 net_4 vdd p W=1.84U L=0.18U AD=0.57408P PD=3.024U AS=0.3588P 
+ PS=2.23U
Mp_5 net_4 net_1 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.760631P 
+ PS=4.72829U
Mp_6 net_3 clk net_5 vdd p W=0.92U L=0.18U AD=0.28704P PD=1.512U 
+ AS=0.332024P PS=2.71881U
Mp_7 net_5 net_6 net_7 vdd p W=0.42U L=0.18U AD=0.151576P PD=1.24119U 
+ AS=0.0819P PS=0.81U
Mp_8 net_7 net_8 vdd vdd p W=0.42U L=0.18U AD=0.0819P PD=0.81U AS=0.173622P 
+ PS=1.07928U
Mp_9 vdd clk net_6 vdd p W=0.92U L=0.18U AD=0.380316P PD=2.36414U 
+ AS=0.4416P PS=2.8U
Mp_10 vdd net_5 net_8 vdd p W=0.92U L=0.18U AD=0.380316P PD=2.36414U 
+ AS=0.2484P PS=1.46U
Mp_11 net_8 net_6 net_9 vdd p W=0.92U L=0.18U AD=0.2484P PD=1.46U 
+ AS=0.4416P PS=3.15821U
Mp_12 vdd net_9 net_10 vdd p W=0.92U L=0.18U AD=0.380316P PD=2.36414U 
+ AS=0.4416P PS=2.8U
Mp_13 net_9 clk net_11 vdd p W=0.42U L=0.18U AD=0.2016P PD=1.44179U 
+ AS=0.0819P PS=0.81U
Mp_14 net_11 net_10 vdd vdd p W=0.42U L=0.18U AD=0.0819P PD=0.81U 
+ AS=0.173622P PS=1.07928U
Mp_15 vdd net_10 q vdd p W=1.84U L=0.18U AD=0.760631P PD=4.72829U 
+ AS=0.8832P PS=4.64U
Mn_1 net_5 net_6 net_3 gnd n W=0.42U L=0.18U AD=0.2016P PD=1.8U AS=0.20331P 
+ PS=1.03699U
Mn_2 net_9 net_6 net_12 gnd n W=0.42U L=0.18U AD=0.2016P PD=1.8U AS=0.0714P 
+ PS=0.76U
Mn_3 net_12 net_10 gnd gnd n W=0.42U L=0.18U AD=0.0714P PD=0.76U 
+ AS=0.16449P PS=1.386U
Mn_4 net_1 sel gnd gnd n W=0.46U L=0.18U AD=0.2208P PD=1.88U AS=0.180156P 
+ PS=1.518U
Mn_5 gnd net_1 net_13 gnd n W=0.92U L=0.18U AD=0.360311P PD=3.036U 
+ AS=0.1794P PS=1.31U
Mn_6 net_13 d0 net_3 gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.445345P 
+ PS=2.2715U
Mn_7 net_3 d1 net_14 gnd n W=0.92U L=0.18U AD=0.445345P PD=2.2715U 
+ AS=0.1886P PS=1.33U
Mn_8 net_14 sel gnd gnd n W=0.92U L=0.18U AD=0.1886P PD=1.33U AS=0.360311P 
+ PS=3.036U
Mn_9 gnd clk net_6 gnd n W=0.46U L=0.18U AD=0.180156P PD=1.518U AS=0.2208P 
+ PS=1.88U
Mn_10 net_5 clk net_15 gnd n W=0.42U L=0.18U AD=0.2016P PD=1.8U AS=0.0819P 
+ PS=0.81U
Mn_11 net_15 net_8 gnd gnd n W=0.42U L=0.18U AD=0.0819P PD=0.81U 
+ AS=0.16449P PS=1.386U
Mn_12 gnd net_5 net_8 gnd n W=0.46U L=0.18U AD=0.180156P PD=1.518U 
+ AS=0.137373P PS=1.58909U
Mn_13 net_8 clk net_9 gnd n W=0.42U L=0.18U AD=0.125427P PD=1.45091U 
+ AS=0.2016P PS=1.8U
Mn_14 gnd net_10 q gnd n W=0.92U L=0.18U AD=0.360311P PD=3.036U AS=0.4416P 
+ PS=2.8U
Mn_15 net_10 net_9 gnd gnd n W=0.62U L=0.18U AD=0.2976P PD=2.2U 
+ AS=0.242819P PS=2.046U
.ENDS	$ MMI_FFMB

.GLOBAL gnd vdd

