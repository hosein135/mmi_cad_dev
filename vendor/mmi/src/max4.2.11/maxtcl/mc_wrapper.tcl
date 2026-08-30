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


# wrappers for megacell compiler procedures
# this file is sourced at Max startup (prior to any MC license check).

# Hspice model names for nfets and pfets
set MC(nfet,model) n
set MC(pfet,model) p

# Bulk terminals of fets
set MC(nfet,bulk) gnd
set MC(pfet,bulk) vdd

# low supply used to tie off caps
set MC(supply,high) vdd
set MC(supply,low) gnd

# For tie-off in verilog netlists
set MC(tie,vdd) VDD
set MC(tie,gnd) GND
set MC(supply,VDD) supply1
set MC(supply,GND) supply0
set MC(supply,VSS) supply0

# if the boundary for the megacell is on this layer, use it
set MC(boundary) prb

set MC(cp_suffix) .tr0

proc mc_init {} -desc {
	Initializes Mega Cell Compiler (usually invoked from .maxrc)
} {	
  global MC MC_VERSION

  # load the menus
  menu_tool_cmd "MC Build" mc_build
  menu_tool_cmd "MC Netlist" mc_netlist
  menu_tool_cmd "MC Critical Path" mc_cp
  menu_tool_cmd "MC What" mc_what

  # announce ourselves	
  msg "MegaCell Compiler (Version MCC$MC_VERSION)\n"
}

proc _mc_load {} -desc {
    load Megacell compiler (if not already loaded)
} {
    global MC

    if { ! [info exists MC(loaded)] || $MC(loaded)==0 } {
	uplevel \#0 mn_load_mc
    }
}

proc mc_build {args} -desc {
  build a megacell using the megacell generator
} {

  # make sure that the megacell compiler is loaded
  _mc_load

  eval _mc_make $args
}

proc mc_netlist {args} -desc {
  netlist the current megacell into spice or verilog
} {

  # make sure that the megacell compiler is loaded
  _mc_load

  eval _mc_netlist $args
}

proc mc_cp {args} -desc {
  find the critical path attached to the selected cells and create a spice model of it
} {

  # make sure that the megacell compiler is loaded
  _mc_load

  eval _mc_cp $args
}

proc mc_what {args} -desc {
  create the megacell-building MACRO statements for the current layout
} {

  # make sure that the megacell compiler is loaded
  _mc_load

  eval _mc_create $args
}

