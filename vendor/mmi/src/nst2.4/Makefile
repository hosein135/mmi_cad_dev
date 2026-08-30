## ************************************************************************
## 
## Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
## Portions Copyright (c) 1994 Sun Microsystems, Inc. All rights reserved.
## 
## Permission is hereby granted, without written agreement and without
## license or royalty fees, to use, copy, modify, and distribute this
## software and its documentation for any purpose, provided that the
## above copyright notice and the following three paragraphs appear in
## all copies of this software.
## 
## IN NO EVENT SHALL JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS, INC. BE
## LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
## CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
## DOCUMENTATION, EVEN IF JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS,
## INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
## 
## JUNIPER NETWORKS, INC. AND SUN MICROSYSTEMS, INC. SPECIFICALLY
## DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
## WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
## NON-INFRINGEMENT.
## 
## THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
## NETWORKS, INC. AND SUN MICROSYSTEMS, INC. HAVE NO OBLIGATION TO
## PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
## 
## ************************************************************************

#
#       Makefile for New SpiceTool (nst)
#
# NOTE: TO COMPILE, RUN ./mknst (NOT make) on appropriate machine
#       TO INSTALL RUN make release

NST_VERSION := 2.4.0

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

#DEFINES      = -DNST_VERSION="\"$(NST_VERSION)"\" -DUSE_FLEXLM=0
DEFINES      = -DNST_VERSION="\"$(NST_VERSION)"\"
#CFLAGS       = -g
CFLAGS       = -O
CC 	     = gcc

# Special BLT stuff

BLT_INCLUDE	= -I${MMI_UTILS}/blt2.4g.$(TARGET)
BLT_LIB         = -L${MMI_UTILS}/blt2.4g.$(TARGET)/src -lBLT


# -------------------------------------------------------------------
#       Put it all together
# ------------------------------------------------------------------------

INCLUDES     = $(BLT_INCLUDE) $(CONFIG_INCLUDES)
CC_SWITCHES  = $(CFLAGS) $(DEFINES) $(INCLUDES)
EXTRA_LIBS   = 
#LIBRARIES    = -static $(BLT_LIB) $(CONFIG_LIBS) $(EXTRA_LIBS)
LIBRARIES    = $(BLT_LIB) $(CONFIG_LIBS) $(EXTRA_LIBS)
SRCS	     = nst.c nstAppInit.c
OBJS	     = nst.o nstAppInit.o
TCLSRC = nst_utils.tcl nst_procs.tcl nst_derive.tcl nst_zoom.tcl fs_box.tcl 

all: 	nst

nst: $(OBJS) 
	$(CC) $(CC_SWITCHES) $(OBJS) -o nst $(LIBRARIES)
	strip nst

$(OBJS): nstInit $(SRCS)
	$(CC) $(CC_SWITCHES) -c $(SRCS)

nstInit: nstinit.a nstinit.b $(TCLSRC)
	$(MMI_UTILS)/bin.$(TARGET)/remove_comments.tcl \
		 nstinit.a $(TCLSRC) nstinit.b > nst_no_comments
	$(MMI_UTILS)/bin.$(TARGET)/prepare -s \
		 nst_no_comments > nstInit

.PHONY: release
release:
	-cp bin.$(TARGET2)/nst $(MMI_CAD)/build/nst/bin.$(TARGET2)/nst
