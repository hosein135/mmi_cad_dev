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

set RCSVERSION(nlt.tcl) { $Revision: 1.5 $ }

# nl_shell.so commands:
#
# nl_list_commands.  Also use -help on any command.
#
# These procs deal with aggregation/unaggregation of busses.
# Each bus is cut into bundles that share all connections.
# The ordering (ie, whether A[0-7] is hooked to B[0-7] or B[7-0])
# is not relevant because this is used only for display purposes,
# and for determining port properties (especially location)
# in a logical view of the design.
#
# For each module, there is a list for the wires and for each cell.

proc nlt_list_compress {{-ascending 0} indlist} -desc {
  Given a list of numbers, construct a nice composite index.
} {
  set len [llength $indlist]
  if {$len == 1} {
    return $indlist
  }
  set result ""
  if {$ascending} {
    set dir 1
    set list [lsort -integer $indlist]
  } else {
    set dir -1
    set list [lsort -decreasing -integer $indlist]
  }

  set i 0
  while {$i < $len} {
    set first [lindex $list $i]
    set last $first
    for {incr i} {$i < $len} {incr i} {
      set this [lindex $list $i]
      if {$this == $last + $dir} {
	set last $this
      } else {
	break
      }
    }

    if {$first == $last} {
      lappend result $first
    } else {
      # Special case:  If the list is 0,0:1,1 it looks better as: 0,0,1,1
      if {$last==$first+$dir && [llength $list] != 2} {
	lappend result "$first,$last"
      } else {
	lappend result "$first:$last"
      }
    }
  }
  return [join $result ","]
}

proc nlt_list_explode {spec} -desc {
  Expand compressed list like 1:3,5 into a full list: 1 2 3 5
} -doc {
  Assume no negative indicies.
} {
  set result ""
  foreach thing [split $spec ,] {
    if {[regexp {([0-9]+)[-:]([0-9]+)} $thing junk i1 i2]} {
      if {$i1 <= $i2} {
	for {set i $i1} {$i <= $i2} {incr i} {
	  lappend result $i
	}
      } else {
	for {set i $i1} {$i >= $i2} {incr i -1} {
	  lappend result $i
	}
      }
    } else {
      lappend result $thing
    }
  }
  return $result
}


proc nlt_bus_get_spec {bus} -desc {
  Given x[1-3] return "1-3"
} {
  if {[regexp {^(.*)\[([^[]*)\]$} $bus junk base spec]} {
    return $spec
  }
  return ""
}

proc nlt_bus_get_name {bus} -desc {
  Given x[1-3] return "x"
} {
  regsub {\[[-0-9,:]+\]$} $bus "" result
  return $result
}

proc nlt_bus_explode {bus} -desc {
  Expand bus like x[1-3,5] into x[1] x[2] x[3] x[5]
} {
  if {[regexp {(.*)\[([^[]*)\]$} $bus junk base spec]} {
    set result ""
    foreach i [nlt_list_explode $spec] {
      lappend result "$base\[$i\]"
    }
  } else {
    set result $bus
  }
  return $result
}


proc nlt_bussify {bitlist} -desc {
  Given list containing single bit names, return list of busses.
} -doc {
  List can contain multiple bus names.  Eg:

    nlt_bussify [list {a[0]} {a[1]} {b[0]} {b[1]}]

  returns: {a[0:1]} {b[0:1]}
} {

  set result ""
  foreach bit $bitlist {
    if {[regexp {^(.*)\[([^[]*)\]$} $bit junk base spec]} {
      # It was a bus.
      lappend bus2indicies($base) $spec
    } else {
      # Not a bus.
      lappend result $bit
    }
  }

  foreach bus_name [array names bus2indicies] {
    lappend result "$bus_name\[[nlt_list_compress $bus2indicies($bus_name)]\]"
  }
  return $result
}


proc nlt_init_aggregate {{-all} {-reset} {-method 0} {mod ""} {nets ""}} -desc {
  Set up the aggregation (busification) tables for this module.
} -doc {
USAGE:
  nlt_init_aggregate [-reset] [-all] [-method <boolean>] [mod]
  If -all, aggregate nets in all modules, otherwise module <mod>.
  If -reset, destroy any previous aggregation tables first.
  If -method 1, compute exact aggregation tables.
  If -method 0, assume all busses are always connected only
  to ports with the same width.

  The nl2_ functions return single bit nets.
  Both for user ease, and efficiency in generating files eg dspf,
  aggregate the single bit nets into maximal net buses.
  In order to be aggregated, all bits of a net bus must be connected to
  the same set of other modules, and to ports with the same name.
  However do not check that the individual bits are connected
  identically in all modules, eg, net n[0-7] may be connected
  to m1/a[0-7] in module1, but to m2/b[0-7] or m2/b[7-0] or even m2/b[31-24].
  This does not matter, because all we care for aggregation
  is that all wires in the aggregated net are going
  to the same approximate locations on the submodules of this module.

  NOTE: We are not worrying about connections to ports in this module.
  Those connections are already aggregated by definition, since the name
  of a net connected to a port, in verilog, is always the name of the port.
  However, the individual bits of the port could be in widely
  different locations, which we are not checking.
} {
  global NLT_AG_NET ;# Maps one bit net to aggregated net name.
  global NLT_AG_NET2 ;# For each aggregated bus, the first bit in the
		      # bus is mapped to the aggregated bus name;
		      # all other bits map to "".
  #global NLT_AG_PIN ;# Maps one bit pin to aggregated pin name.
  #global NLT_AG_PIN2 ;# Like NLT_AG_NET2 but for pins.

  if {$reset} {
    catch {unset NLT_AG_NET}
    catch {unset NLT_AG_NET2}
    #catch {unset NLT_AG_PIN}
    #catch {unset NLT_AG_PIN2}
  }

  if {$all} {
    assert {$mod == ""}
    foreach mod [nl2_list_designs] {
      #set nets [nl2_list_nets -bus 0 $mod]
      #nlt_init_aggregate -method $method $mod $nets
      nlt_init_aggregate -method $method $mod
    }
    return
  }

  if {$mod == ""} {return}

  if {! [nl2_loaded $mod]} {
    error "No verilog read in for module $mod"
  }

  # See if we already did it.
  if {[info exists NLT_AG_NET($mod,.done.)]} {return}

  puts "Aggregating busses in $mod"
  set nets [nl2_list_nets -bus 0 $mod]

  # This is a flag to indicate that we have run nlt_init_aggregate
  set NLT_AG_NET($mod,.done.) 1

  if {$method == 0} {
    # Do it the easy way.
    # Aggregate buses assuming that each bus is connected full width
    # at every point where it is connected.
    foreach net $nets {
      if {[string first {[} $net] == -1} {
	# Net is not a bus.  Map it straight across.
	set NLT_AG_NET($mod,$net) $net
	set NLT_AG_NET2($mod,$net) $net
	continue
      }

      # Get name of net without bus spec.
      if {![regexp {(.*)\[(.*)\]$} $net junk netbase ind]} {
	error "cant parse port name: $net"
      }
      if {[info exists min($netbase)]} {
	set min($netbase) [min $min($netbase) $ind]
      } else {
	set min($netbase) $ind
      }
      if {[info exists max($netbase)]} {
	set max($netbase) [max $max($netbase) $ind]
      } else {
	set max($netbase) $ind
      }
    }

    foreach netbase [array names min] {
      set lo $min($netbase)
      set hi $max($netbase)
      set bus "$netbase\[${lo}:${hi}\]"
      for {set i $lo} {$i <= $hi} {incr i} {
	set NLT_AG_NET($mod,$netbase\[$i\]) $bus
	set NLT_AG_NET2($mod,$netbase\[$i\]) ""
      }
      set NLT_AG_NET2($mod,$netbase\[$lo\]) $bus
    }
  } else {
    # Do it the hard way.
    # Look at all the bus connections and split busses
    # up into maximal busses with identical connections.

    set netcnt 0
    set pincnt 0
    foreach net $nets {
      incr netcnt
#if {$netcnt < 20} {puts net=$net}
      if {[string first {[} $net] == -1} {
	# Net is not a bus.  Map it straight across.
	set NLT_AG_NET($mod,$net) $net
	set NLT_AG_NET2($mod,$net) $net
	continue
      }

      # Make pinlisthash a list of pins with bus specs removed.
      # Carefully anchor bus spec to end of name, in case module
      # instance name also has a bus spec.
      set pins [nl2_get_net_pins $mod $net]
#if {$netcnt < 20} {puts pins=$pins}
      catch {unset pinlisthash}
      foreach pin $pins {
	set pinlisthash([nlt_bus_get_name $pin]) 0
	incr pincnt
      }

      # Get name of net without bus spec.
      if {![regexp {(.*)\[(.*)\]$} $net junk netbase ind]} {
	error "cant parse port name: $net"
      }

      # Bushash index is a netname and set of pins connected to it.
      # The contents is a list of the net bus indicies comprising this bundle,
      # ie, that have an identical set of connections.
      # Each array index consists of the net name and the list of connected pins.
      lappend bushash([list $netbase [lsort [array names pinlisthash]]]) $ind
    }

  puts "processed $netcnt nets, $pincnt pins"

    # Take bus array back apart.
    # NLT_AG_NET maps single bit wire to aggregated bus.
    foreach thing [array names bushash] {
      set namebase [lindex $thing 0]
      set bus_indicies [nlt_list_compress $bushash($thing)]
      set bus_name "$namebase\[$bus_indicies\]"
      set firsttime 1
      foreach index $bushash($thing) {
	set wirebitname "$namebase\[$index\]"
	set NLT_AG_NET($mod,$wirebitname) $bus_name
	if {$firsttime} {
	  set NLT_AG_NET2($mod,$wirebitname) $bus_name
	  set firsttime 0
	} else {
	  set NLT_AG_NET2($mod,$wirebitname) ""
	}

	# Also collect info to build an ag list for each port.
	#set pins [nl2_get_net_pins $mod $wirebitname]
	#foreach pin $pins {
	#	if {![regexp {(.*)\[(.*)\]$} $pin junk portbase ind]} {
	#	  continue ;# Was not a bus.  Ignore it.
	#	}
	#	lappend port_bus_list($portbase) $ind
	#}
      }
    

      if {0} {  ;# UNNEEDED?
	  # The port_bus_list index looks like foo or subcell/foo,
	  # where foo is a port name without a bus spec.
	  foreach thing [array names port_bus_list] {
      puts "port $thing"
	    set bus_indicies [nlt_list_compress $port_bus_list($thing)]
	    set bus_name "$thing\[$bus_indicies\]"
	    set firsttime 1
	    foreach ind $port_bus_list($thing) {
	      set portbitname "$thing\[$ind\]"
	      set NLT_AG_PIN($mod,$portbitname) $bus_name
	      if {$firsttime} {
		set NLT_AG_PIN2($mod,$portbitname) $bus_name
	      } else {
		set NLT_AG_PIN2($mod,$portbitname) ""
	      }
	    }
	  }
      }

    }

  }
}

proc nlt_bus {{-lowest} mod bit} -desc {
  Return the bus associated with bit.
  If -lowest, return the bus for the lowest bit in the bus, and "" for all other bits.
} {
  global NLT_AG_NET NLT_AG_NET2
  if {![info exists NLT_AG_NET2($mod,$bit)]} {
    nlt_init_aggregate $mod
  }

  # If it still does not exist, then verilog does not match design.
  if {![info exists NLT_AG_NET2($mod,$bit)]} {
    error "nlt_bus: module '$mod' name '$bit' not found in verilog"
  }
  return [expr $lowest ? $NLT_AG_NET2($mod,$bit) : $NLT_AG_NET($mod,$bit)]
}

proc nlt_agg_ok {mod} -desc {
  Has nlt_init_aggregate been called on this module?
} -doc {
  If so, then we can call nlt_bus.
} {
  global NLT_AG_NET
  return [expr {[use_first NLT_AG_NET($mod,.done.)] == "1"}]
}


# TODO: use nl_current_design
proc _UNUSED_nlt_list_nets {mod {f_ag 1}} -desc {
  if f_ag, return aggregated busses.
} {
  global NLT_AG_NET2
  if {!$f_ag} {
    return [nl2_list_nets $mod]
  }
  set result ""
  foreach bit [nl2_list_nets $mod] {
    set net $NLT_AG_NET2($mod,$bit)
    if {$net != ""} {
      lappend result $net
    }
  }
  return $result
}

# TODO: I dont think this is right.  It probably returns top-level ports.
proc _UNUSED_nlt_list_ports {mod {f_ag 1}} {
  if {!$f_ag} {
    return [nl_list_ports $mod]
  }
  set result ""
  foreach bit [nl_list_ports $mod] {
    set port $NLT_AG_NET2($cell,$bit)
    if {$port != ""} {
      lappend result $port
    }
  }
  return $result
}

# TODO: Needs unag!
proc _UNUSED_nlt_get_pin_net {subcell pin {f_ag 1}} {
  global NLT_AG_NET
  if {$f_ag} {
    set pinlist [nlt_bus_explode $pin]
    if {[llength $pinlist] > 1} {
      # The pin is a bus.  Since all bits in the bus are connected
      # the same, query any pin on the bus.
      set portbit [lindex $pinlist 0]
      set netbit [nl_get_pin_net $subcell $bit]
      return $NLT_AG_NET($subcell,$netbit)
    }
  }
  return [nl_get_pin_net $subcell $pin]
}


proc _UNUSED_nl {cmd} -desc {
  Optionally log all calls to nl commands.
  NOTE: DOESNT WORK if given a list of args, because eval pre-evaluates
  the arguments and passes objects in the args list.
  Then eval bug in tcl turns all objects into strings.
} {
  global NL_LOG_FILE USE_NL_SERVER
  if {[use_first NL_LOG_FILE] != ""} {
    puts $NL_LOG_FILE $cmd
    flush $NL_LOG_FILE
  }
  if {[use_first USE_NL_SERVER '0]} {
    return [send mmi_wish $cmd]
  } else {
    return [uplevel $cmd]
  }
}


proc _UNUSED_nl2_log {{-off} {-append} {filename ""}} -desc {
  Turn logging on or off
} {
  global NL_LOG_FILE

  if {$off} {
    if {[use_first NL_LOG_FILE] != ""} {
      close $NL_LOG_FILE
      set NL_LOG_FILE ""
    }
  } else {
    if {$filename == ""} {set filename "nl.log"}
    set NL_LOG_FILE [open $filename [expr {$append ? "a" : "w"}]]
  }
}


proc nlt_log_puts {msg} -desc {
  Put msg to the nl_commands.log file.
} {
  global NL_LOG_FILE
  if {[use_first NL_LOG_FILE] == ""} {
    set NL_LOG_FILE [open nl_commands.log w]
  }
  puts $NL_LOG_FILE $msg
  flush $NL_LOG_FILE
}


proc nlt_log {cmd} -desc {
  Run an nl command, logging it to the file nl_commands.log
} {
  set tmp $cmd
  regsub {[[]} $tmp " <@< " tmp
  regsub {[]]} $tmp " >@> " tmp
  set out ""
  foreach word $tmp {
    lappend out [uplevel [list subst -nocommands $word]]
  }
  regsub {<@<} $out {[} out
  regsub {>@>} $out {]} out
  nlt_log_puts $out
  return [uplevel $cmd]
}


# These are bug fixes to nl.  It gets confused about current_design,
# so ALWAYS set it, and then restore it.


proc _nl2_wrap {func mod thingtype thing args} -desc {
  Call nl function <func> on <thing> of nl type <thingtype> in module <mod> with additional <args>
} {
    nlt_log {set nlmod [nl_find_designs -exact $mod]}
    if {$nlmod == ""} {error "can not find nl design $mod"}
    # The funny backslashes are to get the actual name of nl_find_whatever into the log file.
    nlt_log {set nlthing [nl_find_${thingtype}s -exact $thing $nlmod]}
    global nl_current_design
    set save_design $nl_current_design
    nlt_log {set nl_current_design $nlmod}
    nlt_log {set result [eval $func $nlthing $args]}
    nlt_log {set nl_current_design $save_design}
    return $result
}

proc nl2_hier_set_cell_location {mod cell lx ly ori} {
  _nl2_wrap "nl_set_cell_location -origin" $mod cell $cell $lx $ly
  _nl2_wrap nl_set_cell_orientation $mod cell $cell $ori
  #return [_nl2_wrap nl_hier_set_cell_location $mod cell $cell $lx $ly $ori]
}

proc nl2_hier_get_cell_location {mod cell} {
  #return [_nl2_wrap nl_hier_get_cell_location $mod cell $cell]
}


proc nl2_set_port_location {parentmod port lx ly} {
  return [_nl2_wrap nl_set_port_location $parentmod port $port $lx $ly]
}

proc nl2_get_port_location {mod port} {
  return [_nl2_wrap nl_get_port_location $mod port $port]
}

proc nl2_set_port_orientation {mod port ori} {
  return [_nl2_wrap nl_set_port_orientation $mod port $port $ori]
}

proc nl2_get_port_orientation {mod port} {
  return [_nl2_wrap nl_get_port_orientation $mod port $port]
}


proc nl2_set_port_geometry {mod port layer x1 y1 x2 y2} {
  return [_nl2_wrap nl_set_port_geometry $mod port $port $layer [list $x1 $y1 $x2 $y2]]
}

proc nl2_get_port_geometry {mod port} {
  return [_nl2_wrap nl_get_port_geometry $mod port $port]
}

proc nl2_get_port_attr {mod port propname} {
    set nlattr [nl_find_attributes -exact $propname $mod]
    if {$nlattr == ""} {return ""}
    return [_nl2_wrap nl_get_port_attribute $mod attribute $propname $port]
}



proc nl2_set_port_attr {mod port propname value} {
    nlt_log {catch {nl_create_port_attribute -dense $propname $mod}}
    return [_nl2_wrap nl_set_port_attribute $mod attribute $propname $port $value]
}

proc nl2_set_cell_attr {parentmod inst propname value} {
    nlt_log {set nlmod [nl_find_designs -exact $parentmod]}
    if {$nlmod==""} {error "could not find nl design $parentmod"}
    nlt_log {set nlcell [nl_find_cells -exact $inst $nlmod]}
    nlt_log {set nlattr [nl_find_attributes -exact $propname $nlmod]}
    if {$nlattr == ""} {
      nlt_log {nl_create_cell_attribute -dense $propname $nlmod}
      nlt_log {set nlattr [nl_find_attributes -exact $propname $nlmod]}
    }
    return [_nl2_wrap nl_set_cell_attribute $parentmod attribute $propname $nlcell $value]
}

proc nl2_get_cell_attr {parentmod inst propname} {
    nlt_log {set nlattr [nl_find_attributes -exact $propname $parentmod]}
    if {$nlattr == ""} {return ""}
    return [_nl2_wrap nl_get_cell_attribute $parentmod attribute $propname $inst]
}


proc nl2_set_mod_attr {mod propname value} {
    nlt_log {catch {nl_create_design_attribute -dense $propname $mod}}
    return [_nl2_wrap nl_set_design_attribute $mod attribute $propname $mod $value]
}

proc nl2_get_mod_attr {mod propname} {
    nlt_log {set nlmod [nl_find_designs -exact $mod]}
    nlt_log {set nlattr [nl_find_attributes -exact $propname $nlmod]}
    if {$nlattr == ""} {return ""}
    return [nlt_log {nl_get_design_attribute $nlattr $nlmod}]
}


# TODO: There could be multiple verilogs in the same directory.
# Should those all go in the same file?

proc OLD_nlt_write_props {{cell ""}} {
  global VERILOG_MODULE2FILE

  # If no cell specified, do all non-lef cells in hierarachy.
  if {$cell == ""} {
    nlt_write_props [lay_rootcell]
    foreach cell [dbt_kids -hierarchy -nogcells [lay_rootcell]] {
      if {![cell_in_memory $cell]} {continue}
      if {[fplan_cell_info -is_lef $cell]} {continue}

      nlt_write_props $cell
    }
    return
  }

  set mod [fplan_db_cell module $cell]
  # Skip lef cells.
  if {[fplan_cell_info -is_lef $mod]} {return}

  nl2_link $cell

  # Put the file in the same directory as the verilog, if any.
  set vfn [use_first VERILOG_MODULE2FILE($mod)]
  if {$vfn != ""} {
    set fn [file dirname $vfn]/${mod}.etc
  } else {
    set fn ${mod}.etc
  }

  set pf [open $fn "w"]

  unwind_catch {

    # Determine what attributes exist on this design.
    # Create attrs() array with the attributes defined for each kind of object.
    set all_attrs ""
    foreach atname [nl_find_attributes * $mod] {
      # This is a kluge.  If the attribute contains a space, it is an nl internal
      # attribute, and trying to access it from tcl will crash max.
      if {[string first " " $atname] == -1} {
	lappend attrs([nl_attribute_kind $atname]) $atname
	lappend all_attrs $atname
      }
    }

    puts "writing file: $fn attributes: $all_attrs"

    # Output a header
    puts $pf "# NL Properties File.  Format:"
    puts $pf "# M modname - begin module"
    puts $pf "# E modname - end module"
    puts $pf "# P portname - begin port"
    puts $pf "# C portname - begin cell"
    puts $pf "# A name value - generic attribute on current object"
    puts $pf "# S name value ... - special attribute, may be:"
    puts $pf "# S L x y ori - location+orientation of current object in immediate parent"
    puts $pf "# S G layer x1 y1 x2 y2 - port geometry"
    puts $pf "# S D x1 y1 x2 y2 - design size"
    puts $pf "#"


    puts $pf "M [list $mod]"

    # Module props
    setl {x1 y1 x2 y2} [nl2_get_design_size $mod]
    puts $pf "S D $x1 $y1 $x2 $y2"
    foreach atname [use_first attrs(design)] {
      set val [nl2_get_mod_attr $mod $atname]
      if {$val != ""} {
	puts $pf "A $atname [list $val]"
      }
    }

    # Port props
    foreach nlport [nl_list_ports $mod] {
      puts $pf "P [list $nlport]"
      puts $pf "S L [nl2_get_port_location $mod $nlport] [nl2_get_port_orientation $mod $nlport]"
      nlt_log {setl {layer coords} [nl_get_port_geometry $nlport]}
      if {$layer != ""} {
	puts $pf "S G $layer $coords"
      }
      foreach atname [use_first attrs(port)] {
	set val [nl2_get_port_attr $mod $nlport $atname]
	if {$val != ""} {
	  puts $pf "A $atname [list $val]"
	}
      }
    }

    # Cell instance props
    foreach inst [nl_list_cells $mod] {
      puts $pf "C [list $inst]"

      # Pats old way:
      #nlt_log {setl {x y ori} [nl_hier_get_cell_location $inst]}
      # Jays new way:
      nlt_log {setl {x y} [nl_get_cell_location $inst]}
      nlt_log {set ori [nl_get_cell_orientation $inst]}

      puts $pf "S L $x $y $ori"
      foreach atname [use_first attrs(cell)] {
	set val [nl2_get_cell_attr $mod $inst $atname]
	if {$val != ""} {
	  puts $pf "A $atname [list $val]"
	}
      }
    }

    puts $pf "E $mod"

  } always {
    close $pf
  }
}

proc nlt_write_props {{cell ""}} {
  global VERILOG_MODULE2FILE

  # If no cell specified, do all non-lef cells in hierarachy.
  if {$cell == ""} {
    nlt_write_props [lay_rootcell]
    foreach cell [dbt_kids -hierarchy -nogcells [lay_rootcell]] {
      if {![cell_in_memory $cell]} {continue}
      if {[fplan_cell_info -is_lef $cell]} {continue}

      nlt_write_props $cell
    }
    return
  }

  set mod [fplan_db_cell module $cell]
  # Skip lef cells.
  if {[fplan_cell_info -is_lef $mod]} {return}

  nl2_link $cell

  # Put the file in the same directory as the verilog, if any.
  set vfn [use_first VERILOG_MODULE2FILE($mod)]
  if {$vfn != ""} {
    set fn [file dirname $vfn]/${mod}.etc
  } else {
    set fn ${mod}.etc
  }

  set pf [open $fn "w"]

  unwind_catch {

    # Determine what attributes exist on this design.
    # Create attrs() array with the attributes defined for each kind of object.
    set all_attrs ""
    foreach atname [nl_find_attributes * $mod] {
      # This is a kluge.  If the attribute contains a space, it is an nl internal
      # attribute, and trying to access it from tcl will crash max.
      if {[string first " " $atname] == -1} {
	lappend attrs([nl_attribute_kind $atname]) $atname
	lappend all_attrs $atname
      }
    }

    puts "writing file: $fn attributes: $all_attrs"

    # Output a header
    puts $pf "# NL Properties File.  Format:"
    puts $pf "# M modname - begin module"
    puts $pf "# E modname - end module"
    puts $pf "# P portname - begin port"
    puts $pf "# C portname - begin cell"
    puts $pf "# A name value - generic attribute on current object"
    puts $pf "# S name value ... - special attribute, may be:"
    puts $pf "# S L x y ori - location+orientation of current object in immediate parent"
    puts $pf "# S G layer x1 y1 x2 y2 - port geometry"
    puts $pf "# S D x1 y1 x2 y2 - design size"
    puts $pf "#"


    puts $pf "M [list $mod]"

    # Module props
    setl {x1 y1 x2 y2} [nl2_get_design_size $mod]
    puts $pf "S D $x1 $y1 $x2 $y2"
    foreach atname [use_first attrs(design)] {
      set val [nl2_get_mod_attr $mod $atname]
      if {$val != ""} {
	puts $pf "A $atname [list $val]"
      }
    }

    # Port props
    foreach nlport [nl_list_ports $mod] {
      nlt_log {setl {layer coords} [nl_get_port_geometry $nlport]}
      if {$layer == ""} {set layer space}
      puts $pf "P [list $nlport] [nl2_get_port_location $mod $nlport] $layer [nl2_get_port_orientation $mod $nlport]"
      if {$layer != ""} {
	puts $pf "S G $layer $coords"
      }
      foreach atname [use_first attrs(port)] {
	set val [nl2_get_port_attr $mod $nlport $atname]
	if {$val != ""} {
	  puts $pf "A $atname [list $val]"
	}
      }
    }

    # Cell instance props
    foreach inst [nl_list_cells $mod] {
      puts $pf "C [list $inst]"

      # Pats old way:
      #nlt_log {setl {x y ori} [nl_hier_get_cell_location $inst]}
      # Jays new way:
      nlt_log {setl {x y} [nl_get_cell_location $inst]}
      nlt_log {set ori [nl_get_cell_orientation $inst]}

      puts $pf "S L $x $y $ori"
      foreach atname [use_first attrs(cell)] {
	set val [nl2_get_cell_attr $mod $inst $atname]
	if {$val != ""} {
	  puts $pf "A $atname [list $val]"
	}
      }
    }

    puts $pf "E $mod"

  } always {
    close $pf
  }
}


proc nlt_read_props {fn} {

  set pf [open $fn "r"]

  set modname ""
  set modcnt 0
  set type ""

  msg "reading file: $fn\n"

  unwind_catch {
    while {[gets $pf line] >= 0} {

      switch -- [lindex $line 0] {
	"#" {continue}
	"M" {
	  set modname [lindex $line 1]
	  incr modcnt
	  nlt_log {set nlmod [nl_find_designs -exact $modname]}
	  if {$nlmod == ""} {
	    error "file $fn: Can not find module $modname"
	  }
	  nlt_log {catch {nl_create_pdesign -nohierarchy $modname}}
	  set type M
	}
	"C" {
	  set type C
	  set obj [lindex $line 1]
	}
	"P" {
	  set type P
	  set obj [lindex $line 1]
	}
	"A" {
	  set name [lindex $line 1]
	  set val [lindex $line 2]
	  if {$obj == ""} {
	    max_error -buffer "file $fn: attribute $name ignored"
	  } else {
	    switch $type {
	      C {
		nl2_set_cell_attr $modname $obj $name $val
	      }
	      P {
		nl2_set_port_attr $modname $obj $name $val
	      }
	      M {
		nl2_set_mod_attr $modname $name $val
	      }
	      default {
		max_error -buffer "file $fn: orphan A line"
	      }
	    }
	  }
	}
	"S" {
	  switch [lindex $line 1] {
	    "L" { ;# location+orientation
	      setl {junk junk x y ori} $line
	      switch $type {
		"C" {
		  nl2_hier_set_cell_location $modname $obj $x $y $ori
		}
		"P" {
		  nl2_set_port_location $modname $obj $x $y
		  nl2_set_port_orientation $modname $obj $ori
		}
		default {
		  error "unexpected S L statement."
		}
	      }
	    }
	    "G" { ;# port geometry
	      setl {junk junk layer x1 y1 x2 y2} $line
	      nl2_set_port_geometry $modname $obj $layer $x1 $y1 $x2 $y2
	    }
	    "D" { ;# design size.
	      setl {junk junk x1 y1 x2 y2} $line
	      nlt_log {nl_set_design_size $modname $x1 $y1 $x2 $y2}
	    }
	    default {
	      max_error -buffer "file $fn: unrecognized line: $line"
	    }
	  }
	}
	"E" {
	  if {$modname != [lindex $line 1]} {
	    max_error -buffer "file $fn: E modulename does not match preceding M modulename"
	    break
	  }
	  set modname ""
	}
	default {
	  max_error -buffer "file $fn: unrecognized line: $line"
	  break
	}
      }

    };#while

  } always {
    close $pf
  }

  if {$modcnt == 0} {
    max_error -buffer "file $fn: no modules defined"
  }

  if {$modname != ""} {
    max_error -buffer "file $fn: missing E line"
  }
}


proc nl2_link {mod} {
  global FPLAN
  # This command has two mutually incompatible syntaxes.  Try both ways.
  nlt_log {catch {nl_link -silent "" $mod}}
  if {[info exists FPLAN(nl_library)]} {
    nlt_log {catch {nl_link -silent -libraries $FPLAN(nl_library) $mod}}
  } else {
    nlt_log {catch {nl_link -silent $mod}}
  }
}


proc nl2_get_design_size {mod} {
  return [nlt_log {nl_get_die_area $mod}]
}

proc nl2_set_design_size {mod x1 y1 x2 y2} {
  return [nlt_log {nl_set_die_area -- [list $x1 $y1 $x2 $y2] $mod}]
}


proc nl2_load_nl {} {
  global env NL_PATH

  # If already loaded, skip it.
  if {[info commands nl_link] == "nl_link"} {return}

  set nl_path [use_first NL_PATH env(NL_PATH)]
  if {$nl_path != "" && ! [file exists $nl_path]} {
    msg "Warning: Can not find NL_PATH file: $nl_path\n"
    set nl_path ""
  }

  if {$nl_path != ""} {
    set cmd [util_load_pkg $nl_path nl_shell]
  } else {
    set cmd [util_load_pkg nl_shell.so]
  }
  nlt_log_puts $cmd	;# This puts where we loaded nl from into the nl_cmmands.log file.
  fplan_init
}


proc nl2_read_lef {{-direct} leffile} -desc {
  Read lef file into the nl database, and inform floorplanner.
} -doc {
  Strip everything out of the lef file that will choke nl.
  If -direct, skip that step.
} {
  global FPLAN
  nl2_load_nl
  if {[use_first FPLAN(nl_library)] == ""} {
    set FPLAN(nl_library) fplan_lib
    # Only create the library once.  As of 12/10/01, nl still crashes
    # if you call this twice.
    nlt_log {catch {nl_create_library $FPLAN(nl_library)}}
  }

  if {$direct} {
    msg "Loading LEF into NL from file: $leffile\n"
    nlt_log {nl_read_lef $leffile $FPLAN(nl_library)}
  } else {
    # NL barfs on the technology info in a lef file,
    # so take out everything but the MACROs.  This sucks.
    set awkscript {
	/^[ \t]*PROPERTYDEF/,/^[ \t]*END PROPERTYDEF/ {next}
	/^[ \t]*MACRO/ {x=$2}
	/^[ \t]*END/ && x==$2 {x=null;print}
	x {print}
	{next}
    }
    msg "Preprocessing LEF file for NL (removing all but MACROS)\n"
    exec nawk $awkscript $leffile > __tmp__.lef
    #exec nawk {/^[ \t]PROPERTYDEF/,/^[ \t]*MACRO/{x=$2};/^[ \t]*END/&&x==$2{x=null;print};x{print};{next}} $leffile > __tmp__.lef
    msg "Loading MACROs only into NL from file: $leffile\n"
    nlt_log {nl_read_lef __tmp__.lef $FPLAN(nl_library)}
  }
}


proc nl2_find_cell {mod inst} -desc {
  Return nl cell object corresponding to the named module instance: inst in module: mod.
} {
  #nlt_hier_char .
  return [lindex [nlt_log {nl_find_cells -exact $inst $mod}] 0]
}

proc nl2_find_port {mod port} -desc {
  Return nl net object corresponding to the named port in module: mod.
} {
  #nlt_hier_char .
  return [lindex [nlt_log {nl_find_ports -exact $port $mod}] 0]
}

proc nl2_find_inet {mod net} -desc {
  Return nl net object corresponding to the named net in module: mod.
} {
  #nlt_hier_char .
  return [lindex [nlt_log {nl_find_inets -exact $net $mod}] 0]
}

proc nl2_find_net {mod net} -desc {
  Return nl net object corresponding to the named net in module: mod.
} {
  #nlt_hier_char .
  return [lindex [nlt_log {nl_find_nets -exact $net $mod}] 0]
}

proc nl2_find_pin {mod pin} -desc {
  Return nl pin object corresponding to the named pin in module: mod.
} {
  #nlt_hier_char .
  return [lindex [nlt_log {nl_find_pins -exact $pin $mod}] 0]
}

proc nl2_find_ipin {mod pin} -desc {
  Return nl pin object corresponding to the named pin in module: mod.
} {
  #nlt_hier_char .
  return [lindex [nlt_log {nl_find_ipins -exact $pin $mod}] 0]
}

proc nl2_loaded {{-cell} {mod ""}} -desc {
  Return TRUE if nl is loaded, and optionally, has read verilog for mod.
} -doc {
  If -cell, it is a max cell name.  Otherwise it is a verilog module name.
  Does NOT load nl.
} {
  if {$cell} {
    set mod [fplan_unfix_name $mod]
  }

  if {[catch {nl_find_designs -exact $mod} result]} {
    # nl not loaded.
    return 0
  }
  if {$mod == ""} {
    # return 1 to indicate that nl is loaded
    return 1
  } else {
    return [expr {$result == "" ? 0 : 1}]
  }
}

proc nl2_find_design {mod} -desc {
  Return nl object corresponding to named module, or "".
} {
  nl2_load_nl
  return [lindex [nl_find_designs -exact $mod] 0]
}

proc nl2_find_designs {option mod} -desc {
  Return list of matching module names.  option is -exact or -regexp
} {
  global FPLAN
  if {$FPLAN(use_nl_shell)} {
    # Need to load nl_shell.so, because nl2_find_designs might
    # be called to see if verilog was loaded for a module
    # before nl2_read_verilog is called.
    nl2_load_nl
    return [nl_find_designs $option $mod]
  } else {
    global _VERILOG_MODULES
    assert {$option == "-exact"}
    if {[info exists _VERILOG_MODULES($mod)]} {
      return $mod
    } else {
      return ""  ;# Module by this name does not exist in verilog.  Might be a lef cell.
    }
  }
}

proc nl2_ungroup {inst} -desc {
  Ungroup the verilog associated with the specified module using / as hierarchy separator.
} {
  global nl_hierarchy_separator
  set old $nl_hierarchy_separator
  nlt_log {set nl_hierarchy_separator /}
  nlt_log {nl_ungroup $inst}
  nlt_log {set nl_hierarchy_separator $old}
}

proc nl2_group {mod string} -desc {
  Group the verilog associated with the specified module using / as hierarchy separator.
} {
  global nl_hierarchy_separator
  set old $nl_hierarchy_separator
  nlt_log {set nl_hierarchy_separator /}
  nlt_log {nl_group $mod $string}
  nlt_log {set nl_hierarchy_separator $old}
}


proc nl2_is_rtl_cell {def} -desc {
  # Return TRUE if the cell def is one of the ones used by nl to map RTL cells.
} {

  foreach thing [list \*expression* \*process* \*assignment*] {
    if {[string match $thing $def]} {return 1}
  }
  return 0
}


proc nl2_unset_current_design {} {
    # Set nl_current_design to garbage to make SURE we are not
    # doing an implicit conversion from string to nl object,
    # which can result in garbage.
    global nl_current_design
    if {[nl2_find_design __DUMMY__] == ""} {
      nlt_log {nl_create_design __DUMMY__}
    }
    if {[use_first nl_current_design] != "__DUMMY__"} {
      nlt_log {set nl_current_design __DUMMY__}
    }
}

proc nlt_hier_char {{ch ""}} -desc {
  Set/get the current verilog hierarchy separator char.
} -doc {
  Return old on set.
  This is the char we use internal to this tool to indicate
  hierarchy in verilog.  Cant use / because it is inserted
  in instance and pin names by synopsis if user groups/ungroups
  the modules.  Dot is safe because it is illegal in instance and net
  names in verilog.
} {
  global nl_hierarchy_separator
  set old $nl_hierarchy_separator
  if {$ch != "" && $ch != $nl_hierarchy_separator} { nlt_log {set nl_hierarchy_separator $ch} }
  return $old
}

proc nlt_set_idesign {{-stop_attribute ""} mod} -desc {
  Set idesign and nl_current_design to mod.
} -doc {
  Note: The nl_current_design MUST be set to the idesign root in order to do anything
  with the idesign.
} {
  global nl_current_design
  # This proc errors out if there isnt an idesign defined.
  if {[nlt_log {catch {nl_get_idesign_root} result}]} {
    set old_idesign ""
  } else {
    set old_idesign $result
  }

  # Always do it, in case something has been flattened/unflattened since the last call.

  # 2/20/02: The nl_get_idesign FAILS unless nl_current_design is set
  # to the value that nl_current_design is supposed to return.
  # So you must ALWAYS remove the idesign, no matter what, just to make sure.
  # if {$old_idesign != ""} {nlt_log {nl_remove_idesigns $mod}}
  nlt_log {nl_remove_idesigns $mod}
  # Note: you MUST set nl_current_design before calling create_idesign.
  # So why does create_idesign have an argument, one wonders?
  nlt_log {set nl_current_design $mod}
  set cmd [concat nl_create_idesign \
	[expr {$stop_attribute == "" ? "" : "-stop_attribute $stop_attribute"}] \
	[list $mod]]
  nlt_log {eval $cmd}
}
