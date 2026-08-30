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

#
#       Makefile for Global Router
#

# ------------------------------------------------------------------------
#       Include shared config
#       (should come first so that sets below override/modify)
# ------------------------------------------------------------------------

MMI_CAD := /volume/mmi
MMI_UTILS := $(MMI_CAD)/utils

include $(MMI_UTILS)/config/main.config

# ------------------------------------------------------------------------
#       C Compiler options 
# ------------------------------------------------------------------------

# Versions are of the form <major>.<minor>.<inc>
DEFINES      = -DUSE_MAX=1

#CFLAGS       = -O
CFLAGS       = -g
CC 	     = gcc


# ------------------------------------------------------------------------
#       Put it all together
# ------------------------------------------------------------------------

# Well, this sure sucks:
MAX_INCLUDES = -I/homes/mha/max/i

NL_INCLUDES  = -I$(MMI_CAD)/src/nl/include
NL_LIB       = -L$(MMI_CAD)/src/nl/lib-opt.$(TARGET)

#NL_INCLUDES  = -I$(MMI_CAD)/src/nl-0.31x/include
#NL_LIB       = -L$(MMI_CAD)/src/nl-0.31x/lib-debug.$(TARGET) -lnl_shell

#NL_INCLUDES  = 
#NL_LIB       = 

TCL_LIB      = -L/volume/mmi/utils/tcltk/tcl8.0.4/sparc-solaris2 -ltcl8.0

CC_SWITCHES  = $(CFLAGS) $(DEFINES) $(CONFIG_INCLUDES) $(NL_INCLUDES) $(MAX_INCLUDES) -fPIC

LIBRARIES    = $(CONFIG_LIBS) $(NL_LIB) $(TCL_LIB)

SRCS	     = gr.c steiner.c gr_init.c
OBJS	     = gr.o steiner.o gr_init.o

#SRCS	     = gr.c steiner.c
#OBJS	     = gr.o steiner.o

#SRCS	     = gr.c
#OBJS	     = gr.o

#all: 	gr
all: 	max_gr_package.so

install: max_gr_package.so
	cp max_gr_package.so /volume/cad/bin.sparc-solaris2/max_gr_package.so

gr: $(OBJS) 
# for purify
# module add rational
	$(CC) $(CC_SWITCHES) $(OBJS) -o gr $(LIBRARIES)

$(OBJS): $(SRCS) nl_include.h
	$(CC) $(CC_SWITCHES) -c $(SRCS)


max_gr_package.so: $(OBJS) Makefile
	$(CC) -shared -o max_gr_package.so $(OBJS)


foo:
	$(CC) -o max_gr_package.so $(OBJS)



make/config:
	make/:config


