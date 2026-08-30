#!/bin/sh
for i in *.sue
do
    bn=`basename $i .sue`
    if [ ! -f ../max/$bn.max ];then
	echo $i
    fi
done
