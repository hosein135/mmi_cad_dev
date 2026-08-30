# Propagates the highest level labels on all pads unless the label is
# already on the top level.

# Written by Lee Tavrow, 2000.

# The next two lines go into the .maxrc
#source $local_dir/prop_pads.tcl
#menu_tool_cmd "prop pads" prop_pads

proc p {} {
  uplevel #0 source /home/tavrow/dev/max/prop_pads.tcl
  puts loaded
  prop_pads
}

#====================================================================#

# figures out pads from this layer
set PAD_LAYER pad

proc prop_pads {} -desc {
  propagate labels on pads
} {

  global PAD_LAYER

  puts "Propagating pad text ..."

  # make sure everything is fully expanded
  eval lay_box [lay_bbox]
  lay_internals -area

  set pads 0
  set props 0
  set already_props 0

  # get all of the pad areas
  foreach paint [split [db_search paint -any_cell $PAD_LAYER] \n] {
    # db_search labels does have any_cell option, so...
    eval sel_area -any_cell [lrange $paint 1 4]

    incr pads

    set save_label ""
    set depth 10000
    foreach label [split [sel_what labels] \n] {
      setl {layer lx1 ly1 lx2 ly2 pos text path group kind} $label

      if {$path == ""} {
	# already top level
	set save_label ""
	incr already_props
	break
      }

      set this_depth [llength [split $path /]]
      if {$this_depth < $depth} {
	# this is highest level so far
	set depth $this_depth
	set save_label $label
      }
    }

    if {$save_label != ""} {
      # prop this guy
      setl {layer lx1 ly1 lx2 ly2 pos text path group kind} $save_label

      db_label -kind $kind -pos $pos $layer $text $lx1 $ly1
      puts "  $text propagated"

      incr props
    }
  }
 
  # clean up
  sel_clear

  puts "Propagated text on $props pads out of $pads pads.  $already_props pads already had top-level text."
}

