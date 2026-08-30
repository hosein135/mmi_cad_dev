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
#       Makefile for Compiled Sue
#
# NOTE: TO COMPILE, RUN ./mkcsue (NOT make) on appropriate machine
#       TO INSTALL RUN make release

# Use mmi48 for linux, NOT mmifs3 for solaris
# Use lnx2 and mmihp1

SUE_VERSION        = 4.4.1
SUE2EDIF_VERSION   = 1.3
RELEASE            = 1
#RELEASE            = 0

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
DEFINES      = -DSUE_VERSION="\"$(SUE_VERSION)"\" -DSUE2EDIF_VERSION="\"$(SUE2EDIF_VERSION)"\"

# uncomment for no flexlm
#DEFINES	     += -DUSE_FLEXLM=0 

CFLAGS       = -O
#CFLAGS       = -g
CC 	     = gcc


# ------------------------------------------------------------------------
#       Put it all together
# ------------------------------------------------------------------------


ifeq "$(RELEASE)" "1"
  SHARE        = NONE
else
  SHARE        = $(TARGET_OS)
endif


ifeq "$(SHARE)" "SOLARIS"
  # don't statically link.  Will load shared object at run time from .suerc.
  DEFINES      += -DSHARED_OBJECT=1
  NL_INCLUDES  =
  NL_LIB       =

  SPEEDY_OBJ   = 

else
  NL_INCLUDES  = -I$(MMI_CAD)/src/nl/include
  NL_LIB       = -L$(MMI_CAD)/src/nl/lib-opt.$(TARGET) -lnl_shell

#  NL_INCLUDES  = -I$(MMI_CAD)/src/nl-0.32/include
#  NL_LIB       = -L$(MMI_CAD)/src/nl-0.32/lib-debug.$(TARGET) -lnl_shell

  SPEEDY_OBJ   = 
# undefined symbol in nl_cell_set_reference
#  SPEEDY_OBJ   = $(MMI_CAD)/src/speedy/speedy.$(TARGET2).o

#  SPEEDY_LIB   = -L$(MMI_CAD)/build/speedy/bin.$(TARGET2) -lspeedy
#  SPEEDY_LIB   = -L$(MMI_CAD)/src/speedy/bin.$(TARGET2) -lspeedy
# old speedy but works
#  SPEEDY_LIB   = -L$(MMI_CAD)/src/speedy -lspeedy

endif

CC_SWITCHES  = $(CFLAGS) $(DEFINES) $(CONFIG_INCLUDES) $(NL_INCLUDES) 

#ifeq "$(TARGET_OS)" "SOLARIS"
  # don't statically link.  Will load shared object at run time from .suerc.
  LIBRARIES    = $(CONFIG_LIBS) $(NL_LIB)
#else
#  LIBRARIES    = $(CONFIG_LIBS) $(NL_LIB) $(SPEEDY_LIB)
#endif

#SRCS	     = sueAppInit.c mmiInterrupt.c steiner.cc

ifeq "$(SHARE)" "SOLARIS"
  # don't statically link.  Will load shared object at run time from .suerc.
  SRCS	     = sueAppInit.c mmiInterrupt.c steiner.c
  OBJS	     = sueAppInit.o mmiInterrupt.o steiner.o
else
  SRCS	     = sueAppInit.c mmiInterrupt.c steiner.c gr.c
  OBJS	     = sueAppInit.o mmiInterrupt.o steiner.o gr.o
endif

all: 	sue

sue: $(OBJS) 
# for purify
# module add rational
	$(CC) $(CC_SWITCHES) $(OBJS) $(SPEEDY_OBJ) -o sue $(LIBRARIES)
#	purify $(CC) $(CC_SWITCHES) $(OBJS) $(SPEEDY_OBJ) -o sue $(LIBRARIES)
#	ifeq "$(RELEASE)" "1"
	strip sue
#	endif


$(OBJS): sueInit $(SRCS)
	$(CC) $(CC_SWITCHES) -c $(SRCS)

sueInit:
	$(MMI_UTILS)/bin.$(TARGET)/remove_comments.tcl \
		doc0.tcl \
		utilities.tcl \
		sueInit.tcl \
		globals.tcl \
		sueInitA.tcl \
		api.tcl \
		arc.tcl \
		canvas.tcl \
		cell.tcl \
		connect.tcl \
		doc.tcl \
		dpc.tcl \
		dpc_utils.tcl \
		draw_wire.tcl \
		duplication.tcl \
		edit_marker.tcl \
		fs_box.tcl \
		icon.tcl \
		icon_write.tcl \
		instances.tcl \
		lines.tcl \
		net_flat.tcl \
		net_spice.tcl \
		net_verilog.tcl \
		net_vhdl.tcl \
		netlist.tcl \
		print.tcl \
		prop_edit.tcl \
		selection.tcl \
		sim_probe.tcl \
		spice_probe.tcl \
		sticky_move.tcl \
		text.tcl \
		timing.tcl \
		verilog_probe.tcl \
		windows.tcl \
		write.tcl \
		zoom.tcl \
		help.tcl \
		sue2edif.tcl \
		vcd.tcl \
		sueInitB.tcl > sue_no_comments
	$(MMI_UTILS)/bin.$(TARGET)/prepare -s sue_no_comments > sueInit

sue_tee:
	$(CC) $(CC_SWITCHES) -c sue_tee.c
	$(CC) $(CC_SWITCHES) sue_tee.o -o sue_tee

make/config:
	make/:config


# install executable for this architecture

.PHONY: release
release:
	-mv $(MMI_CAD)/build/sue/bin.$(TARGET2)/sue.exe $(MMI_CAD)/build/graveyard/sue.exe.`date +%y%m%d%H%M`
	-cp release/bin.$(TARGET2)/sue.exe $(MMI_CAD)/build/sue/bin.$(TARGET2)/sue.exe


# install documentation

.PHONY: doc
doc:
	-chmod -R a+rw $(MMI_CAD)/build/sue/doc
	-rm -rf $(MMI_CAD)/build/sue/doc
	-chmod -R a+rw $(MMI_CAD)/src/sue/doc
	-gcp -r $(MMI_CAD)/src/sue/doc $(MMI_CAD)/build/sue/doc
	-chmod -R a+rw $(MMI_CAD)/build/sue/doc

