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

# Makefile for modules that we wish to compile with less warnings.
  PERMISSIVE_COMPILE := 1

# Default Makefile for a module.

#include appropriate config file 
MAKE_DIR := ../../make
include $(MAKE_DIR)/config
	

MODULE := $(notdir $(shell pwd))
OBJ_DIR := ../../o/${CONFIG}/${MODULE}

HDRS :=	$(wildcard *.h)
SRCS :=	$(wildcard *.c)
OBJS0 :=  $(addsuffix .o,$(basename ${SRCS}))
OBJS := $(addprefix ${OBJ_DIR}/,${OBJS0})
DEPS0 :=  $(addsuffix .d,$(basename ${SRCS}))
DEPS := $(addprefix ${OBJ_DIR}/,${DEPS0})

COMPILE_FLAGS := $(CONFIG_CFLAGS)  -I. -I../../i $(CONFIG_INCLUDES) 
ifdef PERMISSIVE_COMPILE
	COMPILE_FLAGS := $(COMPILE_FLAGS) $(CONFIG_DEFINES_PERMISSIVE)
else
	COMPILE_FLAGS := $(COMPILE_FLAGS) $(CONFIG_DEFINES)
endif	

$(OBJ_DIR)/%.o: %.c 
	-mkdir -p $(OBJ_DIR)
	-rm -f $@
	${CC} ${COMPILE_FLAGS} -c $< -o $(OBJ_DIR)/$*.o

$(OBJ_DIR)/%.d: %.c 
	-mkdir -p $(OBJ_DIR)
	-rm -f $(OBJ_DIR)/$*.d
	${CC} -MM ${COMPILE_FLAGS} $< > $(OBJ_DIR)/$*.d

$(OBJ_DIR)/$(MODULE).o: ${OBJS} 
	rm -f ${OBJ_DIR}/${MODULE}.o
	ld ${CONFIG_LINK_FLAGS} -r ${OBJS} -o ${OBJ_DIR}/${MODULE}.o

$(OBJ_DIR)/depend: $(DEPS)
	cat $(OBJ_DIR)/*.d | sed \/\^\[\^\ \]\/s=\^=$(OBJ_DIR)/= > $(OBJ_DIR)/depend
include $(OBJ_DIR)/depend

.PHONY: clean
clean:	
	cd ${OBJ_DIR}; rm -f *.o *.d depend

.PHONY: debug
debug: 
	echo module: ${MODULE}
	echo h: ${H}
	echo lib: ${LIB}
	echo hdrs: ${HDRS}
	echo src: ${SRCS}
	echo objs: ${OBJS}
	echo cflags: ${COMPILE_FLAGS}

.PHONY: protoize
protoize: 
	protoize -c "${COMPILE_FLAGS}" *.c >& protoize.out

# -aux-info creates .X files for protoize





