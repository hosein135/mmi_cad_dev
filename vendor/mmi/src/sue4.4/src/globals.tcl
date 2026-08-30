## ************************************************************************
## 
## Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
## Portions Copyright (c) 1994 Sun Microsystems, Inc. All rights reserved.
## 
## Permission is hereby granted, without written agreement and without
## license or royalty fees, to use, copy, modify, and distribute this
## software and its documentation for any purpose, provided that the
## above copyright notice and the following three paragraphs appear in
## all copies of this software.
## 
## IN NO EVENT SHALL JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS, INC. BE
## LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
## CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
## DOCUMENTATION, EVEN IF JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS,
## INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
## 
## JUNIPER NETWORKS, INC. AND SUN MICROSYSTEMS, INC. SPECIFICALLY
## DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
## WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
## NON-INFRINGEMENT.
## 
## THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
## NETWORKS, INC. AND SUN MICROSYSTEMS, INC. HAVE NO OBLIGATION TO
## PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
## 
## ************************************************************************


# Initialize all global variables
# all GLOBAL variables should be in upper case.

# NOTE: must be coordinated with .suerc

init_global SUE_EXECUTE -flags "user startup" -type LIST_OF_LISTS \
    -default "" -desc {

Contains a list of commands which get executed after SUE comes up but before
any command line commands get executed.

Any SUE commands, like api calls, that should be executed at start up
should be add to this variable in the .suerc file, preferably with the
lappend command.  API commands cannot be executed directly from .suerc
files sinces SUE is not yet initialized at that point.  For example, adding the following lines to your local .suerc file:

        lappend SUE_EXECUTE \
            "api_icon_listbox -command change -dir $SUE_DIR/schematics/devices -index 1"
        lappend SUE_EXECUTE \
            "api_icon_listbox -command change -dir $SUE_DIR/schematics/mspice -index 2"

Will set the listboxes at startup.

NOTE: illegal command syntax here can cause SUE to error out before starting up.
}


# This file sets up the defaults for lots of SUE properties.
# If you want to customize certain function for yourself only, copy
# this file into ~/.suerc and make the appropriate changes.

############################################################################
############################################################################
###################   Key Binding defaults #################################
############################################################################
############################################################################

# Warning: if you go and change any of these hotkey definitions then
# your system will be virtually unusable by other SUE users.  Do you 
# really want to do that?


# File menu
set KEYS(new_schematic) Control-n
set KEYS(open) Control-l

set KEYS(save) Control-s
set KEYS(save_and_descendents) Control-w

set KEYS(raise_windows) Control-r

set KEYS(print) Control-t

set KEYS(exit) Control-d

# Edit menu
set KEYS(undo) u

set KEYS(cut_to_clipboard) Alt-x
set KEYS(copy_to_clipboard) Alt-c
set KEYS(paste_from_clipboard) Alt-v

set KEYS(add_wire) w
set KEYS(add_text) t
set KEYS(add_line) l
set KEYS(add_arc) A

set KEYS(delete) Delete
set KEYS(duplicate) d
set KEYS(rotate) r
set KEYS(flip_sideways) x
set KEYS(flip_upsidedown) y
set KEYS(move) m
set KEYS(replace_instance) b
set KEYS(duplicate_text) T
set KEYS(lower) i

# View menu
set KEYS(push_into) e
set KEYS(pop_out_of) Control-e
set KEYS(pop_connected) Alt-e
set KEYS(swap_views) c
set KEYS(make_other_view) C

set KEYS(zoom_in_on_cursor) a
set KEYS(zoom_to_region) z
set KEYS(zoom_out) Z
set KEYS(zoom_to_fit) v
set KEYS(zoom_to_fit_selected) V
set KEYS(pan) j

set KEYS(select_by_name) n

set KEYS(show_text_anchors) Control-a
set KEYS(show_sel_term_names) Control-v

set KEYS(toggle_grid) g
set KEYS(change_grid_spacing) G
set KEYS(ruler) Control-r

set KEYS(display_cell_doc) D

# Other

set KEYS(nudge_up) Up
set KEYS(nudge_down) Down
set KEYS(nudge_left) Left
set KEYS(nudge_right) Right

# Sim Menu
set KEYS(netlist) N
set KEYS(spice_it) h		;# or verilog_it, etc.
set KEYS(init_probe) Control-i
set KEYS(init_probe_options) Control-j
set KEYS(generate_term_names) Control-g

set KEYS(max_cross_probe) k

set KEYS(plot_net) p
set KEYS(unplot_net) o
set KEYS(plot_net_remember) P
set KEYS(unplot_net_forget) O
set KEYS(plot_old_net) Control-p
set KEYS(unplot_old_net) Control-o

set KEYS(toggle_placement_view) q
set KEYS(display_in_other_view) S

set KEYS(irsim_step) s		;# or verilog step
set KEYS(irsim_set_hi) 9
set KEYS(irsim_set_low) 0
set KEYS(irsim_set_x) X

set KEYS(edit_verilog) E


############################################################################
############################################################################
################   Windowing defaults  #####################################
############################################################################
############################################################################

# default window sizes for the main window, the schematic listbox and the
# icon listbox.  Setup mode of listboxes also using ICON_MENU.

# if ICON_MENU is set to flat then you get the "old-style" single flat
# icon menu.  Geometry will use "icons".
# set ICON_MENU flat
set GEOMETRY(icons) 130x600-5-50
set GEOMETRY(schematics) 130x220-5+2

#set ICON_MENU hier
set GEOMETRY(icons1) 130x290-5-359
set GEOMETRY(icons2) 130x290-5-40

# Schematics/Icons listboxes included in the main window
set ICON_MENU include

# This will give you 3 icon windows (along with the one schematic window)
set ICON_WINDOWS "icons1 icons2 icons3"

if {$ICON_MENU == "flat" || $ICON_MENU == "hier"} {
  # This window size is good if you don't have ICON_MENU set to include
  set GEOMETRY(window) 960x850+50+2
} else {
  # Otherwise use this one
  set GEOMETRY(window) 1096x850+50+2
}

# Width (in characters) of icons/schematics listboxes in "include" mode
set GEOMETRY(listbox) 15

# Set up the default colors
# Don't set the grid to black or you might have problems printing.
#set COLORS(main) moccasin
# old means the way sue looked in older versions.
set COLORS(main) old

init_global COLORS -flags user -type ARRAY -desc {

Color array for specifying foreground, background, object, etc
colors in SUE.

The colors can be specified as either legal names as defined in
rgb.txt (see /usr/openwin/lib/X11/rgb.txt for sparc or
/usr/X11/lib/X11/rgb.txt for linux) or as RGB values.  RGB values must
be given in the form of #RRGGBB, where RR, GG, and BB are 2 digit hex
values (is this gross or what).

SUE uses the follwing colors:

        background       Background color of SUE window.
        fore             Standard objects color (i.e. foreground color).
        active           Current object color-- i.e. the object under the
                         cursor.  This object will be selected if Button-1
                         is pressed.
        selected         Selected object color.
        selected,active  Selected and active object color.
        anchor           Text anchor color.  Also temporary annotation color.
        grid             Grid color.
        stroke_box       Stroke box color.
}


set COLORS(background) grey
set COLORS(fore) black
set COLORS(selected) blue
set COLORS(active) white               ;# active has pointer on it, not sel.
set COLORS(selected,active) yellow     ;# active and selected
set COLORS(stroke_box) red
set COLORS(anchor) white	       ;# used for back-annotation, too
set COLORS(grid) #e0e0d0               ;# like ivory2


### FONT SETUP

# "standard" means SUE only uses the standard size fonts available on all 
# X-servers (8,10,12,14,18,24). "extended" uses continuous font sizes from
# 2 point to 80 point.  These fonts are included in the font directory
# supplied with SUE.  To use these fonts, you need to go into the sue
# startup script and uncomment out the lines as directed which will
# add these fonts to the font path.  Otherwise SUE will generate them
# each time you start SUE.

set FONT_MODE extended
#set FONT_MODE standard

# When using standard FONT_MODE, this will allow you to change the
# smallest font.  "nil2" is a good one if your machine has it.
#set FONT(tiny) nil2
set FONT(tiny) -*-*-*-*-*-*-2-*-*-*-*-*-*-*

# font ratio of small to standard and large to standard size fonts
set FONT(very-small) 0.3
set FONT(small) 0.6
set FONT(standard) 1.0
set FONT(large) 1.5
set FONT(very-large) 3.0

# Default font size for menus, etc.
option add *Font *-helvetica-Bold-R-Normal-*-14-*

# need a fixed width font here or the modify flags looks weird
set LISTBOX_FONT *-courier-Bold-R-Normal-*-12-*

# need a fixed width font here so the document looks right
set HELP_FONT *-courier-Bold-R-Normal-*-12-*

init_global GRID_SPACING -flags user -type INTEGER_LIST -default 8 -desc {

Spacing of visible grid lines when grid is enabled.  A spacing of 1 
corresponds to the minimum wiring grid in SUE.

To display grid lines with different spacings in X and Y, set
GRID_SPACING to a list of 2 integers, the first for X and the second for Y.
For example:

        set GRID_SPACING "4 8"
}

init_global DISPLAY_PROPS -flags "user startup" -type LIST_OF_LISTS \
    -default {{name ul} {M ur M=} {dpc ll "dpc "}} -desc {

Determines how and which properties should be displayed on icons.
Each included property will be displayed at the given location using
the given format if it is non-nil and isn't already being displayed
explicitly in the icon.  

For each property, the property name, location, and optional format is
defined.  The locations can be any one of the following:

        upper-left (ul)
        upper-right (ur) 
        lower-left (ll)
        lower-right (lr)
        origin.

The property is displayed as:

        <format><property_value>

The format defaults to nil.

Note that icons with property "primitive" never display properties.

For example, with the following settings:

        set DISPLAY_PROPS {{name ul} {M ur M=} {dpc ll "dpc "}}

The value of the "name" property is displayed in the upper-left corner
of the bounding-box of each instantiation of each icon.  The position
of the "name" property on a given icon can be changed by adding the
text "$name" to its icon view in the desired location.  This will
override the default position.

The value of the "M" property (used for making multiple identical
devices in HSPICE) is displayed in the upper-right corner of each
instantiation of each icon if it's value is non-nil.  Furthermore, it
is display with a format prefix of "M=".  Thus an icon with an "M"
property of 2 would display the string "M=2", while an icon without an
M property defined would display nothing (NOT "M=").
}

# These properties are not displayed
set HIDDEN_PROPS ""

init_global DISPLAY_COORDS -flags user -default "" -type STRING -desc {

Controls whether to display the coordinates of the selected object in
the SUE message window.

Displays if set to non-nil, else doesn't display.
}

# Sets the size of the I/O names in terminals if your I/O devices are
# set up to use this. (small | standard | large)
set IO_PROP_SIZE standard

# After netlisting or generating term names, display any buses as
# fat wires if set.
set SHOW_WIRE_WIDTH 1

init_global AUTO_SAVE(interval) -flags user -default 15 -type INTEGER -desc {

Interval in minutes for auto-saving modified buffers.
If set to 0, auto-saving is disabled.

Modified buffers get automatically saved to disk with the suffix
defined by SUFFIX(auto_save).  The auto-save interval starts from when
a buffer is first modified, after either a save or an auto-save.  If
the buffer is saved before the auto-save interval is up, then the
auto-save is reset.
}


############################################################################
############################################################################
####################   Miscellaneous  ######################################
############################################################################
############################################################################

# To include libraries and automatically loading libraries
# other than on the command line, add lines like these to your .suerc
# Note: an autolib will automatically load all of the cells in the lib.
# lappend LIB <your_lib> <your_lib> ...
# lappend AUTOLIB <your_autolib> <your_autolib> <your_autolib>

# Suffix for schematic/icon files
set SUFFIX(default) .sue
# Suffixes for all files used by SUE (used in creating tclIndex)
set SUFFIX(tclindex) "*$SUFFIX(default) *.tcl"
# For backups of schematic/icon files
set SUFFIX(backup) .BAK
# For auto-saved files
set SUFFIX(auto_save) .sue_as
# For warning/error logs
set SUFFIX(log) .log
# For postscript output files
set SUFFIX(postscript) .ps
# For spice and verilog input decks
set SUFFIX(spice) .sp
set SUFFIX(spice_header) .h
set SUFFIX(verilog) .vh
set SUFFIX(verilog_header) .vi
set SUFFIX(behavioral_verilog) .vb
set SUFFIX(dpc) .vg
set SUFFIX(csim) .csim
set SUFFIX(flat_spice) .sp
set SUFFIX(sim) .sim
set SUFFIX(netlist_cache) .cache
set SUFFIX(merge) ^
set SUFFIX(back_annotate) _lay.sim
set SUFFIX(cell_doc_text) .doc
set SUFFIX(cell_doc_html) .html
# for datapath compiler
set SUFFIX(slow_nodes) .slow_nodes
set SUFFIX(timing_in) .timing_in
set SUFFIX(timing_out) .timing_out
set SUFFIX(dpc_est_cap) .est_cap
set SUFFIX(dpc_est_dspf) .est_dspf
set SUFFIX(dpc_ports) .ports
set SUFFIX(timing_constraint) .constraint

init_global DEFAULT_EDITOR -flags user -default emacs -type STRING -desc {

If your unix environment variable EDITOR is not set, this value will
select which editor SUE should use during functions like "display cell
doc", "edit verilog", or "edit object names".

NOTE: this variable is only used if your unix environment variable
EDITOR is not set.

Typical editors are emacs, xemacs, or vi.
}

init_global DEFAULT_BROWSER -flags user -default netscape -type STRING -desc {

If neither the unix environment variables MMI_BROWSER of BROWSER are
set then this value will select the browser that SUE will use for
displaying html documentation.
}

init_global BATCH -flags user -type BOOLEAN -default 0 -desc {

If set to 1 (true) then all popup queries are bypassed with the same
result as if the user hit the OK button.  Useful for scripts that run
in batch mode.

}


set SCHEM_DIR(devices) $SUE_DIR/schematics/devices
# spice directory is for spice models that have been scaled so don't require
# the user to explicitly put in um's.  For example W=2.0
#set SCHEM_DIR(spice) $SUE_DIR/schematics/spice
# mspice directory is for spice models that require um's.  For example W=2.0u
set SCHEM_DIR(spice) $SUE_DIR/schematics/mspice

set SCHEM_DIR(verilog) $SUE_DIR/schematics/verilog

# auto mount prefix to be stripped
set AUTO_MOUNT_PREFIX tmp_mnt

init_global DONT_REPLACE_PROPS -flags user -default {name M} \
    -type LIST -desc {

List of properties that don't get replaced when running "replace
instance" from the "Edit" menu.

}

init_global READ_ONLY -flags user -default 0 -type BINARY -desc {

Determines if newly loaded cells will be set to read-only (no
modifications allowed) by default.  If true (1) all newly loaded cells
will be read-only.

Changing the status of "all cells" in the "toggle read only" menu
option, will change the value of this command for this SUE session.
}

# If the file is smaller than the BACKUP_PERCENTAGE times the backup
# file then the the backup won't be overwritten.  Prevents accidental
# loss of data.
set BACKUP_PERCENTAGE 0.3

# If DEFAULT_SCCS is non-nil then all files will automatically be
# saved in SCCS irrespective if they have an sccs_title_bar or not.
#set DEFAULT_SCCS 1

# If you can't get people to get their paths correct for sccs, 
# uncomment out the full path, otherwise just "sccs" is fine.
#set SCCS /usr/ccs/bin/sccs
set SCCS sccs

# Default message to SCCS if a new one isn't enterred in an sccs_title_bar.
set DEFAULT_SCCS_COMMENT "Modified from SUE."

# If your machine doesn't have sccs, remove the comment on the next line
# set NO_SCCS 1

# if set to 1, pops up an error window whenever there is a SUE error.
# If 0, just displays the error message in the TCL window.
set ERROR_POPUP 1

# File name (and path) for the sue clipboard.  Should be unique to a
# user and writable by the user.
set CLIPBOARD_FILE ~/.clipboard.sue

init_global DEFAULT_PROPERTIES -flags user -type LIST \
    -default {{-type user -name name} {-type user -name M} {-type user -name dpc}} \
    -desc {

List of properties added to all newly created icons.  This is merely a
convenience item.

}

# choice of {popup radio choice}
# can be overridden in -option field of -user property
set DEFAULT_PROP_MENU_TYPE radio

# This array is for generators that are not defined in SUE files.  
# Mainly used for compatibility with older non-generator icons.
set GENERATORS(name_net) "generate name_net_s name_net -cell name_net"
set GENERATORS(name_net_sw) "generate name_net_s name_net_sw -cell name_net_sw"
set GENERATORS(sccs_title_bar) "generate title_bar sccs_title_bar -cell sccs_title_bar"
set GENERATORS(cvs_title_bar) "generate title_bar cvs_title_bar -cell cvs_title_bar"

# PRINT() controls various printing defaults

init_global PRINT(A,COMMAND) -flags user -type STRING \
    -default "lpr -r %s" -desc {

Default command to print an "A" size schematic/icon postscript file
generated from SUE when using the "print" command in the "File" menu.
The "-r" switch to lpr removes the file after printing.

Can be overridden in the "print setup..." command in the "File" menu.

}

set PRINT(B,COMMAND) "lpr -r -Plpb %s"
set PRINT(A,SIZE) "8.5in 11in"
set PRINT(B,SIZE) "17in 11in"
# either "print" for printer or "file" for print to file.
set PRINT(MODE) print
# 1 is for landscape, 0 is for portrait, 2 is for largest orientation
set PRINT(ORIENT) 2

init_global PRINT(PAGE_SIZE) -flags user -type STRING \
    -default A -desc {

Default page size at which to print the schematic/icon.  The page size
dimensions for this size are defined in PRINT($PRINT(PAGE_SIZE),SIZE)
and the print command for this size is defined in
PRINT($PRINT(PAGE_SIZE),COMMAND).

Can be overridden in the "print setup..." command in the "File" menu.

}

init_global PRINT(PAGE_SIZES) -flags user -type LIST \
    -default "A B" -desc {

Possible page sizes available for printing.  

Pages sizes are defined by specifying PRINT(<page_size>,SIZE) and
PRINT(<page_size>,COMMAND).

}


# print either "permanent" features of cell or "everything", including
# temporary values backannotated, selection, grid, etc.
set PRINT(TYPE) permanent
# margin of white space around border of page (in inches)
set PRINT(MARGIN) 0.3
# number of pages a schematics gets printed across, either 1 (normal), 2, or 4.
set PRINT(PAGES) 1
# for inclusion of encapsulated ps into documents you want no margins, just
# the exact bounding box of the figure.  1 is this.  0 is for printing.
set PRINT(EXACT_BBOX) 0
# 1 means when printing with leaves, don't print the icon if the
# schematic exists.  0 means always print both icons and schematics.
set PRINT(SCHEM_ONLY) 1
# font scaling for printing
set PRINT(font_scale) 1.5

# Can change these only when plotting "permanent"
# standard solid lines
set PRINT(ICON_COLOR) {0.0 0.0 0.0 setrgbcolor}
# dashed lines in icons
#set PRINT(ICON_COLOR) {[2] 1 setdash}
# standard solid lines for wires
set PRINT(WIRE_COLOR) {0.0 0.0 0.0 setrgbcolor}
# dashed lines for wires
#set PRINT(WIRE_COLOR) {[2] 1 setdash}

# When printing with leaves, don't print any schematics or icons from
# these directories.  Generators is where SUE thinks generated cells are from
set PRINT(DONT_PRINT_DIRS) { \
  $SCHEM_DIR(devices) $SCHEM_DIR(spice) $SCHEM_DIR(verilog) \
  generators \
  }	

# When printing, these icons won't show up.
set PRINT(DONT_PRINT_ICONS) "flag"

# Depth of undo stack
set UNDO_LEVEL 100

# Setup arrow head patterns for line drawing.  Arrow heads should
# point to the right
set ARROWS(current) var1
set ARROWS(generic) {{-10 3} {-5 0} {-10 -3} {0 0}}
set ARROWS(var1) {{-5 1} {-10 3} {-5 0} {-10 -3} {-5 -1} {0 0}}

# This is the autorepeat delay for people who want to hold the space bar down.
# The number (in ms) is the amount of time between allowed space keystrokes.
# If people understand that they're not supposed to sit on the space key,
# then set this to 0.
#set IDIOT_DELAY 500
set IDIOT_DELAY 0

# nudge delay should be set to slightly longer than the auto-repeat delay
# for the keyboard or it won't work too well
set NUDGE_DELAY 1000

############################################################################
############################################################################
################   Netlisting/Simulation defaults  #########################
############################################################################
############################################################################

# MODE is used for Sim menu, choice of default icons to load, and netlisting/
# probing commands.  This can be overridden on the command line or with the
# environmental variable SUE_MODE.
set DEFAULT_MODE spice
#set DEFAULT_MODE verilog

# if 1, loaded cells will "flash" on screen during netlisting
set FLASH_CELL_ON_LOAD 0

# Path to search for verilog functions in verilog mode when editing verilog
# for a schematic/icon.  Note that the "." corresponds to the current
# working directory (pwd) at startup and the directory from which the
# schematic/icon came from will always be checked also.
set VERILOG_PATH ". ./verilog ./lib.v"

# Path to search for back annotation capacitance files
# for a schematic.  Note that the "." corresponds to the current
# working directory (pwd) at startup and the directory from which the
# schematic came from will always be checked also.
set BACK_ANNOTATE_PATH ". ./max ../max"

init_global NETLIST_TYPE -flags "user netlist" -type STRING \
    -desc {

Determines which netlister to run.

Valid netlisters are: verilog, dpc, spice, flat_spice, sim.

This variable and its companion, NETLIST_PROPS, should be changed
together.

If changed after SUE is initialized (i.e. not in a .suerc file), then
should be followed by a call to api_change_simulation_mode.

}

init_global NETLIST_PROPS -flags "user netlist" -type LIST \
    -desc {

A string (or list if more than one) containing the icon properties that
will be used when netlisting.

}


# disk caches are enabled if this is set to disk
#set CACHE_TYPE ""
set CACHE_TYPE disk

init_global MAX_BUS_WIDTH -flags user -type INTEGER \
    -default 256 -desc {

Maximum bus width allowed during netlisting.  A value greater than
this flags an error.

}

init_global NETLIST_CONVERT_CONSTANT -flags user -type BINARY \
    -default 0 -desc {

If true (1) then all non-binary constants (hex, decimal, and octal)
will be converted to binary in verilog netlists.  Set this if any
downstream tools don't handle these constant types.

NOTE: you may need to remove .cache files to see the effect of changing this.

}

init_global SPICE_EXTRACTED_CELL_PATH -flags "user simulation" -type LIST \
    -default "" -desc {

List of paths to search for when spice/flat_spice netlisting to use
extracted subckt definitions for.  Useful for simulating with
extracted leafcell netlists.

Extracted netlists must have the filename of
<subckt>.<netlist_suffix>.  If they contain additional subckt
definitions, there may be conflicts with other cells.

SUE will search in order through the directories to try to find
the appropriate subckts to include.  If it doesn't find one, it just
netlists as usual from the schematic for that cell.

NOTE: the order of the I/O's in the extracted subckt definition MUST
match SUE's default calling order.  

NOTE: don't point this variable at a path which includes SUE generated
.sp files or you may get unexpected results.

}

init_global SPICE_PROBE_TYPE -flags "user simulation" -type STRING \
    -default NST -desc {

Waveform viewer to use for cross-probing in spice mode.
}

#set SPICE_PROBE_TYPE simwave

set FLAT_SPICE_PROBE_TYPE NST

# If defined to 1, then uncomments out .SUBCKT and .ENDS statements
# in flat_spice netlisting.
#set FLAT_SPICE_SUBCKT 1

# Note: simwave only works with a special version of the wd tool.

# Directory for new spicetool and default window geometry/placement

init_global GEOMETRY(NST) -flags "user simulation" -type STRING \
    -default 1050x850-6-27 -desc {

Default NST window size and placement for cross-probing.

}

init_global SPICE_PROBE_CMD(NST) -flags "user simulation" -type STRING \
    -default {nst -geometry $GEOMETRY(NST) $PROBE_DISPLAY} -desc {

Command to start up NST from SUE for cross-probing.

NOTE: this string gets evaluated just before execution to allow
current global variables to be used.

}

set SPICE_PROBE_CMD(simwave) {magellan $PROBE_DISPLAY}

# There is no "sim" mode per say, however...
set SIM_PROBE_TYPE analyzer

# Command to start up new analyzer in irsim (is evaluated later)
set SIM_PROBE_CMD(analyzer) "irsim $SUE_DIR/schematics/spice/hp-cmos26b.prm"

# Sim netlisting setup
set SIM_SCALE 100e6
# This line will be the first line of a SIM netlist
set SIM_HEADER "| units: [expr 100e6/$SIM_SCALE]  tech: sue  format: MIT"

init_global SIM_PARAMS -flags user -type ARRAY -desc {

For creating sim files for LVS and cross-probing with max.  

Need to set the values here for any SPICE parameters you use.

For Example:

        set SIM_PARAMS(ln_min) 0.24u
        set SIM_PARAMS(lp_min) 0.24u
}

set SIM_PARAMS(ln_min) 0.24u
set SIM_PARAMS(lp_min) 0.24u
set SIM_PARAMS(wp) 2
set SIM_PARAMS(wn) 1

# in verilog mode, VERILOG_PROBE_TYPE will be the probe of choice

# for signalscan
#set VERILOG_PROBE_TYPE signalscan
# Note, this geometry doesn't understand -x-y.  Must be pluses.
set GEOMETRY(signalscan) 1000x800+50+100
set VERILOG_PROBE_CMD(signalscan) {signalscan -stdio -auto $PROBE_DISPLAY}

# Use simwave waveform viewer
#set VERILOG_PROBE_TYPE simwave
set VERILOG_PROBE_CMD(simwave) {magellan $PROBE_DISPLAY -inputformat vcd}

# Run verilog in interactive mode, displaying values in "flags" in SUE
# Note: to use this mode, the top level verilog module must contain the line:
#   integer         tmp_channel;

set VERILOG_PROBE_TYPE interactive

# uncomment out this line to prevent automatic flag update when
# pushing into and out of cell in interactive verilog/irsim modes
#set UPDATE_FLAGS(__off__) 1

set DISPLAY_TERMS(verilog) "%h"

init_global VERILOG_CMD -flags "user simulation" -type STRING \
    -default {verilog +libext+.vb+.v -y . -y lib.v} -desc {

Command to run verilog when executing "verilog_it" in the "Sim" menu.
The current cell is appended to this string before it is executed.

If using vcs, you must include the -R flag.

}

init_global VERILOG_PROBE_CMD(interactive) -flags "user simulation" \
    -type STRING \
    -default {verilog -s +libext+.vb+.v -y . -y lib.v} -desc {

Command to run when executing "init probe" in the "Sim" menu.
The current cell is appended to this string before it is executed.

If using vcs, you must include the following flags "+cli -O0 -R" and
for version 4.1 or earlier use "+cli+2 -O0 -R".  NOTE: due to a
limitation in the vcs cli, you cannot use the interactive feature of
SUE if your verilog uses the $fopen command.

}

init_global VERILOG_STEP -flags "user simulation" -type NUMBER \
    -default 10 -desc {

This values specifies the amount of simulation time to step forward
when the "step verilog" command is executed from the "Sim" menu.

}

# filename of default header (.h) file for spice and verilog
set DEFAULT_SPICE_HEADER {$SCHEM_DIR(spice)/default_spice_header.h}
set DEFAULT_VERILOG_HEADER {$SCHEM_DIR(verilog)/default_verilog_header.h}

# If you netlist SPICE with no headers, you can still include
# something with the following line
#set SPICE_INCLUDE "* included in spice netlist"

# List of possible spice hosts to look for spice jobs on so we can kill
# them if desired.
set SPICEHOSTS [exec uname -n]

init_global SPICE_TYPES -flags "user netlist" -type LIST \
    -default "spice adm powermill" -desc {

List of types of spice-like simulators available at site.
}

# default spice output suffixes for each spice type
set SPICE_SUFFIX(spice) .tr0
set SPICE_SUFFIX(adm) .xp
set SPICE_SUFFIX(powermill) .
set SPICE_SUFFIX(intel) .split

init_global SPICE_SUFFIX -flags "user netlist" -type ARRAY -desc {

This array provides the suffixes for the spice-like output data files
for cross-probing.
}


init_global SPICE_TYPE -flags "user netlist" -type STRING \
    -default spice -desc {

Spice-like simulator for spice netlist format.  Also set in "Select Simulator".

To change list of simulators seen in "Select Simulator" change SPICE_TYPES.
}


init_global NETLIST(warning) -flags "user netlist" -type BINARY \
    -default 1 -desc {

If true (1), prints netlist warnings of unconnected nets.  If false
(0), ignore. 
}


init_global NETLIST(update_instance_names) -flags "user netlist" -type BINARY \
    -default 0 -desc {

If true (1), then after netlisting each instance will be updated with
its netlist name.

Note: this will modify the schematic.  To preserve these names, save the
cell.
}


init_global CREATE_SUGGESTED_NAMES -flags "user netlist" -type BINARY \
    -default 0 -desc {

If true (1), creates a suggested name on the schematic for any
unnamed nets during generate term names.  Useful if you don't want
these unnamed net names to change on subsequent netlists even after
the schematic changes.
}


init_global NETLIST(ignore_unconnected) -flags "user netlist" -type LIST \
    -desc {

A list Pin names that will not generate unconnected warnings during
netlisting.

For example, to not display warnings when the scan_in pin is
unconnected (presumably, a later script will hook up these pins in the
netlist), use:

         set NETLIST(ignore_unconnected) "scan_in"
}

# set this to the maximum length of the popup window in lines
# to display (the rest only go to the SUE command window).
set NETLIST(popup_length) 8

# The spice netlister will ignore these properties.
set NETLIST(ignore_spice_properties) "name dpc"


init_global NETLIST(no_header) -flags "user netlist" -type BINARY \
    -default 0 -desc {

If true (1), header files are not included in the spice or
verilog netlists.  

Also, when true, the top level spice subcircuit is not commented out.
}

# current netlisting level of cells by property.  All cell properties
# with levels equal to or greater than the current netlist level are skipped.
# Cell properties not in the NETLIST_LEVEL array are the same as being
# set to negative infinity.
set NETLIST_LEVEL(__CURRENT__) 1000

# If this is set then the netlist levels for cells will be read out of 
# the disk cache and be the same as the last netlist.  Note that the
# netlist level of a cell will set if it is undefined.
set NETLIST_LEVEL(__CACHE__) 1

init_global NETLIST_MAX_NAME_LENGTH -flags "user netlist" -type STRING \
    -default 1024 -desc {

Names longer than this will be replaced during netlisting set.
}


init_global VERILOG_ROOT -flags "user" -type STRING \
    -default test -desc {

For verilog crossprobing, SUE needs to know the top most module name
to generate full hierarchical signal names.  

}

init_global GLOBAL_TRANSLATIONS -flags user -type ARRAY -desc {

This array translate the names of globals during netlisting, depending
on the netlisting type.

The format is:

        set GLOBAL_TRANSLATIONS(<netlister>,<global>) <new_name>

For example, to map vdd and gnd to 1'b1 and 1'b0, respectively, in
verilog, use:

        set GLOBAL_TRANSLATIONS(verilog,vdd) "1'b1"
        set GLOBAL_TRANSLATIONS(verilog,gnd) "1'b0"

For verilog, if you don't map a global supply to 1'b0 or 1'b1, you
need to declare the supply.  You can do so with the following lines:

        set GLOBAL_TRANSLATIONS(verilog,supply,GND) "supply0 GND;"
        set GLOBAL_TRANSLATIONS(verilog,supply,VDD) "supply1 VDD;"

NOTE: globals must be upper case.
}

set GLOBAL_TRANSLATIONS(verilog,Vdd) "1'b1"
set GLOBAL_TRANSLATIONS(verilog,VDD) "1'b1"
set GLOBAL_TRANSLATIONS(verilog,vdd) "1'b1"
set GLOBAL_TRANSLATIONS(verilog,gnd) "1'b0"
set GLOBAL_TRANSLATIONS(verilog,GND) "1'b0"
# if you don't remap GND and VDD then you want the netlister to
# add lines of the following for supplies:
# NOTE: globals must be upper case.
set GLOBAL_TRANSLATIONS(verilog,supply,GND) "supply0 GND;"
set GLOBAL_TRANSLATIONS(verilog,supply,VDD) "supply1 VDD;"

set GLOBAL_TRANSLATIONS(spice,1'b0) gnd
set GLOBAL_TRANSLATIONS(spice,1'b1) vdd
set GLOBAL_TRANSLATIONS(flat_spice,1'b0) gnd
set GLOBAL_TRANSLATIONS(flat_spice,1'b1) vdd
set GLOBAL_TRANSLATIONS(sim,1'b0) gnd
set GLOBAL_TRANSLATIONS(sim,1'b1) vdd

# Size and position of window to display design hierarchy in.
set GEOMETRY(design_hierarchy) 250x500+100+150
# List of icon types to exclude from design hierarchy display
set EXCLUDE_ICONS "or* Or* and* And* mux* not Not Xor* Exor* Bus_combine* Bus_split*"

init_global TITLE_BAR_STRING -flags "user" -type STRING \
    -default "Change TITLE_BAR_STRING in .suerc for this string" -desc {

String that appears at the top of title bars

For example

        set TITLE_BAR_STRING "Micro Magic Inc., Confidential and Proprietary"
}


init_global MAX_EXEC -flags "user" -type STRING \
    -default {xterm $PROBE_DISPLAY -e max} -desc {

Command line to start max for cross-probing.
}


# Data path compiler setup

init_global DPC(PATH) -flags "user DPC" -type LIST -desc {

Path(s) to standard-cell/data path cell size information for DPC.

These files have the format: 

         # Comment lines start with a "#"
         # Blank lines are ignored

         <cell_name>     <width>   [<height>]
         <cell_name>     <width>   [<height>]
         ...

Where the width and (optional) height are specified in grids (routing
tracks). For Example,

            # My Standard Cell Library
            INVA      2
            INVB      4
            NAND2A    4
            FAD       10     12
            ...

In this example, all of the cells except for "FAD" would get the
default height defined by DPC(DEFAULT_ROW_HEIGHT).

Note: these values are overridden by .ports files or LEF.
}


init_global DPC(LEF_PATH) -flags "user DPC" -type LIST -desc {

A list of paths to LEF files to be used to determine cell sizes and
port locations instead or, or in addition to, DPC(PATH) or .ports
files.  If a cell is in multiple places, the LEF description will take
precedence followed by the .ports file and finally DPC(PATH).  If a
cell is duplicated in the LEF files, the last one will take
precedence.

LEF files cannot contain LEF headers.  They may only contain MACRO
definitions (i.e. cell definitions) and "END LIBRARY".

Paths may contain glob style wildcarding for LEF files.  For example,
to use all the individual cell LEF files in a given directory:

    set DPC(LEF_PATH) "/proj/tech/mmi25/stdcell/lef/*.lef"

.ports files can be used in conjuction with LEF definitions to
specify flipping and default orientation as these cannot be specified
in the LEF file.  Only bbox and port lines will be overridden in .ports
files.

Note: LEF definitions with bused pins (e.g. foo[1], foo[0]) will be
inferred into buses named <signal>[max:min].  If you intend these to
be <signal>[min:max], DPC may work incorrectly.
}


init_global DPC(VERILOG_PATH) -flags "user DPC" -type LIST -default "" -desc {

Deprecated.  See DPC(LEF) instead.
}


init_global DPC(SCALE) -flags "user DPC" -default 1 -type REAL_LIST -desc {

Scale factor to convert minimum routing grids (which DPC uses) into microns.  

NOTE: the SCALE must be chosen so that all cells are an integral
number of grids tall and wide.

For uneven grid dimensions in X and Y, use a list with the first
element specifiying the X and the second the Y scale in mask coords,
i.e. rotated 90 degrees from DPC orientation.
}

init_global DPC(PITCH) -flags "user DPC" -default 16 -type INTEGER -desc {

The default bit pitch in grids for bit slices.  

Icons with bus notation in their names (e.g. [3:0] or [2]) or dpc properties will be spaced in accordance with this PITCH value.
}

# default mode for placement, either normal or enforce bit spice (bit_slice)
set DPC(MODE) normal

# Additional space added between rows and columns.  0 means abutting.
# Note that these values are not scaled by DPC(SCALE)
set DPC(DEFAULT_ROW_SPACE) 0
set DPC(DEFAULT_COLUMN_SPACE) 0

# Size of datapath cell not found in DPC(PATH)
init_global DPC(DEFAULT_ROW_HEIGHT) -flags "user DPC" -default 10 \
    -type INTEGER -desc {

Default height given to cells not found in the DPC(PATH) and which don't
have .ports files.

Since standard cells have the same height, defaulting this value is
typically OK.
}

init_global DPC(DEFAULT_COLUMN_WIDTH) -flags "user DPC" -default 10 \
    -type INTEGER -desc {

Default width given to cells not found in the DPC(PATH) and which
don't have .ports files.

Since cell widths vary, this default should only be applicable in
early phases of the design when not all cell sizes are known.
}


init_global DPC(FLIP) -flags "user DPC" \
    -default "N FS" -desc {

DEF Orientations for unflipped and flipped cells created by DPC.

NOTE: if you change this, you must remove all cache files.
}


# 1000 means nanometers
set DPC(UNITS) 1000

init_global DPC(PLACE) -flags "user DPC" -type STRING \
    -default PLACED -desc {

The DEF file placement property for icons written by DPC.

Can be either "PLACED" or "FIXED"
}

init_global DPC(UNPLACED) -flags "user DPC" -type LIST \
    -default "bus_combine bus_split sign_extend" -desc {

Ignore these icons (which have verilog properties) during DPC placement.
}

init_global DPC(TRACK_OFFSET) -flags "user DPC" -type NUMBER -default 0.5 \
    -type REAL -desc {

Routing track offset in grids passed to the placement DEF file during DPC.

This value only affects the TRACKS lines in the .place.def file.

Typical values are either 0.0 (no routing offset) or 0.5 (one-half
grid offset).  With no routing offset, wires will be centered around
0, 1, 2, etc. grids.  With a one-half grid offset, wires will be
centered around 0.5, 1.5, 2.5, etc. grids.  

This value depends on the port locations in the layout of the standard
cell library.

For uneven track offsets in x and y, use a list.

}

init_global DPC(TRACKS) -flags "user DPC" \
    -default {{Y M1 M2 M3 M4 M5 M6} {X M1 M2 M3 M4 M5 M6}} \
    -type LIST_OF_LISTS -desc {

A list of lists with the first element in the sublist being the
track direction and the remainder, the track layers.

This value only affects the TRACKS lines in the .place.def file.

Because most large routes require some amount of wrong-way routing,
all layers are typically listed for both horizontal (X) and vertical (Y)
routing.

}

init_global DPC(HALO) -flags "user DPC" \
    -default 0 \
    -type INTEGER -desc {

Additional number of tracks to be added around the DPC block for
routing and pins.  Can be a list for different x and y.
}

init_global DPC(PINS) -flags "user DPC" \
    -default 0 \
    -type BINARY -desc {

If true (1), DPC will compute top level I/O pin locations and
write them to the def file and display them on the DPC placement view.

Pins are placed on the side which corresponds to their orientation and
aligned to minimize wiring to their attached instances.

To use pin placement, you must also set the variables DPC(PIN_SIZE)
and DPC(PIN,w),DPC(PIN,e),DPC(PIN,s),DPC(PIN,n) appropriately.
}

init_global DPC(PIN_SIZE) -flags "user DPC" \
    -default "-0.4 -0.4 0.4 0.4" \
    -type LIST -desc {

The pin size in tracks relative to the pin origin (x1 y1 x2 y2) for the
PINS section of the def file.  

DPC(PINS) must be true (1) for this to be used.  
}


init_global DPC(PIN,w) -flags "user DPC" \
    -default M2 \
    -type STRING -desc {

Pin layer for pins placed by DPC of the west side (DPC direction).

Similar for east (e), north (n), and south (s).

DPC(PINS) must be true (1) for this to be used.  
}

set DPC(PIN,e) M2
set DPC(PIN,n) M3
set DPC(PIN,s) M3


init_global PREROUTE(row_pitch) -flags "user DPC" -type INTEGER \
    -default "" -desc {

When computing a horizontal (DPC orient) preroute position, the track
is defined from the bit pitch edge.  The pitch defaults to DPC(PITCH)
but can be overwritten by setting PREROUTE(row_pitch).  Also, if
PREROUTE(row_pitch) is set to 1, then the track starts from the port
location instead of the pitch edge.  
}


init_global PREROUTE(column_pitch) -flags "user DPC" -type INTEGER \
    -default "" -desc {

When computing a vertical (DPC orient) preroute position, the track is
defined from the row edge.  The row defaults to
DPC(DEFAULT_ROW_HEIGHT) but can be overwritten by setting
PREROUTE(column_pitch).  Also, if PREROUTE(column_pitch) is set to 1,
then the track starts from the port location instead of the row edge.
}


init_global PREROUTE(pin_distance) -flags "user DPC" -type INTEGER \
    -default "3 5" -desc {

The distance from the preroute end to the pin end in tracks.  During
the detailed route, the router will make this up.  This accounts for
the pins not being fully specified, also.

For different values in x and y, use a list.
}


init_global PREROUTE(ROUTE_TYPE) -flags "user DPC" \
    -default FIXED \
    -type STRING -desc {

Determines the default preroute type which is written to the DEF file
for preroutes.

Can be either FIXED | ROUTED | COVER.  ROUTED lets the router change
it while FIXED doesn't.
}


# Setup for running timing analysis in SUE.

init_global DPC_TIMING(simulator) -flags "user DPC timing" -default pearl \
    -type STRING -desc {

Selects the static timing analyzer to use during DPC timing.

Valid programs are: pearl, primetime, and pathmill.
}

init_global DPC_TIMING(pearl,command) -flags "user DPC timing pearl" \
    -type STRING -default pearl -desc {

The string used to invoke the Pearl static timing analyzer on this
system.  Arguments will be appended onto this string.
}

init_global DPC_TIMING(tech_file) -flags "user DPC timing pearl" \
    -type STRING -desc {

Path to the Pearl tech file for running timing.  

A sample Pearl tech file for a 2.5V-nominal process is:

        technology mmi25
        power_node_name vdd 2.25
        gnd_node_name gnd
        logic_threshold  1.125
        rise_time 20-80 200PS
        SYNOPSYS_UNITS 1N 1P 1K
        TEMPERATURE 105
        PROCESS 1.0
        LIBRARY_CORNER TYP
        units time 4.0ps 1e-12
        units capacitance 4.0fF 1e-15
        end_technology

Only used in Pearl timing.

}

init_global DPC_TIMING(ctlf_file) -flags "user DPC timing pearl" \
    -type LIST -desc {

List of paths to the tlf/ctlf timing models used by Pearl for timing analysis.  

If a path name includes "ctlf" in the name (or extension), uses
readctlf in Pearl, otherwise uses readtlf.

Typically one of the paths contains the timing models for the entire
standard cell library.  Additional paths might contain timing models
for megacells (e.g. memories) or special datapath cells.

Only used in Pearl timing.

}

init_global DPC_TIMING(filter) -flags "user DPC timing pearl" \
    -default "-same_path -same_node -same_pin" \
    -type LIST -desc {

Arguments passed to Pearl to limit (filter) the paths Pearl reports in
the critical path list.

Used filter similar critical paths that might obscure other important paths.

Only used in Pearl timing.

}


init_global DPC_TIMING(primetime,command) -flags "user DPC timing primetime" \
    -type STRING -default pt_shell -desc {

The string used to invoke the Primetime static timing analyzer on this
system.  Arguments will be appended onto this string.
}

init_global DPC_TIMING(db_file) -flags "user DPC timing primetime" \
    -type LIST -desc {

List of paths to the .db timing models used by Primetime for timing analysis.  

Typically one of the paths contains the timing models for the entire
standard cell library.  Additional paths might contain timing models
for megacells (e.g. memories) or special datapath cells.

Only used in Primetime timing.

}

init_global DPC_TIMING(db_time_units) -flags "user DPC timing primetime" \
    -default 1ns -type PP_NUMBER -desc {

Times units in the .db files.  Typically ns.

Since Primetime requires scaled input values, this value tells DPC
what scale factor to use.

Only used in Primetime timing.

}

init_global DPC_TIMING(db_cap_units) -flags "user DPC timing primetime" \
    -default 1pF -type PP_NUMBER -desc {

Capacitance units in the .db files.  Typically pF.

Since Primetime requires scaled input values, this value tells DPC
what scale factor to use.

Only used in Primetime timing.

}


init_global DPC_TIMING(pathmill,command) -flags "user DPC timing pathmill" \
    -type STRING -default pathmill -desc {

The string used to invoke the Pathmill static timing analyzer on this
system.  Arguments will be appended onto this string.

}

init_global DPC_TIMING(pathmill,tech_file) -flags "user DPC timing pathmill" \
    -type STRING -default "" -desc {

Path to the Pathmill tech file which includes I-V and C-V curves for
various size transistors at the appropriate process corner.  This file
is typically generated by the EPIC gentech program included with
Pathmill, which runs spice over a large matrix of transistor sizes.

If this value is set to "" (null), Pathmill will read the spice models
directly, bypassing the gentech step.  This is the preferred method if
you have BSIM3 spice models.

}


init_global DPC_TIMING(pathmill,library) -flags "user DPC timing pathmill" \
    -type LIST -default "." -desc {

List of pathnames to directories containing spice netlists of
leafcells for Pathmill timing.

}


init_global DPC_TIMING(pathmill,filter) -flags "user DPC timing pathmill" \
    -type BINARY -default 1 -desc {

If set to 1, filters out paths with same starting and ending points,
independent or rise/fall direction.
}


# optional spice lines for normal pathmill operation
set DPC_TIMING(pathmill,spice_command) read_spice_deck
set DPC_TIMING(pathmill,spice_header) "/proj/tech/mmi25/library/pathmill/include_params"

# optional spice lines for spice comparison to pathmill
set DPC_TIMING(pathmill,spice_include) {{.lib '/home/cad/mmi_local/sue/tech/tsmc25.l' TT}}


init_global DPC_TIMING(pathmill,cfg_options) -flags "user DPC timing pathmill" \
    -type LIST -default {{pwl *} {log_on all} {search_structure all}} -desc {

Optional Pathmill configuration commands specified as a list of lists.
These command are directly inserted into the Pathmill run.

}


init_global DPC_TIMING(out_cap) -flags "user DPC timing" -default 20fF \
    -type PP_NUMBER -desc {

When timing the circuit, this load capacitance is added to all primary
outputs.

This value approximates the load of driving the connected block and
can be overridden on a case-by-case basis in the SUE constraint file.

}


init_global DPC_TIMING(driver_cell) -flags "user DPC timing" -default "" \
    -type LIST -desc {

If non-nil, specifies the cell to use to drive any primary inputs to
the circuit during timing.  If nil, uses the default input transition
time specified in DPC_TIMING(input_transition).

The format of this list is:

       "<cell_name> [<output_port>]"

If the output port is not specified, it defaults to "out".

For example, to set the default driver cell to be MMI_INVB (a B-size
inverter), use the following line:

        set DPC_TIMING(driver_cell) "MMI_INVB"

If the output pin is not "out" but, for example "Z", use the following line instead"

        set DPC_TIMING(driver_cell) "MMI_INVB Z"

Only used in Pearl and Primetime timing.

}


init_global DPC_TIMING(input_transition) -flags "user DPC timing" \
    -default 200ps -type PP_NUMBER -desc {

Default input slew rate on primary inputs to the schematic during
timing.

This is an ideal source and, as such, can be abused.  Increasing the
input load of a circuit by oversizing the gates connected to the
inputs may make a specific circuit, in isolation, time faster.  However,
with a real input driver the circuit may actually slow down.

The input slew rate can be overridden in Pearl and Primetime by
specifying a real driver cell using DPC_TIMING(driver_cell).

}


init_global DPC_TIMING(paths) -flags "user DPC timing" \
    -default 10 -type INTEGER -desc {

Specifies the number of critical paths that the static timing analyser
is asked for and thus the maximum number that can be highlighted from
within SUE.

NOTE: too large a number of paths will slow down the timing.

}

init_global DPC(MICRON_CAP_FACTOR) -flags "user DPC" -default 0.22 \
    -type REAL_LIST -desc {

Capacitance (fF) per wire length (microns) used by DPC for computing
wire capacitances.

If you have a non square grid (i.e. DPC(SCALE) is a list of different
numbers), you typically want this capacitance/length to be different
in X and Y.  In this case, make this a list.

}

# Additional capacitance (in fF) added to all wires to account for port
# positions not being ideal.  Usually only important for cells right
# next to each other.
set DPC(CAP_PORT_FUDGE) [expr [lindex $DPC(MICRON_CAP_FACTOR) 0] * 6 * \
	[lindex $DPC(SCALE) 0]]

# special for dspf
init_global DPC(dspf) -flags "user DPC" -default 0 \
    -type BINARY -desc {

If set to 1, DPC will create a dspf file with RC networks based on a
complete steiner route of each net.  If set to 0, DPC will create a
capacitance only file which is also based on a complete steiner route.  

By setting DPC(MIN_RC), you can write out complete RC networks for
only those nets which have a significant RC time constant.

NOTE: Primetime users must run the synopsys 2000.11 release or later
for this to work correctly.
}

init_global DPC(MIN_RC) -flags "user DPC" -default 2ps \
    -type PP_NUMBER -desc {

During DPC DSPF parasitic generation, if the RC time constant of
a net is less than this value, its R's are ignored.  Set to 0 to
force inclusion of all R's.
}


init_global DPC(MICRON_RES_FACTOR) -flags "user DPC" \
    -default [expr 0.11 / 0.6] \
    -type NUMBER -desc {

For DSPF calculation, this wire resistance is used to calculate
resistances for net RC networks.  The value is specified in
Ohms/micron of wire length for the wiring width of the routed wires.

For example, if your wire resistance is 110 mOhms/square @105C and the
wire width is 0.6um, then value here should be 0.110 / 0.6 = 0.183
}


init_global DPC_TIMING(clk_names) -flags "user DPC timing" \
    -default clk -type LIST -desc {

Contains the list of top level clock net names.  SUE searches all
primary inputs, looking for any in this list to determine if the circuit
is purely combinational (i.e. no clocks) or sequential and sets up the
timing accordingly.

}


# name of timing waveform to use for clocks/arrivals/departures
set DPC_TIMING(wave_name) _WAVE_

init_global DPC_TIMING(clk_period) -flags "user DPC timing" \
    -default 5ns -type PP_NUMBER -desc {

When timing a sequential circuit, this value specifies the desired
clock period from which slack times are calculated.

Typically, this clock period includes the overhead of clock skew and
jitter.  For example, if the desired clock frequency is 5.5ns and the
clock skew and jitter are budgeted at 500ps, then this value should be
set to 5ns.

}

init_global DPC_TIMING(arrival_time) -flags "user DPC timing" \
    -default 3n -type PP_NUMBER -desc {

Specifies the default arrival time for primary inputs to sequential
logic circuits.

When timing a circuit in isolation, you must be conscious of the time
required to get a primary input to the circuit in question.  In a
register-based design, all inputs are available at a minimum of a
clock-to-q delay after the clock, and thus the minimum value for the
arrival time should be set to the clock-to-q delay.  However, it is
more than likely that the inputs must come from other parts of the
chip and may even go through other logic in the current cycle before
arriving.  

It is suggested that the sum of the default arrival and departure
times be greater than or equal to the cycle time.

Arrival times of specific signals can be set in the SUE DPC
constraint file for the circuit and will then override the deafult
value.

}

init_global DPC_TIMING(departure_time) -flags "user DPC timing" \
    -default 2n -type PP_NUMBER -desc {

Specifies the default departure time before next clock for primary outputs to
sequential logic circuits.

When timing a circuit in isolation, you must be conscious of the time
required to get a primary output to the circuit it goes to.  In a
register-based design, all outputs must be valid at a minimum of a
setup time before the clock, and thus the minimum value for the
departure time should be set to the setup time of the register.
However, it is more than likely that the outputs must go to other
parts of the chip and may even go through other logic before the
current cycle is over.

It is suggested that the sum of the default arrival and departure
times be greater than or equal to the cycle time.

Departure times of specific signals can be set in the SUE DPC
constraint file for the circuit and will then override the deafult
value.

}


# See output to screen (see) or just write to a file (hidden).
set DPC_TIMING(out) see


init_global DPC_TIMING(max_transition) -flags "user DPC timing" \
    -default 1n -type PP_NUMBER -desc {

Gates, whose outputs transition slower than this value, will be
displayed to the screen during DPC timing and written to the slow
nodes file for later inspection.

Slow nodes can have a large impact on dynamic power consumption since
they potentially cause the gates that they drive to have large
crowbar currents.  Furthermore, slow nodes are more susceptable to
noise, crosstalk, and process variations and should be avoided.

}

# cells ignored when reading back DEF files.
set DPC(ignore_cells) "FILL_1 FILL_2 FILL_4 FILL_8"


init_global AUTOLIB -flags "user library" -init 0 \
    -type LIST -desc {

Pathnames to libraries to be added to the SUE search path and
automatically loaded at startup.

The suggested method for adding an autolib is:

        lappend AUTOLIB <path_to_lib>

This variable is only accessed at startup and thus must be set in a
.suerc file.

}


init_global LIB -flags "user library" -init 0 \
    -type LIST -desc {

Pathnames to libraries to be added to the SUE search path.

The suggested method for adding a lib is:

        lappend LIB <path_to_lib>

Any SUE files (or tcl procedures in files with a .tcl suffix) in the
SUE search path will be automatically loaded when needed.

This variable is only accessed at startup and thus must be set in a
.suerc file.

}
