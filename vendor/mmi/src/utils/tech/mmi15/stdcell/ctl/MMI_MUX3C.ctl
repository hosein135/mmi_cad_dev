# cell name matches file name

function out = !sel0 & in0 & in2 | sel0 & in1 & in2 | ((sel1 & in2) | ((in0 & in1) & in2)) | (!sel1 & ((sel0 & in1) | (!sel0 & in0) | (in0 & in1)))

measure {out v} with {sel0 0} {sel1 0} {in0 v} {in1 0} {in2 1}
measure {out ^} with {sel0 0} {sel1 0} {in0 ^} {in1 0} {in2 1}

# measure late arriving sel0 rise
measure {out v} with {sel0 ^} {sel1 0} {in0 1} {in1 0} {in2 1}

measure {out ^} with {sel0 1} {sel1 0} {in0 1} {in1 ^} {in2 1}
measure {out v} with {sel0 1} {sel1 0} {in0 1} {in1 v} {in2 1}

# measure late arriving sel1 rise
measure {out ^} with {sel0 1} {sel1 ^} {in0 1} {in1 0} {in2 1}

measure {out v} with {sel0 1} {sel1 1} {in0 1} {in1 0} {in2 v}
measure {out ^} with {sel0 1} {sel1 1} {in0 1} {in1 0} {in2 ^}

# measure late arriving sel1 fall
measure {out v} with {sel0 1} {sel1 v} {in0 1} {in1 0} {in2 1}

# measure late arriving sel0 fall
measure {out ^} with {sel0 v} {sel1 0} {in0 1} {in1 0} {in2 1}

step {sel0 ^} {in0 v} {in1 ^} {in2 v}

# measure late arriving sel1 rise
measure {out v} with {sel0 1} {sel1 ^} {in0 0} {in1 1} {in2 0}

# measure late arriving sel1 fall
measure {out ^} with {sel0 1} {sel1 v} {in0 0} {in1 1} {in2 0}

# measure late arriving sel0 fall
measure {out v} with {sel0 v} {sel1 0} {in0 0} {in1 1} {in2 1}

# measure late arriving sel0 rise
measure {out ^} with {sel0 ^} {sel1 0} {in0 0} {in1 1} {in2 0}

# measure the input capacitance
cap sel0
cap sel1
cap in0
cap in1
cap in2

