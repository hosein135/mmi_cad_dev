
# foo.tech is the (somewhat) human readable form of the technology
# file.  For max to use this, it needs drc_macros.i and the 
# preprocessors cpp and m4 (run in that order) to create foo.tech27

#CPP = /lib/cpp
#CPP = /usr/local/bin/cpp
CPP = cpp
M4 = m4

techfile: g18.tech
	${CPP} -P -traditional g18.tech | ${M4} > g18.tech27
	${CPP} -P -traditional -DPOSTGEN g18.tech | ${M4} > g18-PG.tech27
	${CPP} -P -traditional -DNOA g18.tech | ${M4} > g18-NOA.tech27
	grep "TODO" g18.tech > TODO




