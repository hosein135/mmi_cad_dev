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

#!/usr/bin/tclsh
# #!/utility/bin/tclsh
set mdir "~mha/max/m"
set origdir [exec pwd]

proc name_change {old_name new_name} {
    global mdir

    puts "\n\n\nDOING:  $old_name -> $new_name"
    cd $mdir

    foreach d [glob *] {
	puts "--- BEGINNING dir $d\n"
	cd $mdir/$d
	foreach f [glob *.c *.h] {
	    if {[catch {exec grep $old_name $f}] == 0} { 
		puts "$f contains $old_name reference.\n"
		exec mv $f $f.save
		exec sed s/$old_name/$new_name/g < $f.save > $f
	    }
	}
    }
}

proc name_changes {} {
    while {[gets stdin line] != -1} {
	if {[llength $line] != 2} {error {lines must be of form: "old_name new_name"}}
	set old_name [lindex $line 0]
	set new_name [lindex $line 1]
	name_change $old_name $new_name
    }
 
    puts "namechange.tcl DONE."
}

name_changes
cd $origdir







