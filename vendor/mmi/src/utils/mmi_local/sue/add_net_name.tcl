
# Example use of api

# Adds a net name to an instance output if the instance is bused and selected

# source ~/dev/tcl/add_net_name.tcl

menu_add -menu local -label "Add Bus Net Selected" -command add_bus_net \
    -hotkey 1 -help "Adds a net name to an instance output if the selected instance is bused."


proc add_bus_net {} {

  foreach instance [api_instances selected] {
    set data [api_instance_data $instance]
    set name [get_assoc _name $data]
    
    if {[bus_width $name] > 1} {
      # add a net_name for this

      # remove the root, if there is one
      set name "\[[join [lrange [split $name \[] 1 end] \[]"

      set orient [get_assoc orient $data]
      setl {xo yo} [get_assoc origin $data]

      # put this on the output net
      foreach list [api_terminal_data [get_assoc type $data]] {
	setl {port port_data} $list

	if {[get_assoc type $port_data] == "output"} {
	  # got an output
	  setl {xp yp} [api_orient_transform $orient \
			    [get_assoc origin $port_data]]

	  # make name_net
	  api_make name_net_s -origin [list [expr $xo + $xp] [expr $yo + $yp]] \
	      -orient $orient -name $name
	}
      }
    }
  }
}
