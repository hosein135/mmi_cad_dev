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

set RCSVERSION(techinfo.tcl) { $Revision: 1.24 $ }

set _techinfo_inited 0

proc _tech_error {msg {flags ""}} -desc {
  Puts error message generated during calls to techinfo
} -doc {
  Flags arg is as for techinfo.
  This saves reported errors in array _techinfo_errors, in which the
  key is the error message and the value is the command number when
  the error was last reported.  Do not report the same error
  more than once during any single command.
} {
  if { $flags == "opt" } { return }
      # Suppress multiple identical error messages generated
      # by the same command.
      global i_cmd _techinfo_errors
      if { [info exists _techinfo_errors($msg)] } {
	  set old $_techinfo_errors($msg)
	  if { $old == $i_cmd(num) } {
	      return
	  }
      }
      set _techinfo_errors($msg) $i_cmd(num)
      msg -warn "$msg\n"
}

proc _tech_required {var {flags ""}} -desc {
  Return a required variable.  If undefined, generate an error.
} {
    upvar $var name
    if {[info exists name] && [string compare $name ""] != 0} {
	return $name
    }
    _tech_error "required variable not defined: $var" $flags
    return ""
}

proc _tech_list_sub {list1 list2} -desc {
    return elements of list1 that do not appear in list2
} {
    set result ""
    foreach l $list1 {
	if {[lsearch -exact $list2 $l] == -1} {
	    lappend result $l
	}
    }
    return $result
}

proc _techinfo_init {} -desc {
    perform techinfo database initialization.
} {
    global DRC_DATA LAYER_NAME _techinfo_inited
    if { $_techinfo_inited } { return }
    set _techinfo_inited 1

    if { ![info exists DRC_DATA] } {
	# Old tech file in use.
	msg -warn "warning: variable DRC_DATA not found; old tech file in use\n"
	return
    }

    # If techinfo2 asks for "diff", return any old diff.
    set LAYER_NAME(diff) [use_first LAYER_NAME(diff) LAYER_NAME(pdiff) \
	LAYER_NAME(ndiff)]
    if { $LAYER_NAME(diff) == "" } { unset LAYER_NAME(diff) }

    # If techinfo2 asks for "gate", return any old fet device layer.
    # We can also figure out the poly layer from the devices.
    set first_device [lindex [array names DRC_DATA device,fet,*] 0]
    if { $first_device != "" && ! [info exists LAYER_NAME(gate)] } {
	set LAYER_NAME(gate) [lindex [split $first_device ,] 2]
    }
    if { $first_device != "" && ! [info exists LAYER_NAME(poly)] } {
	set LAYER_NAME(poly) [lindex $DRC_DATA($first_device) 0]
    }

    # We can figure out the contact layer name from vias.
    set vias [use_first DRC_DATA(vias)]
    if { ! [info exists LAYER_NAME(contact)] && $vias != "" } {
	set LAYER_NAME(contact) [lindex $vias 0]
    }



    # NOT IMPLMENTED
    # The DRC_DATA comes from the tech file, and can not be modified.
    # The techinfo for all tools comes from DRC_DATA_USER,
    # which the user can modify.  If none exists, make it now.
    #global DRC_DATA_USER
    #if { ![info exists DRC_DATA_USER] } {
    #	foreach x [array names DRC_DATA] {
    #	    set DRC_DATA_USER($x) $DRC_DATA($x)
    #	}
    #}
}

proc _techinfo_translate_layer {layer} -desc {
  translate mmi layer name to customer tech file layer name.
} -doc {
    Internal proc used by techinfo2.
} {
    global LAYER_NAME
    if { $layer == "" } { return "" }
    # Look for v0, v1, etc...
    if { [regexp {v([0-9])} $layer junk n] } {
	set newlayer [lindex [techinfo layers via] $n]
    } elseif { [regexp {m([1-9])} $layer junk n] } {
	set newlayer [lindex [techinfo layers metal] [expr $n - 1]]
    } elseif {[info exists LAYER_NAME($layer)]} {
	set newlayer $LAYER_NAME($layer)
    } else {
	set newlayer $layer
    }
    return $newlayer
}

proc techinfo2 {what {l1 ""} {l2 ""} {flags ""}} -desc {
  Like techinfo, but takes mmi canonical layer names.
} -doc {
  This routine is similar to techinfo, but the layer names are assumed
  to be MMI canonical layer names instead of layer names in the current
  technology file.  This routine makes it easier to query the
  technology data-base without knowing what the specific layer names
  are in the current technology.

  Canonical layer names are:
    poly = poly layer used to draw fets and stdcell routing;
    pplus, nplus, pdiff, ndiff, nwell;
    v0 = contact;
    v1, v2, ... = other via cut layers;
    m1, m2, ... = metal layers;

  NOTE: These names may conflict with user defined names!!!  For
  example, the user may name their metal layers m0, m1, etc.  So only
  use techinfo2 when supplying MMI canoninical layer names; otherwise
  use techinfo.

  This routine can only be used for those techinfo calls that require
  layer names.  For example, you should not use it to replace "techinfo
  device".

  The mapping of mmi canonical layer names to technology layer names
  may be specified with the LAYER_NAME array in the technology file. 
} {

  _techinfo_init

  # l1 and l2 may be mmi layer names.  Convert to customer tech layer names.
  set canl1 [_techinfo_translate_layer $l1]
  if { $canl1 == "" } {
    # There is no such layer in the tech file.
    # Pass the original layer to techinfo, which will print an error message
    # and return a default value appropriate for this type of rule.
    set canl1 $l1
  }
  set canl2 [_techinfo_translate_layer $l2]
  if { $canl2 == "" } {
    # There is no such layer in the tech file.
    # Pass the original layer to techinfo, which will print an error message
    # and return a default value appropriate for this type of rule.
    set canl2 $l2
  }
  return [techinfo $what $canl1 $canl2 $flags]
}




proc techinfo {what {l1 ""} {l2 ""} {flags ""}} -desc {
  Return info about process technology.
} -doc {
  The <what> argument determines the meaning of the <l1> and <l2>
  arguments, and whether they are required or optional.

  Normally techinfo generates an error if a requested technology rule
  was not specified in the current technology file.  If <flags> is
  "opt", do not print a warning in these cases, instead just return 0
  or "", whichever is appropriate.

  To specify the <flags> when <l1> or <l2> are not required, specify an
  empty string ("") for <l1> and/or <l2>.

  In general, when a layer name is required, it must exactly match the
  layer name in the technology file.  Use "techinfo layer" to convert
  MMI canonical layer names to names in the current technology.  See
  also: techinfo2.

  The following are various ways techinfo can be called:

  techinfo layer <l1>
      Return the layer name in the current technology for the
      mmi canonical layer name: l1.  See techinfo2 for
      a list of canonical layer names.

  techinfo enclose <l1> <l2> [all]
  techinfo overlap <l1> <l2> [all]
      These are synonyms.  Return amount layer l1 must enclose layer l2.
      By default, return a single number, which is the maximum enclosure
      in either x or y directions.  If optional "all" is specified,
      return one or two numbers;  if two numbers returned, first is
      x enclosure and second is y enclosure.
      Example:
	[techinfo enclose m1 ct]   returns: 0.06


  techinfo extend <l1> <l2>
      Return amount layer l1 must extend beynod l2.  Mostly used
      for poly extensions beyond diff in fets.
      Example:
	[techinfo extend pfet pdiff]  returns: 0.32
  
  techinfo area <l1>
      Return min area rule for layer l1.
  
  techinfo spacing <l1> <l2>
  techinfo space_to <l1> <l2>
  techinfo sep <l1> <l2>
      These are synonyms.  Return separation between layer l1 and l2.
      If l1 == l2, return min sep on that layer.
  
  techinfo layer_order
      Return list of all layers in order from bottom to top

  wire_layers
      Return list of wire layers in the order they should be tried
      when searching for a valid wiring layer.  Usually metal first.
      Note that wire_layers usually includes poly and diff layers,
      in addition to metal layers.
  
  techinfo min_width <l1>
  techinfo width <l1>
      These are synonyms.  Return min width rule for layer l1.
  
  techinfo connect <l1>
    Return list of layers to which l1 will electrically connect.
    Example:
      [techinfo connect m1]   returns: "ct v12"

  techinfo vianame <l1> <l2>
    Given two layer names, return the name of the via cell that would
    be needed to connect the two layers.  These names are chosen by MMI
    using the following rules:  For simple vias, the via cell name is
    the same as the name of the via layer, eg: v12.  If there are
    multiple possible via cells for the same cut layer, the via cell
    name is created by returning the two layer names separated by an
    underbar.  Note that depending on the technology, the "ct_poly" via
    might be called just "ct", if there is no conflict.
    Examples:
      [techinfo vianame m1 m2]     returns: v12
      [techinfo vianame poly m1]   returns: ct_poly
      [techinfo vianame ndif m1]   returns: ct_ndif


  techinfo viawidth <l1> <l2>
      Return the total minimum width of the specified via structure.
      l1 and l2 are the two layers that are to be connected by the via,
      in either order.

  techinfo layers via
  techinfo vias
      These are synonyms.
      Return a list of the layers that are via/contact/cut layers.

  techinfo below <l1>
    Return the list of layers that may appear immediately below the
    specified layer.  If l1 is a metal layer, the return value is the
    name of the via layer.  If l1 is a via/contact/cut layer, the name
    is the list of layers that can appear below that layer.
    Examples:
      [techinfo below m1]   returns: ct
      [techinfo below ct]   returns: "ndif pdif nwc pwc poly"

  techinfo above <l1>
    Like techinfo above, but return list of layers that may
    appear above layer l1.

  techinfo devices
    Return complete list of devices defined in this technology.
    Example:
      [techinfo devices]   returns: "nfet pfet"

  techinfo device <l1>
    Return the layers that make up the device specified by l1.
    Example:
      [techinfo device pfet]  returns: "poly pdif"
  
    
} {
  global TECHINFO DRC_DATA
  global LAYINFO  ;# Used for backward compatibility with old tech files.
  _techinfo_init
  set ret ""
  # Default error message on failure.
  set errmsg "Current technology file does not provide data to satisfy request: techinfo $what $l1 $l2"
  set default "0"   ;# Value to return if we fail.  Most should return 0.

  switch -- $what {

    "layers" {
      switch -- $l1 {
	"via" {
	    # We will not let the user change the vias in DRC_DATA_USER:
	    # they must redo their tech files for that.
	    return [use_first DRC_DATA(vias)]
	}
	"metal" {
	    set via_layers [use_first DRC_DATA(vias)]
	    if { $via_layers == "" } { return "" }
	    set metal_layers ""
	    foreach v $via_layers {
	      set m [lindex [techinfo above $v] 0]
	      if { $m != "" } {
		  lappend metal_layers $m
	      }
	    }
	    return $metal_layers
	}
      }
    }

    "layer" {
      # Given an MMI canonical layer name, return the name in this technology,
      # or "" if layer does not exist.
      set newl1 [_techinfo_translate_layer $l1]
      set order [_tech_required DRC_DATA(layer_order) $flags]
      if { $order == "" } { return "" }
      if { [lsearch -exact $order $newl1] == -1 } {
	  # Layer does not exist...
	  _tech_error "Layer $l1 does not exist" $flags
	  return ""
      }
      return $newl1
    }

    "enclose" -
    "overlap" {
	set ret [use_first DRC_DATA(enclose,$l1,$l2) \
		LAYINFO($l1,$l2,overlap)]
	# If enclose rule has two numbers, it is assymetric,
	# for example, contact must have overlap one side
	# greater than the other.  If flags includes "all",
	# return both numbers, if known.
	if {![memq $flags "all"]} {
	  if {[llength $ret] == 2} {
	    set ret [max [lindex $ret 0] [lindex $ret 1]]
	  }
	}
    }

    "ext" -
    "extend" {
	set ret [use_first DRC_DATA(extend,$l1,$l2)]
    }

    "area" {
	set ret [use_first DRC_DATA(area,$l1)]
    }

    "spacing" -
    "space_to" -
    "sep" {
	if { $l1 == $l2  || $l2 == "" } {
	    set ret [use_first DRC_DATA(spacing,$l1) LAYINFO($l1,$l1,sep)]
	} else {
	    # l1 and l2 can be reversed
	  set ret [use_first DRC_DATA(space_to,$l1,$l2) \
		       DRC_DATA(space_to,$l2,$l1) \
		       LAYINFO($l1,$l2,sep) \
		       LAYINFO($l2,$l1,sep) \
		      ]
	}
    }

    "layer_order" {
	# Return all layers in order from bottom to top
	return [_tech_required DRC_DATA(layer_order) $flags]
    }

    "wire_layers" {
	# Return wire layers in the order they should be tried
	# when searching for a valid wiring layer.  Usually metal first.
	set vias [techinfo vias "" "" opt]
	if { $vias == "" } {
	  # This happens if there are no vias specified in the tech file.
	  _tech_error "can not determine wiring layers:\
		no vias defined in tech file" $flags
	  # Save this info so we only print the message once.
	  # We do not want to save this bogus layer order in the user
	  # preference file, in case they later fix their tech file,
	  # so keep it in the private variable TECHINFO.
	  set ret [techinfo layer_order "" $flags]
	} else {
	  # Compute wiring layers from via information
	  set ret ""
	  # Make a list of all layers that vias can connect to.
	  # There will be dups in this list.
	  set layers ""
	  foreach via $vias {
	    foreach l "[techinfo below $via] [techinfo above $via]" {
		lappend layers $l
	    }
	  }
	  # Now make a unique list in layer order.
	  foreach l [techinfo layer_order] {
	    if { [lsearch -exact $layers $l] >= 0} {
	      lappend ret $l
	    }
	  }
	}
    }

    "min_width" -
    "width" {
	set ret [use_first DRC_DATA(width,$l1) \
		LAYINFO($l1,width) LAYINFO($l1,min_width)]
    }

    "connect" {
	set default ""
	set ret [use_first DRC_DATA(connect,$l1)]
    }

    "vianame" {
	# Given two layer names, return the name used by the via
	# generator to create a via between those two layers.
	# Its complicated for contacts.  Examples:
	# techinfo vianame m1 m2 => v12
	# techinfo vianame poly m1 => ct_poly
	# techinfo vianame ndif m1 => ct_ndif
	# Note that depending on the technology, the "ct_poly"
	# via could be called just "ct".

	set order [_tech_required DRC_DATA(layer_order) $flags]
	set pos1 [lsearch -exact $order $l1]
	if {$pos1 == -1} {
	    _tech_error \
		"illegal layer $l1 in tech info request: techinfo $what $l1 $l2" $flags
	    return ""
	}
	set pos2 [lsearch -exact $order $l2]
	if {$pos2 == -1} {
	    _tech_error \
		"illegal layer $l2 in tech info request: techinfo $what $l1 $l2" $flags
	    return ""
	}

	# Make sure layer l1 is above l2.
	if { $pos1 > $pos2 } {
	  set tmp $l1
	  set l1 $l2
	  set l2 $tmp
	}

	set vialayer [techinfo above $l2]

	if {[llength [techinfo below $vialayer]] > 1} {
	  # Multiple possibilities below this via, so we use
	  # composite vianame of the form vialayer_l2
	  set vialayer ${vialayer}_$l2
	}
	return $vialayer
    }

    viawidth {
	# Return the total minimum width of the specified via structure.
	# Specify the two layers that are to be connected by the via.
	set vianame [techinfo vianame $l1 $l2]
	if { $vianame == "" } { return 0 }
	set v1 [techinfo above $l1]
	set v2 [techinfo below $l2]
	if { $v1 != $v2 } {
	    _tech_error "via confusion: $v1 (above $l1) != $v2 (below $l2)"
	    return ""
	}
	set w1 [techinfo overlap $l1 $v1]
	set w2 [techinfo overlap $l2 $v1]
	return [expr [techinfo width $v1] + [max $w1 $w2]]
    }

    vias {
      # This is a duplicate added by Lee.
      set default ""
      set ret [use_first DRC_DATA(vias)]
    }

    above {
      set default ""
      set layers [_tech_required DRC_DATA(layer_order) $flags]
      if { $layers == "" } {
	return ""
      }
      set pos [lsearch $layers $l1]
      if {$pos == -1} {
	_tech_error "illegal layer $l1 in tech info request: techinfo $what $l1" $flags
	return ""
      }

      set ret ""
      foreach layer [techinfo connect $l1] {
	set pos2 [lsearch $layers $layer]

	if {$pos2 != -1 && $pos2 < $pos} {
	  lappend ret $layer
	}
      }
    }

    below {
      set default ""
      set layers [_tech_required DRC_DATA(layer_order) $flags]
      if { $layers == "" } {
	return ""
      }
      set pos [lsearch $layers $l1]
      if {$pos == -1} {
	_tech_error "illegal layer $l1 in tech info request: techinfo $what $l1" $flags
	return ""
      }

      set ret ""
      foreach layer [techinfo connect $l1] {
	set pos2 [lsearch $layers $layer]

	if {$pos2 != -1 && $pos2 > $pos} {
	  lappend ret $layer
	}
      }
    }

    devices {
      set default ""
      # look for lines like:
      # set DRC_DATA(device,fet,nfet) {poly ndif}

      set ret ""
      foreach name [lsort [array names DRC_DATA device,*]] {
	lappend ret [lindex [split $name ,] 2]
      }
      set errmsg "No devices defined in technology file to satisfy request: techinfo $what $l1 $l2"
    }

    device {
      set default ""
      # look up the layers that make up the device
      if { $l1 == "" } {
	error "Missing argument to call: techinfo device $l1 $l2"
      } else {
	set ret [use_first DRC_DATA(device,fet,$l1)]
      }
    }

    default {
      if {! [memq $flags "opt"]} {
	msg -warn "unrecognized tech info request: techinfo $what $l1 $l2\n"
      }
      return ""
    }
  }

  if { $ret == "" } {
    _tech_error $errmsg $flags
    set ret $default
  }
  return $ret
}
