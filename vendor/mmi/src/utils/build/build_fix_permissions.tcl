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

# build_file_permissions
#
# usage:
#       build_file_permissions [dir]
#
# descends recursively to do entire tree rooted at "dir" (default ".")
#
# sets permissions as follows:
#     
#     all files readable by all
#     dirs and binaries executable by all
#     dirs writable by owner and group
# 

if {$argc > 1} {
    error "Usage: build_fix_permissions [dir]"
}

# if dir given, start there
if {$argc == 1} {
    set root_dir [lindex $argv 0]
} else {
    set root_dir "."
} 

# do dir contents
proc do_dir {dir} {
    set orig_dir [pwd]

    cd $dir
    foreach f [glob .* *] {
	set type [file type $f]

	# skip . and ..
	if {$f == "." || $f == ".."} {
	    continue
	}

	# skip symbolic links
	if {$type == "link"} {
	    continue
	}

	# read permissions for all, write permissions for nobody
	# if executable, make executable by anyone
	set executable [file executable $f]
	exec chmod a=r $f
	if {$executable} {
	    exec chmod a+x $f
	}

	# if directory, process recursively
	if {$type == "directory" } {
	    exec chmod ug+w $f
	    do_dir $f
	}
    }
    cd $orig_dir
}

#set permissions on the root dir itself
exec chmod a=rx $root_dir
exec chmod ug+w $root_dir

#do the contents of the root_dir
do_dir $root_dir
    
    
    