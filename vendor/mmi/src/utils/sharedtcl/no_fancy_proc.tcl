set RCSVERSION(no_fancy_proc.tcl) { $Revision: 1.1 $ }

# if you have no fancy proc, this will make one for you

rename proc _oldproc

# Redefine the proc command
_oldproc proc {name argv args} {
  # Skip the -whatever arguments.  Use only last two arguments.
  set argc [llength $args]
  set body [lindex $args [expr $argc-1]]
  _oldproc $name $argv $body
}
