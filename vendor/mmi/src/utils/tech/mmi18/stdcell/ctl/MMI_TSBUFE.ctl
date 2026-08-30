# cell name matches file name

function out = in

measure {out ^} with {in ^} {en 1} {enb 0}
measure {out v} with {in v} {en 1} {enb 0}
step {en 0} {enb 1} 
measure {out ^} with {enb v} {en ^} {in 1}
step {en 0} {enb 1} 
measure {out v} with {enb v} {en ^} {in 0}

# measure the input capacitance
cap in with {en 1} {enb 0}
cap en
cap enb


