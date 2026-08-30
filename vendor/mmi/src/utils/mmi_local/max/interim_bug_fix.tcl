# RCS $Revision: 1.24 $

# Random useful generic utility procedures for Max.
# (see also $MMI_UTILS/sharedtcl/share_utils.tcl for utils shared
#  between Max Sue and who knows who.)
 
proc res {args} -desc {
  Returns design grid size (minimum increment)
} -doc {
  USAGE: res [-userx | -usery | -internal | -mask]

  If -userx or -usery, return user resolution grid size
     in x or y, as set in the Grid Menu - this is the grid the mouse
     snaps to.
  If -mask, return foundry grid.
  If -internal, return max minimum internal grid.
  Default is -internal.
} {
  global GRID
  switch -- $args {
    "-userx" - "-user" {
      # There is a race condition: GRID(userx) and GRID(usery) are
      # defined during max initialization in grid_init.
      # Unfortunately, it is possible to get res -userx called
      # by moving the mouse on the screen as max is coming up,
      # and it can beat out grid_init.  So it is possible that
      # GRID(userx) is undefined, but only during startup.
      set res [res -internal]
      return [use_first GRID(userx) GRID(resolution) res]
    }
    "-usery" {
      set res [res -internal]
      return [use_first GRID(usery) GRID(resolution) res]
    }
    "" -
    "-internal" {
      return [lindex [mn_units] 1]
    }
    "-mask" {
      # Old tech files will not have GRID(mask) defined, so use internal grid
      # Dont think this is necessary, because GRID(mask) is inited at start up.
      if {[info exists GRID(mask)]} {
	return $GRID(mask)
      } else {
	return [res -internal]
      }
    }
    default {
      error {res: syntax: res [-userx | -usery | -internal | -mask]}
    }
  }
}

# Note: this function does not distuinguish x/y grid directions,
# so it is not possible to add non-square grids from here.
# However, layt_grid and layt_box do, so it would be possible
# to implement them there.
proc uusnap args -desc {
  Takes any number of values as args, returns list of results
} -doc {
  USAGE: uusnap [-floor | -ceil] [-user | -mask | -internal]  arg ...
  Rounds args to nearest legal units (design grid points.)
  If -user, round to user units.   If the user grid is assymetric,
  the first arg is assumed to be an X coord, the second a Y coord, etc.
  if -mask, round to minimum mask units;
  if -internal, round to nearest legal internal units (default case).
  if -floor, round value down to the next smaller unit;
  if -ceil, round value up to the next higher unit;
  otherwise round to nearest unit.
} {
  global GRID
  set rounding_type "round"
  set resx [res]
  set resy $resx

  # Parse options out of args
  while {1} {
    switch -- [lindex $args 0] {
      "-floor" {
	# We want to round down.
	# Unfortunately, accumulated floating point error means
	# we cant just use the "floor" function below, because
	# the input value could be just one FP error unit
	# below a res.  Instead, we will later add in an
	# offset that is guaranteed to round down.
	set rounding_type "floor"
      }
      "-ceil" {
	set rounding_type "ceil"
      }
      "-user" {
        set resx [res -userx]
        set resy [res -usery]
      }
      "-mask" {
        set resx [res -mask]
        set resy $resx
      }
      "-internal" { ;# This is also the default case.
	set resx [res]
	set resy $resx
      }
      default {
	# The rest of the args are number arguments
	break
      }
    }
    set args [lrange $args 1 end]
  }

  set result {}
  set i 0
  foreach val $args {
    if { $i % 2 == 0 } {
      set res $resx
    } else {
      set res $resy
    }
    incr i
    # This doesnt do exact ceil and floor, but close enough.
    switch $rounding_type {
    "floor" { set val [expr $val - $res/2.1] }
    "ceil" { set val [expr $val + $res/2.1] }
    }
    set val [expr $res * round($val/(0.0+$res))]
     

    # DONT REMOVE THIS string trim!!!!
    # There is a horrible bug in tcl as follows:
    # If a floating point number is coerced to a string
    # and then converted back to a number, it may or may not
    # be the same number and will compare unequal, SOMETIMES BUT NOT ALWAYS.
    # I tracked this down, and the problem is the least significant
    # bit in the floating point may be set or not after reconversion.
    # Since tcl now preserves numbers in lists, the number
    # can end up being preserved as long as it is in lists
    # or variables, and then suddenly get converted back to
    # a string by some operation, or as a return value, and then
    # it will no longer be quite the same number any more.
    # This was very difficult to see because 
    # if you just look at the numbers (via puts or any normal
    # means) they will look identical; but if you print
    # them with format %20.18f you can see how they differ.
    # This is particularly bad for uusnap, because, essentially,
    # it was returning two different numbers for the
    # same input, depending on how the result was stored. (pat)

    set val [string trim $val]   ;# DO NOT REMOVE!!!!!!

    # If you take out the above string trim, the following
    # code will catch the error:
    # Without the string trim, sample output was:
    #     1.14 == 1.14  but 1.1400000000000000124 != 1.1399999999999999902
    #set dummy [string trim $val]
    #if { $val != 0 + $dummy } {
    #    error "uusnap failed!!! $val == $dummy but \
    #    	   [format %20.18f $val] != [format %20.18f $dummy]"
    #}

    lappend result $val
  }
  return $result
}
