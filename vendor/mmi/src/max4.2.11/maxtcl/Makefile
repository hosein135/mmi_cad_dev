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

# Makefile for maxtcl 
# (creates encrypted startup scripts for inclusion in C code)

#include appropriate config file 
MAKE_DIR := ../make
include $(MAKE_DIR)/config

REMOVE_COMMENTS := $(MMI_UTILS)/bin.$(TARGET)/remove_comments.tcl
#REMOVE_COMMENTS := cat

# order is important in MAX0_FILES
MAX0_FILES := max0.prep_pro max0.tcl doc_user0.tcl doc_var_user0.tcl doc0.tcl help0.tcl

MAX_FILES := $(filter-out max.tcl %0.tcl,$(wildcard *.tcl))
MAX_FILES := max.prep_pro $(SHARED_FILES) $(MAX_FILES) max.tcl 

.PHONY: all
all: max0.prep_h max.prep_h 

max0.prep_h: $(MAX0_FILES)
	$(REMOVE_COMMENTS) $(MAX0_FILES) > max0.no_comments
	prepare -s max0.no_comments > max0.prep_h

max.prep_h: $(MAX_FILES) 
	$(REMOVE_COMMENTS) $(MAX_FILES) > max.no_comments
	prepare -s max.no_comments > max.prep_h

.PHONY: clean
clean: 
	-rm -f *.prep_h *.no_comments

# get latest and greatest
.PHONY: update
update:
	-rm -f  *.tcl
	co $(MMI_CAD)/src/max/maxtcl/RCS/*.tcl,v
	make all

