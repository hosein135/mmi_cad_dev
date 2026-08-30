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

proc celltype_is_clock_buffer {type} {
    return [string match CLK* $type]
}


proc get_timing_points {clock_net} {
    global is_startpoint
    global is_endpoint

    if { [info exists is_startpoint] } {
	unset is_startpoint
    }

    if { [info exists is_endpoint] } {
	unset is_endpoint
    }

    set startpoints [list_ports -inputs]
    set endpoints [list_ports -outputs]

    if { $clock_net != {} } {
	set pins [nl_get_net_pins -hierarchy -noassign -loads $clock_net]

	while { $pins != {} } {
	    set more_pins [list]

	    foreach clk_pin $pins {
		set cell [nl_get_pin_owner $clk_pin]

		set ref [nl_get_cell_reference $cell]

		set is_clkbuf [celltype_is_clock_buffer $ref]

		if { $is_clkbuf } {
		    foreach out_pin [nl_get_cell_pins -outputs $cell] {
			set out_net [nl_get_pin_net $out_pin]

			if { $out_net != {} } {
			    set other_in_pins [nl_get_net_pins -hierarchy -noassign -loads $out_net]

			    foreach other_in_pin $other_in_pins {
				lappend more_pins $other_in_pin
			    }
			}
		    }
		} else {
		    foreach in_pin [nl_get_cell_pins -inputs $cell] {
			if { $in_pin != $clk_pin } {
			    lappend endpoints $in_pin
			}
		    }

		    foreach out_pin [nl_get_cell_pins -outputs $cell] {
			lappend startpoints $out_pin
		    }
		}
	    }

	    set pins $more_pins
	}
    }

    foreach point $startpoints {
	set is_startpoint($point) $point
    }

    foreach point $endpoints {
	set is_endpoint($point) $point
    }

    return [list $startpoints $endpoints]
}


proc compute_timing_fanin {pin} {
    if { [nl_object_type $pin] == "port" } {
	if { [nl_get_port_direction $pin] == "in" } {
	    error "input port showed up with no arrival time: $pin"
	}

	set net [nl_get_pin_net $pin]

	if { $net != {} } {
	    set in_pins [nl_get_net_pins -hierarchy -noassign -drivers $net]
	} else {
	    set in_pins {}
	}

	set levels 0
    } else {
	set dir [nl_get_pin_direction $pin]

	if { $dir == "in" } {
	    set net [nl_get_pin_net $pin]

	    if { $net != {} } {
		set in_pins [nl_get_net_pins -hierarchy -noassign -drivers $net]
	    } else {
		set in_pins {}
	    }

	    set levels 0
	} elseif { $dir == "out" } {
	    set cell [nl_get_pin_owner $pin]
	    set in_pins [nl_get_cell_pins -inputs $cell]
	    set levels 1
	}
    }

    return [list $levels $in_pins]
}


proc compute_timing_fanout {pin} {
    if { [nl_object_type $pin] == "port" } {
	if { [nl_get_port_direction $pin] == "out" } {
	    error "output port showed up with no required time: $pin"
	}

	set net [nl_get_pin_net $pin]

	if { $net != {} } {
	    set out_pins [nl_get_net_pins -hierarchy -noassign -loads $net]
	} else {
	    set out_pins {}
	}

	set levels 0
    } else {
	set dir [nl_get_pin_direction $pin]

	if { $dir == "out" } {
	    set net [nl_get_pin_net $pin]

	    if { $net != {} } {
		set out_pins [nl_get_net_pins -hierarchy -noassign -loads $net]
	    } else {
		set out_pins {}
	    }

	    set levels 0
	} elseif { $dir == "in" } {
	    set cell [nl_get_pin_owner $pin]
	    set out_pins [nl_get_cell_pins -outputs $cell]
	    set levels 1
	}
    }

    return [list $levels $out_pins]
}


proc compute_pin_arrival_time {pin} {
    global arrival_time
    global arrival_open

    if { [info exists arrival_time($pin)] } {
	return $arrival_time($pin)
    }

    if { [info exists arrival_open($pin)] } {
	puts "TIMING LOOP DETECTED:"
	return -1
    } else {
	set arrival_open($pin) 1
    }

    set timing_fanin [compute_timing_fanin $pin]
    set levels [lindex $timing_fanin 0]
    set in_pins [lindex $timing_fanin 1]

    set max 0

    foreach in_pin $in_pins {
	set arrival [compute_pin_arrival_time $in_pin]

	if { $arrival < 0 } {
	    puts $in_pin
	    return -1
	}

	if { $arrival > $max } {
	    set max $arrival
	}
    }

    set arrival [expr $max + $levels]

    set arrival_time($pin) $arrival

    unset arrival_open($pin)

    return $arrival
}


proc compute_pin_required_time {pin} {
    global required_time

    if { [info exists required_time($pin)] } {
	return $required_time($pin)
    }

    set timing_fanout [compute_timing_fanout $pin]
    set levels [lindex $timing_fanout 0]
    set out_pins [lindex $timing_fanout 1]

    set max 0

    foreach out_pin $out_pins {
	set required [compute_pin_required_time $out_pin]

	if { $required > $max } {
	    set max $required
	}
    }

    set required [expr $max + $levels]

    set required_time($pin) $required

    return $required
}


proc compute_arrival_and_required_times {{clock {}}} {
    global arrival_time
    global required_time
    global arrival_open

    if { [info exists arrival_time] } {
	unset arrival_time
    }

    if { [info exists required_time] } {
	unset required_time
    }

    if { [info exists arrival_open] } {
	unset arrival_open
    }

    puts -nonewline stderr "getting timing points..."
    set timing_points [get_timing_points $clock]
    puts stderr "done."

    set startpoints [lindex $timing_points 0]
    set endpoints [lindex $timing_points 1]

    foreach point $startpoints {
	set arrival_time($point) 0
    }

    foreach point $endpoints {
	set required_time($point) 0
    }

    set num_endpoints [llength $endpoints]
    set count 0

    puts -nonewline stderr "arrival times..."
    foreach point $endpoints {
	set arrival [compute_pin_arrival_time $point]
	if { $arrival < 0 } {
	    puts $point
	    return
	}

	incr count
	if { ($count % 1000) == 0 } {
	    puts -nonewline stderr "[expr (100 * $count) / $num_endpoints]%..."
	}
    }
    puts stderr "done."

    set num_startpoints [llength $startpoints]
    set count 0
    puts -nonewline stderr "required times..."

    foreach point $startpoints {
	compute_pin_required_time $point

	incr count
	if { ($count % 1000) == 0 } {
	    puts -nonewline stderr "[expr (100 * $count) / $num_startpoints]%..."
	}
    }
    puts stderr "done."
}


proc compute_critical_path_to {pin} {
    global arrival_time
    global required_time
    global is_startpoint
    global is_endpoint

    if { [info exists is_startpoint($pin)] } {
	return [list $is_startpoint($pin)]
    } else {
	set timing_fanin [compute_timing_fanin $pin]
	set in_pins [lindex $timing_fanin 1]

	set max -1
	set max_pin {}

	foreach in_pin $in_pins {
	    if { [info exists arrival_time($in_pin)] == 0 ||
		 [info exists required_time($in_pin)] == 0 } {
		continue
	    }

	    set arrival $arrival_time($in_pin)
	    set required $required_time($in_pin)
	    set path_time [expr $arrival + $required]

	    if { $path_time > $max } {
		set max $path_time
		set max_pin $in_pin
	    }
	}

	if { $max < 0 } {
	    error "no max for $pin"
	}

	set path [compute_critical_path_to $max_pin]
	lappend path $pin

	return $path
    }
}


proc compute_critical_path_from {pin} {
    global arrival_time
    global required_time
    global is_startpoint
    global is_endpoint

    if { [info exists is_startpoint($pin)] } {
	return [list $is_startpoint($pin)]
    } else {
	set timing_fanin [compute_timing_fanin $pin]
	set in_pins [lindex $timing_fanin 1]

	set max -1
	set max_pin {}

	foreach in_pin $in_pins {
	    set arrival $arrival_time($in_pin)
	    set required $required_time($in_pin)
	    set path_time [expr $arrival + $required]

	    if { $path_time > $max } {
		set max $path_time
		set max_pin $in_pin
	    }
	}

	set path [compute_critical_path_to $max_pin]
	lappend path $pin

	return $path
    }
}


proc show_critical_path_to {pin {with_nets 0}} {
    global is_endpoint

    if { [info exists is_endpoint($pin)] } {
	set pin $is_endpoint($pin)
    } elseif { [nl_object_type $pin] != "pin" } {
	set pin [lindex [nl_find_pins -exact $pin] 0]
    }

    set path [compute_critical_path_to $pin]
    set index 0

    foreach point $path {
	set type [nl_object_type $point]

	if { $type == "port" } {
	    set dir [nl_get_port_direction $point]

	    puts [format "%3d. $point ($dir)" $index]

	    if { $with_nets } {
		if { $dir == "in" } {
		    puts "     [nl_get_pin_net $point] (net)"
		}
	    }
	} else {
	    set dir [nl_get_pin_direction $point]

	    if { $dir == "out" } {
		set cell [nl_get_pin_owner $point]
		set ref [nl_get_cell_reference $cell]

		incr index
		puts [format "%3d. $point ($ref)" $index]

		if { $with_nets } {
		    puts "     [nl_get_pin_net $point] (net)"
		}
	    }
	}
    }
}


proc show_logic_levels {{file stdout}} {
    global is_endpoint
    global arrival_time

    if { $file != "stdout" } {
	set file [open $file "w"]
    }

    foreach endpoint [array names is_endpoint] {
	puts $file [format "%3d  $endpoint" $arrival_time($endpoint)]
    }

    if { $file != "stdout" } {
	close $file
    }
}
