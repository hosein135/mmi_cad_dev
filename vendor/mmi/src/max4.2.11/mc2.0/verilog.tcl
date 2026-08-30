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


# Verilog netlister for max megacell compiler

# TODO: could group buses with internal wires but is unlikely to happen

proc _mc_verilog_netlist {} -desc {
  create a verilog netlist for an entire block with calls for leafcells.
} {

  global MC_SPICE_INST SEPARATOR CP_NAMES FILE_ID CONTINUATION
  global MC_SPICE_TOP_NETS COMMENT MC max_win MC_VERSION MC_VERILOG_GLOBAL
  global MC_SPICE_CELL MC_SPICE_TRACE MC_VERILOG_WIRES

  # must insure that everything is expanded for this to work
  eval lay_box [lay_bbox]
  lay_internals -area

  set cell [lay_rootcell]

  # compute directory for netlist
  set file [lindex [cell_info $cell] 1]
  if {$file == ""} {
    set dir "[pwd]/"
  } else {
    set dir [file dirname $file]/
    if {$dir == "./"} {
      set dir "[pwd]/"
    }
  }
  set filename "$dir$cell.v"

  puts "Creating verilog netlist from CELL $cell ..."

  # open the verilog output file
  if {[catch {open $filename w} FILE_ID]} {
    puts "Aborting, can't create file $filename"
    return
  }

  catch {unset MC_SPICE_TRACE}
  catch {unset MC_SPICE_CELL}
  catch {unset MC_SPICE_INST}
  catch {unset MC_VERILOG_GLOBAL}

  # unset this stuff
  foreach var [uplevel #0 "info vars _MC_CP_*"] {
    global $var
    unset $var
  }

  catch {unset MC_SPICE_TOP_NETS}
  catch {unset MC_VERILOG_WIRES}

  catch {unset CP_NAMES}
  set CP_NAMES(_unique) 0

  set CONTINUATION "\t\t"
  set COMMENT "//"

  set SEPARATOR "/"

  ext_puts "// FILE: $cell.v\n"
  ext_puts "// Verilog netlist for \"$cell\" (generated from MAX-MCC$MC_VERSION)\n"

  undo_disable

  # find all leaf cells
  puts "Searching for leafcells (need behavioral verilog models) ..."
  _spice_find_leafcells verilog

  # restore toplevel cell
  :load $cell

  puts "Tracing all nets ..."
  _verilog_trace_nets

  # restore toplevel cell
  :load $cell

  # now write the top level spice netlist
  puts "Writing netlist (top level) ..."

  # ports -- must combine buses
  set nets [lsort [array names MC_SPICE_TOP_NETS]]
  set new_nets ""
  set last ""
  set min ""
  set max ""
  foreach net $nets {
    catch {unset MC_VERILOG_WIRES($net)}

    if {[string first \[ $net] != -1} {
      # bit of a bus
      setl {rootname bit} [split $net \[\]]

      if {$rootname != $last} {
	# new bus, output last
	if {$last != ""} {
	  lappend new_nets "$last\[$max:$min\]"
	  set MC_SPICE_TOP_NETS($last\[$max:$min\]) $MC_SPICE_TOP_NETS($last_net)
	  set min ""
	  set max ""
	}

	set last $rootname
      }

      # compute min and max
      if {$min == ""} {
	set min $bit
      } else {
	set min [min $min $bit]
      }

      if {$max == ""} {
	set max $bit
      } else {
	set max [max $max $bit]
      }

    } elseif {$last != ""} {
      lappend new_nets "$last\[$max:$min\]"
      set MC_SPICE_TOP_NETS($last\[$max:$min\]) $MC_SPICE_TOP_NETS($last_net)
      set last ""
      lappend new_nets $net
    } else {
      lappend new_nets $net
    }

    set last_net $net
  }

  # get the stragglers
  if {$last != ""} {
    lappend new_nets "$last\[$max:$min\]"
    set MC_SPICE_TOP_NETS($last\[$max:$min\]) $MC_SPICE_TOP_NETS($net)
  }
  set nets $new_nets

  # remove [xxx]
  regsub -all {\[[0-9:]+\]} $nets "" tmp_nets
  ext_puts "module $cell ([join $tmp_nets {, }]);"

  # add port types
  foreach net $nets {
    if {[string first \[ $net] != -1} {
      # bus
      setl {rootname bus} [split $net \[]
      ext_puts "\t$MC_SPICE_TOP_NETS($net)\t\[$bus\t$rootname;"

    } else {
      ext_puts "\t$MC_SPICE_TOP_NETS($net)\t$net;"
    }
  }

  ext_puts " "

  foreach g [array names MC_VERILOG_GLOBAL] {
    catch {unset MC_VERILOG_WIRES($g)}
  }

  foreach net [lsort [array names MC_VERILOG_WIRES]] {
    ext_puts "\twire\t$net;"
  }

  foreach g [array names MC_VERILOG_GLOBAL] {
    ext_puts "\t[use_first MC(supply,$g) 'MC(supply,$g)]\t$g;\n"
  }

  ext_puts " "

  _mc_create_verilog_netlist

  ext_puts "endmodule\t// $cell"

  # close the verilog output file
  close $FILE_ID

  # make things look purty
  sel_clear
  eval lay_box [lay_bbox]

  undo_enable

  puts "Verilog netlist $filename created."
}


proc _verilog_trace_nets {} -desc {
  trace all nets that are connected to leafcells.
} {

  global MC_SPICE_INST MC_SPICE_TOP_NETS
  global NET_EQUIV MC MC_SPICE_CELL MC_VERILOG_WIRES MC_VERILOG_GLOBAL

  set NET_EQUIV ""

  set count 0

  # walk thru all leafcells
  foreach leafcell [array names MC_SPICE_CELL] {
    foreach path [_mc_find_paths $leafcell] {

      set MC_SPICE_INST($path) $leafcell

      upvar #0 _MC_CP_$path cp_array

      # TODO: check for multiple ports in same cell of same name
      foreach port [_mc_get_ports $path] {
	setl {layer x1 y1 x2 y2 pos text path group kind} $port

	# trace attached wire
	if {![info exists cp_array($text)]} {
	  # haven't traced this net yet
	  
	  incr count
	  if {$count > 10} {
	    set count 0
	    puts -nonewline "."
	    flush stdout
	  }

	  # select the entire net associated with this port
	  sel_net -point $x1 $y1 $layer
	  
	  # find a name for this net.  Choose net name with least hierarchy
	  set min_len 10000
	  set tie_off 0
	  foreach label [split [sel_what labels] \n] {
#	    setl {_layer _x1 _y1 _x2 _y2 _pos _text _path _group _kind} $label
	    set _text [lindex $label 6]
	    set _path [lindex $label 7]
	    set _kind [lindex $label 9]

	    if {$_kind == "global"} {
	      # this net is tied off
	      set net_name [use_first MC(tie,$_text) _text]
	      set MC_VERILOG_GLOBAL($net_name) 1
	      set tie_off 1
	      break
	    }

	    set len [llength [split $_path /]]
	    if {$len < $min_len} {
	      set min_len $len
	      set net_name $_path$_text
	    }
	  }
	
	  if {!$tie_off} {
	    # make a unique name
	    set net_name [_mc_verilog_unique_name $net_name "" net]
	  }
	
	  if {$MC(verbose)} {
	    lappend NET_EQUIV "// $net_name ="
	  }

	  # add this net to all labels of leaf cells
	  foreach label [split [sel_what labels] \n] {
#	    setl {_layer _x1 _y1 _x2 _y2 _pos _text _path _group _kind} $label
	    set _text [lindex $label 6]
	    set _path [string trimright [lindex $label 7] /]
	    set _kind [lindex $label 9]

	    if {[lsearch "input output inout" $_kind] != -1} {
	      
	      if {$_path == ""} {
		# top level net
		# it doesn't have the same name as net_name then
		# layout has a problem
		if {$_text != $net_name} {
		  puts "ERROR, multiple unconnected top-level ports called $_text."
		}
	      
		set MC_SPICE_TOP_NETS($net_name) $_kind
	      
	      } else {
		# remember net name associated with this port
	      
		set MC_VERILOG_WIRES($net_name) $_kind

		upvar #0 _MC_CP_$_path cp_new
		set cp_new($_text) $net_name
	      }
	      
	      if {$MC(verbose)} {
		lappend NET_EQUIV "//   $_path/$_text"
	      }
	    }
	  }
	}
      }
    }
  }

  puts ""
}


proc _mc_create_verilog_netlist {} -desc {
  create the verilog netlist instance calls
} {

  global MC_SPICE_INST NET_EQUIV MC lvs

  if {[use_first MC(verbose)] == 1} {
    foreach line $NET_EQUIV {
      ext_puts $line
    }

    ext_puts " "
  }

  foreach cell [array names MC_SPICE_INST] {
    upvar #0 _MC_CP_$cell cp_array

    set ports ""
    foreach net [lsort [array names cp_array]] {
      lappend ports ".${net}($cp_array($net))"
    }

    # write the spice instance cell.  Nets are in alphabetical order
    ext_puts "// $cell"

    set cellname $MC_SPICE_INST($cell)
    # use the lvs translation if there is one
    ext_puts "[use_first lvs($cellname) cellname] [_mc_verilog_unique_name $cellname] ([join $ports {, }]);"
  }

  ext_puts " "
}


set LINE_LENGTH 70

proc ext_puts {line} -desc {
  breaks the long lines at spaces and writes to a file
} {
  global LINE_LENGTH FILE_ID CONTINUATION COMMENT

  # note that "begin" must be larger than the length of the continuation
  # if the continuation includes a space
  set begin 20

  regsub -all {\{|\}} $line "" line
  while {$line != ""} {

    if {[string length $line] < $LINE_LENGTH} {
      puts $FILE_ID $line
      break
    }

    set space [string last " " [string range $line $begin $LINE_LENGTH]]

    if {$space == -1} {
      # no spaces, try looking forward instead
      set space [string first " " "[string range $line $begin end] "]
    }

    # if you break a comment line, the new line should still be a comment
    if {[string first $COMMENT $line] == 0} {
      set cont_char "$COMMENT$CONTINUATION"
    } else {
      set cont_char "$CONTINUATION"
    }

    incr space $begin
    puts $FILE_ID [string range $line 0 $space]
    set rest [string range $line [incr space] end]
    if {[string trim $rest] == ""} {
      # nothing left, we're done
      break
    }

    set line "$cont_char$rest"
  }
}


proc _mc_verilog_unique_name {name {prefix ""} {alt ""}} -desc {
  creates a unique name suitable for verilog
} {

  global CP_NAMES

  set name $prefix$name

  regsub -all {/} $name {$} name

  if {[info exists CP_NAMES($name)]} {
    set name ${name}_[incr CP_NAMES($name)]
  } else {
    # name is unique, just save it
    set CP_NAMES($name) 0
  }

  return $name
}

