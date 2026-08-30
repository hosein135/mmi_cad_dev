# cell name matches file name

function out = !(((sel & in1) | (!sel & in0)) | (in0 & in1))

measure {out ^} with {sel 0} {in0 v} {in1 0}
measure {out v} with {sel 0} {in0 ^} {in1 0}

# measure late arriving sel rise
measure {out ^} with {sel ^} {in0 1} {in1 0}

measure {out v} with {sel 1} {in0 1} {in1 ^}
measure {out ^} with {sel 1} {in0 1} {in1 v}

# measure late arriving sel fall
measure {out v} with {sel v} {in0 1} {in1 0}

step {sel ^} {in0 v} {in1 ^}

measure {out ^} with {sel v} {in0 0} {in1 1}
measure {out v} with {sel ^} {in0 0} {in1 1}

# measure the input capacitance
cap sel
cap in0
cap in1


