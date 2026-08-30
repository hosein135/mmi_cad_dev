# Generated automatically from Makefile.in by configure.
# ------------------------------------------------------------------------
#       Makefile for demonstation shell of BLT library
# ------------------------------------------------------------------------

# ------------------------------------------------------------------------
#       C Compiler options 
# ------------------------------------------------------------------------

DEFINES      = 
CFLAGS       =  
EXTRA_CFLAGS = -Wwrite-strings -Wshadow -Wtraditional -fwritable-strings -Wall
CC 	     = gcc

# ------------------------------------------------------------------------
#       Source and target installation directories
# ------------------------------------------------------------------------

prefix	     = /mmi-cad/utils/tcltk/install.i486-linux2.2
exec_prefix  = /mmi-cad/utils/tcltk/install.i486-linux2.2
srcdir	     = .
bindir       = ${exec_prefix}/bin
includedir   = ${prefix}/include
libdir	     = ${exec_prefix}/lib

instdirs  = $(prefix) $(exec_prefix) $(bindir) $(libdir) $(includedir)

# ------------------------------------------------------------------------
#       Include directives for Tcl, Tk, and X include files 
# ------------------------------------------------------------------------

INCLUDES     = -I.  -I/mmi-cad/utils/tcltk/install.i486-linux2.2/include -I/usr/X11R6/include

# ------------------------------------------------------------------------
#       Libraries directives for Tcl, Tk, X11, and BLT
# ------------------------------------------------------------------------

LIBRARIES    =  -L/mmi-cad/utils/tcltk/install.i486-linux2.2/lib -ltk8.0${TK_DBGX} -ltcl8.0 -L/usr/X11R6/lib -lX11 -lm -lnsl  -ldl

# ------------------------------------------------------------------------
#       Don't edit anything beyond this point
# ------------------------------------------------------------------------

demo 	     = bltwish
headers	     = blt.h

CC_SWITCHES  = $(EXTRA_CFLAGS) $(CFLAGS) $(DEFINES) $(INCLUDES)
LDFLAGS      = -Wl,-rpath,${exec_prefix}/lib:/mmi-cad/utils/tcltk/install.i486-linux2.2/lib:/usr/X11R6/lib
INSTALL      = /usr/bin/install -c
INSTALL_DATA = ${INSTALL} -m 644
RANLIB 	     = ranlib
SHELL 	     = /bin/sh
RM 	     = rm -f
LN_S	     = ln -s

subdirs	     = src src/shared demos library man 

all:  bltwish shared lib.tcl manuals 

bltwish: static
	@echo "making BLT demo \"bltwish\"..."
	$(RM) bltwish
	$(CC) $(CC_SWITCHES) $(LDFLAGS) \
		$(srcdir)/bltUnixMain.c -o bltwish ./src/libBLT.a $(LIBRARIES) 
	@echo "make finished on `date`"

shared:
	(cd src/shared; $(MAKE) CFLAGS="$(CFLAGS)" all) 
static: 
	(cd src; $(MAKE) CFLAGS="$(CFLAGS)" all) 

lib.tcl:
	(cd library; $(MAKE) CFLAGS="$(CFLAGS)" all) 
manuals:
	(cd man; $(MAKE) CFLAGS="$(CFLAGS)" all) 


install: bltwish mkdirs install-headers install-libs 
	$(INSTALL) -m 0755 bltwish $(bindir)/bltwish2.4
	(cd $(bindir); $(RM) bltwish ; $(LN_S) bltwish2.4 bltwish)

mkdirs:
	@for i in $(instdirs) ; do \
	    if test ! -d $$i ; then \
		echo " mkdir $$i" ; \
		mkdir $$i ; \
	    fi ; \
        done

install-headers:
	@for i in $(headers) ; do \
	    echo "installing $(includedir)/$$i..." ; \
	    $(INSTALL_DATA) -m 0444 $(srcdir)/$$i $(includedir) ; \
	done

install-libs:
	@for i in $(subdirs) ; do \
	    (cd $$i; $(MAKE) install) ; \
	done

clean:
	@for i in $(subdirs) ; do \
	    echo "cleaning $$i..." ; \
	    (cd $$i; $(MAKE) clean) ; \
	done
	$(RM) bltwish *.bak *\~ "#"* *pure* .pure*

.c.o:
	$(CC) -c $(CC_SWITCHES) $<

GENERATED_FILES = \
	config.status config.cache config.log \
	config.BLT src/bltConfig.h \
	Makefile \
	src/Makefile \
	src/TAGS \
	src/shared/Makefile \
	man/Makefile \
	library/Makefile \
	demos/*.ps

distclean: 
	@for i in $(subdirs) ; do \
	    echo "cleaning $$i..." ; \
	    (cd $$i; $(MAKE) distclean) ; \
	done
	$(RM) bltwish *.bak *\~ "#"* *pure* .pure*
	$(RM) $(GENERATED_FILES)

PUREFLAGS=
pure: static
	$(PURIFYHOME)/purify $(PUREFLAGS) $(CC) $(CC_SWITCHES) \
		$(srcdir)/bltUnixMain.c -o bltwish ./src/libBLT.a $(LIBRARIES)

QUANTIFYFLAGS=
quant: static
	$(QUANTIFYHOME)/quantify $(QUANTIFYFLAGS) $(CC) $(CC_SWITCHES) \
		$(srcdir)/bltUnixMain.c -o bltwish ./src/libBLT.a $(LIBRARIES)
