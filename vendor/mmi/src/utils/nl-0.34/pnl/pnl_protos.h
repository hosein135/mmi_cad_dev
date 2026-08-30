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

pnl_design	pnl_design_create (nl_design);
pnl_idesign	pnl_idesign_create (nl_idesign);
pnl_idesign	pnl_idesign_fill (nl_idesign);
void		pnl_idesign_update_locations (nl_idesign, int, int,
					      pnl_orientation, pnl_loctype);
void		pnl_design_free (pnl_design);
pnl_cell	pnl_design_get_cell_by_name (pnl_design, char *);
void		pnl_design_set_die_area (pnl_design, int, int, int, int);
void		pnl_design_clear_die_area (pnl_design);
int		pnl_design_get_die_area (pnl_design,
					 int *, int *, int *, int *);
void		pnl_design_set_distance_units (pnl_design, char *, int);
void		pnl_design_get_distance_units (pnl_design, char **, int *);
void		pnl_design_add_x_tracks (pnl_design, int, int, int, ar);
void		pnl_design_add_y_tracks (pnl_design, int, int, int, ar);
void		pnl_design_free_x_tracks (pnl_design);
void		pnl_design_free_y_tracks (pnl_design);
#if 0
void		pnl_design_get_x_tracks (pnl_design,
					 int *, int *, int *, ar *);
void		pnl_design_get_y_tracks (pnl_design,
					 int *, int *, int *, ar *);
#endif
void		pnl_design_add_row_site (pnl_design, char *, char *,
					 int, int, pnl_orientation,
					 int, int, int);
void		pnl_design_free_row_sites (pnl_design);
void		pnl_design_add_history (pnl_design, char *);


pnl_cell	pnl_cell_create (nl_cell);
pnl_icell	pnl_icell_create (nl_icell);
char *		pnl_cell_name (pnl_cell);
char *		pnl_icell_name (pnl_icell);
void		pnl_cell_free (pnl_cell);
void		pnl_icell_free (pnl_icell);
void		pnl_cell_set_loctype (pnl_cell, pnl_loctype);
void		pnl_icell_set_loctype (pnl_icell, pnl_loctype);
void		pnl_cell_set_location (pnl_cell, int, int, int);
void		pnl_icell_set_location (pnl_icell, int, int, int);
int		pnl_cell_has_location (pnl_cell);
int		pnl_icell_has_location (pnl_icell);
void		pnl_cell_get_location (pnl_cell, int, int *, int *);
void		pnl_icell_get_location (pnl_icell, int, int *, int *);
void		pnl_cell_set_orientation (pnl_cell, pnl_orientation);
void		pnl_icell_set_orientation (pnl_icell, pnl_orientation);
		
pnl_port	pnl_port_create (nl_port);
char *		pnl_port_name (pnl_port);
void		pnl_port_free (pnl_port);
void		pnl_port_set_loctype (pnl_port, pnl_loctype);
void		pnl_port_set_location (pnl_port, int, int);
int		pnl_port_has_location (pnl_port);
void		pnl_port_get_location (pnl_port, int *, int *);
void		pnl_port_set_orientation (pnl_port, pnl_orientation);
void		pnl_port_set_geometry (pnl_port, char *, int, int, int, int);
int		pnl_port_get_geometry (pnl_port, char **, int *, int *,
				       int *, int *);
void		pnl_port_clear_geometry (pnl_port);
void		pnl_port_set_use (pnl_port, pnl_use);

pnl_net		pnl_net_create (nl_net);
pnl_inet	pnl_inet_create (nl_inet);
char *		pnl_net_name (pnl_net);
char *		pnl_inet_name (pnl_inet);
void		pnl_net_free (pnl_net);
void		pnl_inet_free (pnl_inet);
void		pnl_net_add_route (pnl_net, pnl_route);
void		pnl_inet_add_route (pnl_inet, pnl_route);
void		pnl_net_set_use (pnl_net, pnl_use);
void		pnl_inet_set_use (pnl_inet, pnl_use);
void		pnl_net_set_pattern (pnl_net, pnl_pattern);
void		pnl_inet_set_pattern (pnl_inet, pnl_pattern);
void		pnl_net_set_special (pnl_net, int);
void		pnl_inet_set_special (pnl_inet, int);

pnl_dll_head	pnl_dll_create (void);
void		pnl_dll_add (pnl_dll_head, pnl_dll);
void		pnl_dll_remove (pnl_dll_head, pnl_dll);
void		pnl_dll_free (pnl_dll_head);		
pnl_dll		pnl_dll_gen_first (pnl_dll_head);
pnl_dll		pnl_dll_gen_next (pnl_dll_head, pnl_dll);

pnl_route	pnl_route_create (pnl_routekind);
void		pnl_route_free (pnl_route);
void		pnl_route_add_branch (pnl_route, pnl_branch);

pnl_branch	pnl_branch_create (char *, int, int, int);
void		pnl_branch_free (pnl_branch);
void		pnl_branch_add_segment (pnl_branch, pnl_segment);

pnl_segment	pnl_segment_create_x_segment (int);
pnl_segment	pnl_segment_create_y_segment (int);
pnl_segment	pnl_segment_create_via (char *);
void		pnl_segment_free (pnl_segment);


pnl_loctype	pnl_string_to_loctype (char *);
pnl_orientation	pnl_string_to_orientation (char *);

pnl_library	pnl_library_create (nl_library);
void		pnl_library_free (pnl_library);
void		pnl_libcell_free (pnl_libcell);
void		pnl_libpin_free  (pnl_libpin);
		
pnl_rectangle	pnl_rectangle_create (char *, int, int, int, int);
void		pnl_rectangle_free (pnl_rectangle);
pnl_libcell	pnl_libcell_create (nl_libcell, pnl_library);
pnl_libpin	pnl_libpin_create (nl_libpin, pnl_libcell);
void		pnl_libcell_set_class (pnl_libcell, pnl_cellclass);
void		pnl_libcell_set_size (pnl_libcell, int, int);
void		pnl_libcell_set_origin (pnl_libcell, int, int);
void		pnl_libcell_add_symmetry (pnl_libcell, pnl_symmetry);
int		pnl_libcell_get_symmetry (pnl_libcell, pnl_symmetry);
void		pnl_libcell_set_site (pnl_libcell, char *);
void		pnl_libcell_add_obs_geometry (pnl_libcell, pnl_geometry);
char *		pnl_libcell_name (pnl_libcell);
int		pnl_libpin_set_or_check_direction (pnl_libpin, nl_direction);
void		pnl_libpin_add_port_rectangle (pnl_libpin, pnl_rectangle);
void		pnl_libpin_set_antennadiffarea (pnl_libpin, int);
void		pnl_libpin_set_antennagatearea (pnl_libpin, int);
void		pnl_libpin_set_capacitance (pnl_libpin, float);
int		pnl_libcell_sizex (pnl_libcell);
int		pnl_libcell_sizey (pnl_libcell);
void		pnl_libcell_get_bounding_box (pnl_libcell,
					      int *, int *, int *, int *);
void		pnl_libpin_set_location (pnl_libpin, int, int);
char *		pnl_libpin_name (pnl_libpin);
int		pnl_libpin_set_or_check_use (pnl_libpin, nl_use);
void		pnl_libpin_set_shape (pnl_libpin, pnl_shape);
pnl_libcell	pnl_library_get_libcell (pnl_library, nl_libcell);
pnl_libpin	pnl_library_get_libpin (pnl_library, nl_libpin);
pnl_orientation	pnl_translate_orientation (pnl_orientation, pnl_orientation);
void		pnl_translate_coordinates (pnl_orientation, int, int,
					   int, int, int, int, int *, int *);
void		pnl_rectangle_get_center (pnl_rectangle, int *, int *, int *);
void		pnl_layer_geometry_get_center (pnl_geometry, int *, int *,
					       double *);
void		pnl_icell_get_pin_location (pnl_icell, nl_pin, int *, int *);
void		pnl_cell_get_pin_location (pnl_cell, nl_pin, int *, int *);
pnl_cell	pnl_design_get_cell (pnl_design, nl_cell);
pnl_icell	pnl_idesign_get_icell (pnl_idesign, nl_icell);
pnl_net		pnl_design_get_net (pnl_design, nl_net);
pnl_inet	pnl_idesign_get_inet (pnl_idesign, nl_inet);
pnl_port	pnl_design_get_port (pnl_design, nl_port);
pnl_orientation pnl_max_string_to_orientation (char *);
pnl_orientation pnl_sue_string_to_orientation (char *);
pnl_orientation pnl_any_string_to_orientation (char *);
const char *    pnl_orientation_to_max_string (pnl_orientation);
const char *    pnl_orientation_to_sue_string (pnl_orientation);
pnl_geometry	pnl_geometry_create (pnl_geometryclass, char *);
void		pnl_geometry_free (pnl_geometry);
