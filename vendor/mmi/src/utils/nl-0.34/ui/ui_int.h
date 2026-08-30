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

/* ui_getopt.c */

enum ui_arg_type { ui_null,
		   ui_boolean,
		   ui_integer,
		   ui_string,
		   ui_double,

		   ui_writable_file, ui_readable_file,
		   ui_writable_channel, ui_readable_channel,

		   ui_design, ui_port, ui_cell, ui_cell_or_port,
		   ui_cell_port_icell_or_iport, ui_net, ui_reference,
		   ui_pin, ui_refpin, ui_idesign, ui_icell, ui_inet,
		   ui_iport, ui_ipin, ui_net_or_inet, ui_pin_or_ipin,
		   ui_cell_or_icell, ui_port_or_iport, ui_bus, ui_library,
		   ui_libcell, ui_libpin, ui_net_bus, ui_cell_bus, ui_port_bus,

		   ui_current_design, ui_current_idesign,
		   
		   ui_list, ui_integer_list, ui_string_list, ui_cell_list,
		   ui_icell_list,

		   ui_tcl_object,

		   ui_attr, ui_cell_attr, ui_net_attr, ui_port_attr,
		   ui_reference_attr, ui_design_attr, ui_pin_attr,
		   ui_icell_attr, ui_inet_attr, ui_iport_attr,
		   ui_ipin_attr, ui_idesign_attr,

		   ui_pcell, ui_pport, ui_pdesign, ui_current_pdesign,
		   ui_type,

		   ui_help, ui_required, ui_optional };


struct ui_option {
  char *name;
  enum ui_arg_type type;
  void *variable;
  char *doc;
};


struct ui_argument {
  enum ui_arg_type type;
  void *variable;
  void *path_variable;
  enum ui_arg_type requirement;
  char *doc;
};


int ui_getopt (nl_context, struct ui_option *, char **, 
		      struct ui_argument *, char *, Tcl_Interp *, int,
		      Tcl_Obj *CONST []);
nl_design ui_get_current_design (nl_context);
nl_idesign ui_get_current_idesign (nl_context);
void ui_set_current_design (Tcl_Interp *, nl_context, nl_design, int);


/* ui_find.c */

char *ui_hierarchy_separator;
char *ui_bus_naming_style;
int ui_x_grid_size;
int ui_y_grid_size;
ar ui_tokenize_hierarchy_path (char *, char **, char *);
int ui_find_path (Tcl_Interp *, nl_context, char *, nl_kind, nl_kind,
		  nl_design, int, int, int, ar, ar);
int ui_find_iobject (Tcl_Interp *, char *, char *, nl_kind, nl_idesign,
			    int, int, int, ar);
int ui_find_object_path (Tcl_Interp *, nl_context, ar, nl_kind, nl_kind,
			 nl_design, ui_find_mode, ar, ar);
int ui_find_iobject_path (Tcl_Interp *, ar, nl_kind, nl_idesign,
			  ui_find_mode, ar);
nl_idesign_object ui_path_to_iobject (ar, nl_idesign);


#if 0
int ui_find_cells (Tcl_Interp *, char *, int, int, int, nl_design, ar);
int ui_find_nets (Tcl_Interp *, char *, int, int, int, nl_design, ar);
int ui_find_ports (Tcl_Interp *, char *, int, int, int, nl_design, ar);
int ui_find_references (Tcl_Interp *, char *, int, int, int, nl_design,
			ar);
int ui_find_attributes (Tcl_Interp *, char *, int, int, int, nl_design,
			ar);
int ui_find_types (Tcl_Interp *, char *, int, int, int, nl_design, ar);
#endif


/* ui_obj.c */

void ui_obj_register_type (void);
Tcl_Obj *ui_obj_create (nl_object, ar);
Tcl_ObjType *ui_obj_get_type (void);
ar ui_obj_get_nl_path (Tcl_Obj *);


/* ui_tcl.c */

void ui_tcl_register_commands (Tcl_Interp *, char *, nl_context);


/* ui_cmd_util.c */

ar ui_all_commands;
void ui_cmd_object_result (Tcl_Interp *, nl_object, ar);
void ui_cmd_append_object_list (Tcl_Interp *, Tcl_Obj *, nl_object, ar);
void ui_cmd_object_list_result (Tcl_Interp *, ar, ar);
nl_walk_status ui_cmd_append_result_walker (nl_object, void *);
nl_idesign ui_get_idesign_for_path (ar, nl_context);
void ui_cmd_register (Tcl_Interp *, char *, char *, Tcl_ObjCmdProc *,
		      nl_context);
void ui_cmd_register_commands (Tcl_Interp *, char *, nl_context);
void ui_cmd_sort_commands (void);


/* ui_procedure.c */

extern int ui_procedure_create (Tcl_Interp *, Tcl_Obj *, Tcl_Obj *,
				Tcl_Obj **);


/* ui_walk.c */

enum ui_walk_status { ui_walk_continue, ui_walk_stop, ui_walk_skip };
typedef enum ui_walk_status (*ui_walk_net_fun) (nl_net, ar);
typedef enum ui_walk_status (*ui_walk_pin_fun) (nl_pin, ar);
typedef enum ui_walk_status (*ui_walk_cell_fun) (nl_cell, ar);

void ui_walk_connected_nets (nl_net, int, int, int, int, int, ar,
			     ui_walk_net_fun);
void ui_walk_connected_pins (nl_net, int, int, int, int, int, ar,
			     ui_walk_pin_fun);


void ui_cmd_register_basic_commands (Tcl_Interp *, char *, nl_context);
void ui_cmd_register_find_commands (Tcl_Interp *, char *, nl_context);
void ui_cmd_register_io_commands (Tcl_Interp *, char *, nl_context);
void ui_cmd_register_misc_commands (Tcl_Interp *, char *, nl_context);
void ui_cmd_register_physical_commands (Tcl_Interp *, char *, nl_context);
void ui_cmd_register_synthesis_commands (Tcl_Interp *, char *, nl_context);
void ui_cmd_register_pat_commands (Tcl_Interp *, char *, nl_context);
void ui_cmd_register_gui_commands (Tcl_Interp *, char *, nl_context);

/* ui_app.c */

extern mem_group ui_default_mem_group;
