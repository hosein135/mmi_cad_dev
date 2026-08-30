# This is an example API script to print out the 
# hierarchy tree for the current cell.

proc print_tree {} -desc {
prints out the hierarchy below the current cell
} {
  global space
  set space ""
  set topcell [lay_rootcell]
  puts $topcell
  append space "  "
  _print_hier $topcell
}

proc _print_hier {cellname} {
  catch {unset CELL_TREE}
  set CELL_TREE(__count__) 0
  global space

  foreach line [split [db_search cells -cell $cellname] \n ] {
    setl {instname pname} $line
    if {[info exists CELL_TREE($pname)]} {
      #already found this cell
      incr CELL_TREE($pname)
    } else {
      incr CELL_TREE(__count__)
      set CELL_TREE($pname) 1
    }
  }
 
  foreach subcell [db_kids $cellname] {
    if {[is_gcell $subcell]} {
      continue
    }
    set kids [db_kids $subcell]
    if {$kids == ""} {
      # no kids
      puts "$space$subcell $CELL_TREE($subcell)"
    } else { 
      # kids exist
      puts "$space$subcell $CELL_TREE($subcell)"
      append space "  "
      set indent [string length $space]
      _print_hier $subcell
      set space ""
      incr indent -2
      while {$indent > 0} {
        append space "  "
        incr indent -2
      }
    }
  }

}

