# cell name matches file name

function out = !(in0 | !in1)

measure {out v} with {in0 ^} {in1 1} 
measure {out ^} with {in0 v} {in1 1} 

measure {out v} with {in0 0} {in1 v} 
measure {out ^} with {in0 0} {in1 ^} 

# measure the input capacitance
cap in0 with {in1 1}
cap in1 with {in0 0}


