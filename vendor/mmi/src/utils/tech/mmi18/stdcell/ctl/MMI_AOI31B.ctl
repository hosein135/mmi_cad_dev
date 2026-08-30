# cell name matches file name

function out = !(in0 | ((in1 & in2) & in3))

measure {out v} with {in0 ^} {in1 1} {in2 1} {in3 0}
measure {out ^} with {in0 v} {in1 1} {in2 1} {in3 0}

measure {out v} with {in0 0} {in1 ^} {in2 1} {in3 1}
measure {out ^} with {in0 0} {in1 v} {in2 1} {in3 1}

measure {out v} with {in0 0} {in1 1} {in2 ^} {in3 1}
measure {out ^} with {in0 0} {in1 1} {in2 v} {in3 1}

measure {out v} with {in0 0} {in1 1} {in2 1} {in3 ^}
measure {out ^} with {in0 0} {in1 1} {in2 1} {in3 v}

# measure the input capacitance
cap in0 with {in1 0} {in2 0} {in3 1}
cap in1 with {in0 0} {in2 1} {in3 1}
cap in2 with {in0 0} {in1 1} {in3 1}
cap in3 with {in0 0} {in1 1} {in2 1}
