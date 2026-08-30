
# This procedure must be executed last (after loading all other tcl files)


# set up menus and such
set WIN .nst
setup_window $WIN

# hide the nst main window.  
wm withdraw .

# bring in the blt namespace
catch "namespace import blt::*"

# start off with one graph window

nst_make_graph
nst_find_limits

# if NST was brought up with any command line arguments, assume they
# are files and try to load them.

regsub -all {\*} $SUFFIX(default) 0 suffix

nst_fun

foreach file $argv {
  if {[file extension $file] == "" && [file exists $file$suffix]} {
    set file $file$suffix
  }

  puts "Loading $file ..."
  set result [nst_load $file]
  if {$result != 1} {
    puts $result
  }
}

