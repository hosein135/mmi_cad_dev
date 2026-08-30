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

set RCSVERSION(fplan_cong.tcl) { $Revision: 1.2 $ }

# TODO: The C congestion blockage code does not know about layers with different grids.


proc fplan_congest_init {} {
  global CONGESTION

  #use_init CONGESTION(dim,x) 1000		;# Number of elements in global route grid.
  #use_init CONGESTION(dim,y) 1000

  use_init CONGESTION(tracks_per_grid,x) 10
  use_init CONGESTION(tracks_per_grid,y) 10
  #use_init CONGESTION(display_threshold,x) 1
  #use_init CONGESTION(display_threshold,y) 1
  use_init CONGESTION(resources_per_track,x) 2
  use_init CONGESTION(resources_per_track,y) 2
  use_init CONGESTION(set_grid) 1
  use_init CONGESTION(track_layer,x) [techinfo layer m3]
  use_init CONGESTION(track_layer,y) [techinfo layer m4]
  use_init CONGESTION(use_existing) [techinfo layer m4]
}


proc fplan_congestion {{-menu 1} {-tracks_per_grid_x 10} {-tracks_per_grid_y 10} \
  {-layers_h m3,m5} {-layers_v m2,m4} {-avail_h 1} {-avail_v 1} \
  {-use_existing 1} {-use_cover 1} {-add_text 0} {-text_size 0} {-set_grid 1} \
  {-display_only 0}} {
  global CONGESTION
  use_init CONGESTION(display_layers) "Red Yellow Green"
  use_init CONGESTION(util,Green) 0.5		;# Amount of utilization to get this color
  use_init CONGESTION(util,Yellow) 0.8
  use_init CONGESTION(util,Red) 1

  if {$menu} {
    # Show interactive menu.  Init options to defaults on first pass.
    foreach thingy $__proc_options {
      set option [lindex $thingy 0]
      use_init CONGESTION($option) [set $option]
    }
  } {
    # Non-interactive.  Set _FPLAN_PLACE_IT from command line options.
    foreach thingy $__proc_options {
      set option [lindex $thingy 0]
      set CONGESTION($option) [set $option]
    }
  }

  if {$menu} {

    set prop_list ""
    lappend prop_list [list "Horizontal tracks per global grid" CONGESTION(tracks_per_grid_x) -number \
      -help {Determines size of global routing grid by multiplying this number times the pitch\
      of the first layer listed below.}]
    lappend prop_list [list "Vertical tracks per global grid" CONGESTION(tracks_per_grid_y) -number]

    #lappend prop_list [list "Horizontal routing resources per track" CONGESTION(resources_per_track,x) -number \
      -help {Average number of horizontal routes possible per track.  For example, if there are two\
      horizontal layers each obstructed 25%, set this to 1.5}]
    #lappend prop_list [list "Vertical routing resources per track" CONGESTION(resources_per_track,y) -number]
    #lappend prop_list [list "Horizonal display threshold" CONGESTION(display_threshold,x) -number]
    #lappend prop_list [list "Vertical display threshold" CONGESTION(display_threshold,y) -number]

    lappend prop_list [list "Horizontal wiring layers" CONGESTION(layers_h) -entry \
      -help {The routing resources are determined from this comma or space separated list of layers. \
      The first layer in the list is used to determine the global grid size by using its pitch\
      times the tracks_per_grid specified above.}]

    lappend prop_list [list "Vertical wiring layers" CONGESTION(layers_v) -entry]

    lappend prop_list [list "Horizontal resource availability " CONGESTION(avail_h) -number \
      -help {An additional congestion multiplier applied across the entire grid. \
      Eg: A value of 0.7 means allow use 70% of the available wiring tracks on\
      the layers specified above.}]

    lappend prop_list [list "Vertical resource availability " CONGESTION(avail_v) -number]

    lappend prop_list [list "Include existing congestion" CONGESTION(use_existing) -binary \
      -help {if set, max uses existing wiring congestion in the layout to pre-load\
      the global router congestion grid.}]

    lappend prop_list [list "Include cover cell congestion" CONGESTION(use_cover) -binary \
      -help {if including existing congestion and this is also set, max will look for a\
      cover cell and include congestion from that, too.}]

    lappend prop_list [list "Set visible max grid to track grid" CONGESTION(set_grid) -binary]

    lappend prop_list [list "" "" -separator]
    lappend prop_list [list "Display Options:" "" -label]
    lappend prop_list [list "Clear congestion feedback now" "" -button _fplan_cong_clear]
    lappend prop_list [list "Redisplay only using prior run" CONGESTION(display_only) -binary]

    foreach layer $CONGESTION(display_layers) {
      lappend prop_list [list "$layer Display Threshold" CONGESTION(util,$layer) -number]
    }

    lappend prop_list [list "Add text in each grid" CONGESTION(add_text) -binary \
      -help {This option places a text annotation (see lay_text) in the middle of each grid\
      of the form: used/available,used/available where used is the number of wires through the grid\
      and available is the number of available tracks through the grid; the first two numbers are for the\
      horizontal direction and the second two are for the vertical congestion.}]
    lappend prop_list [list "Text size" CONGESTION(text_size) -enum {small medium large larger}]


    #lappend prop_list [list "Number of Global Route Grids in X" CONGESTION(dim,x) -number]
    #lappend prop_list [list "Number of Global Route Grids in Y" CONGESTION(dim,y) -number]

    if {![prop_menu2 -title "Congestion Analyzer" $prop_list]} {return}
  }

  if {$CONGESTION(display_only)} {
    fplan_cong_display
  } else {
    _fplan_congestion_int
  }
}


proc _fplan_cong_clear {} {
  global CONGESTION
  foreach color [use_first CONGESTION(display_layers)] {
    eval db_paint -erase $color [lay_bbox]
  }
  # Erase text is put in by gr_max_display
  lay_text -clear -tag cg
}



proc _fplan_congestion_int {} {
  global CONGESTION

  if {0} {
  global NO_GLOBAL_ROUTER
  set NO_GLOBAL_ROUTER 0
  #set USE_NL 1
    if {[use_first NO_GLOBAL_ROUTER] == 1} {
      proc gr_command {args} {
	global GR_FD
	puts "In substitute global router"
	#mm_check
	if {[use_first GR_FD] != ""} {close $GR_FD}
	set GR_FD ""
      }
      proc gr_grid {args} {
	global GR_FD
	set GR_FD [open __gr.log r]
      }
      proc gr_grid_iter {args} {
	global GR_FD
	#mm_check
	gets $GR_FD line
	return $line
      }
    }
  }

  nl2_load_nl
  if {[info commands gr_command] != "gr_command"} {
    util_load_pkg max_gr_package.so
    #puts "DEBUG VERSION: using max_gr_package.so from pats home work area!!"
    #util_load_pkg /homes/pat/src/groute/max_gr_package.so
  }

  set mod [fplan_db_cell module [lay_rootcell]]

  global CONGESTION
  fplan_congest_init

  # Clear previous feedback paint now, so if this command aborts,
  # user will not think that previous paint are the new results.
  _fplan_cong_clear


  # NOTE NOTE NOTE
  # Pass the info to gr_command in this hoaky way through nl.
  catch {nl_create_pdesign -nohierarchy $mod}

  setl {bx1 by1 bx2 by2} [db_bbox -user]
  nl2_set_design_size $mod $bx1 $by1 $bx2 $by2


  # Dont use the requested bbox!  There might be tons of cells
  # outside it, and the user will be confused. Use the current actual size.
  setl {bx1 by1 bx2 by2} [db_bbox]
  # The user bbox should already be set up for prb

  # Copy the routing track info into the NL spot for it.
  # NL blithely assumes that everything is in millimicrons.
  set units 1000.0
  # gminx and gminy are the lower left corner of the routing grid.
  set gminy $by2		;# Init to impossibly large value
  set gminx $bx2		;# Init to impossibly large value
  #catch {nl_clear_x_tracks}     ;# Not defined yet.
  #catch {nl_clear_y_tracks}     ;# Not defined yet.


#DEBUG!!!  Needed until nl can erase tracks!
global FIRST_CONGESTION
if {![info exists FIRST_CONGESTION]} {
  set FIRST_CONGESTION 1

  foreach metal_layer [techinfo layers metal] {
    # Get the wire grid for this layer.
    setl {wgridx wgridy woffsetx woffsety} [wire_get_grid $metal_layer]

    # Set begx,endx to bbox snapped to wgridx.
    set begx [round_list_scale -ceil $bx1 $wgridx $woffsetx]
    set endx [round_list_scale -floor $bx2 $wgridx $woffsetx]
    set track_cnt(x) [expr int(round(($endx-$begx)/$wgridx))]
    nlt_log {nl_add_x_tracks -- [expr int($begx*$units)] $track_cnt(x) \
	[expr int($wgridx*$units)] [list $metal_layer] $mod}

    set begy [round_list_scale -ceil $by1 $wgridy $woffsety]
    set endy [round_list_scale -floor $by2 $wgridy $woffsety]
    set track_cnt(y) [expr int(round(($endy-$begy)/$wgridy))]
    nlt_log {nl_add_y_tracks -- [expr int($begy*$units)] $track_cnt(y) \
	[expr int($wgridy*$units)] [list $metal_layer] $mod}

    set gminx [min $gminx $begx]
    set gminy [min $gminy $begy]
  }
}

  setl {wgridx wgridy} [wire_get_grid $CONGESTION(track_layer,x)]
  set ggridx [expr $CONGESTION(tracks_per_grid_x) * $wgridx]	;# Size of global routing grid in microns
  setl {wgridx wgridy} [wire_get_grid $CONGESTION(track_layer,y)]
  set ggridy [expr $CONGESTION(tracks_per_grid_y) * $wgridy]

  # TODO: Should use the first specified layer to set the grid.
  if {$CONGESTION(set_grid)} {
    setl {wgridx wgridy woffsetx woffsety} [wire_get_grid [lindex [techinfo layers metal] 1]]
    grid_set -coarse "$ggridx $ggridy" -coarse_origin "$woffsetx $woffsety" \
	     -fine "$wgridx $wgridy" -fine_origin "$woffsetx $woffsety" \
	     -coarse_visibility lines -fine_visibility dots
    toggle_grid on
  }


  msg "congest-it: Invoking global router...\n"

  set nlobj [lindex [nl_find_designs -exact $mod] 0]
  setl {bx1 by1 bx2 by2} [db_bbox]

  puts "gr_command -grid_size_tracks $CONGESTION(tracks_per_grid_x) $CONGESTION(tracks_per_grid_y) \
	-avail $CONGESTION(avail_h) $CONGESTION(avail_v) \
	-hlayer $CONGESTION(layers_h) -vlayer $CONGESTION(layers_v) \
	-cover_cell [expr {$CONGESTION(use_cover) ? "[lay_editcell]_cover" : {}}] \
	-area $bx1 $by1 $bx2 $by2 -use_existing $CONGESTION(use_existing) $nlobj"

  gr_command -grid_size_tracks $CONGESTION(tracks_per_grid_x) $CONGESTION(tracks_per_grid_y) \
	-avail $CONGESTION(avail_h) $CONGESTION(avail_v) \
	-hlayer $CONGESTION(layers_h) -vlayer $CONGESTION(layers_v) \
	-cover_cell [expr {$CONGESTION(use_cover) ? "[lay_editcell]_cover" : {}}] \
	-area $bx1 $by1 $bx2 $by2 -use_existing $CONGESTION(use_existing) $nlobj

  msg "Displaying congestion...\n"

  fplan_cong_display
}

proc fplan_cong_display {} {
  global CONGESTION

  set thresholds ""
  foreach color $CONGESTION(display_layers) {
    lappend thresholds $CONGESTION(util,$color)
  }

  gr_max_display -add_text $CONGESTION(add_text) -text_size $CONGESTION(text_size) $CONGESTION(display_layers) $thresholds

  return

  # THIS IS THE OLD CODE THAT DISPLAYS USING MAX:

  #foreach dir "x y" {
  #  set total_resources($dir) [expr $CONGESTION(tracks_per_grid_$dir) * \
  #		$CONGESTION(resources_per_track,$dir)]
  #}

  # Clear previous feedback paint, if any.
  _fplan_cong_clear

  # DEBUG!!!  Just hack in some resource numbers to get this working.
  # HACK HACK HACK!!!
  set total_resources(x) 20
  set total_resources(y) 20

  setl {wgridx wgridy} [wire_get_grid $CONGESTION(track_layer,x)]
  set ggridx [expr $CONGESTION(tracks_per_grid_x) * $wgridx]	;# Size of global routing grid in microns
  setl {wgridx wgridy} [wire_get_grid $CONGESTION(track_layer,y)]
  set ggridy [expr $CONGESTION(tracks_per_grid_y) * $wgridy]

  # The threshold() of each color is the congestion in that direction
  # which is the minimum required to display that color.
  # The thresh_min_x and thresh_min_y are the minimum for any color,
  # so if congestion is less than thresh_min_x and thresh_min_y,
  # we can totally ignore it.
  set thresh_min_x 1000
  set thresh_min_y 1000
  foreach color $CONGESTION(display_layers) {
    set threshold(x,$color) [expr $total_resources(x) * $CONGESTION(util,$color)]
    set threshold(y,$color) [expr $total_resources(y) * $CONGESTION(util,$color)]
    if {$threshold(x,$color) < $thresh_min_x} {
	set thresh_min_x $threshold(x,$color)
    }
    if {$threshold(y,$color) < $thresh_min_y} {
	set thresh_min_y $threshold(y,$color)
    }
  }

  # Set scale so that a completely full global grid draws a display rectangle
  # 20% the size of the global grid rectangle.
  set scalex [expr 0.2 * $ggridx / $total_resources(x)]
  set scaley [expr 0.2 * $ggridy / $total_resources(y)]
  set scale [expr ($scalex + $scaley) / 2.0]

  msg "Displaying Congestion Grid...\n"
  set display_time [clock seconds]


  # Also save the congestion info into file __gr.log for debugging.
  set log_fd [open __gr.log w]

  # NOTE: Arguments backwards!!!!
  gr_grid [expr int(round($thresh_min_y))] [expr int(round($thresh_min_x))]
  set cnt 0
  while {1} {
    set a [gr_grid_iter]
    puts $log_fd $a
    set x [lindex $a 0]			;# global grid x coord
    if {$x == ""} {break}
    set y [lindex $a 1]			;# global grid y coord
    set h [expr int(ceil([lindex $a 2]))]  ;# horizontal congestion
    set v [expr int(ceil([lindex $a 3]))]  ;# vertical congestion

    # Save total congestion to try to compute IBM-like congestion merit factor
    set hvtotal [expr $h + $v]
    if {[info exists histo($hvtotal)]} {
      incr histo($hvtotal)
    } else {
      set histo($hvtotal) 1
    }

    if {$h >= $thresh_min_x} {
      foreach color $CONGESTION(display_layers) {
	if {$h > $threshold(x,$color)} { break }
      }

      #set maxh [max $maxh $h]
      #set color $colorx($h)

      set width2 [expr $h * $scale / 2.0]
      #set gx1 [expr $gminx + $x * $ggridx]
      #set gycenter [expr $gminy + ($y+0.5) * $ggridy]
      set gx1 [expr $x * $ggridx]
      set gycenter [expr ($y+0.5) * $ggridy]
      eval db_paint $color [uusnap $gx1 [expr $gycenter-$width2] [expr $gx1 + $ggridx] [expr $gycenter+$width2]]
      #db_paint $color $gx1 [expr $gycenter-$width2] [expr $gx1 + $ggridx] [expr $gycenter+$width2]
    }

    if {$v >= $thresh_min_y} {
      foreach color $CONGESTION(display_layers) {
	if {$v > $threshold(y,$color)} { break }
      }

      set width2 [uusnap [expr $v * $scale / 2.0]]
      #set gy1 [expr $gminy + $y * $ggridy]
      #set gxcenter [expr $gminx + ($x+0.5) * $ggridx]
      set gy1 [expr $y * $ggridy]
      set gxcenter [expr ($x+0.5) * $ggridx]
      eval db_paint $color [uusnap [expr $gxcenter-$width2] $gy1  [expr $gxcenter+$width2] [expr $gy1 + $ggridy]]
      #db_paint $color [expr $gxcenter-$width2] $gy1  [expr $gxcenter+$width2] [expr $gy1 + $ggridy]
    }
  }
  close $log_fd

  msg "done.  elapsed time [expr [clock seconds] - $display_time]\n"

  # Compute IBM-like congestion merit factor.
  # We dont really know exactly what this figure is based on.
  # But take the average congestion of the top 20% of the congestion grids.
  # The histo array indicies are congestion numbers, and the value
  # is the number of global grids that had that congestion.
  # First, count how many global grids.
  set total_grids 0
  foreach i [array names histo] {
    incr total_grids $histo($i)
  }
  # Now look at the top 20% of global grids.
  set grids_seen 0
  set total_congestion 0
  foreach cong [lsort -integer -decreasing [array names histo]] {
    set grids_seen [expr $grids_seen + $histo($cong)]
    set total_congestion [expr $total_congestion + ($cong * $histo($cong))]
    if {$grids_seen >= $total_grids * 0.2} break
  }
puts "total_grids=$total_grids grids_seen=$grids_seen total_congestion=$total_congestion"
  set factor [expr (1.0 * $total_congestion/$grids_seen) / ($total_resources(x) + $total_resources(y))]
  msg "IBM Congestion Factor = [format %.1f [expr 100.0 * $factor]]% \n"
}

proc _UNUSED_gr_grid_dump {} {
  #set log_fd [open __gr.log w]

  gr_grid 0 0
  set cnt 0
  while {1} {
    set a [gr_grid_iter]
    set x [lindex $a 0]			;# global grid x coord
    if {$x == ""} {break}
    #puts $log_fd $a
  }
  #close $log_fd
}
