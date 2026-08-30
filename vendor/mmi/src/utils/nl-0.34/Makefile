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

include Makefile.mmi

LIBDIRS		= nl pnl def2pnl lef2pnl hier nl2sim nl2v ast2g report	\
		  rtl2dpc ui utility mem mem-purify v2nl ssa error tcl	\
		  namegen pat tsp vim2nl pl

LIBDIR_TARGET	= lib
EXEC_TARGET	= exec
PKG_TARGET	= package
ARC_TARGET	= archive

default:	$(LIBDIRS) exec package archive

debug:	$(LIBDIRS) exec package

opt:
	@$(MAKE) LIBDIR_TARGET=lib-opt EXEC_TARGET=exec-opt PKG_TARGET=package-opt ARC_TARGET=archive-opt

all:	debug opt archive doc

exec:
	cd nlsh; $(MAKE) $(EXEC_TARGET) help_text

purify:
	cd nlsh; $(MAKE) purify

purify-opt:
	cd nlsh; $(MAKE) purify-opt

purify-w-mem:
	cd nlsh; $(MAKE) purify-w-mem

quantify:
	cd nlsh; $(MAKE) quantify

quantify-opt:
	cd nlsh; $(MAKE) quantify-opt

purecov:
	cd nlsh; $(MAKE) purecov

purecov-opt:
	cd nlsh; $(MAKE) purecov-opt

package:
	cd nlsh; $(MAKE) $(PKG_TARGET)

archive:
	cd nlsh; $(MAKE) $(ARC_TARGET)

clean:
	for i in $(LIBDIRS); do (cd $$i; $(MAKE) clean); done
	(cd nlsh; $(MAKE) clean)
	rm -fr lib-opt.* lib-debug.* bin-opt.* bin-debug.*


.RECURSIVE: $(LIBDIRS)

$(LIBDIRS): FRC
	cd $@; $(MAKE) $(LIBDIR_TARGET)

FRC:
