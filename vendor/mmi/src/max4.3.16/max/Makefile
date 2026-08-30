## ************************************************************************
## 
## Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
## 
## Permission is hereby granted, without written agreement and without
## license or royalty fees, to use, copy, modify, and distribute this
## software and its documentation for any purpose, provided that the
## above copyright notice and the following three paragraphs appear in
## all copies of this software.
## 
## IN NO EVENT SHALL JUNIPER NETWORKS, INC. BE LIABLE TO ANY PARTY FOR
## DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
## ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
## JUNIPER NETWORKS, INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
## DAMAGE.
## 
## JUNIPER NETWORKS, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES,
## INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
## NON-INFRINGEMENT.
## 
## THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
## NETWORKS, INC. HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
## UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
## 
## ************************************************************************

#include appropriate config file 
MAKE_DIR := ../make
include $(MAKE_DIR)/config

# megacell compiler version
include ../mc/mc_version

# max verison
include max_version

VERSION_FLAGS = -DMAX_VERSION="\"${MAX_VERSION}"\" -DMAX_VERSION_TAG="\"${MAX_VERSION_TAG}"\" -DMC_VERSION="\"${MC_VERSION}"\"
COMPILE_FLAGS_0 = ${CONFIG_CFLAGS} -I. -I../i ${CONFIG_INCLUDES} ${CONFIG_DEFINES}
COMPILE_FLAGS = ${COMPILE_FLAGS_0} ${VERSION_FLAGS} 

# libraries
LIBS = ${CONFIG_LIBS}

MODULES = bplane cif database def drc extract gds graphics\
	layout main memory mgc netlist select special\
	tile undo utils 

OBJ_DIR = ../o/${CONFIG}

# convert MODULES list to file names of corresponding .o's
M1 = $(addprefix ${OBJ_DIR}/,${MODULES})
M2 = $(addsuffix /, ${M1})
M3 = $(join ${M2},${MODULES})
MODULE_OBJS= $(addsuffix .o,${M3})

${OBJ_DIR}/max:  ${MODULE_OBJS} maxVersion.c
	rm -f ${OBJ_DIR}/max ${OBJ_DIR}/maxVersion.o
	${CC} ${COMPILE_FLAGS} -c maxVersion.c -o ${OBJ_DIR}/maxVersion.o
	${CC} ${COMPILE_FLAGS} ${MODULE_OBJS} ${OBJ_DIR}/maxVersion.o ${LIBS} -o ${OBJ_DIR}/max
	${CONFIG_STRIP} ${OBJ_DIR}/max

clean: forceit
	rm -f max maxVersion.o

forceit:

 

