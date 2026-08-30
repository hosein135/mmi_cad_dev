#!/bin/sh

SUEDIR=../sue_param


for i
do
    echo $i

    # Create sim file from .ext file.
    cell=`basename $i .max`
    ext2sim -B -c 0 -R -p "." -o tmp.sim ${cell}.ext
    sed '1s/$/ format: UCB/' tmp.sim > ${cell}_lay.sim

    lvs_err=$cell.lvserr
    # Remove all comments from sim file except on the first line.
    sed '1p;/^|/d' $SUEDIR/$cell.sim >tmp.sim
    gemini -n 80 -w5 -c -D ${cell}.dict -M ${lvs_err}:5 ${cell}_lay.sim tmp.sim > $cell.gemini 2>&1

done
