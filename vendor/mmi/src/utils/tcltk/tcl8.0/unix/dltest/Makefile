# Generated automatically from Makefile.in by configure.
# This Makefile is used to create several test cases for Tcl's load
# command.  It also illustrates how to take advantage of configuration
# exported by Tcl to set up Makefiles for shared libraries.
# RCS: @(#) $Id: Makefile.in,v 1.2 1998/09/14 18:40:18 stanton Exp $

CC = gcc
LIBS =			-L/home/cad/utilities/tcltk/tcl8.0.4/unix -ltcl8.0${TCL_DBGX} -ldl  -lsocket -lnsl -lm -lc
SHLIB_CFLAGS =		-fPIC
SHLIB_LD =		/usr/ccs/bin/ld -G -z text
SHLIB_SUFFIX =		.so
SHLIB_VERSION =		
SRC_DIR =		.
TCL_VERSION=		8.0

CFLAGS = -g
CC_SWITCHES = $(CFLAGS) -I${SRC_DIR}/../../generic -DTCL_MEM_DEBUG \
	${SHLIB_CFLAGS}

all: pkga${SHLIB_SUFFIX} pkgb${SHLIB_SUFFIX} pkgc${SHLIB_SUFFIX} pkgd${SHLIB_SUFFIX} pkge${SHLIB_SUFFIX}

pkga${SHLIB_SUFFIX}: $(SRC_DIR)/pkga.c
	$(CC) -c $(CC_SWITCHES) $(SRC_DIR)/pkga.c
	${SHLIB_LD} -o pkga${SHLIB_SUFFIX} pkga.o 

pkgb${SHLIB_SUFFIX}: $(SRC_DIR)/pkgb.c
	$(CC) -c $(CC_SWITCHES) $(SRC_DIR)/pkgb.c
	${SHLIB_LD} -o pkgb${SHLIB_SUFFIX} pkgb.o 

pkgc${SHLIB_SUFFIX}: $(SRC_DIR)/pkgc.c
	$(CC) -c $(CC_SWITCHES) $(SRC_DIR)/pkgc.c
	${SHLIB_LD} -o pkgc${SHLIB_SUFFIX} pkgc.o 

pkgd${SHLIB_SUFFIX}: $(SRC_DIR)/pkgd.c
	$(CC) -c $(CC_SWITCHES) $(SRC_DIR)/pkgd.c
	${SHLIB_LD} -o pkgd${SHLIB_SUFFIX} pkgd.o 

pkge${SHLIB_SUFFIX}: $(SRC_DIR)/pkge.c
	$(CC) -c $(CC_SWITCHES) $(SRC_DIR)/pkge.c
	${SHLIB_LD} -o pkge${SHLIB_SUFFIX} pkge.o 

clean:
	rm -f *.o *${SHLIB_SUFFIX} config.cache config.log config.status lib.exp

distclean: clean
	rm -f Makefile
