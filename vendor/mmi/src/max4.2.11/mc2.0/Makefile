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

# Makefile for Mega Cell Compiler (MC)
# (creates encrypted script for inclusion in C code)

ifeq "$(HOSTTYPE)" "i386-linux"
   include ../make/config.linux$(MAX_CONFIG_OPTIONS)
else
   include ../make/config.solaris$(MAX_CONFIG_OPTIONS)
endif

REMOVE_COMMENTS := $(MMI_UTILS)/bin.$(TARGET)/remove_comments.tcl

MC_FILES := $(filter-out mc_wrapper.tcl, $(wildcard *.tcl))

.PHONY: all
all:  mc.prep_h 

mc.prep_h: $(MC_FILES) 
	$(REMOVE_COMMENTS) $(MC_FILES) > mc.no_comments
	prepare -s mc.no_comments > mc.prep_h

.PHONY: test
test:	
	echo $(MC_FILES)

.PHONY: clean
clean: 
	-rm -f *.prep_h *.no_comments

