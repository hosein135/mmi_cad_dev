*** Extracted spice netlist generated from MAX ***

.SUBCKT MMI_NAND3A in0 in1 in2 out
C_1 out gnd 1.57125fF
C_2 in0 gnd 0.89557fF
C_3 vdd gnd 1.72682fF
C_4 in1 gnd 0.96031fF
C_5 in2 gnd 1.0419fF
C_6 gnd gnd 1.72214fF
Mp_1 out in0 vdd vdd p W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.3128P 
+ PS=1.90667U
Mp_2 vdd in1 out vdd p W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.3128P 
+ PS=1.90667U
Mp_3 out in2 vdd vdd p W=0.92U L=0.18U AD=0.3128P PD=1.90667U AS=0.3128P 
+ PS=1.90667U
Mn_1 out in0 net_1 gnd n W=1.38U L=0.18U AD=0.6624P PD=3.72U AS=0.2691P 
+ PS=1.77U
Mn_2 net_1 in1 net_2 gnd n W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.2691P 
+ PS=1.77U
Mn_3 net_2 in2 gnd gnd n W=1.38U L=0.18U AD=0.2691P PD=1.77U AS=0.6624P 
+ PS=3.72U
.ENDS	$ MMI_NAND3A

.GLOBAL gnd vdd

