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

ANTLR   = $(MMI_UTILS)/pccts/bin.$(TARGET)/antlr
DLG   = $(MMI_UTILS)/pccts/bin.$(TARGET)/dlg
DFLAGS = -C2
PCCTS_INCLUDE   = $(MMI_UTILS)/pccts/h
MODULE_EXTRA_OBJS = def_parse.o def_lex.o def_parse_err.o
MODULE_EXTRA_CFLAGS = -I$(PCCTS_INCLUDE)

include ../../make/Makefile.module

# This builds the DEF file parser and lexer using antler
# Additional files built by ANTLR are: tokens.h, stdpccts.h remap.h tokens.h
def_parse.c def_lex.dlg def_parse_err.c: def_parse.g def2max.h mode.h
	@echo "Expect 1 ambiguity warning from Antlr."
	#$(ANTLR) -gh -fl def_lex.dlg -fe def_parse_err.c def_parse.g
	$(ANTLR) -gl -fl def_lex.dlg -fe def_parse_err.c -fh def_parse.h def_parse.g

def_lex.c:    def_lex.dlg
	$(DLG) $(DFLAGS) $< > $@
	#$(DLG) $(DFLAGS) $< \
	#| sed "s/static void act[0-9][0-9]*(/&void/g" \
	#| sed "s/void (\\*actions\\[[0-9][0-9]*\\])(/&void/" > $@
