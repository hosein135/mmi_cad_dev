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

include ../Makefile.common

OBJ_VARIANT	= debug
LIBDIR		= ../lib-$(OBJ_VARIANT).$(TARGET)
BINDIR		= ../bin-$(OBJ_VARIANT).$(TARGET)
OBJDIR		= obj-$(OBJ_VARIANT).$(TARGET)
TMPDIR		= tmp-$(OBJ_VARIANT).$(TARGET)

EXECNAME= nl_shell
EXEC    = $(BINDIR)/$(EXECNAME)
PKG     = $(BINDIR)/$(EXECNAME).so
ARCHIVE	= $(LIBDIR)/lib$(EXECNAME).a
PKGOBJ  = $(OBJDIR)/nlpkg.o
EXECOBJ = $(OBJDIR)/nlsh.o
SHELL	= /bin/bash

DEPS	= $(LIBDIR)/libui.a $(LIBDIR)/libv2nl.a $(LIBDIR)/libnl2v.a	\
	  $(LIBDIR)/libnl2sim.a $(LIBDIR)/libhier.a $(LIBDIR)/libssa.a	\
	  $(LIBDIR)/libdef2pnl.a $(LIBDIR)/liblef2pnl.a			\
	  $(LIBDIR)/libreport.a $(LIBDIR)/libpat.a			\
	  $(LIBDIR)/libast2g.a $(LIBDIR)/librtl2dpc.a			\
	  $(LIBDIR)/libpnl.a $(LIBDIR)/libnl.a $(LIBDIR)/libutility.a	\
	  $(LIBDIR)/libnamegen.a $(LIBDIR)/liberror.a			\
	  $(LIBDIR)/libtsp.a $(LIBDIR)/libvim2nl.a $(LIBDIR)/libpl.a	\
	  $(LIBDIR)/libtcl_init.a $(MEMLIB)

OTHER_LIBS = -lm

MEMLIB	= $(LIBDIR)/libmem.a
MEM_PURIFY_LIB	= $(LIBDIR)/libmem-purify.a
TCL_DEBUG = # /volume/mmi/utils/tcltk/tcl8.0.4/debug.sparc-solaris2/libtcl8.0.a
TK_DEGUG = # /volume/mmi/utils/tcltk/tk8.0.4/debug.sparc-solaris2/libtk8.0.a
SYSLIBS = # -lc -lm -lnsl -lsocket -ldl
LDFLAGS = -L$(LIBDIR) $(CONFIG_LINK_FLAGS) # -B /homes/jka/lib/gcc-lib/sparc-sun-solaris2.7/2.95


LD_sparc-solaris2	= gcc
LD_hppa			= /usr/ccs/bin/ld
LD_i486-linux2.2	= gcc

LD_SHARED_sparc-solaris2= -shared
LD_SHARED_hppa		= -b
LD_SHARED_i486-linux2.2	= -shared

LD			= $(LD_$(TARGET))
LD_SHARED		= $(LD_SHARED_$(TARGET))

HELP_FILE=../doc/nl-commands.txt

WARNINGS_nlsh = -Wno-implicit-int


all:	exec exec-opt package package-opt archive archive-opt

exec: $(EXEC)

exec-opt:
	@$(MAKE) OBJ_VARIANT=opt exec

purify:
	@$(MAKE) CC="purify $(CC)" MEMLIB=$(MEM_PURIFY_LIB) \
		EXECNAME=$(EXECNAME)-p exec

purify-opt:
	@$(MAKE) CC="purify $(CC)" MEMLIB=$(MEM_PURIFY_LIB) \
		EXECNAME=$(EXECNAME)-p OBJ_VARIANT=opt exec

purify-w-mem:
	@$(MAKE) CC="purify $(CC)" EXECNAME=$(EXECNAME)-pm exec

quantify:
	@$(MAKE) CC="quantify $(CC)" EXECNAME=$(EXECNAME)-q exec

quantify-opt:
	@$(MAKE) CC="quantify $(CC)" EXECNAME=$(EXECNAME)-q \
		OBJ_VARIANT=opt exec

purecov:
	@$(MAKE) CC="purecov $(CC)" EXECNAME=$(EXECNAME)-c exec

purecov-opt:
	@$(MAKE) CC="purecov $(CC)" EXECNAME=$(EXECNAME)-c \
		OBJ_VARIANT=opt exec

package: $(PKG)

package-opt:
	@$(MAKE) OBJ_VARIANT=opt package

archive: $(ARCHIVE)

archive-opt:
	@$(MAKE) OBJ_VARIANT=opt archive

help_text: $(HELP_FILE)

clean:
	rm -f *~ *.o

nlsh_version.h: FORCE
	echo "#define NLSH_VERSION \"`cat VERSION` for `uname` built `date` on `hostname`\"" \
		> nlsh_version.h
	echo "#define TCL_LIBRARY \"$(TCL_LIBRARY)\"" >> nlsh_version.h
	echo "#define TK_LIBRARY \"$(TK_LIBRARY)\"" >> nlsh_version.h

FORCE:

$(EXECOBJ): nlsh_version.h

$(EXEC): $(EXECOBJ) $(DEPS) $(CONFIG_DEPENDENCY)
	@mkdir -p $(BINDIR)
	$(CC) -o $@ $(LDFLAGS) $(EXECOBJ) $(DEPS) $(TCL_DEBUG) $(CONFIG_LIBS) \
		$(OTHER_LIBS)

$(PKG): $(PKGOBJ) $(DEPS) $(CONFIG_DEPENDENCY)
	@mkdir -p $(BINDIR)
	$(LD) $(LD_SHARED) -o $@ $(LDFLAGS) $(PKGOBJ) $(DEPS) $(OTHER_LIBS)

$(ARCHIVE): $(PKGOBJ) $(DEPS)
	@mkdir -p $(TMPDIR)
	@for i in $?; do \
	    if [ $${i##*.} = "o" ]; then echo ar r $@ $$i; ar r $@ $$i; \
	    else echo ar x $$i; (cd $(TMPDIR); ar x ../$$i); \
	    fi \
	  done
	ar r $@ $(TMPDIR)/*.o
	ranlib $@
	@rm -fr $(TMPDIR)

$(HELP_FILE): $(EXEC)
	/bin/echo "NL_SHELL COMMAND HELP\c" > $(HELP_FILE)
	/bin/echo "       (generated on" `date` ")" >> $(HELP_FILE)
	/bin/echo >> $(HELP_FILE)
	/bin/echo "nl_dump_help" | $(EXEC) >> $(HELP_FILE)
