IRSIM_TOP := ../..
AUX_TOP := $(IRSIM_TOP)/..
MAX_TOP := $(AUX_TOP)/..
INCLUDE_DIR := .

#include appropriate config file 
MAKE_DIR := $(MAX_TOP)/make
include $(MAKE_DIR)/config

MODULE := $(notdir $(shell pwd))
OBJ_DIR := $(MAX_TOP)/o/${CONFIG}/aux/irsim/${MODULE}
PROGRAM := $(OBJ_DIR)/$(MODULE)

HDRS :=	$(wildcard *.h)
SRCS :=	$(wildcard *.c)
OBJS0 :=  $(addsuffix .o,$(basename ${SRCS}))
OBJS := $(addprefix ${OBJ_DIR}/,${OBJS0})
DEPS0 :=  $(addsuffix .d,$(basename ${SRCS}))
DEPS := $(addprefix ${OBJ_DIR}/,${DEPS0})

# Add these flags for development
# -DASSERTIONS -g -DDEBUG

COMPILE_FLAGS=	$(CONFIG_CFLAGS) -I $(INCLUDE_DIR) $(CONFIG_DEFINES_PERMISSIVE) 

$(OBJ_DIR)/%.o: %.c 
	-mkdir -p $(OBJ_DIR)
	-rm -f $@
	${CC} ${COMPILE_FLAGS} -c $< -o $(OBJ_DIR)/$*.o

$(OBJ_DIR)/%.d: %.c 
	-mkdir -p $(OBJ_DIR)
	-rm -f $(OBJ_DIR)/$*.d
	${CC} -MM ${COMPILE_FLAGS} $< > $(OBJ_DIR)/$*.d

$(PROGRAM): $(OBJS) $(HDRS)
	-rm -f $(PROGRAM)
	$(CC) $(COMPILE_FLAGS) $(OBJS) $(LIBS) -o $(PROGRAM) -lm
	$(CONFIG_STRIP) $(PROGRAM)

$(OBJ_DIR)/depend: $(DEPS)
	cat $(OBJ_DIR)/*.d | sed \/\^\[\^\ \]\/s=\^=$(OBJ_DIR)/= > $(OBJ_DIR)/depend
include $(OBJ_DIR)/depend

.PHONY: clean
clean:	
	cd ${OBJ_DIR}; rm -f *.a *.o *.d depend

.PHONY: debug
debug: 
	echo module: ${MODULE}
	echo hdrs: ${HDRS}
	echo srcs: ${SRCS}
	echo objs: ${OBJS}
	echo cflags: ${COMPILE_FLAGS}

.PHONY: program
program: $(PROGRAM)
	echo "$(PROGRAM) built."
