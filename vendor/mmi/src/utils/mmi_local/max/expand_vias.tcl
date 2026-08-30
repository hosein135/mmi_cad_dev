#source $local_dir/expand_vias.tcl
#menu_tool_cmd "expand vias" expand_vias

proc expand_vias {} -desc {
  show internals on vias only
} {

  set save_box [lay_box]
  sel_clear

  set count 0
  foreach inst [split [db_search cells] \n] {
    setl {name type} $inst

    if {[string first VIA $type] != -1} {
      sel_cell $name
      lay_internals

      incr count
      if {[expr $count % 10000] == 0} {
	puts "... $count ..."
      }
    }
  }

  sel_clear
  eval lay_box $save_box

  puts "Expanded $count vias."
}
