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

set RCSVERSION(nlt.tcl) { $Revision: 1.2 $ }

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

proc nlt_list_compress {indlist} -desc {
  Given a list of numbers, construct a nice composite index.
} {
  set list [lsort -integer $indlist]
  set len [llength $list]
  if {$len == 1} {
    return $list
  }
  set result ""
  set i 0
  while {$i < $len} {
    set first [lindex $list $i]
    set last $first
    for {incr i} {$i < $len} {incr i} {
      set this [lindex $list $i]
      if {$this == $last + 1} {
	set last $this
      } else {
	break
      }
    }

    if {$first == $last} {
      lappend result $first
    } else {
      # Special case:  If the list is 0,0:1,1 it looks better as: 0,0,1,1
      if {$last==$first+1 && [llength $list] != 2} {
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

  return
}

proc nlt_bus {mod bit} -desc {
  For the first bit in a bus, return the bus associated with bit.
  For all other bits, return "".
} {
  global NLT_AG_NET2
  if {![info exists NLT_AG_NET2($mod,$bit)]} {
    nlt_init_aggregate $mod
  }

  # If it still does not exist, then verilog does not match design.
  if {![info exists NLT_AG_NET2($mod,$bit)]} {
    error "nlt_bus: module '$mod' name '$bit' not found in verilog"
  }
  return $NLT_AG_NET2($mod,$bit)
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
proc UNUSED_nlt_list_nets {mod {f_ag 1}} -desc {
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
proc UNUSED_nlt_list_ports {mod {f_ag 1}} {
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
proc UNUSED_nlt_get_pin_net {subcell pin {f_ag 1}} {
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


proc nl {cmd} -desc {
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


proc nl2_log {{-off} {-append} {filename ""}} -desc {
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
