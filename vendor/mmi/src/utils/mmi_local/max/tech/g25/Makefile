# Makefile for generic 0.35um (g35) CMOS technology file.

# g25.tech is the (somewhat) human readable form of the technology
# file.  For max to use this, it needs drc_macros.i and the 
# preprocessors cpp and m4 (run in that order) to create g25.tech27

#CPP = /lib/cpp
#CPP = /usr/local/bin/cpp
CPP = cpp
M4 = m4

techfile: g25.tech
	${CPP} -P -traditional g25.tech | ${M4} > g25.tech27
	${CPP} -P -traditional -DPOSTGEN g25.tech | ${M4} > g25-PG.tech27
	${CPP} -P -traditional -DNOA g25.tech | ${M4} > g25-NOA.tech27

	grep "TODO" g25.tech > TODO

cm: g25-1cm.tech
	${CPP} -P -traditional g25-1cm.tech | ${M4} > g25-1cm.tech27

tsmc: g25-tsmc.tech
	${CPP} -P -traditional g25-tsmc.tech | ${M4} > g25-tsmc.tech27
	${CPP} -P -traditional -DPOSTGEN g25-tsmc.tech | ${M4} > g25-tsmcPG.tech27
	${CPP} -P -traditional -DNOA g25-tsmc.tech | ${M4} > g25-NOA.tech27
	${CPP} -P -traditional -DPOSTGEN -DRES01 g25-tsmc.tech | ${M4} > g25-tsmcPG01.tech27



g25-test:
	mmi_cpp -P -traditional g25-test.tech | mmi_m4 > g25-test.tech27

convert: g25-convert.tech
	${CPP} -P -traditional g25-convert.tech | ${M4} > g25-convert.tech27
