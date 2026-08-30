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

#include <sys/stat.h>	// for statinfo
#include <math.h>	// sqrt, atan
#include <stdlib.h>	// for malloc

#include <sue.h>

BOOLEAN	SUE::SHOW_RIPPERS;
BOOLEAN	SUE::LITERAL_NETNAMES;
char *	SUE::cellname_prefix;
char *	SUE::output_dir_path;
BOOLEAN SUE::CONTINUE_ON_TRANSLATE_ERRORS;
BOOLEAN SUE::SUPPRESS_PROGRESS_MESSAGES;
BOOLEAN SUE::MAKE_NETLISTS;
BOOLEAN SUE::SKIP_BAD_PORTS;
BOOLEAN SUE::ROUND_TO_GRID_LINES;
ListOfCHARSTAR *SUE::IGNORE_PROPERTY_LIST;
BINDING_CHAIN *	SUE::USE_GLOBALS;
BOOLEAN SUE::CADENCE_PROPERTY_VALUES;
ListOfCHARSTAR *SUE::ADD_VERILOG_PROPERTY_BY_LIBRARY;
BOOLEAN SUE::CONVERT_CADENCE_NETNAMES;
BOOLEAN SUE::ADD_TITLE_BAR;
char *  SUE::SUPPRESS_INSTANCE_NAME_PREFIX;
BOOLEAN SUE::UNIQUIFY_DUPLICATE_NAMES;
BOOLEAN SUE::SCALE_COORDS;
int		SUE::scale_coords_factor;
ListOfCHARSTAR	*SUE::ignore_cellnames_list;
BOOLEAN SUE::TANNER_RENAME_BUG;

BOOLEAN SUE::ORCAD_CELLNAME_BUG;
FILE *rename_info_file = NULL;

// how much to space properties on icon display
int SUE::PROPERTY_STR_YINCR;

SUE::SUE()
    :  buscombine_netnumber(0)
{
}

char *SUE::buscombine_namestr = "buscombine";

rc_t
SUE::translate(EDIF_EXPR *arg_edif_expr)
{
	if (ORCAD_CELLNAME_BUG) {
		rename_info_file = fopen("rename_info", "w");
		if (rename_info_file == NULL) {
			exxit(43, "open rename info file failed");
		}
	}


	const char *edif_name = arg_edif_expr->namedef->get_stringvalue();
	if (!SUPPRESS_PROGRESS_MESSAGES)
		printf("translate edif expression %s\n", edif_name);

	ListOfLIBRARY_EXPR *tlibrary_list = arg_edif_expr->library_list;
	while (tlibrary_list != NULL) {
		LIBRARY_EXPR *library = tlibrary_list->expr;

		add_verilog_property = false;

		const char *library_name = library->namedef->get_stringvalue();
		if (!SUPPRESS_PROGRESS_MESSAGES)
			printf("translate library %s\n", library_name);
		if (ADD_VERILOG_PROPERTY_BY_LIBRARY) {
			ListOfCHARSTAR *tliblist = ADD_VERILOG_PROPERTY_BY_LIBRARY;
			while (tliblist != NULL) {
				if (strcmp(tliblist->str, library_name) == 0) {
					add_verilog_property = true;
					if (!SUPPRESS_PROGRESS_MESSAGES)
						printf("add verilog properties for library %s\n", library_name);
					break;
				}
				tliblist = tliblist->next;
			}
		}

		ListOfCELL_EXPR *tcell_list = library->cell_list;
		while (tcell_list != NULL) {
			CELL_EXPR *cell = tcell_list->expr;

			const char *cellname = cell->namedef->get_stringvalue();
			if (!SUPPRESS_PROGRESS_MESSAGES)
				printf("translate cell %s\n", cellname);
			rc_t rc = translate_cell(cell);
			if (rc != RC_NOMINAL)	return rc;

			tcell_list = tcell_list->next;
		}

		tlibrary_list = tlibrary_list->next;
	}
	delete edif_name;
	return RC_NOMINAL;
}

char *
SUE::convert_to_nice_filename(char *cellname)
{
	char *new_cellname = new char[strlen(cellname) + 1];
	char *p = cellname;
	char *r = new_cellname;
	BOOLEAN modified = false;
	while (*p != '\0') {
		switch (*p) {
		    case ' ':
			*r++ = '_';
			p++;
			modified = true;
			break;

		    case '/':
			*r++ = '-';
			p++;
			modified = true;
			break;

		    default:
			*r++ = *p++;
			break;
		}
	}

	if (modified == true) {
		printf("converted cellname \"%s\" to nice filename \"%s\"\n", 
		    cellname, new_cellname);
		return new_cellname;
	} else {
		delete new_cellname;
		return cellname;
	}
}



rc_t
SUE::translate_cell(CELL_EXPR *arg_cell)
{
	char *unprefixed_cellname = arg_cell->namedef->get_stringvalue();
	unprefixed_cellname = convert_to_nice_filename((char *)unprefixed_cellname);
	name_net_nets = NULL;

	// ...debug hook...
	// char *my_favorite_cell = "nand3";
	// if (strcmp(unprefixed_cellname, my_favorite_cell) == 0) {
	// 	printf("my favorite cell %s\n", my_favorite_cell);
	// }

	if (ignore_cellnames_list != NULL) {
		ListOfCHARSTAR *cellnameslist = ignore_cellnames_list;
		while (cellnameslist != NULL) {
			char *cellname = cellnameslist->str;
			cellnameslist = cellnameslist->next;

			if (strcmp(unprefixed_cellname, cellname) == 0) {
				printf("suppress creating sue file for %s\n", unprefixed_cellname);
				return RC_NOMINAL;
			}
		}
	}				


	char *cellname = (char *)malloc(strlen(unprefixed_cellname) +
	    strlen(cellname_prefix) + 3);
	sprintf(cellname, "%s%s", cellname_prefix, unprefixed_cellname);
	// delete unprefixed_cellname;

	SUE_FILE *sue_file = new SUE_FILE(cellname);
	this->out = sue_file->open();
	if (out == NULL) {
		return RC_FAILED;
	}

	// find a SCHEMATIC or GRAPHIC view...
	VIEW_EXPR *view = NULL;
	ListOfVIEW_EXPR *tview_list = arg_cell->view_list;
	while (tview_list != NULL) {
		view = tview_list->expr;

		switch (view->viewtype) {
		    case SCHEMATIC:
			write_icon_proc(view, cellname);
			if (view->contents != NULL) {

				// schematics for circuit elements like
				// N and P have no contents

				write_schematic_proc(view, cellname);
		
				// if (MAKE_NETLISTS) {
				//	if (!SUPPRESS_PROGRESS_MESSAGES)
				//		printf("write netlist for cell %s\n", cellname);		
				//	write_netlist(view, cellname);
				// }
			} else {
				// printf("schematic view with no contents for cell %s\n", cellname);
			}
			break;

		    case GRAPHIC:
			printf ("graphic view for cell %s\n", cellname);
			write_icon_proc(view, cellname);
			break;

		    default:
			break;
		}
		tview_list = tview_list->next;
	}
	sue_file->close();
	// delete cellname;
	return RC_NOMINAL;
}


rc_t
SUE::write_icon_proc(VIEW_EXPR *view, char *cellname) {

char *my_favorite_cell = "inv";
if (strcmp(cellname, my_favorite_cell) == 0) {
	printf("my favorite cell %s\n", my_favorite_cell);
}
	rc_t rc;

	// put icon header in sue file	
	fprintf(out,"proc ICON_%s args {\n",cellname);
	fprintf(out,"  icon_setup $args {{origin {0 0}} {orient R0} {name {}}");

	//////////////////////////////////////////////

	// the Tanner guys put input arguements to cells (eg, transistor sizes)
	// as properties on the view->interface, which certainly seems like a 
	// reasonable thing to be doing; Cadence guys put them on the view
	// itself, which actually seems *less* reasonable, but they got here
	// first.  So this cleverness is designed to avoid a lot of code
	// duplication, yet cover both cases.

	if (view->property_list == NULL &&
	    view->interface != NULL	&&
	    view->interface->property_list != NULL) {
		view->property_list = view->interface->property_list;
	}

	//////////////////////////////////////////////

	// view properties turn into icon_setup arg defaults...
	ListOfPROPERTY_EXPR *tproperty_list = view->property_list;
	ListOfCHARSTAR *cadence_properties = NULL;
	ListOfCHARSTAR *cadence_property_defaults = NULL;
	while (tproperty_list != NULL) {
		PROPERTY_EXPR *property = tproperty_list->expr;

		tproperty_list = tproperty_list->next;
		if (property->is_ignorable)	continue;

		char *prop_name_str = property->namedef->get_stringvalue();
		char *prop_value_str = property->get_value_str();

		if (CADENCE_PROPERTY_VALUES			&&
		    strpbrk(prop_value_str, "[]") != NULL	) {

			char conv_prop_name[100];
			char conv_default_value[100];

			char *p = prop_value_str;
			char *endp = prop_value_str + strlen(prop_value_str);
			while (p < endp) {
				if (*p != '[') {
					p++;
					continue;
				}

				// got one
				rc = convert_cadence_property(p, conv_prop_name, conv_default_value);
				if (rc != RC_CONVERTED) {
					printf("ERROR converting cadence property \"%s\"\n", property->get_value_str());
					break;
				}
				while (p < endp && *p != ']')	p++;
				if (p == endp) { 
					printf("ERROR 2 converting cadence property \"%s\"\n", property->get_value_str());
					break;
				}
				
				// have we got this one already?
				ListOfCHARSTAR *csl = cadence_properties;
				while (csl != NULL) {
					if (strcmp(csl->str, conv_prop_name) == 0) break;
					csl = csl->next;
				}
				if (csl != NULL) continue;

				// nope, write arg & add to list
				if (strcmp(prop_value_str, "{}") == 0) {	// ...don't double up curleys
					fprintf(out, " {%s {}}", prop_name_str);
				}
				else {
					fprintf(out, " {%s {%s}}", conv_prop_name, conv_default_value);
				}
				cadence_properties = new ListOfCHARSTAR(strdup(conv_prop_name), cadence_properties);			
				cadence_property_defaults = new ListOfCHARSTAR(strdup(conv_default_value), cadence_property_defaults);			
			}
		}
		else {
			if (strpbrk(prop_value_str, "[]") != NULL) {
				fprintf(out, " {%s %s}", prop_name_str, "string-with-unknown-replacement-variables");
			}
			else if (strcmp(prop_value_str, "{}") == 0) {	// ...don't double up curleys
				fprintf(out, " {%s {}}", prop_name_str);
			}
			else {
				fprintf(out, " {%s {%s}}", prop_name_str, prop_value_str);
			}
		}

		// delete prop_name_str;
	}

	// close curley on icon_setup arg defaults, 
	fprintf(out, "}\n");

	//////////////////////////////////////////////

	// properties show up again
	fprintf(out, "  icon_property -origin {-60 50} -type user -name name\n");
	int yvalue = 100;

	if (CADENCE_PROPERTY_VALUES && cadence_properties != NULL) {
		// ...also need standalone property for this thingy
		ListOfCHARSTAR *csl = cadence_properties;
		ListOfCHARSTAR *csl2 = cadence_property_defaults;
		while (csl != NULL) {
			char *prop_name = csl->str;
			char *default_value = csl2->str;
			csl = csl->next;
			csl2 = csl2->next;

			fprintf(out, "  icon_property -type user"
			    " -origin {-60 %d} -name %s -default {%s}\n",
			    yvalue,  prop_name, default_value);
			yvalue += PROPERTY_STR_YINCR;
		}
	}

	tproperty_list = view->property_list;
	while (tproperty_list != NULL) {
		PROPERTY_EXPR *property = tproperty_list->expr;

		tproperty_list = tproperty_list->next;
		if (property->is_ignorable)	continue;

		yvalue += PROPERTY_STR_YINCR;

		const char *prop_name_str = 
		    property->namedef->get_stringvalue();
		char *prop_value_str = property->get_value_str();

		if (CADENCE_PROPERTY_VALUES			&&
		    strpbrk(prop_value_str, "[]") != NULL	) {

			char prop_name[100];
			char default_value[100];

			char *p = prop_value_str;
			char *endp = prop_value_str + strlen(prop_value_str);
			while (p < endp) {
				if (*p != '[') {
					p++;
					continue;
				}

				// got one
				rc = convert_cadence_property(p, prop_name, default_value);
				if (rc != RC_CONVERTED) {
					// we already parsed this string once, so it BETTER be OK now, but heck....
					printf("ERROR 3 converting cadence property \"%s\"\n", property->get_value_str());
					break;
				}
				char *r = p; 
				while (r < endp && *r != ']')	r++;
				if (r == endp) { 
					printf("ERROR 4 converting cadence property \"%s\"\n", property->get_value_str());
					break;
				}
				r++;
				
				// replace the cadence prop with converted in the prop value str
				sprintf(p, "{$%s}%s", prop_name, r);
	


			}
		}

		if (strncmp(prop_value_str, "-type fixed", 11) == 0) {

			fprintf(out, "  icon_property -origin {-60 %d} %s\n",
			    yvalue, prop_value_str);

		} else if (strpbrk(prop_value_str, "[]") == NULL) {
			fprintf(out, "  icon_property -type user"
			    " -origin {-60 %d} -name %s -default {%s}\n",
			    yvalue,  prop_name_str, prop_value_str);
		}

		yvalue += PROPERTY_STR_YINCR;
	}


	//////////////////////////////////////////////

	// sometimes there isn't any view->symbol,
	// in which case I don't know what else we can do....

	SYMBOL_EXPR *symbol = view->interface->symbol;
	if (symbol == NULL) {
		// close curley on proc ICON_xxx
		fprintf(out, "}\n\n");
		return RC_NOMINAL;
	}

	//////////////////////////////////////////////

	// now look for the icon picture, which is the set
	// of figure exprs within the symbol

	ListOfFIGURE_EXPR *tfigure_list = symbol->figure_list;
	while (tfigure_list != NULL) {
		FIGURE_EXPR *figure = tfigure_list->expr;
		rc_t  rc = convert_to_iconlines(figure);
		tfigure_list = tfigure_list->next;
	}
	
	//////////////////////////////////////////////

	// the interface connections are symbol::portimpelementations
	ListOfPORTIMPLEMENTATION_EXPR *tportimplementation_list =
	    symbol->portimplementation_list;
	while (tportimplementation_list != NULL) {
		PORTIMPLEMENTATION_EXPR *portimplementation = 
		    tportimplementation_list->expr;
	
		PORT_EXPR *port = NULL;
		portimplementation->namedef->get_where_defined(&port);
		char *portnamestr = convert_portname(port);

		char *direction_str = NULL;
		char *orientation_str = "";
		// BUG... this code is duplicated below
		switch (port->direction) {
		    case INPUT:		
			direction_str = "input";
			orientation_str = "-orient RY"; 
			break;

		    case OUTPUT:
			direction_str = "output";
			orientation_str = "-orient R0";
			break;

		    case INOUT:	
			direction_str = "inout";
			orientation_str = "-orient RY"; 
			break;

		    case DIRECTION_NOT_SPECIFIED: 
			// BUG... is this a reasonable default?  Not specified in 
			// Db.edf::lib primitives::cell ripper_3, for one...  
			printf("port %s...default direction to inout\n", portnamestr);
		        direction_str = "inout"; 
			orientation_str = "-orient R0"; 
			break;
			// exxit(2, "");
		}

		ListOfUSERDATA_EXPR *userdata_list = portimplementation->userdata_list;
		if (userdata_list != NULL) {
			// .... orientation information ....
			USERDATA_EXPR *userdata = userdata_list->expr;

			if (userdata_list->next != NULL ||
			    strcmp(userdata->identifier, "orientation") != 0) {
				exxit(20001, userdata->identifier);
			}
			
			switch (userdata->orientation) {
			case R0:	orientation_str = "-orient R0";		break;
			    case R90:	orientation_str = "-orient R270";	break;
			    case R270:	orientation_str = "-orient R90";	break;
			    case MYR90:	orientation_str = "-orient R90Y";	break;
			    case MXR90:	orientation_str = "-orient R90X";	break;
			    case R180:	orientation_str = "-orient RXY";	break;
			    case MY:	orientation_str = "-orient RX";		break;
			    case MX:	orientation_str = "-orient RY";		break;
			}
		}

		// there are a pretty good number of syntactic options
		// in here; I assume that the figure for a port will be
		// a single dot that gives the connectlocation.
		// If that isn't the situation, yell for help...
	
		CONNECTLOCATION_EXPR *connectlocation = 
		    portimplementation->connectlocation;
		if (connectlocation == NULL) 	exxit(3, "");
	
		ListOfFIGURE_EXPR *tfigure_list = connectlocation->figure_list;
		if (tfigure_list == NULL |
		    tfigure_list->next != NULL) exxit(4, "");

		FIGURE_EXPR *figure = tfigure_list->expr;
		if (figure->path_list != NULL |
		    figure->polygon_list != NULL) exxit(5, "");

		ListOfDOT_EXPR *tdot_list = figure->dot_list;
		if (tdot_list == NULL |
		    tdot_list->next != NULL) exxit(6, "");

		DOT_EXPR *dot = tdot_list->expr;
		PT_EXPR *pt = dot->pt;

		if (ROUND_TO_GRID_LINES) {
			round_to_grid(&pt->xvalue);
			round_to_grid(&pt->yvalue);
		}
		
		if (pt->xvalue % 10 != 0   ||
		    pt->yvalue % 10 != 0      ) {
			printf("WARNING: icon_term \"%s\" is off grid at {%d %d}\n",
			    portnamestr, pt->xvalue, pt->yvalue);
		}
	
		fprintf(out, "  icon_term -type %s -name {%s} %s  -origin {%d %d}\n",
		    direction_str, portnamestr, orientation_str, pt->xvalue, pt->yvalue);
	
		// delete portnamestr;
		tportimplementation_list = tportimplementation_list->next;
	}

	//////////////////////////////////////////////

	// annotate commentGraphics turn into 
	// icon_properties of the -label kind
	// ...sue objects if there is an "-orient" paramteter

	ListOfCOMMENTGRAPHICS_EXPR *tcommentgraphics_list =
	    symbol->commentgraphics_list;
	while (tcommentgraphics_list != NULL) {
		COMMENTGRAPHICS_EXPR *commentgraphics = 
		    tcommentgraphics_list->expr;

		ListOfANNOTATE_EXPR *tannotate_list =		
		    commentgraphics->annotate_list;
		while (tannotate_list != NULL) {
			ANNOTATE_EXPR *annotate = tannotate_list->expr;

			convert_to_iconlines(annotate);

			tannotate_list = tannotate_list->next;
		}

		tcommentgraphics_list = tcommentgraphics_list->next;
	} 
	
	//////////////////////////////////////////////

	// if specified, write a verilog property
	if (add_verilog_property) {
		fprintf(out, 
		    "  icon_property -origin {-60 %d} -type auto -name verilog -text {%s [unique_name \"\" $name %s]\n(",
		    yvalue, cellname, cellname);
		yvalue += PROPERTY_STR_YINCR;
				    
		ListOfPORTIMPLEMENTATION_EXPR *tportimplementation_list =
		    symbol->portimplementation_list;
		while (tportimplementation_list != NULL) {
			PORTIMPLEMENTATION_EXPR *portimplementation = 
			    tportimplementation_list->expr;
	
			PORT_EXPR *port = NULL;
			portimplementation->namedef->get_where_defined(&port);
			char *portnamestr = convert_portname(port);

			fprintf(out, ".%s($%s)", portnamestr, portnamestr);

			// delete portnamestr;
			tportimplementation_list = tportimplementation_list->next;
		
			if (tportimplementation_list != NULL) {
				fprintf(out, ",");
			}
		}

		fprintf(out, ")\\;}\n");
	}

	//////////////////////////////////////////////

	// close curley on proc ICON_xxx
	fprintf(out, "}\n\n");
}

rc_t
SUE::write_schematic_proc(VIEW_EXPR *view, char *cellname)
{

char *my_favorite_cell = "eq_pathtr1";
if (strcmp(cellname, my_favorite_cell) == 0) {
	printf("my favorite cell %s\n", my_favorite_cell);
}

	fprintf(out, "proc SCHEMATIC_%s {} {\n", cellname);

	CONTENTS_EXPR *contents = view->contents;  // already checked for NULL

	ListOfPAGE_EXPR *tpage_list = contents->page_list;
	while (tpage_list != NULL) {
		PAGE_EXPR *page = tpage_list->expr;		
		ripper_pt_list = NULL;
		portimp_pt_chain = NULL;
	
		// ...instances
		ListOfINSTANCE_EXPR *tinstance_list = page->instance_list;
		while (tinstance_list != NULL) {
			INSTANCE_EXPR *instance = tinstance_list->expr;

			convert_to_schematiclines(instance);

			tinstance_list = tinstance_list->next;
		}

		// in order to lay down extra buscombiners, we keep track of the
		// fartherest-south connection point (most positive yvalue)
		SUE::maxy = -100000;		// large northwards offset
		SUE::minx = 100000;		// large eastwards offset

		// ...make index of port points
		// (so we can find net segments that connect to ports
		// efficiently...when we find one, we choose an orientation
		// for the port symbol)
		ListOfPORTIMPLEMENTATION_EXPR *tportimplementation_list = page->portimplementation_list;
		while (tportimplementation_list != NULL) {
			PORTIMPLEMENTATION_EXPR *portimplementation = 
			    tportimplementation_list->expr;
			
			make_portimp_pt_chain(portimplementation);

			tportimplementation_list = 
			    tportimplementation_list->next;
		}

	
	
		// ...nets
		defered_netname_list = NULL;	// should be already
		ListOfNET_EXPR *tnet_list = page->net_list;
		while (tnet_list != NULL) {
			NET_EXPR *net = tnet_list->expr;
			
			convert_to_schematiclines(net);

			tnet_list = tnet_list->next;
		}

		// ...port implementations
		tportimplementation_list = page->portimplementation_list;
		while (tportimplementation_list != NULL) {
			PORTIMPLEMENTATION_EXPR *portimplementation = 
			    tportimplementation_list->expr;
			
			convert_to_schematiclines(portimplementation);

			tportimplementation_list = 
			    tportimplementation_list->next;
		}

//		// ... tanner bug
//		if (SUE::TANNER_PORTIMPLEMENTATION_BUG == true	&&
//		    page->portimplemenation_list == NULL) {
//			
//			make_portimplementations_for_tanner_bug();
//		}
		
		ListOfCOMMENTGRAPHICS_EXPR *tcommentgraphics_list =
		    page->commentgraphics_list;
			while (tcommentgraphics_list != NULL) {
			COMMENTGRAPHICS_EXPR *commentgraphics = 
			    tcommentgraphics_list->expr;

			ListOfANNOTATE_EXPR *tannotate_list =		
			    commentgraphics->annotate_list;
			while (tannotate_list != NULL) {
				ANNOTATE_EXPR *annotate = tannotate_list->expr;

				convert_to_schematiclines(annotate);

				tannotate_list = tannotate_list->next;
			}

			tcommentgraphics_list = tcommentgraphics_list->next;
		} 

		// ...generated bus combiners

// ... do we still need to do this? Lee has made changes to handle
// net bundles in a more general way, so maybe not.  In at least 
// some cases we are generating buscombines we don't need.... so
// let's be a lazyman and shut it off & see what kind of trouble 
// we get into...
//		handle_defered_netnames();

		// if (ripper_pt_list)	delete ripper_pt_list;


		// ...title bar
		if (ADD_TITLE_BAR == true) {
			fprintf(out, "  make title_bar -origin {%d %d}\n", minx, maxy + 140);
		}

		tpage_list = tpage_list->next;
	}

	// close curley on proc SCHEMATIC_xxx
	fprintf(out, "}\n");

	return RC_NOMINAL;
}


rc_t
SUE::convert_to_iconlines(ANNOTATE_EXPR *annotate)
{
	STRINGDISPLAY_EXPR *stringdisplay = annotate->stringdisplay;
	if (stringdisplay == NULL) return RC_NOMINAL;

	///////////////////////////////
	  /* JDJ 990924:
	     For now, don't clutter the icons with the "cds" strings. */
	///////////////////////////////	
	if (strncmp("\"cds", stringdisplay->string, 4) == 0) return RC_NOMINAL;

	if (SUE::CADENCE_PROPERTY_VALUES == true		&&
	    strpbrk(stringdisplay->string, "[@%]") != NULL	) {

		// here's a style of variable substitution from Intel Cadence...
		char *newstr = new char[strlen(stringdisplay->string) + 10];
		char *p = stringdisplay->string;
		char *r = newstr;
		while (*p != '\0') {
			switch (*p) {

			    case '[':
				if (*(++p) != '@') break;
				*r++ = '$';
				p++;
				while (*p != ']') {
					if (*p == '\0') break;
					*r++ = *p++;
				}
				p++;
				continue;
		
			    default:
				*r++ = *p++;
				continue;
			}

			printf("unusable substitution in icon string %s\n", 
			    stringdisplay->string);
			return RC_NOMINAL;
		}
		*r = '\0';
		// delete stringdisplay->string;
		stringdisplay->string = newstr;
	}

	ListOfDISPLAY_EXPR *tdisplay_list = stringdisplay->display_list;
	while (tdisplay_list != NULL) {
		DISPLAY_EXPR *display = tdisplay_list->expr;

		char *rotate_str = "";
		if (display->orientation != R0) {
			rotate_str = " -rotate 1";
			display->orientation = R0;
		}

		fprintf(out, "  icon_property ");
		convert_to_args(display);

		char *p = stringdisplay->string;

		fprintf(out, "%s -label {%s}\n", rotate_str, p);

		tdisplay_list = tdisplay_list->next;
	}
}



rc_t  
SUE::convert_to_iconlines(FIGURE_EXPR *figure)
{
	// possibly this turns into a more general proc,
	// but for now its "just a bunch of inline code"
	// ...so the figure has a list of each of various
	// kinds of elements (a list of "dots", a list of
	// "circles", ...and we just step through each list,
	// drawing out each member dot, circle, ...

	if (figure->circle_list != NULL) {
		ListOfCIRCLE_EXPR *tcircle_list = figure->circle_list;
		while (tcircle_list != NULL) {
			CIRCLE_EXPR *circle = tcircle_list->expr;
			convert_to_iconlines(circle);
		
			tcircle_list = tcircle_list->next;
		}
	}
	
	if (figure->dot_list != NULL) {
		printf("converting figure::dot_list not implemented\n");
		exxit(14, "");
	}
	
	if (figure->openshape_list != NULL) {
		ListOfOPENSHAPE_EXPR *topenshape_list = figure->openshape_list;
		while (topenshape_list != NULL) {
			OPENSHAPE_EXPR *openshape = topenshape_list->expr;
			convert_to_iconlines(openshape);
		
			topenshape_list = topenshape_list->next;
		}
	}
		
	if (figure->path_list != NULL) {
		ListOfPATH_EXPR *tpath_list = figure->path_list;
		while (tpath_list != NULL) {
			PATH_EXPR *path = tpath_list->expr;
			convert_to_iconlines(path);
		
			tpath_list = tpath_list->next;
		}
	}
	
	if (figure->polygon_list != NULL) {
		ListOfPOLYGON_EXPR *tpolygon_list = figure->polygon_list;
		while (tpolygon_list != NULL) {
			POLYGON_EXPR *polygon = tpolygon_list->expr;
			convert_to_iconlines(polygon);
		
			tpolygon_list = tpolygon_list->next;
		}
	}
		
	if (figure->rectangle_list != NULL) {
  		ListOfRECTANGLE_EXPR *trectangle_list = figure->rectangle_list;
		while (trectangle_list != NULL) {
			RECTANGLE_EXPR *rectangle = trectangle_list->expr;
			convert_to_iconlines(rectangle);
		
			trectangle_list = trectangle_list->next;
		}
	}
	
	return RC_NOMINAL;
}

rc_t
SUE::convert_to_iconlines(CIRCLE_EXPR *circle)
{
  	int x1 = circle->pt1->xvalue;
	int x2 = circle->pt2->xvalue;
  	int y1 = circle->pt1->yvalue;
	int y2 = circle->pt2->yvalue;

	// this is the circle algorithm from "ep"
	// it doesn't make sense to me...  
  
  	int new_y1 = y1 + (x1 - x2) / 2;
	int new_y2 = y2 + (x2 - x1) / 2;

	fprintf(out, "  icon_arc %d %d %d %d -start 91 -extent 359\n",
	    x1, new_y1, x2, new_y2);
	    
	return RC_NOMINAL;
}

rc_t
SUE::convert_to_iconlines(OPENSHAPE_EXPR *openshape)
{

	CURVE_EXPR *curve = openshape->curve;
	CURVE_ELEMENT *element = curve->element_list;
	if (element == NULL) return RC_NOMINAL;

	// the curve is a bunch of connected line segments

	int lastx = 0;
	int lasty = 0;
	
	if (element->pt != NULL) {
		lastx = element->pt->xvalue;		
		lasty = element->pt->yvalue;		
	
	} else if (element->arc != NULL) {
		convert_to_iconlines(element->arc);
		lastx = element->arc->pt3->xvalue;		
		lasty = element->arc->pt3->yvalue;		
	
	} else		exxit(15, "");
	
	element = element->next;
	while (element != NULL) {

		if (element->pt != NULL) {
			fprintf(out, "  icon_line %d %d %d %d\n", 
			    lastx, lasty, 
			    element->pt->xvalue, element->pt->yvalue);
	
			lastx = element->pt->xvalue;		
			lasty = element->pt->yvalue;		
	
		} else if (element->arc != NULL) {
			fprintf(out, "  icon_line %d %d %d %d\n", 
			    lastx, lasty, 
			    element->arc->pt1->xvalue, element->arc->pt1->yvalue);
	
			convert_to_iconlines(element->arc);
	
			lastx = element->arc->pt3->xvalue;		
			lasty = element->arc->pt3->yvalue;
	
		} else	exxit(16, "");
		element = element->next;
	}
	
	return RC_NOMINAL;
}

rc_t
SUE::convert_to_iconlines(ARC_EXPR *arg_arc)
{
	int x1 = arg_arc->pt1->xvalue;
	int y1 = arg_arc->pt1->yvalue;
	int x2 = arg_arc->pt2->xvalue;
	int y2 = arg_arc->pt2->yvalue;
	int x3 = arg_arc->pt3->xvalue;
	int y3 = arg_arc->pt3->yvalue;

	double xc = ((double)(y3-y1)*(y2-y3)*(y2-y1)+(x2-x3)*(x3+x2)*(y2-y1)+(x1-x2)*(x1+x2)*(y2-y3))
	        /(2*((y2-y3)*(x1-x2)-(y2-y1)*(x3-x2)));
	double yc = ((double)(x3-x1)*(x3-x2)*(x2-x1)+(y2-y3)*(y3+y2)*(x1-x2)+(y2-y1)*(y1+y2)*(x2-x3))
	        /(2*((y2-y3)*(x1-x2)-(y2-y1)*(x3-x2)));

	// Use the midpoint to determine radius to reduce differences in radius 
	double r = sqrt((double)(xc-x2)*(xc-x2)+(yc-y2)*(yc-y2));

	int xul = (int)(xc-r);
	int yul = (int)(yc+r);
	int xlr = (int)(xc+r);
	int ylr = (int)(yc-r);

	// Y axis is oposite for cds and sue, 
	int sa = (int)(57.30*atan2((double) yc-y1, (double) x1-xc));
	int ea = (int)(57.30*atan2((double) yc-y3, (double) x3-xc));

	fprintf(out,"  icon_arc %d %d %d %d ", xul, yul, xlr, ylr);
	fprintf(out," -start %d -extent %d\n", sa, ea-sa);

	return RC_NOMINAL;
}

rc_t
SUE::convert_to_iconlines(PATH_EXPR *path)
{
	POINTLIST_EXPR *pointlist = path->pointlist;
	ListOfPT_EXPR *tpt_list = pointlist->pt_list;
	
	fprintf(out, "  icon_line");			
	while (tpt_list != NULL) {
		PT_EXPR *pt = tpt_list->expr;
		fprintf(out, " %d %d", pt->xvalue, pt->yvalue);
		tpt_list = tpt_list->next;
	}
	fprintf(out, "\n");

	return RC_NOMINAL;
}

rc_t
SUE::convert_to_iconlines(POLYGON_EXPR *polygon)
{
	POINTLIST_EXPR *pointlist = polygon->pointlist;
	ListOfPT_EXPR *tpt_list = pointlist->pt_list;
	
	fprintf(out, "  icon_line");			
	while (tpt_list != NULL) {
		PT_EXPR *pt = tpt_list->expr;
		fprintf(out, " %d %d", pt->xvalue, pt->yvalue);
		tpt_list = tpt_list->next;
	}
	// ...and back to the first point
	PT_EXPR *pt = pointlist->pt_list->expr;
	fprintf(out, " %d %d", pt->xvalue, pt->yvalue);
	
	fprintf(out, "\n");
	return RC_NOMINAL;
}


rc_t
SUE::convert_to_iconlines(RECTANGLE_EXPR *rectangle)
{
	fprintf(out, "  icon_line");			
	
	// the rectangle is defined by two points, which are
	// opposite corners

	fprintf(out, " %d %d", rectangle->corner1->xvalue, rectangle->corner1->yvalue);
	fprintf(out, " %d %d", rectangle->corner1->xvalue, rectangle->corner2->yvalue);
	fprintf(out, " %d %d", rectangle->corner2->xvalue, rectangle->corner2->yvalue);
	fprintf(out, " %d %d", rectangle->corner2->xvalue, rectangle->corner1->yvalue);
	fprintf(out, " %d %d", rectangle->corner1->xvalue, rectangle->corner1->yvalue);

	fprintf(out, "\n");
	return RC_NOMINAL;
}

rc_t
SUE::convert_to_schematiclines(INSTANCE_EXPR *instance)
{
	// make a "make <whatnot>" line

	VIEWREF_EXPR *viewref = instance->viewref;
	if (viewref == NULL)  exxit(17, "");

	CELLREF_EXPR *cellref = viewref->cellref;
	if (cellref == NULL) exxit(18, "");

	char *cellnamestr = cellref->cellnamedef->get_stringvalue();
	char *instancenamestr = instance->namedef->get_stringvalue();

	if (ORCAD_CELLNAME_BUG) {
		// look for "Implementation" property; if there is none,
		// accept the cell reference

		ListOfPROPERTY_EXPR *property_list = instance->property_list;
		while (property_list != NULL) {
			PROPERTY_EXPR *property = property_list->expr;
			
			if (strcmp(property->namedef->get_stringvalue(), 
			    "Implementation") == 0) {
				char *new_cellnamestr = property->get_value_str();
				char *p = new_cellnamestr;
				while (*p != '\0') {
					if (*p == ' ')	*p = '_';
					if (*p == '/')	*p = '-';
					p++;
				}
				fprintf(rename_info_file, "%s %s\n", 
				    cellnamestr, new_cellnamestr);
				cellnamestr = new_cellnamestr;
				break;
			}

			property_list = property_list->next;
		}
	}


	// ... insert mmi global symbols rather than cells
	// for ground & etc.
	if (USE_GLOBALS != NULL) {
		// this strategy for SUE_EDIF files
		if (strcmp(cellnamestr, "global") == 0) {
			if (strncmp(instancenamestr, "GLOBAL_", strlen("GLOBAL_")) != 0) exxit(181, instancenamestr);
			// skip past "GLOBAL_nnn_"
			char *globalname = instancenamestr + strlen("GLOBAL_");
			while (*globalname++ != '_') continue;
			fprintf(out, "  make global -name %s ", globalname);
			convert_to_args(instance->transform);
			fprintf(out, "\n");
			return RC_NOMINAL;
		}
	
		else {
			// this strategy used explicit list of global names
			BINDING_CHAIN *global_list = USE_GLOBALS;
			while (global_list != NULL) {

				if (strcmp(cellnamestr, global_list->str1) == 0) {
					fprintf(out, "  make global -name %s ", global_list->str2);
					if (instance->transform == NULL ||
					    instance->transform->origin == NULL) exxit(19, "");
					convert_to_arg(instance->transform->origin);
					if (global_list->str3[0] != '\0') {
						fprintf(out, "-orient %s ", global_list->str3);
					}
					fprintf(out, "\n");
					return RC_NOMINAL;
				}
				global_list = global_list->next;
			}
		}
	}

	// remember name_nets
	if (strcmp(cellnamestr, "name_net_s") == 0 ||
	    strcmp(cellnamestr, "name_net") == 0) {
		name_net_nets = new ListOfCHARSTAR(instancenamestr, name_net_nets);
	}

	// ... magic hackware ... see option documentation
	// look for ripper instances
	// possibly a better tho' more tedious way to do this 
	// would be to follow the cellnamedef looking for celltype RIPPER
	if (strncmp(instancenamestr, "splitter", 8) == 0) {
		if (!SHOW_RIPPERS) {
			// don't write an instance
			// just remember where it was so we can clean up wires
			record_ripper_instance(instance);
			return RC_NOMINAL;
		}
	}

	// convert cadence net bundle notation to Sueish

	if (CONVERT_CADENCE_NETNAMES == true) {
		NETNAME *netname = new NETNAME(instancenamestr);
		rc_t rc = netname->parse();
		if (rc != RC_NOMINAL)	exxit(191, "");

		// delete instancenamestr;
		instancenamestr = netname->get_simple_name();
		if (instancenamestr == NULL)	exxit(192, ""); 
	}

	if (SUPPRESS_INSTANCE_NAME_PREFIX != NULL && 
	    strncmp(instancenamestr, SUPPRESS_INSTANCE_NAME_PREFIX, 
            strlen(SUPPRESS_INSTANCE_NAME_PREFIX)) == 0) {
		fprintf(out, "  make %s%s ", cellname_prefix, cellnamestr);

	} else {
		fprintf(out, "  make %s%s -name {%s} ", cellname_prefix, cellnamestr, instancenamestr);

	}

	// delete cellnamestr;
	// delete instancenamestr; 

	if (instance->transform != NULL) {

		if (instance->transform->origin != NULL		&&
		    (instance->transform->origin->pt->xvalue % 10 != 0	||
		     instance->transform->origin->pt->xvalue % 10 != 0	)  ) {
			printf("WARNING: instance \"%s\" origin is off-grid at {%d %d}\n",
			    instancenamestr, instance->transform->origin->pt->xvalue, 
			    instance->transform->origin->pt->yvalue);

		}
		convert_to_args(instance->transform);
	}

	ListOfPROPERTY_EXPR *tproperty_list = instance->property_list;
	while (tproperty_list != NULL) {
		PROPERTY_EXPR *property = tproperty_list->expr;

		tproperty_list = tproperty_list->next;
		if (property->is_ignorable)	continue;

		char *prop_name_str = property->namedef->get_stringvalue();
		char *prop_value_str = property->get_value_str();

if (strcmp(prop_name_str, "dpc") == 0) {
	printf("3dpc property\n");
}
		
		if (strcmp(prop_value_str, "") == 0) continue;

		if (CADENCE_PROPERTY_VALUES) {
			convert_cadence_property(prop_value_str, prop_value_str, NULL);
		}

		// convert floating point sizes to fixed microns, if that's what it is
		// char *t = convert_float_to_fixed(prop_value_str);
		// if (t != NULL) 	prop_value_str = t;

		// why the $???
		// fprintf(out, "-%s {$%s} ", prop_name_str, prop_value_str);
		fprintf(out, "-%s {%s} ", prop_name_str, prop_value_str);
	}    
	
	fprintf(out, "\n");

	// sometimes add a "make_text" line
	// (when the instance->name contains a display expr)
	// NOTE: Lee says this is exteraneous bit of text, since 
	// Sue will attach a text name to the instance-icon
	// already.
	// convert_to_textline(instance->namedef);

	return RC_NOMINAL;
}


rc_t
SUE::convert_to_schematiclines(ANNOTATE_EXPR *annotate)
{
	STRINGDISPLAY_EXPR *stringdisplay = annotate->stringdisplay;
	if (stringdisplay == NULL) return RC_NOMINAL;

	// backconvert in place edif "ascii notation"
	char *p = stringdisplay->string;

	char *r = p;
	while (*p != '\0') {
		if (*p != '%') {
			*r++ = *p++;
			continue;
		}
		if (strncmp(p, "%34%", 4) != 0) {
			*r++ = *p++;
			continue;
		}
		p += 4;
		*r++ = '"';
	}
	*r = '\0';

	ListOfDISPLAY_EXPR *tdisplay_list = stringdisplay->display_list;
	while (tdisplay_list != NULL) {
		DISPLAY_EXPR *display = tdisplay_list->expr;

		// BUG...need documentation...
		// feature not supported in sue
		display->orientation = R0;

		fprintf(out, "  make_text ");
		convert_to_arg(display->origin);

		char *p = stringdisplay->string;

		fprintf(out, "-text {%s}\n", p);

		tdisplay_list = tdisplay_list->next;
	}
}


rc_t
SUE::convert_to_schematiclines(PORTIMPLEMENTATION_EXPR *portimplementation)
{
	// make a "make <whatnot>" line

	PORT_EXPR *port = NULL;
	portimplementation->namedef->get_where_defined(&port);
	char *portnamestr = convert_portname(port);
	
	// sanity check.....
	// "in Sue, interface pins have special names:
	// ipin, opin, and inout" -Lee
	// ...so the cellref related to this portimplementation
	// had better have one of those names, corresponding
	// to the port->direction....

	// instance can actually be a list.  I suppose that
	// has to do with arrays.  right now, not supported....
	if (portimplementation->instance_list != NULL) {
		if (portimplementation->instance_list->next != NULL)	exxit(21, "");
		INSTANCE_EXPR *instance = portimplementation->instance_list->expr;
		if (instance == NULL) 		exxit(22, "");
		VIEWREF_EXPR *viewref = instance->viewref;
		if (viewref == NULL)  exxit(23, "");
		CELLREF_EXPR *cellref = viewref->cellref;
		if (cellref == NULL) exxit(24, "");
		NAMEDEF *cellnamedef = cellref->cellnamedef;
		if (cellnamedef == NULL) exxit(25, "");
		char *cellname = cellnamedef->get_stringvalue();

		if((port->direction == INPUT && strcmp(cellname, "ipin") == 0) ||
		   (port->direction == OUTPUT && strcmp(cellname, "opin") == 0) || 
		   (port->direction == INOUT && strcmp(cellname, "iopin") == 0)) {
			; // ok
		} else {
			printf("sanity check failed: port direction doesn't match cell name %s\n",
			    cellname);
			// exxit(26, "");
		}
	}

	char *direction_str = NULL;
	switch (port->direction) {
	    // BUG... this code is duplicated below
	    case INPUT:		direction_str = "input";   break;

	    case OUTPUT: {
		direction_str = "output";  
		switch (portimplementation->orientation) {
		    case R0:	portimplementation->orientation = R180;		break;
		    case R90:	portimplementation->orientation = R270;		break;
		    case R270:	portimplementation->orientation = R90;		break;
		    case MYR90:	portimplementation->orientation = MXR90;	break;
		    case MXR90:	portimplementation->orientation = MYR90;	break;
		    case R180:	portimplementation->orientation = R0;		break;
		    case MY:	portimplementation->orientation = MX;		break;
		    case MX:	portimplementation->orientation = MY;		break;
		}
	    } break;

	    case INOUT:		direction_str = "inout";   break;
	    case DIRECTION_NOT_SPECIFIED: 
		// BUG... is this a reasonable default?  Not specified in 
		// Db.edf::lib primitives::cell ripper_3, for one...  
		printf("port %s...default direction to inout\n", portnamestr);
	        direction_str = "inout"; break;
		// exxit(26, "");
	}

	fprintf(out, "  make %s -name {%s} ",
	    direction_str, portnamestr);

	// orient according to connected net
	convert_to_arg(portimplementation->orientation);

	CONNECTLOCATION_EXPR *connectlocation = 
	    portimplementation->connectlocation; 
	FIGURE_EXPR *figure = connectlocation->figure_list->expr;
	DOT_EXPR *dot = figure->dot_list->expr;

	if (dot->pt->xvalue % 10 != 0	||
	    dot->pt->yvalue % 10 != 0	    ) {
		printf("WARNING: portimplementation \"%s\" is off-grid at {%d %d}\n",
		    portnamestr, dot->pt->xvalue, dot->pt->yvalue);
	}

	convert_to_origin_arg(dot->pt->xvalue, dot->pt->yvalue);
	fprintf(out, "\n");

	if (dot->pt->yvalue > maxy) maxy = dot->pt->yvalue;
	if (dot->pt->xvalue < minx) minx = dot->pt->xvalue;

	// sometimes add a "make_text" line
	// (when an instance->name contains a display expr)
	// ...multiple instances would be sensible here,
	// but we have blown off the others already
	if (portimplementation->instance_list != NULL) {
		if (portimplementation->instance_list->next != NULL)	exxit(32, "");
		INSTANCE_EXPR *instance = portimplementation->instance_list->expr;
		convert_to_textline(instance->namedef);
	}

	// delete portnamestr;  ....gets passed to portimp_pt_chain....
	return RC_NOMINAL;
}

rc_t
SUE::make_portimp_pt_chain(PORTIMPLEMENTATION_EXPR *portimplementation)
{
	// need this so I can verify same name on port & net
	PORT_EXPR *port = NULL;
	portimplementation->namedef->get_where_defined(&port);
	char *portnamestr = convert_portname(port);

	CONNECTLOCATION_EXPR *connectlocation = 
	    portimplementation->connectlocation; 
	if (connectlocation == NULL) {
		printf("portimplementation without connectlocation???\n");
		exxit(29, "");
	}
	if (connectlocation->figure_list == NULL ||
	    connectlocation->figure_list->next != NULL)	exxit(30, "");

	FIGURE_EXPR *figure = connectlocation->figure_list->expr;
	// I expect this figure to have exactly one dot...
	if (figure->circle_list != NULL || 
	    figure->openshape_list != NULL ||
	    figure->path_list != NULL ||
	    figure->polygon_list != NULL ||
	    figure->rectangle_list != NULL ||
	    figure->shape_list != NULL ||
	    figure->dot_list == NULL ||
	    figure->dot_list->next != NULL)	exxit(31, "");
	
	DOT_EXPR *dot = figure->dot_list->expr;
	portimp_pt_chain = new ChainOfPORTIMP_PT(
	    portnamestr, dot->pt, portimplementation, portimp_pt_chain);

	return RC_NOMINAL;
}

rc_t
SUE::align_portimplementation(ChainOfPORTIMP_PT *port_chain, WIRESEG *wireseg)
{
	PORTIMPLEMENTATION_EXPR *portimplementation = 
	    port_chain->portimplementation;
	
	int otherend_x = 0;
	int otherend_y = 0;

	if (wireseg->x1 == port_chain->xvalue &&
	    wireseg->y1 == port_chain->yvalue) {
		otherend_x = wireseg->x2;
		otherend_y = wireseg->y2;
	}
	else if (wireseg->x2 == port_chain->xvalue &&
	    wireseg->y2 == port_chain->yvalue) {
		otherend_x = wireseg->x1;
		otherend_y = wireseg->y1;
	}
	else	exxit(311, "");

	ORIENTATION orientation = R0;
	if (otherend_x == port_chain->xvalue) {
		if (otherend_y > port_chain->yvalue) orientation = R270;
		else				     orientation = R90;
	} else 
	if (otherend_y == port_chain->yvalue) {
		if (otherend_x > port_chain->xvalue) orientation = R0;
		else				     orientation = R180;
	}
	portimplementation->orientation = orientation;
	return RC_NOMINAL;
}

rc_t
SUE::convert_to_schematiclines(NET_EXPR *net)
{
	// RFE...
	// I have got myself confused about allocations.  As it is,
	// "don't ever delete the net_expr", just exit.

	// RFE....
	// we ought to make sure that the points mentioned
	// in the figures correspond to the portrefs.
	// That doesn't sound so hard to do, actually....
	// for each port in the portrefs, the actual location
	// is the origin of the instance, plus the connectionlocation
	// of the port within the cellref of the instance, 
	// adjusted for orientation. 
	// Except that some of the joined portlists are messed up...
	// Cadence isn't doint it right for bundles.
  

	if (net->figure_list == NULL) {
		// if the ports are coincident, then they
		// are already connected & we don't need any
		// wires.  Evidently in Sue, we don't need
		// to mention them at all, so we are done.

		// there are also a number of multiplier cases where
		// the net is one-bit wide: "<*128>bloopclk"
		// In the Cadence world we would need the equivalent of
		// a buscombine (see below), but Sue doesn't need it,
		// so we also have nothing to do for this case.

		return RC_NOMINAL;
	}
	
	char *namestr = net->namedef->get_stringvalue();
	BOOLEAN name_is_simple = false;
	NETNAME *netname = NULL;

	if (LITERAL_NETNAMES) {
		// command line option; just leave net name as it is.
		;

	} else {
		// delete namestr;
		netname = new NETNAME(namestr);
		rc_t rc = netname->parse();
		if (rc != RC_NOMINAL)		exxit(33, "");
	
		namestr = netname->get_simple_name();
		if (namestr == NULL) {
		
			
			// we will need to do a buscombine to be the source
			// for this net, but since we want to locate it south 
			// of all connection points to avoid collisions, we 
			// can't do it now.
	
			// .....generate a name for this net, use it
			// just like ordinary netname
	
			namestr = (char *)malloc(40); // strlen ("buscombine_") +
						// strlen of decimal largest int...?
			sprintf(namestr, "%s_%d[%d:0]", buscombine_namestr, 
			    ++buscombine_netnumber, 
			    netname->get_width() - 1);
			// printf("%s_%d %s\n", buscombine_namestr, buscombine_netnumber, netname->name);
	
			// save real net info for later...
			netname->generated_name = strdup(namestr);

		} else {
			name_is_simple = true;
			delete netname;
			netname = NULL;
		}
	}


	// ...debug hook...
	// char *my_favorite_net = "Dmxx_diagwr_tag_4e3[29]";
	// if (strcmp(namestr, my_favorite_net) == 0) {
	// 	printf("my favorite net %s\n", my_favorite_net);
	// }

	// convert the somewhat ungainly net_expr figures to simple
	// list of wire segments (a line between two points)
	ListOfWIRESEG *wireseg_list = convert_to_wireseg_list(net);

	// identify any wiresegments herein that terminate at a ripper
	if (!SHOW_RIPPERS && ripper_pt_list != NULL) {	
		rc_t rc = identify_rippers(wireseg_list);
	}

	// organize the wire segments into lists of connected segments
	ListOfListOfWIRESEG *connected_wireseg_list = segregate_connected_wiresegs(wireseg_list);

	// now emit a netname on each connected segment
	// except see note at method; sometimes this net is just generated 
	rc_t rc = emit_netnames(connected_wireseg_list, namestr, name_is_simple);
	if (rc == RC_NOMINAL && netname != NULL) {
		defered_netname_list = new ListOfNETNAME(netname, 
			    defered_netname_list);
	}

	// finally, emit the wire segments.
	ListOfWIRESEG *tseg_list;
	WIRESEG *tseg;

	ListOfListOfWIRESEG *tlist_list = connected_wireseg_list;
	while (tlist_list != NULL) {

		// ListOfWIRESEG *
		tseg_list = tlist_list->wireseg_list;
		while (tseg_list != NULL) {

			// WIRESEG *
			tseg = tseg_list->wireseg;
			if (!tseg->pt1_is_ripper && !tseg->pt2_is_ripper) {
				if (ROUND_TO_GRID_LINES) {
					round_to_grid(&tseg->x1);
					round_to_grid(&tseg->y1);
					round_to_grid(&tseg->x2);
					round_to_grid(&tseg->y2);
				}
		 		fprintf(out, "    make_wire %d %d  %d %d\n", tseg->x1, tseg->y1, tseg->x2, tseg->y2);


				if (tseg->x1 % 10 != 0	||
				    tseg->y1 % 10 != 0	||
				    tseg->x2 % 10 != 0	||
				    tseg->y2 % 10 != 0	    ) {
					printf("WARNING: wire segment is off-grid at {%d %d},{%d %d}\n",
					    tseg->x1, tseg->y1, tseg->x2, tseg->y2);
				}

			}
			tseg_list = tseg_list->next;
		}
		tlist_list = tlist_list->next;
	}

	// BUG.... there's a bunch of stuff that needs to be freed

	return RC_NOMINAL;
}

ListOfWIRESEG *
SUE::convert_to_wireseg_list(NET_EXPR *net)
{
	// what we expect:
	// a net contains a list of figures; each figure
	// contains a (possibly empty) list of paths of two or more points;
	//  each consecutive pair is a wire segment.  
	// *Rather* more complicated stuff is acceptable to EDIF.
	// RFE.... perhaps someday we will want to make 
	// this code accept more general structures. 

	ListOfWIRESEG *wireseg_list = NULL;

	ListOfFIGURE_EXPR *figure_list = net->figure_list;
	while (figure_list != NULL) {

		FIGURE_EXPR *figure = figure_list->expr;

		// ...I *guess* he can have an empty list
		// if he *wants* to....
		if (figure->path_list == NULL) {
			figure_list = figure_list->next;
			continue;
		}

		if (figure->circle_list != NULL ||
		    figure->openshape_list != NULL ||
		    figure->dot_list != NULL ||
		    figure->polygon_list != NULL ||
		    figure->rectangle_list != NULL ||
		    figure->shape_list != NULL) exxit(34, "");

		ListOfPATH_EXPR *path_list = figure->path_list;
		while (path_list != NULL ) {
		
			PATH_EXPR *path = path_list->expr;
			POINTLIST_EXPR *pointlist = path->pointlist;
			ListOfPT_EXPR *pt_list = pointlist->pt_list;
			if (pt_list == NULL	   ||
			    pt_list->next == NULL	 ) exxit(35, "");	

			PT_EXPR *pt1;
			PT_EXPR *pt2;
			while (pt_list->next != NULL) {
				pt1 = pt_list->expr;
				pt2 = pt_list->next->expr;

				wireseg_list = new ListOfWIRESEG(
				    new WIRESEG(pt1->xvalue, pt1->yvalue,
					pt2->xvalue, pt2->yvalue),
				    wireseg_list);

				if (pt1->yvalue > maxy) maxy = pt1->yvalue;
				if (pt1->xvalue < minx) minx = pt1->xvalue;

				pt_list = pt_list->next;
			}

			if (pt2->yvalue > maxy) maxy = pt2->yvalue;
			if (pt2->xvalue < minx) minx = pt2->xvalue;

			path_list = path_list->next;
		}
		figure_list = figure_list->next;
	}
	return wireseg_list;
}		

rc_t
SUE::identify_rippers(ListOfWIRESEG *wireseg_list)
{
	// for each of the segments in the list,
	// can I find a ripper point that matches an endpoint of this segment?
	// if so, in the "normal" case I can just drop this segment, but
	// I have to worry about (common enough) cases where this is the only 
	// wire in this connected set, going from a ripper to an instance
	// ....in that case, I will need to put a namenet on the instance pin.  
	// OTOH, if this segment is just going between rippers, then I am
	// back to wanting to just dropping it.

	while (wireseg_list != NULL) {
		WIRESEG *tseg = wireseg_list->wireseg;
		ListOfPT_EXPR *tripper_list = ripper_pt_list;
		while (tripper_list != NULL) {
			PT_EXPR *ripper_pt = tripper_list->expr;
			tripper_list = tripper_list->next;

			if (ripper_pt->xvalue == tseg->x1 && ripper_pt->yvalue == tseg->y1) 
				wireseg_list->wireseg->pt1_is_ripper = true;
			if (ripper_pt->xvalue == tseg->x2 && ripper_pt->yvalue == tseg->y2)
				wireseg_list->wireseg->pt2_is_ripper = true;

		}
		wireseg_list = wireseg_list->next;
	}
	return RC_NOMINAL;
}


ListOfListOfWIRESEG *
SUE::segregate_connected_wiresegs(ListOfWIRESEG *wireseg_list)
{
	// While there are more wire segments in the wireseg list,
	//	start a new wireseg list with that segment
	//	for each point some wireseg in the new wireseg list,
	//		look through the rest of the segments for
	//		    a matching point
	//		when found, remove the containing wireseg
	//		    from the arg wireseg list and add it to 
	//		    the new wireseg list

	ListOfListOfWIRESEG *connected_wiresegs_list = NULL;
	ListOfWIRESEG *new_wireseg_list;
	ListOfWIRESEG *tseg_list;
	WIRESEG *tseg;
	WIRESEG *newseg;

	while (wireseg_list != NULL) {
		// take the first wirseg of the arg list,
		// start a new (connected) list
		// ListOfWIRESEG *
		new_wireseg_list = wireseg_list;
		wireseg_list = wireseg_list->next;
		new_wireseg_list->next = NULL;

		if (new_wireseg_list->wireseg == NULL) {
			// wire has been connected already; delete list item
			// delete new_wireseg_list;
			continue;
		}
	
		connected_wiresegs_list = new ListOfListOfWIRESEG(
		    new_wireseg_list, connected_wiresegs_list);
	
		while (new_wireseg_list != NULL) {	
			// scan over the rest of the wiresegs in the 
			// original list, transfering those that match
			// to the new list

			// WIRESEG *
			newseg = new_wireseg_list->wireseg;

			// ListOfWIRESEG *
			tseg_list = wireseg_list;
			while (tseg_list != NULL) {

				// WIRESEG *
				tseg = tseg_list->wireseg;
				if (tseg != NULL) {
					// ripper points don't participate in connectedness decisions
					if (( !tseg->pt1_is_ripper && !newseg->pt1_is_ripper &&
					      tseg->x1 == newseg->x1  && tseg->y1 == newseg->y1       ) ||

					    ( !tseg->pt2_is_ripper && !newseg->pt2_is_ripper &&
					      tseg->x2 == newseg->x2 && tseg->y2 == newseg->y2        ) ||

					    ( !tseg->pt1_is_ripper && !newseg->pt2_is_ripper &&	
					      tseg->x1 == newseg->x2 && tseg->y1 == newseg->y2        ) ||

					    ( !tseg->pt2_is_ripper && !newseg->pt1_is_ripper &&	
					      tseg->x2 == newseg->x1 && tseg->y2 == newseg->y1        )     ) {

						// ...one or the other non-ripper point over here matches
						// one or the other non-ripper point over there...
				
						new_wireseg_list->next = new ListOfWIRESEG(tseg, new_wireseg_list->next);
						tseg_list->wireseg = NULL;
					}
				}

				tseg_list = tseg_list->next;
			}
			new_wireseg_list = new_wireseg_list->next;
		}			
		// .... already bumped wireseg_list above
	}
	return connected_wiresegs_list;
}

rc_t
SUE::emit_netnames(ListOfListOfWIRESEG *connected_wireseg_list, 
    char *namestr, BOOLEAN name_is_simple)
{
	// don't want to put a name net on globals
	// ... this assumes that there is a global symbol on every
	// net fragment, which seems to be true so far....

	if (USE_GLOBALS != NULL) {
		BINDING_CHAIN *global_list = USE_GLOBALS;
		while (global_list != NULL) {
			if (strcmp(namestr, global_list->str1) == 0) {
				return RC_NOMINAL;
			}
			global_list = global_list->next;
		}
	}

	// if this net has a name_net on it already, it would
	// be silly to place another one
	ListOfCHARSTAR *tnets = name_net_nets;
	while (tnets != NULL) {
		if (strcmp(tnets->str, namestr) == 0)	return RC_NOMINAL;
		tnets = tnets->next;
	}

	if (connected_wireseg_list != NULL &&
	    connected_wireseg_list->next == NULL &&
	    name_is_simple) {

		// eliminate clutter; if the net's segments are connected, and
		// the net has a simple name that doesn't seem to be meaningful,
		// then don't bother with namenet.  Also, kill the generated name
		// for this net (by returning RC_EXCEPTION), which will prevent 
		// generating an erroneous buscombine

		if (strncmp(namestr, "net", 3) == 0	 ||
		    strncmp(namestr, "NET", 3) == 0 	 ||
		    strncmp(namestr, "THING_", 6) == 0 ) {
			// never mind
			return RC_EXCEPTION;
		}
	}

	while (connected_wireseg_list != NULL) {

		// walk the connected chunk to see if it connected directly
		// to a port; if so, never mind.
		BOOLEAN found_a_port = false;
		ListOfWIRESEG *tseg_list = connected_wireseg_list->wireseg_list;
		while (tseg_list != NULL && !found_a_port) {
			WIRESEG *tseg = tseg_list->wireseg;

			ChainOfPORTIMP_PT *tportpt = portimp_pt_chain;
			while (tportpt != NULL && !found_a_port) {
				if ((!tseg->pt1_is_ripper && 
				     tportpt->xvalue == tseg->x1 && tportpt->yvalue == tseg->y1) ||
				    (!tseg->pt2_is_ripper &&
				     tportpt->xvalue == tseg->x2 && tportpt->yvalue == tseg->y2)) {
					found_a_port = true;

					// orient the port symbol with the net segment
					align_portimplementation(tportpt, tseg);

					if (strcmp(tportpt->portname, namestr) != 0) {
						printf("net name \"%s\" doesn't match port name \"%s\"\n",
						    namestr, tportpt->portname);
					}	 
				}
				tportpt = tportpt->next;
			}
			tseg_list = tseg_list->next;
		}
	
		if (!found_a_port) {
			// put the netname on pt1 of the first segment, 
			// ("nearest my thumb" rule) (unless it's a ripper point)

			WIRESEG *tseg = connected_wireseg_list->wireseg_list->wireseg;
			if (!tseg->pt1_is_ripper) {
				fprintf(out, "  make name_net_s ");
				convert_to_origin_arg(tseg->x1, tseg->y1);
				fprintf(out, " -name {%s}\n", namestr);
			}
			else if (!tseg->pt2_is_ripper) {
				fprintf(out, "  make name_net_s ");
				convert_to_origin_arg(tseg->x2, tseg->y2);
				fprintf(out, " -name {%s}\n", namestr);
			}
			else if (connected_wireseg_list->wireseg_list->next != NULL)	exxit(36, "");
		}
		connected_wireseg_list = connected_wireseg_list->next;
	}
	return RC_NOMINAL;
}


rc_t
SUE::handle_defered_netnames()
{
	ListOfNETNAME *tnl = defered_netname_list;

	// make a buscombine for each defered netname
	// put them in a horizontal row with their tops aligned
	// somewhat below the lowest connection point (they might
	// overlap with some icon lines, but that won't be bad,
	// just ugly.

	int y_buscombine = maxy + 200;

	// put them from left to right, starting about below the 
	// leftmost connection point, and trying to space them
	// reasonably.

	int x_origin = minx;

	while (defered_netname_list != NULL) {
		NETNAME *netname = defered_netname_list->netname;
		int width = netname->get_width();

		// printf("handle_defered_netname %s %s width %d\n",
		// netname->name, netname->generated_name, width);

		int size = (width -1) * BUS_COMBINE_YINCR;
		int y_origin = y_buscombine + size / 2;
		if (y_buscombine + size > maxy)
			maxy = y_buscombine + size;

		fprintf(out, 
		    "  generate bus_combine buscombine%d -ninputs %d\n",
		    width, width);
		fprintf(out,
		    "make_wire %d %d %d %d\n", 
		    x_origin + 20, y_origin, x_origin + 100, y_origin);
		fprintf(out,
		    "make name_net_s -name {%s} -origin {%d %d}\n",
		    netname->generated_name,
		    x_origin + 100, y_origin);
		fprintf(out,
		    "  make buscombine%d -origin {%d %d}\n",
		    width, x_origin, y_origin); 
		netname->generate_name_nets(out, 
		    // input pads are offset 1 grid line from buscombine origin
		    x_origin - 10,			
		    y_buscombine);	

		defered_netname_list = defered_netname_list->next;
		x_origin += BUS_COMBINE_XINCR;
	}

	// delete tnl;

	return RC_NOMINAL;
}


rc_t
SUE::convert_to_args(DISPLAY_EXPR *display)
{
	// BUG....
	// this is really quite wrong... what I should do is
	// find the figureGroup from the display->figureGroupOverride,
	// see what the figureGroup attributes are
	// override them with as-specified in the fGOverride,
	// compare them with the Sue defaults,
	// and write out arguements accordingly.
	// Actually, the only thing we seem to care about
	// is textheight, plus the values in the display_expr.

	if (display->figuregroupoverride == NULL) {
		fprintf(out, "-size small ");
	}
	else if (display->figuregroupoverride->textheight_valid) {
		int text_height = display->figuregroupoverride->textheight;

		if (SCALE_COORDS) {
			// "large" and "small" text sizes will be
			// scaled in Sue, or so we expect...
			text_height = text_height / scale_coords_factor;
			// that gets it back to normal, now let's actually reduce it
			text_height = text_height / scale_coords_factor;
		}

		if (text_height < 9)		fprintf(out, "-size small ");
		else if (text_height > 10)	fprintf(out, "-size large ");
	}

	convert_to_arg(display->justify);
	convert_to_arg(display->orientation);
	convert_to_arg(display->origin);

	return RC_NOMINAL;
}

rc_t
SUE::convert_to_args(TRANSFORM_EXPR* transform)
{
	if (transform == NULL) 
		return RC_NOTSPECIFIED;

	convert_to_arg(transform->orientation);
	convert_to_arg(transform->origin);
}				

rc_t
SUE::convert_to_arg(JUSTIFY justify)
{
	char *str = NULL;
	switch (justify) {
	    case LOWERLEFT:	str = "sw";	break;
	    case LOWERCENTER:	str = "s";	break;
	    case LOWERRIGHT:	str = "se";	break;
	    case CENTERLEFT:	return RC_NOMINAL;
	    case CENTERCENTER:	str = "center";	break;
	    case CENTERRIGHT:	str = "e";	break;
	    case UPPERLEFT:	str = "nw";	break;
	    case UPPERCENTER:	str = "n";	break;
	    case UPPERRIGHT:	str = "ne";	break;
	}

	fprintf(out, "-anchor %s ", str);

	return RC_NOMINAL;
}

rc_t
SUE::convert_to_arg(ORIENTATION orientation)
{
	char *str = NULL;
	switch (orientation) {
	    case ORIENTATION_NOT_SPECIFIED:	
		return RC_NOTSPECIFIED;
		break;

	    case R0:		return RC_NOMINAL;	break;
	
	    case R90:		str = "R270";	break;
	    case R270:		str = "R90";	break;
	    case MYR90:		str = "R90Y";	break;
	    case MXR90:		str = "R90X";	break;
	    case R180:		str = "RXY";	break;
	    case MY:		str = "RX";	break;
	    case MX:		str = "RY";	break;
	}

	fprintf(out, "-orient %s ", str);
	return RC_NOMINAL; 	
}

rc_t
SUE::convert_to_arg(ORIGIN_EXPR *origin)
{
	if (origin == NULL)
		return RC_NOTSPECIFIED;

	return convert_to_origin_arg(origin->pt->xvalue, origin->pt->yvalue);
}

rc_t
SUE::convert_to_origin_arg(int xval, int yval)
{
	int orgx = xval;
	int orgy = yval; 

	if (ROUND_TO_GRID_LINES) {
		round_to_grid(&orgx);
		round_to_grid(&orgy);
	}

	fprintf(out, " -origin {%d %d} ", orgx, orgy); 
	return RC_NOMINAL;
}


void
SUE::round_to_grid(int *arg)
{
	int r = (*arg) % 10;
	if (r != 0) {
		*arg = ((*arg) / 10) * 10;
		if (r > 5) *arg = (*arg) + 10;
		if (r < -5) *arg = (*arg) - 10;
	}
}

rc_t
SUE::convert_to_textline(NAMEDEF *namedef)
{
	// .... if there is a DISPLAY_EXPR in here somewhere ....

	if (namedef->identifier != NULL)		
		return RC_NOMINAL;

	if (namedef->name != NULL)
		return convert_to_textline(namedef->name);

	if (namedef->rename != NULL &&
	    namedef->rename->stringdisplay != NULL) 
		return convert_to_textline(namedef->rename->stringdisplay);
	         
}

rc_t
SUE::convert_to_textline(NAME_EXPR *name)
{
	ListOfDISPLAY_EXPR *tdisplay_list = name->display_list;
	while (tdisplay_list != NULL) {
		DISPLAY_EXPR display = *(tdisplay_list->expr);

		// BUG...(documentation required)
		// Sue doesn't support orientation of text
		display.orientation = R0;

		fprintf(out, "  make_text -text %s ", name->identifier);
		convert_to_args(&display);
		fprintf(out, "\n"); 

		tdisplay_list = tdisplay_list->next;
	}
	return RC_NOMINAL;
}

rc_t
SUE::convert_to_textline(STRINGDISPLAY_EXPR *stringdisplay)
{
	ListOfDISPLAY_EXPR *tdisplay_list = stringdisplay->display_list;
	while (tdisplay_list != NULL) {
		DISPLAY_EXPR display = *(tdisplay_list->expr);

		// BUG...(documentation required)
		// Sue doesn't support orientation of text
		display.orientation = R0;

		fprintf(out, "  make_text -text %s ", 
		    stringdisplay->string);
		convert_to_args(&display);
		fprintf(out, "\n"); 

		tdisplay_list = tdisplay_list->next;
	}
	
	return RC_NOMINAL;
}


char *	
SUE::convert_portname(PORT_EXPR *port) {

	// want to convert array notation to Sueish

	char *original_namestr = port->namedef->get_stringvalue();

	NETNAME *netname = new NETNAME(original_namestr);
	rc_t rc = netname->parse();
	if (rc != RC_NOMINAL)	exxit(37, "");

	char *portnamestr = netname->get_simple_name();
	if (portnamestr == NULL) {
		// BUG...
		// ...have actually seen complex names here.
		// see buglist... 
		printf(
		    "complex port name: sue won't handle this right \"%s\"\n",
		    original_namestr);
		portnamestr = original_namestr;

	} // else	delete original_namestr;
		
		
	// delete netname;
	return portnamestr;
}

rc_t
SUE::record_ripper_instance(INSTANCE_EXPR *instance)
{
	if (instance->transform == NULL ||
 	    instance->transform->origin == NULL ||
	    instance->transform->origin->pt == NULL) {
		printf("ripper instance with no origin %s\n", instance->namedef->get_stringvalue());
		return RC_NOTFOUND;
	}	

	ripper_pt_list = new ListOfPT_EXPR(
	    instance->transform->origin->pt, ripper_pt_list);
 
	return RC_NOMINAL;
}



// this performs a pretty bizzare transformation that made sense to 
// somebody once.  Dave sez, just don't do it... so size strings
// will come out as "2.4e-4" sometimes.  Whoever designed it 
// knows what that means & why he wants it that way.
//
//
//char *
//SUE::convert_float_to_fixed(char *str)
//{
//#define CONVERT_MAX 10
//	char *outstr = new char[CONVERT_MAX];
//	char *p = str;
//	char *r = outstr;
//
//	if (*p == '\"') p++;
//
//	int brk = 0;
//	while (brk != -1) {
//		switch (*p) {
//			case '0': case '1': case '2': case '3': case '4': 
//			case '5': case '6': case '7': case '8': case '9': 
//			case '.':
//				*r++ = *p++;
//				brk++;
//				break;
//
//			default:
//				if (brk >= CONVERT_MAX) exxit(371, str);
//				*r = '\0';
//				brk = -1;
//				break;
//		}
//	}
//
//	if (strcmp(p, "e-4") != 0 && strcmp(p, "e-4\"") != 0) {
//		delete outstr;
//		return NULL;
//	}
//
//	return outstr;
//}

void
SUE::exxit(int exit_number, char *exit_msg)
{
 	printf("fatal error %d called: \"%s\"\n", exit_number, exit_msg);

	// ...mostly "exxit"s are hung on places where
	// something is syntacticly legal, but I don't
	// know how to handle it.  Rather than clutter
	// up the code with a lot of printf's & annoying
	// curlies, since we're just going to bail
	// anyway, just bail.  Unless he *said* to keep
	// going.

	// ...so run again under the debugger with
	// a breakpoint here & walk up the stack to 
	// find out what happened

	if (CONTINUE_ON_TRANSLATE_ERRORS) {
		printf("...continueing after error\n");
		return;
	} else {
		exit(-1);
	}
}

rc_t
SUE::convert_cadence_property(char *prop_str, char *return_prop_name, char *return_default_value)
{
	if (strncmp(prop_str, "[@", 2) == 0) {

		char prop_name[100];
		char default_value[100];
		
		char *p = prop_str + 2;
		char *endp = p + strlen(prop_str);
		char *r = prop_name;
		while (p < endp && *p != ':' && *p != ']')	*r++ = *p++;
		if (p == endp)	goto nope;
		*r = '\0';
		if (*p == ']') {
			sprintf(return_prop_name, "%s", prop_name);
			sprintf(return_default_value, "{}");
			return RC_CONVERTED;
		}

		p++;

		while (p < endp && *p != ':')	p++;
		if (p == endp)	goto nope;

		p++;

		r = default_value;
		while (p < endp && *p != ']')	*r++ = *p++;
		if (p == endp)	goto nope;
		*r = '\0';

		if (return_prop_name != NULL) {
			sprintf(return_prop_name, "%s", prop_name);
		}
		if (return_default_value != NULL) {
			sprintf(return_default_value, "%s", default_value);
		}
		return RC_CONVERTED;

	    nope:
		return RC_NOTCONVERTED;

	}
	return RC_NOTCONVERTED;	
}

////////////////////////////////////////////////

SUE_FILE::SUE_FILE(const char *arg_name)
{
	name = strdup(arg_name);
}


FILE *
SUE_FILE::open()
{
#define MAX_FN_LENGTH	1000
	char	pathname[MAX_FN_LENGTH];

	sprintf(pathname, "%s/%s.sue", SUE::output_dir_path, name);
	if (strlen(pathname) >= MAX_FN_LENGTH) {
		printf("SUE_FILE::open: overran pathname buffer\n");
		exit(-1);
	}

	struct stat statinfo;
	BOOLEAN	exists = false;
	if (stat(pathname, &statinfo) == 0)	exists = true;	

	file = fopen(pathname, "w");
	if (file == NULL) {
		if (errno == 2) {
			mkdir(SUE::output_dir_path, 0777);
			file = fopen(pathname, "w");
		}
		if (file == NULL) {
			printf("open sue_file %s failed %d\n", pathname, errno);
			return NULL;
		}
	}

	// if (exists == true)
	//	printf("opened sue_file %s TRUNCATED\n", pathname);
	// else
	//	printf("opened sue_file %s\n", pathname);

	return file;
}

rc_t
SUE_FILE::close()
{
	int rc = fclose(file);
	if (rc == 0)	return RC_NOMINAL;
	else		return RC_FAILED;
}


NETLIST_FILE::NETLIST_FILE(const char *arg_name)
{
	name = strdup(arg_name);
}


FILE *
NETLIST_FILE::open()
{
#define MAX_FN_LENGTH	1000
	char	pathname[MAX_FN_LENGTH];

	sprintf(pathname, "netlist/%s.nl", name);
	if (strlen(pathname) >= MAX_FN_LENGTH) {
		printf("NETLIST_FILE::open: overran pathname buffer\n");
		exit(-1);
	}

	struct stat statinfo;
	BOOLEAN	exists = false;
	if (stat(pathname, &statinfo) == 0)	exists = true;	

	file = fopen(pathname, "w");
	if (file == NULL) {
		printf("open sue_file %s failed %d\n", pathname, errno);
		return NULL;
	}

	if (exists == true)
		printf("opened sue_file %s TRUNCATED\n", pathname);
	else
		printf("opened sue_file %s\n", pathname);

	return file;
}

rc_t
NETLIST_FILE::close()
{
	int rc = fclose(file);
	if (rc == 0)	return RC_NOMINAL;
	else		return RC_FAILED;
}


ListOfCHARSTAR::ListOfCHARSTAR(char *arg_str, ListOfCHARSTAR *arg_next) 
    : str(arg_str), next(arg_next)
{
}

ListOfCHARSTAR::~ListOfCHARSTAR() 
{
	// if (str) delete str;
}
