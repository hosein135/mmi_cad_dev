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

MMI_UTILS := /volume/mmi/utils

-include $(MMI_UTILS)/config/main.config
BIN_DIR := /volume/cad/bin.$(TARGET)

LIBTCLMODS=libtclmods8.0.a

CC := gcc
COMPILE_FLAGS := $(CONFIG_CFLAGS)  -I. $(CONFIG_INCLUDES) $(CONFIG_DEFINES)

OBJS := MMITclInfo.o MMITclProc.o MMITclRename.o MMITclLic.o MMIwarp.o \
	MMITclLsearch2.o mmilock.o

OBJ_DIR = o/$(TARGET)
# The VPATH means something to gmake.
VPATH = $(OBJ_DIR)

# These are flags that must be passed to gcc when making a shared object library.
# The -DMAKE_PACKAGE=1 controls stuff inside mmilock.c
SOFLAGS = -fPIC -shared -DMAKE_PACKAGE=1

# The gmake on the sun *requires* the path to be prepended to the rule, and gmake
# on the linux machine *requires* that it not be!  (free software!)
# So need both of the following two rules:
%.o: %.c
	rm -f $(OBJ_DIR)/$*.o 
	${CC}  ${COMPILE_FLAGS} -c $< -o $(OBJ_DIR)/$*.o

$(OBJ_DIR)/%.o: %.c
	rm -f $(OBJ_DIR)/$*.o 
	${CC}  ${COMPILE_FLAGS} -c $< -o $(OBJ_DIR)/$*.o

.PHONY: all
all: $(OBJ_DIR)/$(LIBTCLMODS) sema_package.so

sema_package.so: mmilock.c
	gcc -c $(COMPILE_FLAGS) $(SOFLAGS) -o $(OBJ_DIR)/shared_mmilock.o mmilock.c
	gcc $(SOFLAGS) -o $(OBJ_DIR)/mmi_sema_package.so $(OBJ_DIR)/shared_mmilock.o


$(OBJ_DIR)/$(LIBTCLMODS): $(OBJS)
	cd $(OBJ_DIR); \
	rm -f $(LIBTCLMODS); \
	ar r $(LIBTCLMODS) $(OBJS); \
	ranlib $(LIBTCLMODS)

.PHONY: clean
clean:	
	rm -f $(OBJ_DIR)/*.o
	rm -f $(OBJ_DIR)/*.a
	rm -f $(OBJ_DIR)/*.so

.PHONY: install
install: all
	rm -f $(MMI_UTILS)/lib.$(TARGET)/$(LIBTCLMODS)
	cp $(OBJ_DIR)/$(LIBTCLMODS) $(MMI_UTILS)/lib.$(TARGET)
	cp $(OBJ_DIR)/mmi_sema_package.so $(BIN_DIR)



$(OBJS): $(TCLTK_DEPENDENCY) $(LM_DEPENDENCY)
