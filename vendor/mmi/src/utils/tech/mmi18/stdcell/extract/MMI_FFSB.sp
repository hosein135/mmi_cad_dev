*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_FFSB clk d q setb
C_1 vdd gnd 7.28047fF
C_2 d gnd 0.77235fF
C_3 net_1 gnd 1.62142fF
C_4 clk gnd 4.75229fF
C_5 net_2 gnd 4.40918fF
C_6 net_3 gnd 2.28108fF
C_7 net_5 gnd 3.60911fF
C_8 setb gnd 1.8605fF
C_9 net_6 gnd 3.8223fF
C_10 net_7 gnd 2.41761fF
C_11 net_9 gnd 3.70482fF
C_12 q gnd 1.09526fF
C_13 gnd gnd 6.7602fF
Mp_1 vdd d net_1 vdd p W=1.84U L=0.18U AD=0.762744P PD=4.97798U AS=0.8832P 
+ PS=4.96U
Mp_2 vdd clk net_2 vdd p W=0.92U L=0.18U AD=0.381372P PD=2.48899U 
+ AS=0.4416P PS=2.8U
Mp_3 net_1 clk net_3 vdd p W=0.92U L=0.18U AD=0.4416P PD=2.48U AS=0.394021P 
+ PS=3.01403U
Mp_4 net_3 net_2 net_4 vdd p W=0.42U L=0.18U AD=0.179879P PD=1.37597U 
+ AS=0.0735P PS=0.77U
Mp_5 net_4 net_5 vdd vdd p W=0.42U L=0.18U AD=0.0735P PD=0.77U AS=0.174105P 
+ PS=1.13628U
Mp_6 vdd net_3 net_5 vdd p W=0.92U L=0.18U AD=0.381372P PD=2.48899U 
+ AS=0.3128P PS=1.90667U
Mp_7 net_5 setb vdd vdd p W=0.92U L=0.18U AD=0.3128P PD=1.90667U 
+ AS=0.381372P PS=2.48899U
Mp_8 vdd setb net_6 vdd p W=1.2U L=0.18U AD=0.497442P PD=3.24651U AS=0.576P 
+ PS=3.36U
Mp_9 net_5 net_2 net_7 vdd p W=0.92U L=0.18U AD=0.3128P PD=1.90667U 
+ AS=0.378161P PS=2.93851U
Mp_10 net_7 clk net_8 vdd p W=0.42U L=0.18U AD=0.172639P PD=1.34149U 
+ AS=0.0966P PS=0.88U
Mp_11 net_8 net_9 vdd vdd p W=0.42U L=0.18U AD=0.0966P PD=0.88U 
+ AS=0.174105P PS=1.13628U
Mp_12 vdd net_6 net_10 vdd p W=1.84U L=0.18U AD=0.762744P PD=4.97798U 
+ AS=0.3588P PS=2.23U
Mp_13 net_10 net_7 net_9 vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U 
+ AS=0.8832P PS=4.64U
Mp_14 vdd net_9 q vdd p W=1.84U L=0.18U AD=0.762744P PD=4.97798U AS=0.8832P 
+ PS=4.64U
Mn_1 gnd d net_1 gnd n W=0.92U L=0.18U AD=0.376108P PD=2.76312U AS=0.4416P 
+ PS=3.15821U
Mn_2 net_1 net_2 net_3 gnd n W=0.42U L=0.18U AD=0.2016P PD=1.44179U 
+ AS=0.2016P PS=1.8U
Mn_3 net_5 net_3 net_11 gnd n W=0.92U L=0.18U AD=0.4416P PD=3.15821U 
+ AS=0.1794P PS=1.31U
Mn_4 net_11 setb gnd gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.376108P 
+ PS=2.76312U
Mn_5 net_5 clk net_7 gnd n W=0.42U L=0.18U AD=0.2016P PD=1.44179U 
+ AS=0.12075P PS=0.995U
Mn_6 net_7 net_2 net_12 gnd n W=0.42U L=0.18U AD=0.12075P PD=0.995U 
+ AS=0.0819P PS=0.81U
Mn_7 net_12 net_9 gnd gnd n W=0.42U L=0.18U AD=0.0819P PD=0.81U 
+ AS=0.171702P PS=1.26142U
Mn_8 gnd net_9 q gnd n W=0.92U L=0.18U AD=0.376108P PD=2.76312U AS=0.4416P 
+ PS=2.8U
Mn_9 gnd clk net_2 gnd n W=0.46U L=0.18U AD=0.188054P PD=1.38156U 
+ AS=0.2208P PS=1.88U
Mn_10 net_3 clk net_13 gnd n W=0.42U L=0.18U AD=0.2016P PD=1.8U AS=0.0819P 
+ PS=0.81U
Mn_11 net_13 net_5 gnd gnd n W=0.42U L=0.18U AD=0.0819P PD=0.81U 
+ AS=0.171702P PS=1.26142U
Mn_12 gnd setb net_6 gnd n W=0.6U L=0.18U AD=0.245288P PD=1.80203U 
+ AS=0.288P PS=2.16U
Mn_13 net_9 net_6 gnd gnd n W=0.62U L=0.18U AD=0.2976P PD=2.2U AS=0.253464P 
+ PS=1.8621U
Mn_14 gnd net_7 net_9 gnd n W=0.62U L=0.18U AD=0.253464P PD=1.8621U 
+ AS=0.2976P PS=2.2U
.ENDS	$ MMI_FFSB

.GLOBAL gnd vdd

