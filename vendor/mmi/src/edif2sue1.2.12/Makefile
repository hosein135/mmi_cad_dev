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
#	Makefile for Edif File Conversion Tool (edif2sue)
#

VERSION = 1.2.12

# ------------------------------------------------------------------------
#       Include shared config
#       (should come first so that sets below override/modify)
# ------------------------------------------------------------------------
MMI_UTILS := /volume/mmi/utils
include $(MMI_UTILS)/config/main.config

INSTALL_DIR	= /volume/mmi/build

# CC	= /usr/local/bin/gcc

# CFLAGS		= -O
CFLAGS		= -g

LOCAL_DEFINES	= -DE2S_VERSION="\"$(VERSION)"\"
COMPILE		= $(CC) $(CFLAGS) $(LOCAL_DEFINES) $(CONFIG_INCLUDES)
LINK		= $(CC) $(CFLAGS) 
LINK_LIBS	= $(CONFIG_LIBS)


DOTOS= netnames.o sue.o edif2sueAppInit.o token.o expressions.o files.o names.o
DOTHS=sue.h token.h expressions.h files.h names.h netnames.h util.h


all:	edif2sue.$(TARGET2) 

edif2sue.$(TARGET2): 	$(DOTHS) $(DOTOS) 
	$(LINK) -o edif2sue.$(TARGET2) $(DOTOS) $(LINK_LIBS)

clean:
	/bin/rm -f *.o edif2sue.$(TARGET2)
.o:
	$(COMPILE) -I. -c $<

.c.o:
	$(COMPILE) -I. -c $<

.cc.o:
	$(COMPILE) -I. -c $<

install: edif2sue.$(TARGET2) user_doc
	mkdir -p $(INSTALL_DIR)/edif2sue$(VERSION)/bin.$(TARGET2)
	cp edif2sue.$(TARGET2) \
		$(INSTALL_DIR)/edif2sue$(VERSION)/bin.$(TARGET2)/edif2sue
	cp user_doc $(INSTALL_DIR)/edif2sue$(VERSION)/user_doc
	cp e2s_rc $(INSTALL_DIR)/edif2sue$(VERSION)/e2s_rc

# "et" contains some exciting Edif Tools that 
# were helpful while debugging edif2sue
# ...this is not a shipable binary, 
# so don't copy it to build during install
 
et.$(TARGET2):	et.cc
	$(COMPILE) -lm -I. -o et.$(TARGET2) et.cc

tidy:
	/bin/rm -f *~ 
	/bin/rm -f \#*
	/bin/rm -f xx*

clobber:	clean tidy
	/bin/rm -f edif2sue.i486-linux
	/bin/rm -f edif2sue.sparc-solaris2
	/bin/rm -f et.i486-linux  
	/bin/rm -f et.sparc-solaris2 
