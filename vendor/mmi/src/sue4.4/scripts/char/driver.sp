.SUBCKT driver in out 
M_0 q in vdd vdd p W='20*1.0e-6' L=lp_min ad='areap(3.6,sdd)' 
+ as='areap(3.6,sdd)' pd='perip(3.6,sdd)' ps='perip(3.6,sdd)' 
M_1 q in gnd gnd n W='10*1.0e-6' L=ln_min ad='arean(1.8,sdd)' 
+ as='arean(1.8,sdd)' pd='perin(1.8,sdd)' ps='perin(1.8,sdd)' 
M_2 out q vdd vdd p W='60*1.0e-6' L=lp_min ad='areap(10.0,sdd)' 
+ as='areap(10.0,sdd)' pd='perip(10.0,sdd)' ps='perip(10.0,sdd)' 
M_3 out q gnd gnd n W='30*1.0e-6' L=ln_min ad='arean(5.0,sdd)' 
+ as='arean(5.0,sdd)' pd='perin(5.0,sdd)' ps='perin(5.0,sdd)' 
.ENDS


