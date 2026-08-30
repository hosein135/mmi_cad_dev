*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_SFFSB clk d q s_en s_in s_out setb
C_1 net_1 gnd 2.59839fF
C_2 s_en gnd 6.35288fF
C_3 vdd gnd 9.24977fF
C_4 d gnd 1.21348fF
C_5 net_3 gnd 3.31885fF
C_6 s_in gnd 1.34945fF
C_7 clk gnd 6.81542fF
C_8 net_5 gnd 6.03297fF
C_9 net_6 gnd 2.69976fF
C_10 net_8 gnd 3.6916fF
C_11 setb gnd 2.25655fF
C_12 net_9 gnd 3.52155fF
C_13 net_10 gnd 3.16788fF
C_14 net_11 gnd 5.555fF
C_15 s_out gnd 1.1889fF
C_16 q gnd 1.36878fF
C_17 gnd gnd 8.42863fF
Mp_1 net_1 s_en vdd vdd p W=1.2U L=0.18U AD=0.576P PD=3.36U AS=0.413439P 
+ PS=2.69235U
Mp_2 vdd s_en net_2 vdd p W=1.84U L=0.18U AD=0.63394P PD=4.12827U 
+ AS=0.3588P PS=2.23U
Mp_3 net_2 d net_3 vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U AS=0.7084P 
+ PS=4.3U
Mp_4 net_3 net_1 net_4 vdd p W=0.92U L=0.18U AD=0.3542P PD=2.15U AS=0.1794P 
+ PS=1.31U
Mp_5 net_4 s_in vdd vdd p W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.31697P 
+ PS=2.06414U
Mp_6 vdd clk net_5 vdd p W=0.92U L=0.18U AD=0.31697P PD=2.06414U AS=0.4416P 
+ PS=2.8U
Mp_7 net_3 clk net_6 vdd p W=0.92U L=0.18U AD=0.3542P PD=2.15U AS=0.332024P 
+ PS=2.71881U
Mp_8 net_6 net_5 net_7 vdd p W=0.42U L=0.18U AD=0.151576P PD=1.24119U 
+ AS=0.0819P PS=0.81U
Mp_9 net_7 net_8 vdd vdd p W=0.42U L=0.18U AD=0.0819P PD=0.81U AS=0.144704P 
+ PS=0.942323U
Mp_10 vdd net_6 net_8 vdd p W=0.92U L=0.18U AD=0.31697P PD=2.06414U 
+ AS=0.3128P PS=1.90667U
Mp_11 net_8 setb vdd vdd p W=0.92U L=0.18U AD=0.3128P PD=1.90667U 
+ AS=0.31697P PS=2.06414U
Mp_12 vdd setb net_9 vdd p W=1.2U L=0.18U AD=0.413439P PD=2.69235U 
+ AS=0.576P PS=3.36U
Mp_13 net_8 net_5 net_10 vdd p W=0.92U L=0.18U AD=0.3128P PD=1.90667U 
+ AS=0.4416P PS=3.15821U
Mp_14 net_11 net_10 net_12 vdd p W=1.84U L=0.18U AD=0.8824P PD=5.28U 
+ AS=0.3588P PS=2.23U
Mp_15 net_12 net_9 vdd vdd p W=1.84U L=0.18U AD=0.3588P PD=2.23U 
+ AS=0.63394P PS=4.12827U
Mp_16 net_10 clk net_13 vdd p W=0.42U L=0.18U AD=0.2016P PD=1.44179U 
+ AS=0.0819P PS=0.81U
Mp_17 net_13 net_11 vdd vdd p W=0.42U L=0.18U AD=0.0819P PD=0.81U 
+ AS=0.144704P PS=0.942323U
Mp_18 vdd net_11 s_out vdd p W=0.84U L=0.18U AD=0.289407P PD=1.88465U 
+ AS=0.2268P PS=1.38U
Mp_19 s_out s_en vdd vdd p W=0.84U L=0.18U AD=0.2268P PD=1.38U AS=0.289407P 
+ PS=1.88465U
Mp_20 vdd net_11 q vdd p W=1.84U L=0.18U AD=0.63394P PD=4.12827U AS=0.8832P 
+ PS=4.64U
Mn_1 net_1 s_en gnd gnd n W=0.6U L=0.18U AD=0.288P PD=2.16U AS=0.216277P 
+ PS=1.62769U
Mn_2 net_3 d net_14 gnd n W=0.92U L=0.18U AD=0.4416P PD=3.312U AS=0.1794P 
+ PS=1.31U
Mn_3 net_14 net_1 gnd gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U 
+ AS=0.331625P PS=2.49579U
Mn_4 net_3 net_5 net_6 gnd n W=0.42U L=0.18U AD=0.2016P PD=1.512U 
+ AS=0.2016P PS=1.8U
Mn_5 net_8 net_6 net_15 gnd n W=0.92U L=0.18U AD=0.4416P PD=3.15821U 
+ AS=0.1794P PS=1.31U
Mn_6 net_15 setb gnd gnd n W=0.92U L=0.18U AD=0.1794P PD=1.31U AS=0.331625P 
+ PS=2.49579U
Mn_7 net_10 net_5 net_16 gnd n W=0.42U L=0.18U AD=0.2016P PD=1.8U 
+ AS=0.0819P PS=0.81U
Mn_8 net_16 net_11 gnd gnd n W=0.42U L=0.18U AD=0.0819P PD=0.81U 
+ AS=0.151394P PS=1.13938U
Mn_9 net_8 clk net_10 gnd n W=0.42U L=0.18U AD=0.2016P PD=1.44179U 
+ AS=0.2016P PS=1.8U
Mn_10 net_3 s_en net_17 gnd n W=0.46U L=0.18U AD=0.2208P PD=1.656U 
+ AS=0.0897P PS=0.85U
Mn_11 net_17 s_in gnd gnd n W=0.46U L=0.18U AD=0.0897P PD=0.85U 
+ AS=0.165812P PS=1.2479U
Mn_12 gnd clk net_5 gnd n W=0.46U L=0.18U AD=0.165812P PD=1.2479U 
+ AS=0.2208P PS=1.88U
Mn_13 net_6 clk net_18 gnd n W=0.42U L=0.18U AD=0.2016P PD=1.8U AS=0.0819P 
+ PS=0.81U
Mn_14 net_18 net_8 gnd gnd n W=0.42U L=0.18U AD=0.0819P PD=0.81U 
+ AS=0.151394P PS=1.13938U
Mn_15 gnd setb net_9 gnd n W=0.6U L=0.18U AD=0.216277P PD=1.62769U 
+ AS=0.288P PS=2.16U
Mn_16 net_11 net_9 gnd gnd n W=0.62U L=0.18U AD=0.2976P PD=2.2U 
+ AS=0.223486P PS=1.68195U
Mn_17 gnd net_10 net_11 gnd n W=0.62U L=0.18U AD=0.223486P PD=1.68195U 
+ AS=0.2976P PS=2.2U
Mn_18 s_out net_11 net_19 gnd n W=0.84U L=0.18U AD=0.4032P PD=2.64U 
+ AS=0.1638P PS=1.23U
Mn_19 net_19 s_en gnd gnd n W=0.84U L=0.18U AD=0.1638P PD=1.23U 
+ AS=0.302788P PS=2.27877U
Mn_20 gnd net_11 q gnd n W=0.92U L=0.18U AD=0.331625P PD=2.49579U 
+ AS=0.4416P PS=2.8U
.ENDS	$ MMI_SFFSB

.GLOBAL gnd vdd

