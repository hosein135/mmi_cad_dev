# Generated automatically from Makefile.in by configure.
# ------------------------------------------------------------------------
# 	Makefile for static version of BLT library
# ------------------------------------------------------------------------

# ------------------------------------------------------------------------
# 	C Compiler options 
# ------------------------------------------------------------------------

CC           = gcc
CFLAGS       =  
EXTRA_CFLAGS = -Wwrite-strings -Wshadow -Wtraditional -fwritable-strings -Wall
DEFINES      = 
DEF_BLTINIT  = -DBLT_LIBRARY=\"$(BLT_LIBRARY)\"

# ------------------------------------------------------------------------
# 	Source and targer installation directories 
# ------------------------------------------------------------------------

prefix	     = /mmi-cad/utils/tcltk/install.sparc-solaris2
exec_prefix  = /mmi-cad/utils/tcltk/install.sparc-solaris2
libdir	     = ${exec_prefix}/lib
srcdir	     = .

BLT_LIBRARY  = /mmi-cad/utils/tcltk/install.sparc-solaris2/lib/blt2.4

instdirs     = $(exec_prefix) $(prefix) $(libdir)

# ------------------------------------------------------------------------
# 	Directories containing Tcl and Tk include files and libraries
# ------------------------------------------------------------------------

INCLUDES	= -I. -I$(srcdir) -I$(srcdir)/..  -I/mmi-cad/utils/tcltk/install.sparc-solaris2/include -I/usr/openwin/include

# ------------------------------------------------------------------------
# 	You don't need to edit anything beyond this point
# ------------------------------------------------------------------------

#N_OBJS		= bltTed.o
V3_OBJS		= bltTri.o bltGrMt.o 

TK_OBJS		= tkButton.o tkFrame.o tkScrollbar.o 

OBJS =		bltGraph.o bltGrAxis.o bltGrBar.o bltGrElem.o \
		bltGrGrid.o bltGrHairs.o bltGrLegd.o bltGrLine.o \
		bltGrMarker.o bltGrMisc.o bltGrPen.o bltGrPs.o \
	       	bltBeep.o bltBgexec.o bltBitmap.o bltBusy.o \
		bltContainer.o bltCutbuffer.o bltDebug.o bltDnd.o \
		bltHier.o bltHtext.o bltSpline.o bltTable.o bltTabset.o \
		bltVector.o bltWatch.o bltWinop.o \
		bltCanvEps.o bltInit.o bltBind.o bltColor.o \
		bltConfig.o bltImage.o bltInput.o bltList.o \
		bltNsUtil.o bltParse.o bltPs.o bltText.o bltTile.o \
		bltUnixPipe.o bltUtil.o \
		$(TK_OBJS) $(N_OBJS) 

# GNU Make-specific macro
SRCS 		= $(patsubst %.o,$(srcdir)/%.c,$(OBJS)) 

bltlib  	= libBLT.a
CC_SWITCHES	= $(EXTRA_CFLAGS) $(CFLAGS) $(DEFINES) $(INCLUDES)
INSTALL  	= /utility/bin/ginstall -c
INSTALL_DATA  	= ${INSTALL} -m 644
RANLIB   	= ranlib
SHELL    	= /bin/sh
AR       	= ar rc
RM       	= rm -f
LINT		= lint
LINTFLAGS	= -axhbns

all: $(bltlib)

$(bltlib):  $(OBJS)
	$(RM) $@
	$(AR) $@ $(OBJS)
	$(RANLIB) $@

install: mkdirs $(bltlib) 
	$(INSTALL_DATA) $(bltlib) $(libdir)
	$(RANLIB) $(libdir)/$(bltlib)

mkdirs:
	@for i in $(instdirs) ; do \
	    if test ! -d $$i ; then \
		echo " mkdir $$i" ; \
		mkdir $$i ; \
	    fi ; \
        done

lint:
	$(LINT) $(LINTFLAGS) $(DEFINES) $(INCLUDES) $(SRCS)

clean:
	$(RM) $(OBJS) $(bltlib) *pure* .pure*

distclean: clean
	$(RM) $(srcdir)/*.bak $(srcdir)/*\~ $(srcdir)/"#"*  Makefile


bltInit.o: bltInit.c
	$(CC) -c $(CC_SWITCHES) $(DEF_BLTINIT) $<

.c.o:
	$(CC) -c $(CC_SWITCHES) $<
