# This is an example API script for MAX to print out how
# many instances of each type of cell are instantiated
# in the current cell.

proc info_inst {} -desc {
  return information about instances in current cell
} {

    # select  subcells for current edit cell
    eval sel_area -layers subcell [lay_bbox]
    # break up large list of info for cells into a  list of
    # lists separated by a <CR>, go through each item in list
    foreach cell [split [sel_what cells] \n] {
	# set first field to name, second field to type
	setl {name type} $cell

	# check it that type (cellname) has already been found
	if {![info exists types($type)]} {
	    set types($type) 0
	}

	incr types($type)
    }

    #print out the number is instances and cell name
    foreach type [lsort [array names types]] {
	puts [format "%-10d %s" $types($type) $type]
    }
}

