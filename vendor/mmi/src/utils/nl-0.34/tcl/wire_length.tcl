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

proc report_wire_length {} {
  set nets [nl_list_nets -noassign -noconstant]
  set half_perim_sum 0.0
  set half_perim_sum_sq 0.0
  set load_dist_sum 0.0
  set load_dist_sum_sq 0.0
  set net_count 0
  set load_count 0

  foreach net $nets {
    if { [string match clk* $net] || [string match rst* $net] } {
      puts "skipping $net"
      continue
    }

    set loads [llength [nl_get_net_pins -noassign $net]]

    set bbox [nl_get_net_bbox $net]
    set xmin [lindex $bbox 0]
    set ymin [lindex $bbox 1]
    set xmax [lindex $bbox 2]
    set ymax [lindex $bbox 3]

    set driver [nl_get_net_pins -noassign -drivers $net]

    if { [llength $driver] < 1 } {
      puts stderr "Net $net has no driver--ignoring it."
      continue
    } elseif { [llength $driver] > 1 } {
      puts stderr "Net $net has multiple drivers--ignoring it."
      continue
    }

    set driver_loc [nl_get_pin_location $driver]
    set driver_x [lindex $driver_loc 0]
    set driver_y [lindex $driver_loc 1]

    if { ![info exists net_count_h($loads)] } {
      set net_count_h($loads) 0
      set half_perim_sum_h($loads) 0.0
      set half_perim_sum_sq_h($loads) 0.0
      set load_dist_sum_h($loads) 0.0
      set load_dist_sum_sq_h($loads) 0.0
    }
      
    set half_perim [expr $xmax - $xmin + $ymax - $ymin]
    set half_perim_sum [expr $half_perim_sum + $half_perim]
    set half_perim_sum_sq [expr $half_perim_sum_sq + $half_perim * 1.0 * $half_perim]
    set half_perim_sum_h($loads) [expr $half_perim_sum_h($loads) + $half_perim]
    set half_perim_sum_sq_h($loads) [expr $half_perim_sum_sq_h($loads) + $half_perim * 1.0 * $half_perim]
    incr net_count
    incr net_count_h($loads)

    set load_pins [nl_get_net_pins -noassign -loads $net]

    set load_count 0
    set load_dist_net_sum 0.0
    set load_dist_net_sum_sq 0.0

    foreach load $load_pins {
      set load_loc [nl_get_pin_location $load]

      if { $load_loc == {} } {
	continue
      }

      set load_x [lindex $load_loc 0]
      set load_y [lindex $load_loc 1]

      set load_dx [expr abs ($load_x - $driver_x)]
      set load_dy [expr abs ($load_y - $driver_y)]

      set load_dist [expr $load_dx + $load_dy]

      set load_dist_net_sum [expr $load_dist_net_sum + $load_dist]
      set load_dist_net_sum_sq [expr $load_dist_net_sum_sq + $load_dist * 1.0 * $load_dist]
      incr load_count
    }

    if { $load_count > 0 } {
      set load_dist_net_avg [expr $load_dist_net_sum / $load_count]
      set load_dist_net_sq_avg [expr $load_dist_net_sum_sq / $load_count]

      set load_dist_sum [expr $load_dist_sum + $load_dist_net_avg]
      set load_dist_sum_sq [expr $load_dist_sum_sq + $load_dist_net_sq_avg]
      set load_dist_sum_h($loads) [expr $load_dist_sum_h($loads) + $load_dist_net_avg]
      set load_dist_sum_sq_h($loads) [expr $load_dist_sum_sq_h($loads) + $load_dist_net_sq_avg]
    }
  }

  set half_perim_avg [expr $half_perim_sum / $net_count]
  set half_perim_sq_avg [expr $half_perim_sum_sq / $net_count]
  set half_perim_var [expr $half_perim_sq_avg - $half_perim_avg * $half_perim_avg]
  set half_perim_sd [expr sqrt ($half_perim_var)]

  set load_dist_avg [expr $load_dist_sum / $net_count]
  set load_dist_sq_avg [expr $load_dist_sum_sq / $net_count]
  set load_dist_var [expr $load_dist_sq_avg - $load_dist_avg * $load_dist_avg]
  set load_dist_sd [expr sqrt ($load_dist_var)]

  puts ""
  puts [format "half perimeter avg. = %.0f +/- %.0f%%" $half_perim_avg [expr 100.0 * $half_perim_sd / $half_perim_avg]]
  puts [format "load distance avg.  = %.0f +/- %.0f%%" $load_dist_avg  [expr 100.0 * $load_dist_sd  / $load_dist_avg]]

  puts ""
  puts "[lsort -integer [array names net_count_h]]"

  foreach loads [lsort -integer [array names net_count_h]] {
    set half_perim_avg [expr $half_perim_sum_h($loads) / $net_count_h($loads)]
    set half_perim_sq_avg [expr $half_perim_sum_sq_h($loads) / $net_count_h($loads)]
    set half_perim_var [expr $half_perim_sq_avg - $half_perim_avg * $half_perim_avg]
    set half_perim_sd [expr sqrt ($half_perim_var)]

    set load_dist_avg [expr $load_dist_sum_h($loads) / $net_count_h($loads)]
    set load_dist_sq_avg [expr $load_dist_sum_sq_h($loads) / $net_count_h($loads)]
    set load_dist_var [expr $load_dist_sq_avg - $load_dist_avg * $load_dist_avg]
    set load_dist_sd [expr sqrt ($load_dist_var)]

    puts "$loads LOADS: N=$net_count_h($loads)"
    if { $half_perim_avg > 0.0 } {
      puts [format "    half perimeter avg. = %.0f +/- %.0f%%" $half_perim_avg [expr 100.0 * $half_perim_sd / $half_perim_avg]]
    }
    if { $load_dist_avg > 0.0 } {
      puts [format "    load distance avg.  = %.0f +/- %.0f%%" $load_dist_avg  [expr 100.0 * $load_dist_sd  / $load_dist_avg]]
    }
  }
}
