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

SPEEDY_VERSION	= 4.0

MMI_UTILS 	= /volume/mmi/utils
include $(MMI_UTILS)/config/main.config

# linux build machine: lnx2
# hp build machine: mmihp1 (warnings about delcaration conflict for 
#				memcpy & memcmp, but it works fine)


# ------------------------------------------------------------------------
#       C Compiler options 
# ------------------------------------------------------------------------

DEFINES		= -DSPEEDY_VERSION="\"$(SPEEDY_VERSION)"\"

CFLAGS 		= -fPIC -fno-gnu-linker -g -Wall

# with profiling ... can't use fPIC 
# ... say "make speedy" ... can't make speedy_package.so 
# CFLAGS = -pg -fno-gnu-linker -g -Wall

CC 	     	= gcc


# ------------------------------------------------------------------------
#       Put it all together
# ------------------------------------------------------------------------

NL_SOURCE 		= /volume/mmi/src/nl-0.31
# NL_SOURCE 		= /volume/mmi/src/nl-0.31x
# NL_SOURCE 		= /volume/mmi/src/nl-0.27
# NL_SOURCE 		= /volume/mmi/src/nl-0.26
# NL_SOURCE	= $(MMI_CAD)/src/nl

INCLUDES     	= -I. -I$(NL_SOURCE)/include $(CONFIG_INCLUDES) 

# needed for linux, not for solaris.. copied from sue
MMI_CAD 	= /volume/mmi
NL_LIB       	= -L$(MMI_CAD)/src/nl/lib-opt.$(TARGET) -lnl_shell

#LIBRARIES    	= -static $(CONFIG_LIBS) $(EXTRA_LIBS)
EXTRA_LIBS   	= 
# LIBRARIES    	= $(CONFIG_LIBS) $(EXTRA_LIBS) $(GCCLIB)

CC_SWITCHES  	= $(CFLAGS) $(DEFINES) $(INCLUDES)
COMPILE_FLAGS 	= $(CONFIG_CFLAGS) -I. $(CONFIG_INCLUDES) $(CONFIG_DEFINES) -fPIC

ifeq "$(TARGET_OS)" "SOLARIS"

	LIBRARIES	= libgcc2.so.a
	LD		= gcc -shared

else
ifeq "$(TARGET_OS)" "LINUX"

#	LIBRARIES	= $(NL_LIB) $(CONFIG_LIBS) $(EXTRA_LIBS)
	LIBRARIES	= $(CONFIG_LIBS) $(EXTRA_LIBS)
	LD		= gcc -shared

else
ifeq "$(TARGET_OS)" "HPUX"

#	LIBRARIES	= $(CONFIG_LIBS) $(EXTRA_LIBS)
#	LIBRARIES	= -L/volume/mmi/utils/lib.hppa -ltclmods8.0 /volume/mmi/utils/lib.hppa/lm_new.o -L/volume/mmi/utils/lib.hppa -lmmilic -llmgr -L/volume/mmi/utils/lib.hppa -ltk8.0 -L/volume/mmi/utils/lib.hppa -ltcl8.0 -L/usr/openwin/lib -lX11 -lnsl -lm -lc 
	LIBRARIES	= $(NL_LIB) -L/volume/mmi/utils/lib.hppa -ltclmods8.0 -L/volume/mmi/utils/lib.hppa -lmmilic -L/volume/mmi/utils/lib.hppa         -L/volume/mmi/utils/lib.hppa          -L/usr/openwin/lib -lX11 -lnsl -lm -lc 

	LD		= /usr/ccs/bin/ld -b

endif
endif
endif


# ------------------------------------------------------------------------
#       biz
# ------------------------------------------------------------------------
RELEASE_FEATURES =


STANDALONE_FEATURES =

OBJS = 	package.o		\
	nl.o 			\
	design.o 		\
	steiner.o 		\
	lib.o 			\
	libfile_read.o 		\
	libfile_write.o		\
	constraintsfile.o	\
	dspffile.o		\
	resize.o		\
	timing.o		\
	path.o			\
	commands.o  		\


SRCS =  package.cc		\
	nl.cc 			\
	design.cc 		\
	steiner.cc 		\
	lib.cc 			\
	libfile_read.cc 	\
	libfile_write.cc	\
	dspffile.cc 		\
	resize.cc		\
	timing.cc		\
	path.cc			\
	commands.cc  		\

COMMANDS_SRCS =			\
	commands.cc		\
	nl_commands.cc 		\
	timing_commands.cc 	\
	resize_commands.cc	\
	sue_commands.cc		\

HEADERS = util.h		\
	design.h		\
	lib.h			\
	path.h			\
	libfile.h		\
	constraintsfile.h	\
	nl_speedy.h		\

usual:	speedy_package_temp.so	
	mv speedy_package_temp.so speedy_package.so

speedy_package_temp.so: $(OBJS) Makefile 
	$(LD) -o speedy_package_temp.so $(OBJS) $(LIBRARIES)

speedy: $(OBJS) main.o
	$(CC) $(CC_SWITCHES) $(OBJS) main.o -o speedy $(LIBRARIES)

speedy.o:	
	$(LD) -o speedy.o $(OBJS) $(LIBRARIES)

link_test:	$(OBJS)
	$(CC) $(CC_SWITCHES) $(OBJS) -o link_test $(LIBRARIES)


commands.o:	$(COMMANDS_SRCS) $(HEADERS)
	$(CC) $(CC_SWITCHES) -I. -c -shared commands.cc

.c.o:
	$(CC) $(CC_SWITCHES) -I. -c -shared $<

.cc.o:	$(HEADERS)
	$(CC) $(CC_SWITCHES) -I. -c -shared $<

clean:
	rm -f speedy $(OBJS) speedy_package_temp.so speedy.o

clena:	clean

tidy:	clean
	rm -f *~ 
	rm -f \#*
	rm -f xx*
	rm -f core
	rm -f a.out
	rm -f */*~ 
	rm -f */\#* 
	rm -f */xx* 
	rm -f */core
	rm -f */a.out

scrubbed:	clean tidy
	rm -f speedy_package.* 



# ------------------------------------------------------------------------
#       Release
# ------------------------------------------------------------------------

BUILD			=	/volume/mmi/build
SPEEDY_BUILD_DIR	=	$(BUILD)/speedy$(SPEEDY_VERSION)


release:	build_dir release_package release_common
	/bin/cp speedy_package.$(TARGET2).so 	$(SPEEDY_BUILD_DIR)/bin.$(TARGET2)/speedy_package.so

release_package:	clean	speedy_package_temp.so speedy.o
	/bin/cp speedy_package_temp.so	speedy_package.$(TARGET2).so 
	/bin/cp speedy.o		speedy.$(TARGET2).o 

release_common:

xxxrelease_common:
	/bin/cp src/speedy_menu.tcl		$(SPEEDY_BUILD_DIR)/src
	/bin/cp src/speedy_procs.tcl		$(SPEEDY_BUILD_DIR)/src
	/bin/cp src/utils.tcl			$(SPEEDY_BUILD_DIR)/src
	/bin/cp src/icon_creator.tcl		$(SPEEDY_BUILD_DIR)/src
	/bin/cp doc/*				$(SPEEDY_BUILD_DIR)/doc

build_dir:
	/bin/mkdir -p	$(SPEEDY_BUILD_DIR)
	/bin/mkdir -p	$(SPEEDY_BUILD_DIR)/bin.sparc-solaris2
	/bin/mkdir -p	$(SPEEDY_BUILD_DIR)/bin.i486-linux
	/bin/mkdir -p	$(SPEEDY_BUILD_DIR)/bin.hppa
	/bin/mkdir -p	$(SPEEDY_BUILD_DIR)/src
	/bin/mkdir -p	$(SPEEDY_BUILD_DIR)/doc
