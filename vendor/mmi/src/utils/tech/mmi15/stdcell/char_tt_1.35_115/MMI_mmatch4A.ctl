# cell name matches file name

function mm_out = (in0 & in1) | (in0 & in2) | (in0 & in3) | (in1 & in2) | (in1 & in3) | (in2 & in3)

measure {mm_out ^} with {in0 ^} {in1 0} {in2 0} {in3 1}
measure {mm_out v} with {in0 v} {in1 0} {in2 0} {in3 1}

measure {mm_out ^} with {in0 1} {in1 ^} {in2 0} {in3 0} 
measure {mm_out v} with {in0 0} {in1 v} {in2 0} {in3 1}

measure {mm_out ^} with {in0 1} {in1 0} {in2 ^} {in3 0}
measure {mm_out v} with {in0 1} {in1 0} {in2 v} {in3 0}

measure {mm_out ^} with {in0 0} {in1 1} {in2 0} {in3 ^}
measure {mm_out v} with {in0 0} {in1 1} {in2 0} {in3 v} 

# measure the input capacitance
cap in0 with {in1 0} {in2 1} {in3 0}
cap in1 with {in0 0} {in2 1} {in3 0}
cap in2 with {in0 1} {in1 0} {in3 0}
cap in3 with {in0 0} {in1 0} {in2 1}
