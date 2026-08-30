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

LIBNAME	= libast2g.a
SRCS	= ast2g.c ast2g_util.c ast2g_expression.c 	\
	  ast2g_sequential.c ast2g_error.c ast2g_rewrites.c \
	  ast2g_typebal.c

EE_SRC  = ast2g_rewrites.ee

# SOR_SRC = ast2g_infer_reg.sor
# SOR_PREFIX = ast2g_

include ../Makefile.common

GENERATED_CODE_WARNINGS = -Wstrict-prototypes -Wmissing-prototypes	\
	-Wreturn-type -Wparentheses -Wformat -Wchar-subscripts

DONT_WARN_$(basename $(EE_GEN)) = -Wall
WARNINGS_$(basename $(EE_GEN))  = $(GENERATED_CODE_WARNINGS)

OPT_FLAGS=-O # -Wuninitialized


.PRECIOUS:	$(EE_GEN)


INCLUDE	= -I$(PCCTS_INCLUDE)

ast2g.c:	$(EE_GEN)
