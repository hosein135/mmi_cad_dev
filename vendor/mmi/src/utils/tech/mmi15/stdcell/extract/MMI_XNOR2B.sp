*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_XNOR2B in0 in1 out
C_1 out gnd 1.86203fF
C_2 net_1 gnd 2.1311fF
C_3 vdd gnd 2.44822fF
C_4 in0 gnd 2.0907fF
C_5 in1 gnd 2.12634fF
C_6 net_4 gnd 0.94142fF
C_7 gnd gnd 2.0686fF
Mp_1 out net_1 vdd vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.4158P 
+ PS=2.9825U
Mp_2 vdd in0 net_2 vdd p W=1.54U L=0.15U AD=0.4158P PD=2.9825U AS=0.24255P 
+ PS=1.855U
Mp_3 net_2 in1 out vdd p W=1.54U L=0.15U AD=0.24255P PD=1.855U AS=0.428633P 
+ PS=2.61U
Mp_4 out in1 net_3 vdd p W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.2464P 
+ PS=1.86U
Mp_5 net_3 in0 vdd vdd p W=1.54U L=0.15U AD=0.2464P PD=1.86U AS=0.4158P 
+ PS=2.9825U
Mp_6 vdd in0 net_1 vdd p W=0.77U L=0.15U AD=0.2079P PD=1.49125U AS=0.1694P 
+ PS=1.21U
Mp_7 net_1 in1 vdd vdd p W=0.77U L=0.15U AD=0.1694P PD=1.21U AS=0.2079P 
+ PS=1.49125U
Mn_1 out net_1 net_4 gnd n W=1.54U L=0.15U AD=0.6083P PD=3.87U AS=0.428633P 
+ PS=2.61U
Mn_2 net_4 in1 gnd gnd n W=1.54U L=0.15U AD=0.428633P PD=2.61U AS=0.3927P 
+ PS=2.516U
Mn_3 gnd in0 net_4 gnd n W=1.54U L=0.15U AD=0.3927P PD=2.516U AS=0.428633P 
+ PS=2.61U
Mn_4 net_1 in0 net_5 gnd n W=0.77U L=0.15U AD=0.30415P PD=2.33U AS=0.1232P 
+ PS=1.09U
Mn_5 net_5 in1 gnd gnd n W=0.77U L=0.15U AD=0.1232P PD=1.09U AS=0.19635P 
+ PS=1.258U
.ENDS	$ MMI_XNOR2B

.GLOBAL gnd vdd

