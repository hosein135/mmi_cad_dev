*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_AO22C in0 in1 in2 in3 out
C_1 net_1 gnd 1.88031fF
C_2 in1 gnd 0.744207fF
C_3 net_2 gnd 2.44959fF
C_4 in0 gnd 0.696725fF
C_5 in2 gnd 0.705785fF
C_6 vdd gnd 2.99822fF
C_7 in3 gnd 0.783605fF
C_8 out gnd 0.980295fF
C_9 gnd gnd 2.98112fF
Mp_1 net_1 in1 net_2 vdd p W=2.08U L=0.15U AD=0.6526P PD=3.7475U AS=0.4576P 
+ PS=2.52U
Mp_2 net_2 in0 net_1 vdd p W=2.08U L=0.15U AD=0.4576P PD=2.52U AS=0.6526P 
+ PS=3.7475U
Mp_3 net_1 in2 vdd vdd p W=2.08U L=0.15U AD=0.6526P PD=3.7475U AS=0.612451P 
+ PS=3.6716U
Mp_4 vdd in3 net_1 vdd p W=2.08U L=0.15U AD=0.612451P PD=3.6716U AS=0.6526P 
+ PS=3.7475U
Mp_5 vdd net_2 out vdd p W=1.54U L=0.15U AD=0.453449P PD=2.7184U AS=0.3388P 
+ PS=1.98U
Mp_6 out net_2 vdd vdd p W=1.54U L=0.15U AD=0.3388P PD=1.98U AS=0.453449P 
+ PS=2.7184U
Mn_1 gnd in1 net_3 gnd n W=1.04U L=0.15U AD=0.4108P PD=2.98785U AS=0.1612P 
+ PS=1.35U
Mn_2 net_3 in0 net_2 gnd n W=1.04U L=0.15U AD=0.1612P PD=1.35U AS=0.2288P 
+ PS=1.48U
Mn_3 net_2 in2 net_4 gnd n W=1.04U L=0.15U AD=0.2288P PD=1.48U AS=0.1664P 
+ PS=1.36U
Mn_4 net_4 in3 gnd gnd n W=1.04U L=0.15U AD=0.1664P PD=1.36U AS=0.4108P 
+ PS=2.98785U
Mn_5 gnd net_2 out gnd n W=0.77U L=0.15U AD=0.30415P PD=2.21215U AS=0.1694P 
+ PS=1.21U
Mn_6 out net_2 gnd gnd n W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.30415P 
+ PS=2.21215U
.ENDS	$ MMI_AO22C

.GLOBAL gnd vdd

