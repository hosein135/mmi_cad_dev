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

#ifndef sue_h
#define sue_h

#include <util.h>

class BINDING_CHAIN;

class SUE {
    public:

		SUE();
		
	// parameters for conversion, from options
	static BOOLEAN	SHOW_RIPPERS;
	static BOOLEAN	LITERAL_NETNAMES;
	static char *	cellname_prefix;
	static char *	output_dir_path;
	static BOOLEAN	CONTINUE_ON_TRANSLATE_ERRORS;
	static BOOLEAN	SUPPRESS_PROGRESS_MESSAGES;
	static BOOLEAN  MAKE_NETLISTS;
	static BOOLEAN  SKIP_BAD_PORTS;
	static BOOLEAN  ROUND_TO_GRID_LINES;
	static ListOfCHARSTAR *	IGNORE_PROPERTY_LIST;
	static BINDING_CHAIN *	USE_GLOBALS;
	static BOOLEAN	CADENCE_PROPERTY_VALUES;
	static ListOfCHARSTAR *	ADD_VERILOG_PROPERTY_BY_LIBRARY;
	static BOOLEAN CONVERT_CADENCE_NETNAMES;
	static BOOLEAN ADD_TITLE_BAR;
	static char *  SUPPRESS_INSTANCE_NAME_PREFIX;
	static BOOLEAN UNIQUIFY_DUPLICATE_NAMES;
	static BOOLEAN SCALE_COORDS;
	static int		scale_coords_factor;
	static ListOfCHARSTAR	*ignore_cellnames_list;
	static BOOLEAN TANNER_RENAME_BUG;
	static BOOLEAN ORCAD_CELLNAME_BUG;

	// how much to space properties on icon display
	static int PROPERTY_STR_YINCR;


	rc_t	translate(class EDIF_EXPR *);
	char *	convert_to_nice_filename(char *);

	rc_t	translate_cell(class CELL_EXPR *);

	rc_t	write_icon_proc(VIEW_EXPR *, char *cell_name);
	rc_t	write_schematic_proc(VIEW_EXPR *, char *cell_name);

	// rc_t	write_netlist(VIEW_EXPR *, char *cell_name);

	rc_t	convert_to_iconlines(ANNOTATE_EXPR *);
	rc_t	convert_to_iconlines(ARC_EXPR *);
	rc_t	convert_to_iconlines(CIRCLE_EXPR *);
	rc_t	convert_to_iconlines(FIGURE_EXPR *);
	rc_t	convert_to_iconlines(OPENSHAPE_EXPR *);
	rc_t	convert_to_iconlines(PATH_EXPR *);
	rc_t	convert_to_iconlines(POLYGON_EXPR *);
	rc_t	convert_to_iconlines(RECTANGLE_EXPR *);

	rc_t	convert_to_schematiclines(ANNOTATE_EXPR *);
	rc_t	convert_to_schematiclines(INSTANCE_EXPR *);

	rc_t	convert_to_schematiclines(PORTIMPLEMENTATION_EXPR *);
	rc_t	make_portimp_pt_chain(PORTIMPLEMENTATION_EXPR *);
	rc_t	align_portimplementation(class ChainOfPORTIMP_PT *, class WIRESEG *);

	rc_t	convert_to_schematiclines(NET_EXPR *);
	class ListOfWIRESEG *	convert_to_wireseg_list(NET_EXPR *);
	rc_t		identify_rippers(ListOfWIRESEG *);
	class ListOfListOfWIRESEG *segregate_connected_wiresegs(
			    ListOfWIRESEG *);
	rc_t		emit_netnames(ListOfListOfWIRESEG *, 
			    char *name, BOOLEAN name_is_simple);


	rc_t	convert_to_args(DISPLAY_EXPR *);
	rc_t	convert_to_args(TRANSFORM_EXPR *);
	rc_t	convert_to_arg(JUSTIFY);
	rc_t	convert_to_arg(ORIENTATION);

	rc_t	convert_to_arg(ORIGIN_EXPR *);
	rc_t	convert_to_origin_arg(int xval, int yval);
	void	round_to_grid(int *);

	rc_t	convert_to_textline(NAMEDEF *);
	rc_t	convert_to_textline(NAME_EXPR *);
	rc_t	convert_to_textline(STRINGDISPLAY_EXPR *);

	// niceify port name string
	char *	convert_portname(PORT_EXPR *);

	// record ripper instances, so we can not
	// short the nets together, confusing Sue
	rc_t	record_ripper_instance(INSTANCE_EXPR *);
	ListOfPT_EXPR *	ripper_pt_list;

	// ...don't do this...
	// convert float to fixed point ... "0.238e-4" becomes "23.8"
	// (help dealing with transistor sizes)
	// char *	convert_float_to_fixed(char *str);

	rc_t	convert_cadence_property(char *arg_prop_str, char *return_prop_name, char *return_prop_value);

	// remember where the ports are, so we can not
	// put a namenet there, offending Lee
	class ChainOfPORTIMP_PT * portimp_pt_chain;

	// should we be adding verilog properties while
	// converting the current library?  Support
	// for option.
	BOOLEAN	add_verilog_property;

	// to avoid extra parms in methods  
	FILE *	out;

	int	buscombine_netnumber;
	static char *	buscombine_namestr;
	int	minx;
	int	maxy;
	ListOfNETNAME *	defered_netname_list;
	rc_t	handle_defered_netnames();

	ListOfCHARSTAR *name_net_nets;

	// debugging/decluttering aid
	static void	exxit(int, char *);

};

class SUE_FILE {
    public:

		SUE_FILE(const char *name);

	FILE *	open();
	rc_t	close();

	char *	name;
	FILE *	file;

};

class NETLIST_FILE {
    public:

		NETLIST_FILE(const char *name);

	FILE *	open();
	rc_t	close();

	char *	name;
	FILE *	file;

};

class WIRESEG {
    public:
		WIRESEG(int argx1, int argy1, int argx2, int argy2)
		    : x1(argx1), y1(argy1), x2(argx2), y2(argy2),
		    pt1_is_ripper(false), pt2_is_ripper(false)
		{
		}


	int	x1;
	int	y1;
	int	x2;
	int	y2;

	BOOLEAN		pt1_is_ripper;
	BOOLEAN		pt2_is_ripper;
};

class ListOfWIRESEG {
    public:
		ListOfWIRESEG(WIRESEG *arg_wireseg, ListOfWIRESEG *arg_next)
		    : wireseg(arg_wireseg), next(arg_next)
		{
		}

		~ListOfWIRESEG()
		{
			if (next) delete next;
		}

	WIRESEG		*wireseg;
	ListOfWIRESEG	*next;

};

class ListOfListOfWIRESEG {
    public:
		ListOfListOfWIRESEG(ListOfWIRESEG *arg_wireseg_list, ListOfListOfWIRESEG *arg_next)
		    : wireseg_list(arg_wireseg_list), next(arg_next)
		{
		}

		~ListOfListOfWIRESEG()
		{
			if (next) delete next;
		}

	ListOfWIRESEG		*wireseg_list;
	ListOfListOfWIRESEG	*next;
};

class ChainOfPORTIMP_PT {
    public:
		ChainOfPORTIMP_PT(char *arg_name, PT_EXPR *arg_pt, 
		    PORTIMPLEMENTATION_EXPR *arg_impl,
		    ChainOfPORTIMP_PT *arg_next)
		    : portname(arg_name), xvalue(arg_pt->xvalue),
		    yvalue(arg_pt->yvalue), 
		    portimplementation(arg_impl),
		    next(arg_next)
		{
		}

	char *	portname;
	int	xvalue;
	int	yvalue;
	PORTIMPLEMENTATION_EXPR *portimplementation;

	ChainOfPORTIMP_PT *	next;
};
		
class BINDING_CHAIN {
    public:
		BINDING_CHAIN(char *arg_str1, char *arg_str2, char *arg_str3, BINDING_CHAIN *arg_next)
		    : str1(arg_str1), str2(arg_str2), str3(arg_str3), next(arg_next)
		{
		}
	
	char *		str1;
	char *		str2;
	char *		str3;
	BINDING_CHAIN *	next;
};



#endif

