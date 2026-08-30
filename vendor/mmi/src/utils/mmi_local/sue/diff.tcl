proc diff {other_cell} {

  # save current cell name
  set current_cell [api_current_cell]

  # load other cell
  if {![api_goto_cell $other_cell]} {
    api_load_cell $other_cell
  }

  # save contents of other cell
  foreach id [diff_get_list_of_ids $other_cell] {
    set other([api_get_data $id]) 1
  }

  # return to current cell
  api_goto_cell $current_cell

  # select anything in current cell that's not in other
  api_select_ids ""
  foreach id [diff_get_list_of_ids $current_cell] {
    if {![info exists other([api_get_data $id])]} {
      api_select_ids $id add
    }
  }
}

proc diff_get_list_of_ids {other_cell} {

  set list ""
  foreach thing "instance wire line arc text dot open" {
    set list [concat $list [api_types $thing]]
  }
  return $list

}

# proc dump {} {
  # foreach id [diff_get_list_of_ids [api_current_cell]] {
    # puts [api_get_data $id]
  # }
# }
