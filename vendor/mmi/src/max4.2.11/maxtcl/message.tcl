## ************************************************************************
## 
## Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
## 
## Permission is hereby granted, without written agreement and without
## license or royalty fees, to use, copy, modify, and distribute this
## software and its documentation for any purpose, provided that the
## above copyright notice and the following three paragraphs appear in
## all copies of this software.
## 
## IN NO EVENT SHALL JUNIPER NETWORKS, INC. BE LIABLE TO ANY PARTY FOR
## DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
## ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
## JUNIPER NETWORKS, INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
## DAMAGE.
## 
## JUNIPER NETWORKS, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES,
## INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
## NON-INFRINGEMENT.
## 
## THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
## NETWORKS, INC. HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
## UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
## 
## ************************************************************************

set RCSVERSION(message.tcl) { $Revision: 1.8 $ }
# message handling.

init_global MSG(log_file) \
	-type STRING \
	-default "./max%.log" \
	-desc { Log file name; % replaced by a number }

init_global MSG(logging_on) \
	-type BINARY \
	-default 0 \
	-desc { Logging on or off }

set MSG(log_fd) ""
set MSG_DIVERSION 0

proc msg_init {} -desc {
  setup message handling 
} -doc {
  Map ancient (Magic) TxGetLine() to Tcl gets.
  Register tcl routine to print out info messages 
  with delimeters ("---------") between commands.

  Note: msg_map defines what the msg command will do if it
  does not occur inside a msg_catch.  This routine maps
    msg whatever
  to:
    _msg_print whatever

  Do NOT map these to something that will do an interactive tcl command,
  because they may be called from inside max inside an operation,
  and we do not want the user to be able to gain control at that
  point when max is unstable.
} {
    global MSG
    # If you set either infoScript or warnScript arguments to a null string,
    # the messages will be THROWN AWAY!  Dont do that!
    msg_map {} _msg_print _msg_warn
    set MSG(last_print) 0 
    set MSG(buffer) ""
    _msg_open_log
}


proc msg_end {} -desc {
  Called before max quits to flush the log messages.
} {
  global MSG
  if {$MSG(log_fd) != ""} {
    close $MSG(log_fd)
    set MSG(log_fd) ""
  }
}

proc msg_log {{val 1}} -type local -desc {
  Turn logging on (val == 1 or not specified) or off (val == 0)
} {
  global MSG
  set MSG(logging_on) 1
  if {$val} {
    _msg_open_log
  } else {
    msg_end
  }
}

proc _msg_open_log {} -desc {
  Try to open the log file.  Set MSG(log_fd) to open file.  Write a header.
} {
  global MSG MN_TECH MN_TECH_VAR

  if {! $MSG(logging_on)} {return}

  # See if already logging.
  if {$MSG(log_fd) != ""} {return}

  # Look a file name that is not currently in use.
  for {set i 1} {$i < 100} {incr i} {
    set file_name $MSG(log_file)
    regsub {%} $file_name $i file_name

    if {[vc_sema_file lock -file $file_name] != ""} {
      # This file is currently in use by another max.
      continue
    }
    break
  }

  if {[catch {open $file_name w} result]} {
    puts "Warning: can not open log file: $file_name"
    # We failed for unknown reasons.  Maybe directory is write-only.
    # Give up.
    return
  }
  set MSG(log_fd) $result

  puts "Starting logging to file $file_name"

  # Write a header with the date.
  puts $MSG(log_fd) "Log file created by max on [clock format [clock seconds]]"
  set tech $MN_TECH
  if {$MN_TECH_VAR != ""} {append tech "-$MN_TECH_VAR"}
  puts $MSG(log_fd) "Current max technology option: $tech."
  # Make sure the above is output to the file, even if max crashes.
  flush $MSG(log_fd)
}

proc _msg_print {s} -desc {
  print message (to controlling terminal) - with delims between interactive commands
} {
  global MSG i_cmd

  if {$MSG(last_print) != $i_cmd(num)} {
      # Pat took this out.  Its almost always out of sync.  Just print a newline instead.
      #puts "--------------"	
      puts ""	
      set MSG(last_print) $i_cmd(num)
  }

  if {$MSG(logging_on) && $MSG(log_fd) != ""} {
      puts -nonewline $MSG(log_fd) $s
  }

  puts -nonewline $s
}

proc _msg_warn {s} -desc {
  used by msg_map to print warning message, and buffer for future popup.
} {
  global MSG i_cmd

  if {$MSG(last_print) != $i_cmd(num)} {
      puts ""	
      set MSG(last_print) $i_cmd(num)
  }

  if {$MSG(logging_on) && $MSG(log_fd) != ""} {
      puts -nonewline $MSG(log_fd) $s
  }

  puts -nonewline $s

  append MSG(buffer) $s
}


proc msg_log_file_menu {} {
  global MSG
  set prop_list ""
  set log_file $MSG(log_file)
  set log_clear 0
  lappend prop_list [list {Logging on} MSG(logging_on) -binary]
  lappend prop_list [list {Log file name} log_file -entry -help {\
    The log file name must contain a %, which is replaced by a unique
    number so multiple max can be run simultaneously.}]
  lappend prop_list [list {Clear log file} log_clear -binary]

  if {[prop_menu2 -title "Max Log File" $prop_list] == 0} {
    # Canceled
    return
  }

  if {[string first $log_file %] == -1} {
    error "Max log file must contain a %"
  }

  # Close old log file, if any.
  if {$MSG(log_fd)} {
    close $MSG(log_fd)
    set MSG(log_fd) ""
  }

  if {$log_clear} {
    catch {file delete $MSG(log_file)}
  }

  set MSG(log_file) $log_file

  # Try opening the log file now, to print warnings now.
  _msg_open_log
}



# Notes: this replaces msg_catch, so documentation pretends that it is msg_catch.
# Unlike original msg_catch, if messages are not caught, they are discarded.
# I made this modification because I noticed that many places in tcl code assumed
# that msg_catch worked that way, ie, used msg_catch {command} thinking the error
# messages would be discarded (like catch {command}).
proc _msg_catch_replacement {command {return_var_name ""} {info_var_name ""} {warn_var_name ""}} -desc {
  Catch errors and max warnings.
} -doc {
  Evaluates <command> and returns completion code, like the tcl catch command, but
  additionally diverts info and warning messages.

  If <return_var_name> is given, the return value of <command> is put in the named variable.
  If a null string, the return value is discarded.

  If <info_var_name> is given, any info messages generated by the "msg" proc
  are diverted to the named variable.  If a null string, the messages are discarded.

  If <warn_var_name> is given, any warning messages generated by the "msg -warn" proc
  are diverted to the named variable.  If a null string, the messages are discarded.

  Normally msg_catch returns a completion code of 0.

  If an error occurs during "command", "msg_catch" returns 1, and the return_var_name 
  (if present) is set to the error message, which may be .  The global variable "errorInfo" is set
  to a stack trace.

  msg_catch does not affect messages that were buffered but not flushed before this call;
  they remain buffered, and are not returned by msg_catch.
  You can call msg_flush before msg_catch to force previous errors to be flushed first.
} {
  global MSG_DIVERSION
  incr MSG_DIVERSION
  set ret [uplevel [list _msg_catch_orig $command $return_var_name $info_var_name $warn_var_name]]
  incr MSG_DIVERSION -1
  if {$MSG_DIVERSION < 0} {set MSG_DIVERSION 0}
  return $ret
}


rename msg_catch _msg_catch_orig
rename _msg_catch_replacement msg_catch


proc msg_flush {} -desc {
  Post buffered warning messages, unless inside msg_catch.
} {
  global MSG MSG_DIVERSION
  if {$MSG_DIVERSION} {
    # Do nothing.  Messages are being caught.
    return
  }

  # This is a good time to flush the log file
  if {$MSG(logging_on) && $MSG(log_fd) != ""} {
    flush $MSG(log_fd)
  }

  # Put out any stored warnings.
  set msgs $MSG(buffer)
  set MSG(buffer) ""
  if {$msgs != ""} {
    # Do not call bgerror, because it adds a stack-trace button,
    # but stack trace would not be correct for the current context.

    # TEMPORARY: Take this popup out for the release,
    # until we figure out why it occurs:
    global MAX_DEVELOPER
    if {$MAX_DEVELOPER} {
      prop_dialog -title "max errors" $msgs
    }
  }
}
