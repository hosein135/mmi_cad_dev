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

set RCSVERSION(db.tcl) { $Revision: 1.6 $ }

# tcl routines augmenting db (database module).
# (layer types, cells, painting, searching)

proc dbt_long_name {name} -desc {
    map type (layer) name to official long-name
} {
  global _dbt_type_table

  #initialize type table if necessary
  if {! [info exists _dbt_type_table] } {
    _db_gen_type_table
  }

  return [use_first _dbt_type_table($name.longname)]
}


proc dbt_short_name {names} -desc {
    map (list of) long layer names to (list of) short names
} {
  global PAL _dbt_type_table

  #initialize type table if necessary
  if {! [info exists _dbt_type_table] } {
    _db_gen_type_table
  }

  set ret ""
  foreach name $names {
    # First make sure we have the long name.
    set long [use_first _dbt_type_table($name.longname)]
    set short [use_first PAL(name,$long)]
    if { $short != "" } { lappend ret $short }
  }
  return $ret
}


proc db_plane {name} -desc {
    map type (layer) name to plane it is on
} {
  global _dbt_type_table

  #initialize type table if necessary
  if {! [info exists _dbt_type_table] } {
    _db_gen_type_table
  }

  return [use_first _dbt_type_table($name.plane)]
}


proc _db_gen_type_table {} -desc {
    gen table of db type attributes
} {
  global _dbt_type_table

  foreach type [split [db_types] \n] {
    setl {longName shortName names plane flags} $type
    foreach name $names {
      set _dbt_type_table($name.longname) $longName
      set _dbt_type_table($name.plane) $plane
    }
  }
}
