// ************************************************************************
// 
// Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
// 
// Permission is hereby granted, without written agreement and without
// license or royalty fees, to use, copy, modify, and distribute this
// software and its documentation for any purpose, provided that the
// above copyright notice and the following three paragraphs appear in
// all copies of this software.
// 
// IN NO EVENT SHALL JUNIPER NETWORKS, INC. BE LIABLE TO ANY PARTY FOR
// DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
// ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
// JUNIPER NETWORKS, INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
// DAMAGE.
// 
// JUNIPER NETWORKS, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
// NON-INFRINGEMENT.
// 
// THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
// NETWORKS, INC. HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
// UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
// 
// ************************************************************************

// setup Global Router Tcl interface

#include <tcl.h>

extern int tcl_gr_command();
extern int tcl_gr_term();
extern int tcl_gr_block();
extern int tcl_gr_grid();
extern int tcl_gr_grid_iter();
extern int tcl_gr_max_display();

int Gr_package_Init(Tcl_Interp *interp) {

  Tcl_CreateObjCommand(interp, "gr_command", tcl_gr_command, NULL, NULL);
  Tcl_CreateObjCommand(interp, "gr_block", tcl_gr_block, NULL, NULL);
  Tcl_CreateObjCommand(interp, "gr_grid", tcl_gr_grid, NULL, NULL);
  Tcl_CreateObjCommand(interp, "gr_grid_iter", tcl_gr_grid_iter, NULL, NULL);
  Tcl_CreateObjCommand(interp, "gr_term", tcl_gr_term, NULL, NULL);

  return TCL_OK;

}

int Max_gr_package_Init(Tcl_Interp *interp) {

#if 0
  // Using MnDocCreateObjCommand does not exist in max yet.
  MnDocCreateObjCommand(interp, "gr_command", tcl_gr, NULL, NULL,
	"congestion analyzer primary interface",
	"\
	Assumes nl is already loaded up with the design.
	Usage: gr_command <x_ggrid_size> <y_ggrid_size> <v_resources_per_track> <h_resources_per_track> <show_grid>
	show_grid typically 0 or 1.
	If adding blockages, call this proc with show_grid=2 to setup grid, 
	then call gr_block to add blockages, and then call with show_grid=3 to route.
	");
  MnDocCreateObjCommand(interp, "gr_block", tcl_gr_block, NULL, NULL,
	"add blockage for congestion analyzer",
	"\
	usage (from tcl): gr_block x y v h
	where x,y is the ggrid in ggrid units (i.e. 0,0 is lower left)
	h,v are the blockage amounts in horizontal/vertical dirs.
	");
  MnDocCreateObjCommand(interp, "gr_grid", tcl_gr_grid, NULL, NULL,
	"Set up iterator to get congestion",
	"\
	Sets up iterator to get congestion.
	Then call gr_grid_iter to get results.
	Takes a vertical minimum, horizontal minimum for return.
	");
  MnDocCreateObjCommand(interp, "gr_grid_iter", tcl_gr_grid_iter, NULL, NULL,
	"returns results from congestion analyzer ",
	"\
	Note: call gr_grid first.
	Returns x, y, h, v.  Where x, y are the coords of the ggrid (offset
	to corresponds to microns) and h, v are the congestions there.
	");
#endif

  Tcl_CreateObjCommand(interp, "gr_command", tcl_gr_command, NULL, NULL);
  Tcl_CreateObjCommand(interp, "gr_block", tcl_gr_block, NULL, NULL);
  Tcl_CreateObjCommand(interp, "gr_grid", tcl_gr_grid, NULL, NULL);
  Tcl_CreateObjCommand(interp, "gr_grid_iter", tcl_gr_grid_iter, NULL, NULL);
  Tcl_CreateObjCommand(interp, "gr_max_display", tcl_gr_max_display, NULL, NULL);
  Tcl_CreateObjCommand(interp, "gr_term", tcl_gr_term, NULL, NULL);

  return TCL_OK;

}
