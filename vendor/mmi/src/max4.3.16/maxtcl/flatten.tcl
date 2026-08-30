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

set RCSVERSION(flatten.tcl) { $Revision: 1.8 $ }


proc flatten_init {} -desc {
    Init flatten setup array.
} -doc {
    FLATTEN_SETUP(labeltype,<type>) is the new type
	of the port, or "delete" to delete the port.
    FLATTEN_SETUP(labelname,<type>) is "flatten" to
	flatten the name, or "preserve" to leave it alone.
    Note that hidden labels are treated specially,
    and do not appear in FLATTEN_SETUP.
} {
    global FLATTEN_SETUP

    # For each label, specify:
    #   <original_label_type> <type_after_flatten> <flatten|preserve>
    # The <type_after_flatten> can be "delete" to delete the label.
    # The third action specifies what the flattener should do
    # to the label.  Preserve means leave the name alone.
    # Note: the value MUST be either flatten or preserve, because
    # it must match one of the choices in the prop_menu.
    # Flatten means change the name to a hierarchical name.
    set label_types [list        \
	"input  local  flatten"  \
	"output local  flatten"  \
	"inout  local  flatten"  \
	"global global preserve" \
	"local  local  flatten"  \
	"comment delete flatten" ]
    
    foreach thing $label_types {
      setl {type newtype action} $thing
      set FLATTEN_SETUP(labeltype,$type) \
	[use_first FLATTEN_SETUP(labeltype,$type) '$newtype]
      set FLATTEN_SETUP(labelname,$type) \
        [use_first FLATTEN_SETUP(labelname,$type) '$action]
    }

    set FLATTEN_SETUP(hier_char) [use_first FLATTEN_SETUP(hier_char) '.]
    set FLATTEN_SETUP(cellids) [use_first FLATTEN_SETUP(cellids) 'flatten]
}

proc flatten_setup {} -desc {
  Menu for flattening options.
} {
    global FLATTEN_SETUP
    flatten_init
    set prop_list ""

    foreach labtype {input output inout global local comment} {
	lappend prop_list [list "Text type: $labtype:" "" -label]
	lappend prop_list [list "    $labtype turns into:"  \
		FLATTEN_SETUP(labeltype,$labtype) \
		-choice {local global input output inout comment delete}]
	lappend prop_list [list "    $labtype name:"  \
		FLATTEN_SETUP(labelname,$labtype) \
		-choice {preserve flatten}]
    }

    lappend prop_list [list "" "" -separator]
    lappend prop_list [list "Cell Ids:" FLATTEN_SETUP(cellids) -choice {flatten preserve} \
      -help {if set to "flatten", cell ids are flattened by prepending the name\
	of the parent cell to the name.  If set to "preserve", the cell ids are\
	retained, but may be made unique by appending "_n", where n is a number.}]

    lappend prop_list [list "" "" -separator]
    lappend prop_list [list "Hierarchical name sep" FLATTEN_SETUP(hier_char) -entry \
	-desc {The character used to separate parts of the hierachical name\
	if label names are flattened.}]

    lappend prop_list [list "" "" -help {This menu\
      controls setup for the "flatten" command, accessible \
      through the menus.  The menu specifies \
      what happens to labels in a cell when you flatten it.
For each type of label (input, output, inout, global, local, comment) \
      you can either delete that type of label, or change it into any \
      other type of label.  For example, if you specify  \
      "global turns into: global" then global labels in the flattened \
      cell will be copied into the parent cell without changes. \
      If you specify "global turns into: delete", then global \
      labels will be deleted.
You can also specify whether the \
      label names are preserved or flattened.  If they are preserved, \
      they may conflict with other existing labels with the same name. \
      To avoid this, you can flatten the label names, which will \
      cause the labels to be renamed to something like: "cellname.labelname" \
      where "cellname" is the instance name of the cell that was flattened, \
      and "labelname" was the label name in the cell that was flattened. \
      }]

    # popup window
    return [prop_menu2 -title "Flatten Options" $prop_list]
}


proc _flatten_int {cells f_use_tmpcell parent_cell path f_flat_all f_labels} -doc {
  <cells> is the list of cell structures to flatten.
  <f_use_tmpcell> is set if we are flattening into an initially
  empty temporary cell.  It is set to 0 at all levels but the
  first flattening level, where it may be 1.
  <parent_cell> is the original edit_cell.
  <path> is the original hierarchical path to the current cell.
  If <f_flat_all> then recur to flatten all.
  If <f_labels> then flatten label names, too.
} {
  global _FLATTEN FLATTEN_SETUP

  foreach cellinfo $cells {
    struct max_cell cell $cellinfo

    # Toast the old cell.  If f_use_tmpcell, we are at level 0
    # flattening into __FLATTEN_TMP__, and the cells do not exist there,
    # they are in the original cell.  At lower levels,
    # the cells have been copied into the current cell, so they
    # always need to be deleted.
    if { ! $f_use_tmpcell } {
      sel_cell2 ${cell.id}
      :delete
    }

    # Process each element of the array.
    # Box is the box for an individual array element.
    # The size is irrelevant, only the lower left corner matters.
    set box.x1 0
    set box.y1 0
    
    if { ${cell.arrayinfo} == "" } {
	set xmax 1
	set ymax 1
	set xsep 0
	set ysep 0
    } else {
	struct max_cellarray cellarray ${cell.arrayinfo}
	set xmax [expr ${cellarray.xhi} - ${cellarray.xlo} + 1]
	set ymax [expr ${cellarray.yhi} - ${cellarray.ylo} + 1]
	# Sometimes max makes xsep/ysep negative.
	# Happens when you rotate, for example.  It works out
	# for max internally, because it will also shift the transform
	# origin to the other side of the array at the same time,
	# so starting at the new origin and marching backwards
	# produces the same result.
	# However, we always start at the lower left corner,
	# ignoring the transform, so we must use positive xsep,ysep.
	set xsep [expr abs(${cellarray.xsep})]
	set ysep [expr abs(${cellarray.ysep})]
    }

    set orient [orientation ${cell.transform}]

    # We dump into a temporary group before we rotate/flip
    # to make sure it does not land on an identical cell,
    # which would destroy it, or merge into existing paint, which
    # would erase it when it is flipped.  Unfortunately, the group stuff
    # is very slow, so dont do it if we are not flipping.
    set need_group [expr {$orient != ""}]

    for {set ycnt 0} {$ycnt < $ymax} {incr ycnt} {
      for {set xcnt 0} {$xcnt < $xmax} {incr xcnt} {
	
	set xtmp [expr ${cell.x1} + ${box.x1}]
	set ytmp [expr ${cell.y1} + ${box.y1}]
	layt_box exact $xtmp $ytmp $xtmp $ytmp

#puts "calling :dump [clock seconds]"
	# dump copy of cell into temporary group 
	if {$need_group} {db_group group_flatten}
	if {! $f_flat_all && $FLATTEN_SETUP(cellids) == "flatten"} {
	  # Only flattening one level of hierarchy, and name is to be flattened.
	  # Prepend parent cellid to new cell names.
	  :dump -instance_prefix ${cell.id}$FLATTEN_SETUP(hier_char) ${cell.def}
	} else {
	  # Either we are not flattening names, or we are flattening all levels,
	  # in which case the cells are going away and the cell names are irrelevant.
	  :dump ${cell.def}
	}
#puts "flipping [clock seconds]"
	
	# orient
	switch $orient {
	  "r90" {
	    :clockwise
	  }
	  "r180" {
	    :clockwise 180
	  }
	  "r270" {
	    :clockwise 270
	  }
	  "fx" {
	    :sideways
	  }
	  "fy" {
	    :upsidedown
	  }
	  "fx_r90" {
	    :sideways
	    :clockwise
	  }
	  "fy_r90" {
	    :upsidedown
	    :clockwise
	  }
	}
#puts "calling sel_group_transfer [clock seconds]"
	
	# now that it is in place, move to group 0
	if {$need_group} {sel_group_transfer 0}
#puts "calling sel_what labels [clock seconds]"

	set label_info [sel_what_l labels]
	set sub_cells [sel_what_l cells]
	sel_clear

	# Process labels that were in the cell:
	# Flatten any hidden labels attached to flylines in this cell,
	# and recreate the flylines.  Remove other hidden labels.
	foreach label $label_info {
	  struct max_label lab $label
	  set oldname ${path}${cell.id}/${lab.text}

	  switch -- ${lab.kind} {

	  "hidden" {
	    # Change label name to make sure name is unique.
	    sel_labels -kind ${lab.kind} \
		  -rect ${lab.x1} ${lab.y1} ${lab.x2} ${lab.y2} \
		  -text ${lab.text} -pos ${lab.pos} -layer ${lab.layer}
	    :delete

	    if { [dbt_flyline -cell $parent_cell -find $oldname] != "" } {
	      # There were flylines to the hidden label.
	      # Make new label identical to old but with new name.
	      # Overkill: make it unique both in the parent_cell
	      # and within __FLATTEN_TMP__
	      set uniq [label_unique_id -cell2 $parent_cell]
	      db_label -kind ${lab.kind}  -pos ${lab.pos} \
		      ${lab.layer} $uniq \
		      ${lab.x1} ${lab.y1} ${lab.x2} ${lab.y2}
	      lappend _FLATTEN(labels) [list $oldname $uniq]
	    } else {
	      lappend _FLATTEN(labels) [list $oldname ""]
	    }
	  }

	  default {
	    if { $f_labels } {
	      # Delete the old label.
	      sel_labels -kind ${lab.kind} \
		  -rect ${lab.x1} ${lab.y1} ${lab.x2} ${lab.y2} \
		  -text ${lab.text} -pos ${lab.pos} -layer ${lab.layer}
	      if {[llength [sel_what_l labels]] != 1} {
		error "Could not select label: ${lab.text}"
	      }
	      :delete

	      set new_type $FLATTEN_SETUP(labeltype,${lab.kind})
	      if { $new_type == "delete" } {
		lappend _FLATTEN(labels) [list $oldname ""]
	      } else {
		if { $FLATTEN_SETUP(labelname,${lab.kind}) == "flatten" } {
		    # Use flattened hierarchical name.
		    regsub -all / $oldname $FLATTEN_SETUP(hier_char) new_name
		} else {
		    # Preserve original name.
		    set new_name ${lab.text}
		}

		# Create new label with new kind and optionally flattened name.
		db_label -kind $new_type  -pos ${lab.pos} \
		      ${lab.layer} $new_name \
		      ${lab.x1} ${lab.y1} ${lab.x2} ${lab.y2}
		lappend _FLATTEN(labels) [list $oldname $new_name]
	      }
	    } else {
		lappend _FLATTEN(labels) [list $oldname ${lab.text}]
	    }
	  }

	  } ;# switch
	} ;# foreach label
#puts "tcl done [clock seconds]"

	if { $f_flat_all && [llength sub_cells] != 0 } {
	  _flatten_int $sub_cells 0 $parent_cell \
	    ${path}${cell.id}/ $f_flat_all $f_labels
	}

	set box.x1 [expr ${box.x1} + $xsep]

      } ;# for xcnt
      set box.y1 [expr ${box.y1} + $ysep]
      set box.x1 0
    } ;# for ycnt

  } ;# foreach cellinfo
}


proc flatten_cells {{-show_menu} {-save_labels} {-cellids ""} {-labels_only} {-group 0} {-fast}} -desc {
  flattens all selected cell instances (only one level of hierarchy).
} -doc {
  
  If -save_labels, all labels are saved.  Otherwise, use FLATTEN_SETUP
    to determine how to change labels.
  If -show_menu, bring up the prop_menu first.
  If -group, put objects into a new group.
  If -labels_only, flatten only labels, ie, copy labels in
     hiearchy to current cell.
  If -fast, use fast mode: do not leave result selected,
     and dont worry about flylines.
  If "-cellids flatten", newly created cell names are prepended with the parent name.
  If "-cellids preserve", cell names are unchanged.

  Flylines are preserved.  They are tricky.  They can be hiearchical
  into the cell we are flattening, or into a sub-cell of the
  cell we are flattening.

  Hidden labels that are flattened are renamed with unique names.
  The FLATTEN_SETUP controls what happens to other flattened label names.
  Usually I/O ports are preserved by renaming.
} {
  global FLATTEN_SETUP _FLATTEN

  flatten_init
  set f_flat_all 0     ;# Flatten all levels if true
  set f_use_tmpcell 1  ;# Use tmp cell for flattening if true.

  set flag 0
  set cells [sel_what_l cells -edit_only flag]

  if { $flag } {
    max_error "flatten_cells: Aborting, selection contains subcell(s) not in the current cell"
    return
  }
  if {[llength $cells] == 0} {
    max_error "flatten_cells: Aborting, must select cell(s) before flattening."
    return
  }

  if {$cellids != ""} {
    assert {$cellids == "flatten" || $cellids == "preserve"}
    set FLATTEN_SETUP(cellids) $cellids
  }

  # Temporary: flatten is not working with edit-in-place,
  # and since the code is frozen before the 12/00 release,
  # just print a message and quit.  Fix it later.
  # Check show_menu just in the remote chance that Lee is
  # calling flatten_cells while in edit-in-place and it works somehow?
  if { $show_menu && [lay_rootcell] != [lay_editcell]} {
    max_error "flatten_cells: Aborting, Can not flatten while in edit-in-place. \
      First use Control-e to pop edit stack."
    return
  }

  # Make settings persistent for interactive use.
  # These are the defaults.
  use_init _FLATTEN(group) 0
  use_init _FLATTEN(all) 0
  use_init _FLATTEN(labels_only) 0
  use_init _FLATTEN(fast) 0

  if {$show_menu} {

    set prop_list ""
    lappend prop_list [list \
      "Put flattened layout in a Group" _FLATTEN(group) -binary \
      -help {if set, flattened layout will be placed into a new\
      group sub-cell, which can be moved or edited more easily.}]

    lappend prop_list [list \
      "Flatten entire hierarchy" _FLATTEN(all) -binary \
      -help {if set, flatten operation will recur on subcells until\
      entire cell hierarchy is flattened.  Otherwise, only the selected\
      cells themselves will be flattened; only one level deep.}]

    lappend prop_list [list "Flatten text only:" _FLATTEN(labels_only) \
	-binary -help {if set, only text (labels) will be flattened, not cells.\
	In other words, text in the sub-cell(s)\
	will be copied into the current cell, according to the options\
	set in the flatten setup menu, but the cells themselves\
	will not be affected.}]

    lappend prop_list [list "Fast mode:" _FLATTEN(fast) \
	-binary -help {this is faster for large cells.  It does not\
	leave the result selected, and will not preserve flylines.}]

    lappend prop_list [list "Flatten Setup..." "" -button flatten_setup]

    if {![prop_menu2 -title "Flatten"  $prop_list]} {
      # user hit cancel.
      return
    }

    set group $_FLATTEN(group)
    set f_flat_all $_FLATTEN(all)
    set fast $_FLATTEN(fast)
    set labels_only $_FLATTEN(labels_only)
  }

  if {$fast && ! $labels_only && ! $group} {
    # The tmp cell is slower, so dont use it unless we have to.
    set f_use_tmpcell 0
  }

  sel_clear

  set parent_cell [lay_editcell]
  set _FLATTEN(labels) ""

  dbt_flyline -init $parent_cell

  if {$f_use_tmpcell} {
    # Create temp cell to hold flattened stuff.
    # This way the flattened result is left selected when we are done.
    # Also, if we encounter an error, we havent damaged the edit cell.
    if { [cell_flags __FLATTEN_TMP__] != "__NO_SUCH_BUFFER__" } {
      msg_catch { db_cell_delete __FLATTEN_TMP__ } a b c
    }
    msg_catch { db_cell_new -no_undo -internal __FLATTEN_TMP__ } a b c

    # edit __FLATTEN_TMP__ and copy each cell into it
    edit_push_direct __FLATTEN_TMP__
  }

  # The initial level is taken from f_use_tmpcell.
  _flatten_int $cells $f_use_tmpcell $parent_cell "" $f_flat_all [expr ! $save_labels]

  if {$f_use_tmpcell} {

    # For now, none of the flylines internal to cells that were
    # flattened (now in __FLATTEN_TMP__) are to be preserved.
    # This is unnecessary, since :dump does not yet copy flylines.
    db_flyline -delete

    if { $labels_only } {
      # We did alot of work, but we really only want the labels.
      # Delete everything else.
      eval sel_area -no_labels [lay_bbox]
      :delete
      sel_labels -kind hidden
      :delete
    }

    # Back to the main cell.
    edit_pop_direct

#puts "deleting original cells [clock seconds]"
    # Delete original first-level cells.
    if { ! $labels_only } {
      foreach cellinfo $cells {
	struct max_cell cell $cellinfo

	# toast old instance
	sel_cell2 ${cell.id}
	:delete
      }
    }
  }

  if { $group } {
    setl {newgroup_def newgroup_id} [gcell_group_create]
    db_cell_copy -source __FLATTEN_TMP__ $newgroup_def
    set fly_prefix ${newgroup_id}/

  } elseif {$f_use_tmpcell} {
#puts ":dump __FLATTEN_TMP__ [clock seconds]"
    # place and select contents of __FLATTEN_TMP__
    :dump __FLATTEN_TMP__ child 0 0 parent 0 0
    set fly_prefix ""

#puts "db_cell_delete __FLATTEN_TMP__ [clock seconds]"
    # Recover the memory.
    msg_catch { db_cell_delete __FLATTEN_TMP__ } a b c
  }
#puts "fixing flylines [clock seconds]"

  # _FLATTEN(labels) contains all the label changes.
  # Fix up flylines to point to new labels.
  if {! $labels_only && ! $fast} {
    foreach thingy $_FLATTEN(labels) {
      setl {old new} $thingy
      if { $new == "" } {
	dbt_flyline -delete $old
      } else {
	dbt_flyline -change $old $fly_prefix$new
      }
    }
  }

  return ""
}
