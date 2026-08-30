# This is an example API script for MAX to print out
# detailed DRC information for the current cell.

proc drc_info {} -desc {
  print out the DRC information for the current cell
} {

    # current cell name
    set cell [lay_rootcell]

    # find the directory
    set dir [file dirname [lindex [cell_info $cell] 1]]
    if {$dir == "."} {
      	set dir [pwd]
    }

    set filename $dir/$cell.drc_errors
    puts "Writing DRC error info to $filename ..."

    # open DRC file for writing
    if {[catch "open $filename w" FILE_ID]} {
      	# can't write file, abort
      	warning "Aborting, $FILE_ID"
      	return
    }


    # find out how many errors are in the cell
    msg_catch ":drc count" err msg
    set num_errors [lindex $msg 3]
    set cell_name [lindex $msg 1]
    puts "Number of Errors in $cell_name = $num_errors"
    puts $FILE_ID "####################################"
    puts $FILE_ID "Number of Errors in $cell_name = $num_errors"
    puts $FILE_ID "####################################"
    puts $FILE_ID " "

    if {$num_errors <= 50} {
       # print out each error and its coordinates
       for {set i 1} {$i < $num_errors+1} {incr i} {
           msg_catch ":drc find $i" err msg
           puts $FILE_ID $msg
      	   puts $FILE_ID [lay_box]
	   puts $FILE_ID "-----------"
	   puts $FILE_ID " "
       }
    } else {
       puts $FILE_ID "There are too many errors in $cell_name."
       puts $FILE_ID "No detailed DRC information will be printed."
       puts $FILE_ID " "
    }

    puts $FILE_ID "END DRC Info for $cell"
    close $FILE_ID
}

