# cell name matches file name

function out = (in0 & in1 & in2 & in3) |  (!sel0 & in0 & in2) |  ( sel0 & in1 & in3)  |  (!sel1 & in0 & in1)  |  ( sel1 & in2 & in3)  |  (!sel1 & !sel0 & in0) |  (!sel1 &  sel0 & in1)  |  ( sel1 & !sel0 & in2) |  ( sel1 &  sel0 & in3)

measure {out v} with {sel0 0} {sel1 0} {in0 v} {in1 0} {in2 0} {in3 1}
measure {out ^} with {sel0 0} {sel1 0} {in0 ^} {in1 0} {in2 0} {in3 1}

# measure late arriving sel0 rise
measure {out v} with {sel0 ^} {sel1 0} {in0 1} {in1 0} {in2 0} {in3 1}

measure {out ^} with {sel0 1} {sel1 0} {in0 1} {in1 ^} {in2 0} {in3 1}
measure {out v} with {sel0 1} {sel1 0} {in0 1} {in1 v} {in2 0} {in3 1}

# measure late arriving sel1 rise
measure {out ^} with {sel0 1} {sel1 ^} {in0 1} {in1 0} {in2 0} {in3 1}

measure {out v} with {sel0 1} {sel1 1} {in0 1} {in1 0} {in2 0} {in3 v}
measure {out ^} with {sel0 1} {sel1 1} {in0 1} {in1 0} {in2 0} {in3 ^}

# measure late arriving sel0 fall
measure {out v} with {sel0 v} {sel1 1} {in0 1} {in1 0} {in2 0} {in3 1}

measure {out ^} with {sel0 0} {sel1 1} {in0 1} {in1 0} {in2 ^} {in3 1}
measure {out v} with {sel0 0} {sel1 1} {in0 1} {in1 0} {in2 v} {in3 1}

# measure late arriving sel1 fall
measure {out ^} with {sel0 0} {sel1 v} {in0 1} {in1 0} {in2 0} {in3 1}

# measure late arriving sel1 rise
measure {out v} with {sel0 0} {sel1 ^} {in0 1} {in1 0} {in2 0} {in3 1}

# measure late arriving sel0 rise
measure {out ^} with {sel0 ^} {sel1 1} {in0 1} {in1 0} {in2 0} {in3 1}

# measure late arriving sel1 fall
measure {out v} with {sel0 1} {sel1 v} {in0 1} {in1 0} {in2 0} {in3 1}

# measure late arriving sel0 fall
measure {out ^} with {sel0 v} {sel1 0} {in0 1} {in1 0} {in2 0} {in3 1}


# measure the input capacitance
cap sel0
cap sel1
cap in0
cap in1
cap in2
cap in3

