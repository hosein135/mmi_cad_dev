# cell name matches file name

function out = (in0 & in1) & in2

measure {out v} with {in0 v} {in1 1} {in2 1}
measure {out ^} with {in0 ^} {in1 1} {in2 1}

measure {out v} with {in0 1} {in1 v} {in2 1} 
measure {out ^} with {in0 1} {in1 ^} {in2 1} 

measure {out v} with {in0 1} {in1 1} {in2 v} 
measure {out ^} with {in0 1} {in1 1} {in2 ^} 

# measure the input capacitance
cap in0 with {in1 1} {in2 1}
cap in1 with {in0 1} {in2 1}
cap in2 with {in0 1} {in1 1}

