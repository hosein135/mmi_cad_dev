# RCS $Revision: 1.7 $
RELDIR       = /volume/mmi/build/lib
TCLRELDIR    = $(RELDIR)/tcl8.0
TKRELDIR     = $(RELDIR)/tk8.0

CURRENT_RELEASE = $(MMI_TOOLS)

TCLFILES = call_by_keyword.tcl share_utils.tcl init.tcl proc_redef.tcl
TKFILES = dialog.tcl prop_menu.tcl fs_box.tcl entry.tcl menu.tcl \
	listbox.tcl scale.tcl scrlbar.tcl text.tcl tk.tcl tkfbox.tcl

# Copy the shared tcl files to the release tcl/tk directories.
# These do not need a chmod, because that is taken care of
# when the installation is actually built.
install: $(TCLFILES) $(TKFILES)
	-cd $(TCLRELDIR); rm -f $(TCLFILES)
	cp $(TCLFILES) $(TCLRELDIR)
	cd $(TCLRELDIR); rm -f tclIndex; auto_mkindex
	-cd $(TKRELDIR); rm -f $(TKFILES)
	cp $(TKFILES) $(TKRELDIR)
	cd $(TKRELDIR); rm -f tclIndex; auto_mkindex

# I don't have privledges for chmod on these
lee: $(TCLFILES) $(TKFILES)
	cp $(TCLFILES) $(TCLRELDIR)
	cp $(TKFILES) $(TKRELDIR)

# Slam em directly into the current library that is in use.
# Shouldnt use this at mmi, but can use at a remote site.
direct: $(TCLFILES) $(TKFILES)
	-cd $(CURRENT_RELEASE)/lib/tcl; chmod +w $(TCLFILES) tclIndex
	cp $(TCLFILES) $(CURRENT_RELEASE)/lib/tcl
	cd $(CURRENT_RELEASE)/lib/tcl; rm tclIndex; auto_mkindex
	-cd $(CURRENT_RELEASE)/lib/tk; chmod +w $(TKFILES)
	cp $(TKFILES)  $(CURRENT_RELEASE)/lib/tk
	cd $(CURRENT_RELEASE)/lib/tk; rm tclIndex; auto_mkindex
