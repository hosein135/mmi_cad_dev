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

#include <util.h>

// some hackery for WHATNOT_EXPR::print methods
#define MAX_PRINT_LINE_SIZE	200
char	print_line[MAX_PRINT_LINE_SIZE + 100];
char *	endp = print_line + MAX_PRINT_LINE_SIZE;
 
extern int error_count;
extern int warning_count;

rc_t
pe(int severity, char *arg_str)
{
	if (severity > 0) {
		printf("ERROR line %d %s\n", 
		    EDIF_FILE::current_file->get_lineno(), arg_str);
		error_count++;

	} else {
		printf("WARNING line %d %s\n", 
		    EDIF_FILE::current_file->get_lineno(), arg_str);
		warning_count++;
	}
	return RC_FAILED;
}


//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

ANNOTATE_EXPR::ANNOTATE_EXPR()
    : stringvalue(NULL), stringdisplay(NULL)
{
}

ListOfANNOTATE_EXPR::ListOfANNOTATE_EXPR(
    ANNOTATE_EXPR *arg_expr, ListOfANNOTATE_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

rc_t
ANNOTATE_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	// stringValue or stringDisplay
	if (t->get_type() == STRING) {
		stringvalue = t->get_string();

	} else if (t->get_type() == LPAR) {
		delete t;
		t = ef->read_token();
		if (t->get_type() == KW_STRINGDISPLAY) {
			stringdisplay = new STRINGDISPLAY_EXPR();

///			...if (stringdisplay->read_in(arg_namescope) != RC_NOMINAL)
///			...	return RC_FAILED;
			stringdisplay->read_in(arg_namescope);

		}
	} else {

///		...return pe(1, "annotate expr: expected string or stringDispaly");
		pe(1, "annotate expr: expected string or stringDispaly");
		delete t;
		ef->skip_expr();
		return RC_FAILED;

	}
	delete t;
	
	t = ef->read_token();
	if (t->get_type() != RPAR) {

///		...return pe(1, "annotate expr: junk at the end\n");
		pe(1, "annotate expr: junk at the end\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;

	}

	return RC_NOMINAL;
}

void
ANNOTATE_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(annotate\n");
	printf("%s", print_line);

	if (stringvalue != NULL) {
		sprintf(p, "  stringvalue\n");
		printf("%s", print_line);
	}

	if (stringdisplay != NULL) {
		stringdisplay->print(arg_indent + 1);
	}

	sprintf(p, ")\n");
	printf("%s", print_line);

}

///////////////////////////////////////////////////////

ARC_EXPR::ARC_EXPR()
{
}

rc_t
ARC_EXPR::read_in(NAMESCOPE * arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// pt1
	TOKEN *t = ef->read_token();
	if (t->get_type() != LPAR) {

///		return pe(1, "arc expr: expected pt1");
		pe(1, "arc expr: expected pt1");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_PT) {
		pe(1, "arc expr: expected pt1");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}


	pt1 = new PT_EXPR();
	pt1->read_in(arg_namescope);
	delete t;
	
	// pt2
	t = ef->read_token();
	if (t->get_type() != LPAR) {
		pe(1, "arc expr: expected pt2");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_PT) {
		pe(1, "arc expr: expected pt2");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	pt2 = new PT_EXPR();
	pt2->read_in(arg_namescope);
	delete t;
	
	// pt3
	t = ef->read_token();
	if (t->get_type() != LPAR)  {
		pe(1, "arc expr: expected pt3");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_PT) {
		pe(1, "arc expr: expected pt3");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	pt3 = new PT_EXPR();
	pt3->read_in(arg_namescope);
	delete t;
	
	t = ef->read_token();
	if (t->get_type() != RPAR)  {
		pe(1, "arc expr: junk at end\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	return RC_NOMINAL;
}

void
ARC_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(arc\n");
	printf("%s", print_line);

	pt1->print(arg_indent + 1);
	pt2->print(arg_indent + 1);
	pt3->print(arg_indent + 1);

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfARC_EXPR::ListOfARC_EXPR(
    ARC_EXPR *arg_expr, ListOfARC_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

BOUNDINGBOX_EXPR::BOUNDINGBOX_EXPR()
{
}

rc_t
BOUNDINGBOX_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	// rectangle
	if (t->get_type() != LPAR)  {
		pe(1, "boundingbox expr: expected rectangle");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;
	t = ef->read_token();
	if (t->get_type() != KW_RECTANGLE)  {
		pe(1, "boundingbox expr: expected rectangle");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	rectangle = new RECTANGLE_EXPR();
	rectangle->read_in(arg_namescope);
	delete t;
	
	t = ef->read_token();
	if (t->get_type() != RPAR)  {
		pe(1, "boundingbox expr: junk at the end\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	return RC_NOMINAL;
}

void
BOUNDINGBOX_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(boundingbox\n");
	printf("%s", print_line);

	if (rectangle != NULL) {
		rectangle->print(arg_indent + 1);
	}

	sprintf(p, ")\n");
	printf("%s", print_line);

}

///////////////////////////////////////////////////////

CELL_EXPR::CELL_EXPR()
{
}

rc_t
CELL_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// namedef
	namedef = new NAMEDEF(CELL_NAMECLASS, this);
	namedef->read_in(arg_namescope);

	if (!SUE::SUPPRESS_PROGRESS_MESSAGES)
		printf("...reading cell \"%s\"\n", namedef->get_stringvalue());
	
	rc_t rc = arg_namescope->insert(namedef);
	if (rc != RC_NOMINAL) {
		pe(1, "cell expr: cell name in use\n");
	}
	namescope = new NAMESCOPE(arg_namescope, KW_CELL, this);

	// cellType
	TOKEN *t = ef->read_token();
	if (t->get_type() != LPAR) {
		pe(1, "cell expr: expected cellType");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_CELLTYPE) {
		pe(1, "cell expr: expected cellType");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != STRING)  {
		pe(1, "cellType expr: expected cellType");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	char *tname = t->get_string();
	if	(strcmp(tname, "GENERIC") == 0) celltype = GENERIC;
	else if (strcmp(tname, "TIE") == 0)	   celltype = TIE;
	else if (strcmp(tname, "RIPPER") == 0)  celltype = RIPPER;
	else  {
		pe(1, "cellType expr: don\' recongize type\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete tname;
	delete t;

	t = ef->read_token();
	if (t->get_type() != RPAR) {
		pe(1, "cellType expr: junk at the end\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	// lists of things
	status = NULL;
	viewmap = NULL;
	view_list = NULL;
	property_list = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "cell expr: expected expression");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_STATUS: {
			if (status != NULL)
			    pe(0, "cell expr: additional status? ignore it..."); 
			status++;
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_VIEWMAP: {
			if (status != NULL)
			    pe(0, "cell expr: additional viewMap? ignore it..."); 
			viewmap++;
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_VIEW: {
			VIEW_EXPR *view_expr = new VIEW_EXPR();
			view_expr->read_in(namescope);
			view_list = new ListOfVIEW_EXPR(
			    view_expr, view_list);
		    } break;

		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(namescope);
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default: {
			pe(1, "cell expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    } break;
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
CELL_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(cell\n");
	printf("%s", print_line);

	namedef->print(arg_indent + 1);

	switch (celltype) {
	    case GENERIC:	
		sprintf(p, "  (cellType GENERIC)\n");	
		break;
	    case TIE:
		sprintf(p, "  (cellType TIE)\n");
		break;
	    case RIPPER:
		sprintf(p, "  (cellType RIPPER)\n");
		break;
	    default:
		sprintf(p, "  (cellType <unknown>)\n");
		break;
	}
	printf("%s", print_line);

	ListOfVIEW_EXPR *tview_list = view_list;
	while (tview_list != NULL) {
		tview_list->expr->print(arg_indent + 1);
		tview_list = tview_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);

}

ListOfCELL_EXPR::ListOfCELL_EXPR(
    CELL_EXPR *arg_expr, ListOfCELL_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

CELLREF_EXPR::CELLREF_EXPR()
{
}

rc_t
CELLREF_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// nameRef
	cellnameref = new NAMEREF(CELL_NAMECLASS);
	if (cellnameref->read_in(arg_namescope) != RC_NOMINAL) {
	    pe(1, "cellref: expected name\n");
	    ef->skip_expr();
	    return RC_FAILED;
	   }
	// don't do lookup now


	// maybe library ref
	libraryref = NULL;
	TOKEN *t = ef->read_token();
	if (t->get_type() == LPAR) {
		delete t;

		t = ef->read_token();
		if (t->get_type() != KW_LIBRARYREF) {
			pe(1, "cellref expr: expected libraryref");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}

		libraryref = new LIBRARYREF_EXPR();
		libraryref->read_in(arg_namescope);

		delete t;
		t = ef->read_token();
	}
	if (t->get_type() != RPAR)  {
		pe(1, "cellref expr: junk at end\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	// now resolve the name
	// if there is no libraryref, then resolve the cell locally
	if (libraryref == NULL) {
		cellnamedef = arg_namescope->lookup(cellnameref);
		if (cellnamedef == NULL) {
			pe(1, "cellref expr: can't lookup cellref locally");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}

	} else {
		LIBRARY_EXPR *library = NULL;
		libraryref->librarynamedef->get_where_defined(&library);
		if (library == NULL)  {
			pe(1, "cellref expr: get_where_defined failed\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}

		cellnamedef = library->namescope->lookup(cellnameref);
		if (cellnamedef == NULL)  {
			pe(1, "cellref expr: get_where_defined failed\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
	}
	
	return RC_NOMINAL;
}

void
CELLREF_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(cellref\n");
	printf("%s", print_line);

	sprintf(p, "  %s\n", cellnameref->get_identifier());
	printf("%s", print_line);

	if (libraryref != NULL) {
		libraryref->print(arg_indent + 1);
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

 ///////////////////////////////////////////////////////

CIRCLE_EXPR::CIRCLE_EXPR()
{
}

rc_t
CIRCLE_EXPR::read_in(NAMESCOPE * arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// pt1
	TOKEN *t = ef->read_token();
	if (t->get_type() != LPAR)  {
		pe(1, "circle expr: expected pt1");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_PT) {
		pe(1, "circle expr: expected pt1");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	pt1 = new PT_EXPR();
	pt1->read_in(arg_namescope);
	delete t;
	
	// pt2
	t = ef->read_token();
	if (t->get_type() != LPAR)  {
		pe(1, "circle expr: expected pt1");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_PT) {
		pe(1, "circle expr: expected pt1");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	pt2 = new PT_EXPR();
	pt2->read_in(arg_namescope);
	delete t;
	
	// lists of things
	property_list = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR)  {
			pe(1, "circle expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(arg_namescope);
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    default: {
			pe(1, "circle expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    } break;
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
CIRCLE_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(circle\n");
	printf("%s", print_line);

	pt1->print(arg_indent + 1);
	pt2->print(arg_indent + 1);

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfCIRCLE_EXPR::ListOfCIRCLE_EXPR(
    CIRCLE_EXPR *arg_expr, ListOfCIRCLE_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

COMMENTGRAPHICS_EXPR::COMMENTGRAPHICS_EXPR()
{
}

rc_t
COMMENTGRAPHICS_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	// lists of things
	boundingbox = NULL;
	annotate_list = NULL;
	figure_list = NULL;
	instance_list = NULL;
	property_list = NULL;
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "commentgraphics expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {

		    case KW_BOUNDINGBOX: {
			if (boundingbox)
				pe(1, "commentgraphics expr:additional boundingbox? ignore it\n");
			boundingbox = new BOUNDINGBOX_EXPR();
			boundingbox->read_in(arg_namescope);
		    } break;

		    case KW_ANNOTATE: {
			ANNOTATE_EXPR *annotate_expr = new ANNOTATE_EXPR();
			annotate_expr->read_in(arg_namescope);
			annotate_list = new ListOfANNOTATE_EXPR(
			    annotate_expr, annotate_list);
		    } break;

		    case KW_FIGURE: {
			FIGURE_EXPR *figure_expr = new FIGURE_EXPR();
			figure_expr->read_in(arg_namescope);
			figure_list = new ListOfFIGURE_EXPR(
			    figure_expr, figure_list);
		    } break;

		    case KW_INSTANCE: {
			INSTANCE_EXPR *instance_expr = new INSTANCE_EXPR();
			instance_expr->read_in(arg_namescope);
			instance_list = new ListOfINSTANCE_EXPR(
			    instance_expr, instance_list);
		    } break;

		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(arg_namescope);
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default: {
			pe(1, "commentgraphics expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    } break;
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
COMMENTGRAPHICS_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(commentgraphics\n");
	printf("%s", print_line);

	if (boundingbox != NULL) {
		boundingbox->print(arg_indent + 1);
	}

	ListOfANNOTATE_EXPR *tannotate_list = annotate_list;
	while (tannotate_list != NULL) {
		tannotate_list->expr->print(arg_indent + 1);
		tannotate_list = tannotate_list->next;
	}

	ListOfFIGURE_EXPR *tfigure_list = figure_list;
	while (tfigure_list != NULL) {
		tfigure_list->expr->print(arg_indent + 1);
		tfigure_list = tfigure_list->next;
	}

	ListOfINSTANCE_EXPR *tinstance_list = instance_list;
	while (tinstance_list != NULL) {
		tinstance_list->expr->print(arg_indent + 1);
		tinstance_list = tinstance_list->next;
	}

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfCOMMENTGRAPHICS_EXPR::ListOfCOMMENTGRAPHICS_EXPR(
    COMMENTGRAPHICS_EXPR *arg_expr, ListOfCOMMENTGRAPHICS_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}


///////////////////////////////////////////////////////

CONNECTLOCATION_EXPR::CONNECTLOCATION_EXPR()
{
}

rc_t
CONNECTLOCATION_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	// lists of things
	figure_list = NULL;
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR)  {
			pe(1, "connectlocation expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_FIGURE: {
			FIGURE_EXPR *figure_expr = new FIGURE_EXPR();
			figure_expr->read_in(arg_namescope);
			figure_list = new ListOfFIGURE_EXPR(
			    figure_expr, figure_list);
		    } break;

		    default: {
			pe(1, "connectlocation expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    } break;
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
CONNECTLOCATION_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(connectlocation\n");
	printf("%s", print_line);

	ListOfFIGURE_EXPR *tfigure_list = figure_list;
	while (tfigure_list != NULL) {
		tfigure_list->expr->print(arg_indent + 1);
		tfigure_list = tfigure_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfCONNECTLOCATION_EXPR::ListOfCONNECTLOCATION_EXPR(
    CONNECTLOCATION_EXPR *arg_expr, ListOfCONNECTLOCATION_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}


///////////////////////////////////////////////////////

CONTENTS_EXPR::CONTENTS_EXPR()
{
}

rc_t
CONTENTS_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	// lists of things
	boundingbox = NULL;
	instance_list = NULL;
	figure_list = NULL;
	net_list = NULL;
	page_list = NULL;
	commentgraphics_list = NULL;
	portimplementation_list = NULL;
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "contents expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_BOUNDINGBOX: {
			if (boundingbox)
				pe(1, "contents_expr: additional boundingbox? ignore it\n");
			boundingbox = new BOUNDINGBOX_EXPR();
			boundingbox->read_in(arg_namescope);
		    } break;

		    case KW_OFFPAGECONNECTOR: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_SECTION: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_NETBUNDLE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_TIMING: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_SIMULATE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_WHEN: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_FOLLOW: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_LOGICPORT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_INSTANCE: {
			INSTANCE_EXPR *instance_expr = new INSTANCE_EXPR();
			instance_expr->read_in(arg_namescope);
			instance_list = new ListOfINSTANCE_EXPR(
			    instance_expr, instance_list);
		    } break;

		    case KW_FIGURE: {
			FIGURE_EXPR *figure_expr = new FIGURE_EXPR();
			figure_expr->read_in(arg_namescope);
			figure_list = new ListOfFIGURE_EXPR(
			    figure_expr, figure_list);
		    } break;

		    case KW_NET: {
			NET_EXPR *net_expr = new NET_EXPR();
			net_expr->read_in(arg_namescope);
			net_list = new ListOfNET_EXPR(
			    net_expr, net_list);
		    } break;

		    case KW_PAGE: {
			PAGE_EXPR *page_expr = new PAGE_EXPR();
			page_expr->read_in(arg_namescope);
			page_list = new ListOfPAGE_EXPR(
			    page_expr, page_list);
		    } break;

		    case KW_COMMENTGRAPHICS: {
			COMMENTGRAPHICS_EXPR *commentgraphics_expr = new COMMENTGRAPHICS_EXPR();
			commentgraphics_expr->read_in(arg_namescope);
			commentgraphics_list = new ListOfCOMMENTGRAPHICS_EXPR(
			    commentgraphics_expr, commentgraphics_list);
		    } break;

		    case KW_PORTIMPLEMENTATION: {
			PORTIMPLEMENTATION_EXPR *portimplementation_expr = new PORTIMPLEMENTATION_EXPR();
			portimplementation_expr->read_in(arg_namescope);
			portimplementation_list = new ListOfPORTIMPLEMENTATION_EXPR(
			    portimplementation_expr, portimplementation_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default:  {
			pe(1, "contents expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    }
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
CONTENTS_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(contents\n");
	printf("%s", print_line);

	if (boundingbox != NULL)	boundingbox->print(arg_indent + 1);

	ListOfINSTANCE_EXPR *tinstance_list = instance_list;
	while (tinstance_list != NULL) {
		tinstance_list->expr->print(arg_indent + 1);
		tinstance_list = tinstance_list->next;
	}

	ListOfFIGURE_EXPR *tfigure_list = figure_list;
	while (tfigure_list != NULL) {
		tfigure_list->expr->print(arg_indent + 1);
		tfigure_list = tfigure_list->next;
	}

	ListOfNET_EXPR *tnet_list = net_list;
	while (tnet_list != NULL) {
		tnet_list->expr->print(arg_indent + 1);
		tnet_list = tnet_list->next;
	}

	ListOfPAGE_EXPR *tpage_list = page_list;
	while (tpage_list != NULL) {
		tpage_list->expr->print(arg_indent + 1);
		tpage_list = tpage_list->next;
	}

	ListOfCOMMENTGRAPHICS_EXPR *tcommentgraphics_list = commentgraphics_list;
	while (tcommentgraphics_list != NULL) {
		tcommentgraphics_list->expr->print(arg_indent + 1);
		tcommentgraphics_list = tcommentgraphics_list->next;
	}

	ListOfPORTIMPLEMENTATION_EXPR *tportimplementation_list = portimplementation_list;
	while (tportimplementation_list != NULL) {
		tportimplementation_list->expr->print(arg_indent + 1);
		tportimplementation_list = tportimplementation_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

///////////////////////////////////////////////////////

CURVE_ELEMENT::CURVE_ELEMENT(PT_EXPR *arg_pt)
    : pt(arg_pt), arc(NULL), next(NULL)
{
}	

CURVE_ELEMENT::CURVE_ELEMENT(ARC_EXPR *arg_arc)
    : pt(NULL), arc(arg_arc), next(NULL)
{
}	

CURVE_EXPR::CURVE_EXPR()
{
}

rc_t
CURVE_EXPR::read_in(NAMESCOPE * arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// an *ordered* list of elements
	// the first elemement

	element_list = NULL;
	TOKEN *t = ef->read_token();
	if (t->get_type() == RPAR) {
		// an empty list would appear syntactically correct,
		// though silly
		delete t;
		return RC_NOMINAL;
	}
	if (t->get_type() != LPAR)  {
		pe(1, "curve expr: expected expression\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	switch (t->get_type()) {
	    case KW_ARC: {
		ARC_EXPR *arc_expr = new ARC_EXPR();
		arc_expr->read_in(arg_namescope);
		element_list = new CURVE_ELEMENT(arc_expr);
	    } break;

	    case KW_PT: {
		PT_EXPR *pt_expr = new PT_EXPR();
		pt_expr->read_in(arg_namescope);
		element_list = new CURVE_ELEMENT(pt_expr);
	    } break;

	    default:  {
		pe(1, "curve expr: illegal expression type\n"); 
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	}
	delete t;
	CURVE_ELEMENT *last_element = element_list;

	t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR)  {
			pe(1, "curve expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		t = ef->read_token();
		CURVE_ELEMENT *new_element = NULL;
		
		switch (t->get_type()) {
		    case KW_ARC: {
			ARC_EXPR *arc_expr = new ARC_EXPR();
			arc_expr->read_in(arg_namescope);
			new_element = new CURVE_ELEMENT(arc_expr);
		    } break;
	
		    case KW_PT: {
			PT_EXPR *pt_expr = new PT_EXPR();
			pt_expr->read_in(arg_namescope);
			new_element = new CURVE_ELEMENT(pt_expr);
		    } break;

		    default:  {
			pe(1, "curve expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		}

		last_element->next = new_element;
		last_element = new_element;

		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
CURVE_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(curve\n");
	printf("%s", print_line);

	CURVE_ELEMENT *telement_list = element_list;
	while (telement_list != NULL) {

		if (telement_list->pt != NULL)
			telement_list->pt->print(arg_indent + 1);
		if (telement_list->arc != NULL)
			telement_list->arc->print(arg_indent + 1);

		telement_list = telement_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfCURVE_EXPR::ListOfCURVE_EXPR(
    CURVE_EXPR *arg_expr, ListOfCURVE_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

DISPLAY_EXPR::DISPLAY_EXPR()
	: justify(LOWERLEFT), orientation(R0), origin(NULL)
{
}

rc_t
DISPLAY_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	// nameRef
	if (t->get_type() != LPAR) {
		// string literal
		nameref = new NAMEREF(FIGUREGROUP_NAMECLASS);
		nameref->identifier = t->get_string();
		nameref->name = NULL;
		figuregroupoverride = NULL;

	} else {
		// expression
		delete t;
		t = ef->read_token();

		if (t->get_type() == KW_NAME) {
			nameref->identifier = NULL;
			nameref = new NAMEREF(FIGUREGROUP_NAMECLASS);
			nameref->name->read_in(arg_namescope);
			figuregroupoverride = NULL;

		} else if (t->get_type() == KW_FIGUREGROUPOVERRIDE) {
			figuregroupoverride = 
			    new FIGUREGROUPOVERRIDE_EXPR();
			figuregroupoverride->read_in(arg_namescope);
			nameref = NULL;
		} else {
			pe(1, "figure expr: expected figureGroupOverride\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
	}
	delete t;

	// lookup nameRef, if there was one
	if (nameref != NULL) {
		namedef = arg_namescope->lookup(nameref);
		if (namedef == NULL) {
			pe(1, "display expr: can't lookup name\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
	}

	t = ef->read_token();
	// remaining paramters are optional
	if (t->get_type() == RPAR) return RC_NOMINAL;

	if (t->get_type() != LPAR) {
		pe(1, "display expr: expected expression");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;
	t = ef->read_token();

	// justify
	justify = JUSTIFY_NOT_SPECIFIED;
	if (t->get_type() == KW_JUSTIFY) {
		delete t;
		t = ef->read_token();
		if (t->get_type() != STRING)  {
			pe(1, "justify expr: expected string");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}

		char *tstring = t->get_string();
		if (strcmp(tstring, "UPPERLEFT") == 0) justify = UPPERLEFT;
		else if (strcmp(tstring, "UPPERCENTER") == 0) justify = UPPERCENTER;
		else if (strcmp(tstring, "UPPERRIGHT") == 0) justify = UPPERRIGHT;
		else if (strcmp(tstring, "CENTERLEFT") == 0) justify = CENTERLEFT;
		else if (strcmp(tstring, "CENTERCENTER") == 0) justify = CENTERCENTER;
		else if (strcmp(tstring, "CENTERRIGHT") == 0) justify = CENTERRIGHT;
		else if (strcmp(tstring, "LOWERLEFT") == 0) justify = LOWERLEFT;
		else if (strcmp(tstring, "LOWERCENTER") == 0) justify = LOWERCENTER;
		else if (strcmp(tstring, "LOWERRIGHT") == 0) justify = LOWERRIGHT;
		else  {
			pe(1, "justify expr: don\'t recognize type");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete tstring;
		delete t;	

		t = ef->read_token();
		if (t->get_type() != RPAR) {
			pe(1, "display justify expr: junk at end");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		t = ef->read_token();
		if (t->get_type() == RPAR) return RC_NOMINAL;
		if (t->get_type() != LPAR) {
			pe(1, "display expr: expected expression");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
		t = ef->read_token();
	}

	orientation = ORIENTATION_NOT_SPECIFIED;
	if (t->get_type() == KW_ORIENTATION) {
		delete t;
		t = ef->read_token();
		if (t->get_type() != STRING)  {
			pe(1, "orientation expr: expected string");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		char *tstring = t->get_string();
		if (strcmp(tstring, "R0") == 0) orientation = R0;
		else if (strcmp(tstring, "R90") == 0) orientation = R90;
		else if (strcmp(tstring, "R180") == 0) orientation = R180;
		else if (strcmp(tstring, "R270") == 0) orientation = R270;
		else if (strcmp(tstring, "MX") == 0) orientation = MX;
		else if (strcmp(tstring, "MY") == 0) orientation = MY;
		else if (strcmp(tstring, "MYR90") == 0) orientation = MYR90;
		else if (strcmp(tstring, "MXR90") == 0) orientation = MXR90;
		else  {
			pe(1, "orientation expr: don\'t recognize type");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete tstring;
		delete t;	

		t = ef->read_token();
		if (t->get_type() != RPAR) {
			pe(1, "display orientation expr: junk at end");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		t = ef->read_token();
		if (t->get_type() == RPAR) return RC_NOMINAL;
		if (t->get_type() != LPAR) {
			pe(1, "display expr: expected expression");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
		t = ef->read_token();
	}

	origin = NULL;
	if (t->get_type() == KW_ORIGIN) {
		delete t;
		origin = new ORIGIN_EXPR();
		origin->read_in(arg_namescope);

		t = ef->read_token();
		if (t->get_type() == RPAR) {
			delete t;
			return RC_NOMINAL;
		}
		else  {
			pe(1, "display expr: unexpected expr");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
	} 
	pe(1, "display expr: unexpected expr");
	delete t;
	ef->skip_expr();
	return RC_FAILED;
}

void
DISPLAY_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(display\n");
	printf("%s", print_line);

	if (figuregroupoverride != NULL) {
		figuregroupoverride->print(arg_indent + 1);
	}

	switch (justify) {
	    case UPPERLEFT:
		sprintf(p, "(justify UPPERLEFT)\n");
		break;
	    case UPPERCENTER:
		sprintf(p, "(justify UPPERCENTER)\n");
		break;
	    case UPPERRIGHT:
		sprintf(p, "(justify UPPERRIGHT)\n");
		break;
	    case CENTERLEFT:
		sprintf(p, "(justify CENTERLEFT)\n");
		break;
	    case CENTERCENTER:
		sprintf(p, "(justify CENTERCENTER)\n");
		break;
	    case CENTERRIGHT:
		sprintf(p, "(justify CENTERRIGHT)\n");
		break;
	    case LOWERLEFT:
		sprintf(p, "(justify LOWERLEFT)\n");
		break;
	    case LOWERCENTER:
		sprintf(p, "(justify LOWERCENTER)\n");
		break;
	    case LOWERRIGHT:
		sprintf(p, "(justify LOWERRIGHT)\n");
		break;
	    default:
		sprintf(p, "(justify <unknown>)\n");
		break;
	}
	printf("%s", print_line);

	switch (orientation) {
	    case R0:
		sprintf(p, "(orientation R0)\n");
		break;
	    case R90:
		sprintf(p, "(orientation R90)\n");
		break;
	    case R180:
		sprintf(p, "(orientation R180)\n");
		break;
	    case R270:
		sprintf(p, "(orientation R270)\n");
		break;
	    case MX:
		sprintf(p, "(orientation MX)\n");
		break;
	    case MY:
		sprintf(p, "(orientation MY)\n");
		break;
	    case MXR90:
		sprintf(p, "(orientation MXR90)\n");
		break;
	    case MYR90:
		sprintf(p, "(orientation MYR90)\n");
		break;
	    default:
		sprintf(p, "(orientation <unknown>)\n");
		break;
	}
	printf("%s", print_line);

	if (origin != NULL) {
		origin->print(arg_indent + 1);
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfDISPLAY_EXPR::ListOfDISPLAY_EXPR(
    DISPLAY_EXPR *arg_expr, ListOfDISPLAY_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

DOT_EXPR::DOT_EXPR()
{
}

rc_t
DOT_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	// pointvalue
	if (t->get_type() != LPAR) {
		pe(1, "dot expr: expected pt");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;
	t = ef->read_token();
	if (t->get_type() != KW_PT) {
		pe(1, "dot expr: expected pt");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	pt = new PT_EXPR();
	pt->read_in(arg_namescope);
	delete t;
	
	// lists of things
	property_list = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR)  {
			pe(1, "dot expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(arg_namescope);
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    default:  {
			pe(1, "contents expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    }
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
DOT_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(dot\n");
	printf("%s", print_line);

	if (pt != NULL) {
		pt->print(arg_indent + 1);
	}

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfDOT_EXPR::ListOfDOT_EXPR(
    DOT_EXPR *arg_expr, ListOfDOT_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

EDIF_EXPR::EDIF_EXPR()
{
}

rc_t
EDIF_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// name
	namedef = new NAMEDEF(EDIF_NAMECLASS, this);
	if (namedef->read_in(arg_namescope) != RC_NOMINAL ) {
	    pe(1, "edif expr: expected nameDef\n");
	    ef->skip_expr();
	    return RC_FAILED;
	   }
	if (!SUE::SUPPRESS_PROGRESS_MESSAGES)
		printf("...reading edif \"%s\"\n", namedef->get_stringvalue());

	namescope = new NAMESCOPE(NULL, KW_EDIF, this);
	// there isn't any enclosing namespace, so let's just
	// put the local nameDef in the local namescope
	namescope->insert(namedef);

	// version
	TOKEN *t = ef->read_token();
	if (t->get_type() != LPAR) {
	    pe(1, "edif expr: expected edifVersion expr\n"); 
	    delete t;
	    ef->skip_expr();
	    return RC_FAILED;
	   }
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_EDIFVERSION) {
	    pe(1, "edif expr: expected edifVersion expr\n"); 
	    delete t;
	    ef->skip_expr();
	    return RC_FAILED;
	   }
	delete t;
	// NOT IMPLEMENTED
	ef->skip_expr();
	
	// level
	t = ef->read_token();
	if (t->get_type() != LPAR) {
	    pe(1, "edif expr: expected edifLevel\n"); 
	    delete t;
	    ef->skip_expr();
	    return RC_FAILED;
	   }
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_EDIFLEVEL) {
	    pe(1, "edif expr: expected edifLevel\n"); 
	    delete t;
	    ef->skip_expr();
	    return RC_FAILED;
	   }
	// NOT IMPLEMENTED
	ef->skip_expr();
	delete t;
	
	// keyword map
	t = ef->read_token();
	if (t->get_type() != LPAR) {
	    pe(1, "edif expr: expected keywordMap\n"); 
	    delete t;
	    ef->skip_expr();
	    return RC_FAILED;
	   }
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_KEYWORDMAP) {
	    pe(1, "edif expr: expected keywordMap\n"); 
	    delete t;
	    ef->skip_expr();
	    return RC_FAILED;
	   }
	// NOT IMPLEMENTED
	ef->skip_expr();
	delete t;
	
	// lists of things
	status = NULL;
	library_list = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {

		if (t->get_type() != LPAR) {
		    pe(1, "edif expr: expected expression\n"); 
		    delete t;
		    ef->skip_expr();
		    return RC_FAILED;
		   }
		delete t;
		t = ef->read_token();

		switch (t->get_type()) {
		    case KW_STATUS: {
			if (status != NULL)
			    pe(1, "edif expr: additional status? ignore it...\n"); 
			status++;
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_EXTERNAL: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_LIBRARY: {
			LIBRARY_EXPR *library_expr = new LIBRARY_EXPR();
			library_expr->read_in(namescope);
			library_list = new ListOfLIBRARY_EXPR(
			    library_expr, library_list);
		    } break;

		    case KW_DESIGN: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default: {
			pe(1, "edif expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    } break;
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
EDIF_EXPR::print(int arg_indent)
{
	// BUG... need to worry more about overrunning the print_line
	//	(for all the print methods)
	// BUG... should write to a FILE

	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(edif\n");
	printf("%s", print_line);
	namedef->print(arg_indent + 1);

	if (status != NULL) {
		sprintf(p, "  (status ...)\n");
		printf("%s", print_line);
	}

	ListOfLIBRARY_EXPR *t_lib_list = library_list;
	while (t_lib_list != NULL) {
		t_lib_list->expr->print(arg_indent + 1);
		t_lib_list = t_lib_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

///////////////////////////////////////////////////////

FIGURE_EXPR::FIGURE_EXPR()
{
}

rc_t
FIGURE_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	// nameRef or figureGroupOverride
	if (t->get_type() != LPAR) {
		// string literal
		nameref = new NAMEREF(FIGUREGROUP_NAMECLASS);
		nameref->identifier = t->get_string();
		nameref->name = NULL;
		figuregroupoverride = NULL;

	} else {
		// expression
		delete t;
		t = ef->read_token();

		if (t->get_type() == KW_NAME) {
			nameref->identifier = NULL;
			nameref = new NAMEREF(FIGUREGROUP_NAMECLASS);
			nameref->name->read_in(arg_namescope);
			figuregroupoverride = NULL;

		} else if (t->get_type() == KW_FIGUREGROUPOVERRIDE) {
			figuregroupoverride = 
			    new FIGUREGROUPOVERRIDE_EXPR();
			figuregroupoverride->read_in(arg_namescope);
			nameref = NULL;
		} else {
			pe(1, "figure expr: expected figureGroupOverride\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
	}
	delete t;

	// lookup nameRef, if there was one
	if (nameref != NULL) {
		namedef = arg_namescope->lookup(nameref);
		if (namedef == NULL) {
			pe(1, "figure expr: can't lookup name\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
	}

	// lists of things
	circle_list = NULL;
	dot_list = NULL;
	openshape_list = NULL;
	path_list = NULL;
	polygon_list = NULL;
	rectangle_list = NULL;
	shape_list = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "figure expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_SHAPE: {
			// NOT IMPLEMENTED
			printf("WARNING: shape in figure_expr NOT IMPLEMENTED\n");
			ef->skip_expr();
		    } break;

		    case KW_CIRCLE: {
			CIRCLE_EXPR *circle_expr = new CIRCLE_EXPR();
			circle_expr->read_in(arg_namescope);
			circle_list = new ListOfCIRCLE_EXPR(
			    circle_expr, circle_list);
		    } break;

		    case KW_DOT: {
			DOT_EXPR *dot_expr = new DOT_EXPR();
			dot_expr->read_in(arg_namescope);
			dot_list = new ListOfDOT_EXPR(
			    dot_expr, dot_list);
		    } break;

		    case KW_OPENSHAPE: {
			OPENSHAPE_EXPR *openshape_expr = new OPENSHAPE_EXPR();
			openshape_expr->read_in(arg_namescope);
			openshape_list = new ListOfOPENSHAPE_EXPR(
			    openshape_expr, openshape_list);
		    } break;

		    case KW_PATH: {
			PATH_EXPR *path_expr = new PATH_EXPR();
			path_expr->read_in(arg_namescope);
			path_list = new ListOfPATH_EXPR(
			    path_expr, path_list);
		    } break;

		    case KW_POLYGON: {
			POLYGON_EXPR *polygon_expr = new POLYGON_EXPR();
			polygon_expr->read_in(arg_namescope);
			polygon_list = new ListOfPOLYGON_EXPR(
			    polygon_expr, polygon_list);
		    } break;

		    case KW_RECTANGLE: {
			RECTANGLE_EXPR *rectangle_expr = new RECTANGLE_EXPR();
			rectangle_expr->read_in(arg_namescope);
			rectangle_list = new ListOfRECTANGLE_EXPR(
			    rectangle_expr, rectangle_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default: {
			pe(1, "figure expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    } break;
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
FIGURE_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(figure\n");
	printf("%s", print_line);

	if (nameref != NULL)
		nameref->print(arg_indent + 1);

	if (figuregroupoverride != NULL)
		figuregroupoverride->print(arg_indent + 1);

	ListOfDOT_EXPR *tdot_list = dot_list;
	while (tdot_list != NULL) {
		tdot_list->expr->print(arg_indent + 1);
		tdot_list = tdot_list->next;
	}

	ListOfPATH_EXPR *tpath_list = path_list;
	while (tpath_list != NULL) {
		tpath_list->expr->print(arg_indent + 1);
		tpath_list = tpath_list->next;
	}

	ListOfPOLYGON_EXPR *tpolygon_list = polygon_list;
	while (tpolygon_list != NULL) {
		tpolygon_list->expr->print(arg_indent + 1);
		tpolygon_list = tpolygon_list->next;
	}

	ListOfRECTANGLE_EXPR *trectangle_list = rectangle_list;
	while (trectangle_list != NULL) {
		trectangle_list->expr->print(arg_indent + 1);
		trectangle_list = trectangle_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfFIGURE_EXPR::ListOfFIGURE_EXPR(
    FIGURE_EXPR *arg_expr, ListOfFIGURE_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

FIGUREGROUP_EXPR::FIGUREGROUP_EXPR()
{
}

rc_t
FIGUREGROUP_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// namedef
	namedef = new NAMEDEF(FIGUREGROUP_NAMECLASS, this);
	if (namedef->read_in(arg_namescope) != RC_NOMINAL) {
		pe(1, "figuregroup expr: expected namedef\n");
		ef->skip_expr();
		return RC_FAILED;
	}
	
	rc_t rc = arg_namescope->insert(namedef);
	if (rc != RC_NOMINAL) {
		pe(1, "cell expr: figuregroup name in use\n");
	}
	namescope = new NAMESCOPE(arg_namescope, KW_FIGUREGROUP, this);

	// lists of things
	property_list = NULL;
	textheight_valid = false;
	TOKEN *t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "figuregroup expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_TEXTHEIGHT: {
			delete t;
			t = ef->read_token();
			if (t->get_type() != INTEGER)  {
				pe(1, "textHeight expr: expected integer");
				delete t;
				ef->skip_expr();
				return RC_FAILED;
			}
			textheight = t->get_integer();
			delete t;
			t = ef->read_token();
			if (t->get_type() != RPAR) {
				pe(1, "textHeight expr: junk at end");
				delete t;
				ef->skip_expr();
				return RC_FAILED;
			}
			textheight_valid = true;
		    } break;

		    case KW_CORNERTYPE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_ENDTYPE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PATHWIDTH: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_BORDERWIDTH: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_COLOR: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_FILLPATTERN: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_BORDERPATTERN: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_VISIBLE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_INCLUDEFIGUREGROUP: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(namescope);

			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default: {
			pe(1, "figuregroup expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    } break;
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
FIGUREGROUP_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(figuregroup\n");
	printf("%s", print_line);

	if (textheight_valid) {
		sprintf(p, "  (textHeight %d)\n", textheight);
	}

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfFIGUREGROUP_EXPR::ListOfFIGUREGROUP_EXPR(
    FIGUREGROUP_EXPR *arg_expr, ListOfFIGUREGROUP_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

FIGUREGROUPOVERRIDE_EXPR::FIGUREGROUPOVERRIDE_EXPR()
{
}

rc_t
FIGUREGROUPOVERRIDE_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// nameRef
	nameref = new NAMEREF(FIGUREGROUP_NAMECLASS);
	if (nameref->read_in(arg_namescope) != RC_NOMINAL) {
	    pe(1, "figureGroupOverride expr: expected nameRef\n");
	    ef->skip_expr();
	    return RC_FAILED;
	   }

	namedef = arg_namescope->lookup(nameref);
	if (namedef == NULL) {
		pe(1, "figuregroupoverride expr: can't lookup name");
		ef->skip_expr();
		return RC_FAILED;
	}

	// lists of things
	property_list = NULL;
	textheight_valid = false;
	TOKEN *t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "figuregroupoverride expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_TEXTHEIGHT: {
			delete t;
			t = ef->read_token();
			if (t->get_type() != INTEGER)  {
				pe(1, "textHeight expr: expected integer");
				delete t;
				ef->skip_expr();
				return RC_FAILED;
			}
			textheight = t->get_integer();
			delete t;

			t = ef->read_token();
			if (t->get_type() != RPAR) {
				pe(1, "textHeight expr: junk at end");
				delete t;
				ef->skip_expr();
				return RC_FAILED;
			}
			textheight_valid = true;
		    } break;

		    case KW_CORNERTYPE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_ENDTYPE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PATHWIDTH: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_BORDERWIDTH: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_COLOR: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_FILLPATTERN: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_BORDERPATTERN: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_VISIBLE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(arg_namescope);
;
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default: {
			pe(1, "figuregroupoverride expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    } break;
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
FIGUREGROUPOVERRIDE_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(figuregroupoverride\n");
	printf("%s", print_line);

	nameref->print(arg_indent + 1);

	if (textheight_valid) {
		sprintf(p, "  (textHeight %d)\n", textheight);
	}

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfFIGUREGROUPOVERRIDE_EXPR::ListOfFIGUREGROUPOVERRIDE_EXPR(
    FIGUREGROUPOVERRIDE_EXPR *arg_expr, ListOfFIGUREGROUPOVERRIDE_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

INSTANCE_EXPR::INSTANCE_EXPR()
{
}

rc_t
INSTANCE_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// namedef
	namedef = new NAMEDEF(INSTANCE_NAMECLASS, this);
	if (namedef->read_in(arg_namescope) != RC_NOMINAL) {
		pe(1, "cell expr: expected namedef\n");
		ef->skip_expr();
		return RC_FAILED;
	}
	
	rc_t rc = arg_namescope->insert(namedef);
	if (rc != RC_NOMINAL) {
		pe(1, "instance expr: instance name in use\n");
	}
	namescope = new NAMESCOPE(arg_namescope, KW_INSTANCE, this);

	// lists of things
	transform = NULL;
	viewref = NULL;
	property_list = NULL;
	TOKEN *t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "instance expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_TRANSFORM: {
			if (transform)
				pe(1, "instance expr:additional transform? ignore it\n");
			transform = new TRANSFORM_EXPR();
			transform->read_in(namescope);
		    } break;

		    case KW_VIEWLIST: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_DESIGNATOR: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PARAMATERASSIGN: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PORTINSTANCE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_TIMING: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_VIEWREF: {
			if (viewref)
				pe(1, "instance expr: additional viewref? ignore it\n");
			viewref = new VIEWREF_EXPR();
			viewref->read_in(namescope);
		    } break;

		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(namescope);
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default: {
			pe(1, "instance expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    } break;
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
INSTANCE_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(instance\n");
	printf("%s", print_line);
	namedef->print(arg_indent + 1);

	if (viewref != NULL)	viewref->print(arg_indent + 1);

	if (transform != NULL)	transform->print(arg_indent + 1);

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfINSTANCE_EXPR::ListOfINSTANCE_EXPR(
    INSTANCE_EXPR *arg_expr, ListOfINSTANCE_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

INSTANCEREF_EXPR::INSTANCEREF_EXPR()
    : resolved_name(NULL)
{
}

INSTANCEREF_EXPR::~INSTANCEREF_EXPR()
{
	if (resolved_name != NULL) delete resolved_name;
}

rc_t
INSTANCEREF_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// nameRef
	instancenameref = new NAMEREF(INSTANCE_NAMECLASS);
	if (instancenameref->read_in(arg_namescope) != RC_NOMINAL) {
	    pe(1, "instanceref: expected name\n");
	    ef->skip_expr();
	    return RC_FAILED;
	   }
	// don't do lookup now

	// nested ref types not implemented here
	TOKEN *t = ef->read_token();
	if (t->get_type() != RPAR)  {
		pe(1, "instanceref expr: junk at end\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	// now resolve the name
	instancenamedef = arg_namescope->lookup(instancenameref);
	if (instancenamedef == NULL) {
		pe(1, "instanceref expr: can't lookup instance locally");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	resolved_name = instancenamedef->get_stringvalue();
	return RC_NOMINAL;
}

void
INSTANCEREF_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(instanceref\n");
	printf("%s", print_line);

	sprintf(p, "  %s\n", instancenameref->get_identifier());
	printf("%s", print_line);

	sprintf(p, ")\n");
	printf("%s", print_line);
}


///////////////////////////////////////////////////////

INTERFACE_EXPR::INTERFACE_EXPR()
{
}

rc_t
INTERFACE_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// lists of things
	symbol = NULL;
	port_list = NULL;
	property_list = NULL;
	TOKEN *t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR)  {
			pe(1, "INTERFACE expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_SYMBOL: {
			if (symbol)
				pe(1, "interface expr: additional symbol? ignore it\n");
			symbol = new SYMBOL_EXPR();
			symbol->read_in(arg_namescope);
		    } break;

		    case KW_PROTECTIONFRAME: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_ARRAYRELATEDINFO: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_DESIGNATOR: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PORTBUNDLE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PARAMETER: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_JOINED: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_MUSTJOIN: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_WEAKJOINED: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PERMUTABLE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_TIMING: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_SIMULATE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_CONSTANT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_CONSTRAINT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_VARIABLE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_ASSIGN: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_BLOCK: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_IF: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_ITERATE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_WHILE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PORT: {
			PORT_EXPR *port_expr = new PORT_EXPR();
			port_expr->read_in(arg_namescope);
			port_list = new ListOfPORT_EXPR(
			    port_expr, port_list);
		    } break;

		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(arg_namescope);
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default:  {
			pe(1, "INTERFACE expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    }
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
INTERFACE_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(interface\n");
	printf("%s", print_line);

	if (symbol != NULL) {
		symbol->print(arg_indent + 1);
	}

	ListOfPORT_EXPR *tport_list = port_list;
	while (tport_list != NULL) {
		tport_list->expr->print(arg_indent + 1);
		tport_list = tport_list->next;
	}

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfINTERFACE_EXPR::ListOfINTERFACE_EXPR(
    INTERFACE_EXPR *arg_expr, ListOfINTERFACE_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

JOINED_EXPR::JOINED_EXPR()
{
}

rc_t
JOINED_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// lists of things
	portref_list = NULL;
	TOKEN *t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR)  {
			pe(1, "joined expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_PORTREF: {
			PORTREF_EXPR *portref_expr = new PORTREF_EXPR();
			portref_expr->read_in(arg_namescope);
			portref_list = new ListOfPORTREF_EXPR(
			    portref_expr, portref_list);
		    } break;

		    default:  {
			pe(1, "joined expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    }
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
JOINED_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(joined\n");
	printf("%s", print_line);

	ListOfPORTREF_EXPR *tportref_list = portref_list;
	while (tportref_list != NULL) {
		tportref_list->expr->print(arg_indent + 1);
		tportref_list = tportref_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfJOINED_EXPR::ListOfJOINED_EXPR(
    JOINED_EXPR *arg_expr, ListOfJOINED_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

KEYWORDDISPLAY_EXPR::KEYWORDDISPLAY_EXPR()
{
}

rc_t
KEYWORDDISPLAY_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// nameRef
	nameref = new NAMEREF(KEYWORD_NAMECLASS);
	if (nameref->read_in(arg_namescope) != RC_NOMINAL) {
	    pe(1, "keyworddisplay expr: expected nameRef\n");
	    ef->skip_expr();
	    return RC_FAILED;
	   }

	namedef = arg_namescope->lookup(nameref);
	if (namedef == NULL) {
		pe(0, "keyworddisplay expr: can't lookup name\n");
	}

	// lists of things
	display_list = NULL;
	TOKEN *t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "keyworddisplay expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_DISPLAY: {
			DISPLAY_EXPR *display_expr = new DISPLAY_EXPR();
			display_expr->read_in(arg_namescope);
			display_list = new ListOfDISPLAY_EXPR(
			    display_expr, display_list);
		    } break;

		    default:  {
			pe(1, "keyworddisplay expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
KEYWORDDISPLAY_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(keyworddisplay\n");
	printf("%s", print_line);

	nameref->print(arg_indent + 1);

	ListOfDISPLAY_EXPR *tdisplay_list = display_list;
	while (tdisplay_list != NULL) {
		tdisplay_list->expr->print(arg_indent + 1);
		tdisplay_list = tdisplay_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfKEYWORDDISPLAY_EXPR::ListOfKEYWORDDISPLAY_EXPR(
    KEYWORDDISPLAY_EXPR *arg_expr, ListOfKEYWORDDISPLAY_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

LIBRARY_EXPR::LIBRARY_EXPR()
{
}

rc_t
LIBRARY_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// namedef
	namedef = new NAMEDEF(LIBRARY_NAMECLASS, this);
	if (namedef->read_in(arg_namescope) != RC_NOMINAL) {
		pe(1, "cell expr: expected namedef\n");
		ef->skip_expr();
		return RC_FAILED;
	}
	if (!SUE::SUPPRESS_PROGRESS_MESSAGES)
		printf("...reading library \"%s\"\n", namedef->get_stringvalue());
	
	rc_t rc = arg_namescope->insert(namedef);
	if (rc != RC_NOMINAL) {
		pe(1, "library expr: name in use\n");
	}
	namescope = new NAMESCOPE(arg_namescope, KW_LIBRARY, this);


	// level
	TOKEN *t = ef->read_token();
	if (t->get_type() != LPAR) {
	    pe(1, "library expr: expected edifLevel\n"); 
	    delete t;
	    ef->skip_expr();
	    return RC_FAILED;
	   }
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_EDIFLEVEL) {
	    pe(1, "library expr: expected edifLevel\n"); 
	    delete t;
	    ef->skip_expr();
	    return RC_FAILED;
	   }
	// NOT IMPLEMENTED
	ef->skip_expr();
	delete t;
	
	// technology
	t = ef->read_token();
	if (t->get_type() != LPAR) {
	    pe(1, "library expr: expected technology\n"); 
	    delete t;
	    ef->skip_expr();
	    return RC_FAILED;
	   }
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_TECHNOLOGY) {
	    pe(1, "library expr: expected edifLevel\n"); 
	    delete t;
	    ef->skip_expr();
	    return RC_FAILED;
	   }
	technology = new TECHNOLOGY_EXPR;
	technology->read_in(namescope);
	delete t;

	// lists of things
	status = NULL;
	cell_list = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {

		if (t->get_type() != LPAR) {
		    pe(1, "library expr: expected expression\n"); 
		    delete t;
		    ef->skip_expr();
		    return RC_FAILED;
		   }
		delete t;

		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_STATUS: {
			if (status != NULL)
			    pe(1, "library expr: additional status? ignore it...\n"); 
			status++;
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_CELL: {
			CELL_EXPR *cell_expr = new CELL_EXPR();
			cell_expr->read_in(namescope);
			cell_list = new ListOfCELL_EXPR(cell_expr, cell_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default:  {
			pe(1, "edif expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    }
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
LIBRARY_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(library\n");
	printf("%s", print_line);

	namedef->print(arg_indent + 1);

	if (status != NULL) {
		sprintf(p, "  (status ...)\n");
		printf("%s", print_line);
	}

	ListOfCELL_EXPR *t_cell_list = cell_list;
	while (t_cell_list != NULL) {
		t_cell_list->expr->print(arg_indent + 1);
		t_cell_list = t_cell_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);

}

ListOfLIBRARY_EXPR::ListOfLIBRARY_EXPR(
    LIBRARY_EXPR *arg_expr, ListOfLIBRARY_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

LIBRARYREF_EXPR::LIBRARYREF_EXPR()
{
}

rc_t
LIBRARYREF_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// nameRef
	librarynameref = new NAMEREF(LIBRARY_NAMECLASS);
	if (librarynameref->read_in(arg_namescope) != RC_NOMINAL) {
	    pe(1, "library portimpelemntation: expected name\n");
	    ef->skip_expr();
	    return RC_FAILED;
	   }
	// don't do lookup now

	TOKEN *t = ef->read_token();
	if (t->get_type() != RPAR)  {
		pe(1, "libraryref expr: junk at end\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	// now resolve the name
	// there is no higher ref, so must be local
	librarynamedef = arg_namescope->lookup(librarynameref);
	if (librarynamedef == NULL) {
		pe(1, "libraryref expr: can't lookup library locally");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	return RC_NOMINAL;
}

void
LIBRARYREF_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(libraryref\n");
	printf("%s", print_line);

	sprintf(p, "  %s\n", librarynameref->get_identifier());
	printf("%s", print_line);

	sprintf(p, ")\n");
	printf("%s", print_line);
}

///////////////////////////////////////////////////////

NAME_EXPR::NAME_EXPR()
{
}

rc_t
NAME_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	// identifier
	identifier = t->get_string();
	if (identifier == NULL)	 {
		pe(1, "name expr: expected name\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	delete t;

	// lists of things
	display_list = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "name expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_DISPLAY: {
			DISPLAY_EXPR *display_expr = new DISPLAY_EXPR();
			display_expr->read_in(arg_namescope);
			display_list = new ListOfDISPLAY_EXPR(
			    display_expr, display_list);
		    } break;

		    default:  {
			pe(1, "name expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    }
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
NAME_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(name %s\n", identifier);
	printf("%s", print_line);

	ListOfDISPLAY_EXPR *tdisplay_list = display_list;
	while (tdisplay_list != NULL) {
		tdisplay_list->expr->print(arg_indent + 1);
		tdisplay_list = tdisplay_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfNAME_EXPR::ListOfNAME_EXPR(
    NAME_EXPR *arg_expr, ListOfNAME_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

NET_EXPR::NET_EXPR()
{
}

rc_t
NET_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// namedef
	namedef = new NAMEDEF(NET_NAMECLASS, this);
	if (namedef->read_in(arg_namescope) != RC_NOMINAL) {
		pe(1, "net expr: expected namedef\n");
	}
	
	rc_t rc = arg_namescope->insert(namedef);
	if (rc != RC_NOMINAL) {
		pe(1, "net expr: name in use\n");
	}
	namescope = new NAMESCOPE(arg_namescope, KW_NET, this);

	// joined
	TOKEN *t = ef->read_token();
	if (t->get_type() != LPAR) {
		pe(1, "net expr: expected joined");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_JOINED) {
		pe(1, "net expr: expected joined");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	if (SUE::MAKE_NETLISTS) {
		joined = new JOINED_EXPR();
		joined->read_in(arg_namescope);
	} else	ef->skip_expr();
	

	
	// lists of things
	figure_list = NULL;
	net_list = NULL;
	instance_list = NULL;
	commentgraphics_list = NULL;
	property_list = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "net expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_CRITICALITY: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_NETDELAY: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_FIGURE: {
			FIGURE_EXPR *figure_expr = new FIGURE_EXPR();
			figure_expr->read_in(namescope);
			figure_list = new ListOfFIGURE_EXPR(
			    figure_expr, figure_list);
		    } break;

		    case KW_NET: {
			NET_EXPR *net_expr = new NET_EXPR();
			net_expr->read_in(namescope);
			net_list = new ListOfNET_EXPR(
			    net_expr, net_list);
		    } break;

		    case KW_INSTANCE: {
			INSTANCE_EXPR *instance_expr = new INSTANCE_EXPR();
			instance_expr->read_in(namescope);
			instance_list = new ListOfINSTANCE_EXPR(
			    instance_expr, instance_list);
		    } break;

		    case KW_COMMENTGRAPHICS: {
			COMMENTGRAPHICS_EXPR *commentgraphics_expr = new COMMENTGRAPHICS_EXPR();
			commentgraphics_expr->read_in(namescope);
			commentgraphics_list = new ListOfCOMMENTGRAPHICS_EXPR(
			    commentgraphics_expr, commentgraphics_list);
		    } break;

		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(namescope);
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default: {
			pe(1, "net expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    } break;
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
NET_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(net\n");
	printf("%s", print_line);
	namedef->print(arg_indent + 1);

	ListOfFIGURE_EXPR *tfigure_list = figure_list;
	while (tfigure_list != NULL) {
		tfigure_list->expr->print(arg_indent + 1);
		tfigure_list = tfigure_list->next;
	}

	ListOfNET_EXPR *tnet_list = net_list;
	while (tnet_list != NULL) {
		tnet_list->expr->print(arg_indent + 1);
		tnet_list = tnet_list->next;
	}

	ListOfINSTANCE_EXPR *tinstance_list = instance_list;
	while (tinstance_list != NULL) {
		tinstance_list->expr->print(arg_indent + 1);
		tinstance_list = tinstance_list->next;
	}

	ListOfCOMMENTGRAPHICS_EXPR *tcommentgraphics_list = commentgraphics_list;
	while (tcommentgraphics_list != NULL) {
		tcommentgraphics_list->expr->print(arg_indent + 1);
		tcommentgraphics_list = tcommentgraphics_list->next;
	}

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfNET_EXPR::ListOfNET_EXPR(
    NET_EXPR *arg_expr, ListOfNET_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

OPENSHAPE_EXPR::OPENSHAPE_EXPR()
{
}

rc_t
OPENSHAPE_EXPR::read_in(NAMESCOPE * arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// curve
	TOKEN *t = ef->read_token();
	if (t->get_type() != LPAR)  {
		pe(1, "openshape expr: expected curve");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_CURVE) {
		pe(1, "openshape expr: expected curve");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	curve = new CURVE_EXPR();
	curve->read_in(arg_namescope);
	delete t;
	
	// lists of things
	property_list = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR)  {
			pe(1, "openshape expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(arg_namescope);
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    default: {
			pe(1, "openshape expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    } break;
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
OPENSHAPE_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(openshape\n");
	printf("%s", print_line);

	curve->print(arg_indent + 1);

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfOPENSHAPE_EXPR::ListOfOPENSHAPE_EXPR(
    OPENSHAPE_EXPR *arg_expr, ListOfOPENSHAPE_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

ORIGIN_EXPR::ORIGIN_EXPR()
{
}

rc_t
ORIGIN_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// pt
	TOKEN *t = ef->read_token();
	if (t->get_type() != LPAR) {
		pe(1, "origin expr: expected pt");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_PT) {
		pe(1, "origin expr: expected pt");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	pt = new PT_EXPR();
	pt->read_in(arg_namescope);
	delete t;
	
	t = ef->read_token();
	if (t->get_type() != RPAR) {
		pe(1, "origin expr: junk at the end\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	return RC_NOMINAL;
}

void
ORIGIN_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(origin\n");
	printf("%s", print_line);

	if (pt != NULL) {
		pt->print(arg_indent + 1);
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

///////////////////////////////////////////////////////

PAGE_EXPR::PAGE_EXPR()
{
}

rc_t
PAGE_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// namedef
	namedef = new NAMEDEF(INSTANCE_NAMECLASS, this);
	if (namedef->read_in(arg_namescope) != RC_NOMINAL) {
		pe(1, "page expr: expected namedef\n");
	}
	
	rc_t rc = arg_namescope->insert(namedef);
	if (rc != RC_NOMINAL) {
		pe(1, "page expr: page name in use %s\n");
	}
	namescope = new NAMESCOPE(arg_namescope, KW_PAGE, this);

	// lists of things
	boundingbox = NULL;
	instance_list = NULL;
	net_list = NULL;
	commentgraphics_list = NULL;
	portimplementation_list = NULL;
	TOKEN *t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "page expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_BOUNDINGBOX: {
			if (boundingbox)
				pe(1, "page expr: additional boundingbox? ignore it\n");
			boundingbox = new BOUNDINGBOX_EXPR();
			boundingbox->read_in(namescope);
		    } break;

		    case KW_PAGESIZE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_NETBUNDLE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_INSTANCE: {
			INSTANCE_EXPR *instance_expr = new INSTANCE_EXPR();
			instance_expr->read_in(namescope);
			instance_list = new ListOfINSTANCE_EXPR(
			    instance_expr, instance_list);
		    } break;

		    case KW_NET: {
			NET_EXPR *net_expr = new NET_EXPR();
			net_expr->read_in(namescope);
			net_list = new ListOfNET_EXPR(
			    net_expr, net_list);
		    } break;

		    case KW_COMMENTGRAPHICS: {
			COMMENTGRAPHICS_EXPR *commentgraphics_expr = new COMMENTGRAPHICS_EXPR();
			commentgraphics_expr->read_in(namescope);
			commentgraphics_list = new ListOfCOMMENTGRAPHICS_EXPR(
			    commentgraphics_expr, commentgraphics_list);
		    } break;

		    case KW_PORTIMPLEMENTATION: {
			PORTIMPLEMENTATION_EXPR *portimplementation_expr = new PORTIMPLEMENTATION_EXPR();
			rc_t rc = portimplementation_expr->read_in(namescope);
			if (rc == RC_NOTFOUND) break;	// ...see PORTIMPLEMENTATION_EXPR::read_in
			else if (rc != RC_NOMINAL) 
				return RC_FAILED;
			portimplementation_list = new ListOfPORTIMPLEMENTATION_EXPR(
			    portimplementation_expr, portimplementation_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default: {
			pe(1, "page expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    } break;
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
PAGE_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(page\n");
	printf("%s", print_line);
	namedef->print(arg_indent + 1);

	if (boundingbox != NULL)	boundingbox->print(arg_indent + 1);

	ListOfINSTANCE_EXPR *tinstance_list = instance_list;
	while (tinstance_list != NULL) {
		tinstance_list->expr->print(arg_indent + 1);
		tinstance_list = tinstance_list->next;
	}

	ListOfNET_EXPR *tnet_list = net_list;
	while (tnet_list != NULL) {
		tnet_list->expr->print(arg_indent + 1);
		tnet_list = tnet_list->next;
	}

	ListOfCOMMENTGRAPHICS_EXPR *tcommentgraphics_list = commentgraphics_list;
	while (tcommentgraphics_list != NULL) {
		tcommentgraphics_list->expr->print(arg_indent + 1);
		tcommentgraphics_list = tcommentgraphics_list->next;
	}

	ListOfPORTIMPLEMENTATION_EXPR *tportimplementation_list = portimplementation_list;
	while (tportimplementation_list != NULL) {
		tportimplementation_list->expr->print(arg_indent + 1);
		tportimplementation_list = tportimplementation_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfPAGE_EXPR::ListOfPAGE_EXPR(
    PAGE_EXPR *arg_expr, ListOfPAGE_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

PATH_EXPR::PATH_EXPR()
{
}

rc_t
PATH_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// pointlist
	TOKEN *t = ef->read_token();
	if (t->get_type() != LPAR)  {
		pe(1, "path expr: expected pointlist");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_POINTLIST) {
		pe(1, "path expr: expected pointlist");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	pointlist = new POINTLIST_EXPR();
	pointlist->read_in(arg_namescope);
	delete t;
	
	// lists of things
	property_list = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR)  {
			pe(1, "path expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(arg_namescope);
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    default:  {
			pe(1, "path expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    }
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
PATH_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(path\n");
	printf("%s", print_line);

	if (pointlist != NULL) {
		pointlist->print(arg_indent + 1);
	}

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfPATH_EXPR::ListOfPATH_EXPR(
    PATH_EXPR *arg_expr, ListOfPATH_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

POINTLIST_EXPR::POINTLIST_EXPR()
{
}

rc_t
POINTLIST_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	// lists of things
	pt_list = NULL;
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "pointlist expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_PT: {
			PT_EXPR *pt_expr = new PT_EXPR();
			pt_expr->read_in(arg_namescope);
			pt_list = new ListOfPT_EXPR(
			    pt_expr, pt_list);
		    } break;

		    default:  {
			pe(1, "pointlist expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
POINTLIST_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(pointlist\n");
	printf("%s", print_line);

	ListOfPT_EXPR *tpt_list = pt_list;
	while (tpt_list != NULL) {
		tpt_list->expr->print(arg_indent + 1);
		tpt_list = tpt_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfPOINTLIST_EXPR::ListOfPOINTLIST_EXPR(
    POINTLIST_EXPR *arg_expr, ListOfPOINTLIST_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

POLYGON_EXPR::POLYGON_EXPR()
{
}

rc_t
POLYGON_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	// pointlist
	if (t->get_type() != LPAR)  {
		pe(1, "polygon expr: expected pointlist");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	delete t;
	t = ef->read_token();
	if (t->get_type() != KW_POINTLIST) {
		pe(1, "polygon expr: expected pointlist");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	pointlist = new POINTLIST_EXPR();
	pointlist->read_in(arg_namescope);
	delete t;
	
	// lists of things
	property_list = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "polygon expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(arg_namescope);
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    default:  {
			pe(1, "polygon expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    }
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
POLYGON_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(polygon\n");
	printf("%s", print_line);

	pointlist->print(arg_indent + 1);

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfPOLYGON_EXPR::ListOfPOLYGON_EXPR(
    POLYGON_EXPR *arg_expr, ListOfPOLYGON_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

PORT_EXPR::PORT_EXPR()
{
}

rc_t
PORT_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// namedef
	namedef = new NAMEDEF(PORT_NAMECLASS, this);
	if (namedef->read_in(arg_namescope) != RC_NOMINAL) {
		pe(1, "port expr: expected namedef\n");
	}
	
	rc_t rc = arg_namescope->insert(namedef);
	if (rc != RC_NOMINAL) {
		pe(1, "port expr: port name in use %s\n");
	}
	namescope = new NAMESCOPE(arg_namescope, KW_PORT, this);

	// lists of things
	property_list = NULL;
	direction = DIRECTION_NOT_SPECIFIED;
	TOKEN *t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "port expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_DIRECTION: {
			delete t;

			t = ef->read_token();
			char *tstring = t->get_string();
			if (strcmp(tstring, "INPUT") == 0)	 direction = INPUT;
			else if (strcmp(tstring, "OUTPUT") == 0) direction = OUTPUT;
			else if (strcmp(tstring, "INOUT") == 0)	 direction = INOUT;
			else  {
				pe(1, "port expr: what direction?\n");
				delete t;
				ef->skip_expr();
				return RC_FAILED;
			}
			delete t;

			t = ef->read_token();
			if (t->get_type() != RPAR) {
			    pe(1, "direction expr: junk at end\n");
			    delete t;
			    ef->skip_expr();
			    return RC_FAILED;
			   }
		    } break;

		    case KW_UNUSED: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_DESIGNATOR: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_DCFANINLOAD: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_DCFANOUTLOAD: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_DCMAXFANIN: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_DCMAXFANOUT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_ACLOAD: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(namescope);
;
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default:  {
			pe(1, "port expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
PORT_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(port\n");
	printf("%s", print_line);
	namedef->print(arg_indent + 1);

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfPORT_EXPR::ListOfPORT_EXPR(
    PORT_EXPR *arg_expr, ListOfPORT_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

PORTIMPLEMENTATION_EXPR::PORTIMPLEMENTATION_EXPR()
    : orientation(ORIENTATION_NOT_SPECIFIED)
{
}

rc_t
PORTIMPLEMENTATION_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// nameRef
	nameref = new NAMEREF(PORT_NAMECLASS);
	if (nameref->read_in(arg_namescope) != RC_NOMINAL) {
	    pe(1, "portimpelemntation: expected name\n");
	    ef->skip_expr();
	    return RC_FAILED;
	}

	namedef = arg_namescope->lookup(nameref);
	if (namedef == NULL) {
		if (SUE::SKIP_BAD_PORTS == true) {
			// hack for Cadence/Equator duplicate port problem (see option documentation)
			printf("portref with no interface \"%s\"\n", nameref->get_identifier());
			ef->skip_expr();
			return RC_NOTFOUND;
		} 
		pe(1, "portimplementation expr: can\'t lookup name\n");
	}

	// lists of things
	figure_list = NULL;
	instance_list = NULL;
	commentgraphics_list = NULL;
	keyworddisplay_list = NULL;
	property_list = NULL;
	connectlocation = NULL;
	userdata_list = NULL;
	TOKEN *t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "portimplementation expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_PROPERTYDISPLAY: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_CONNECTLOCATION: {
			if (connectlocation)
				pe(1, "portimplementation expr: additional connectlocation? ignore it\n");
			connectlocation = new CONNECTLOCATION_EXPR();
			connectlocation->read_in(arg_namescope);
		    } break;

		    case KW_FIGURE: {
			FIGURE_EXPR *figure_expr = new FIGURE_EXPR();
			figure_expr->read_in(arg_namescope);
			figure_list = new ListOfFIGURE_EXPR(
			    figure_expr, figure_list);
		    } break;

		    case KW_INSTANCE: {
			INSTANCE_EXPR *instance_expr = new INSTANCE_EXPR();
			instance_expr->read_in(arg_namescope);
			instance_list = new ListOfINSTANCE_EXPR(
			    instance_expr, instance_list);
		    } break;

		    case KW_COMMENTGRAPHICS: {
			COMMENTGRAPHICS_EXPR *commentgraphics_expr = new COMMENTGRAPHICS_EXPR();
			commentgraphics_expr->read_in(arg_namescope);
			commentgraphics_list = new ListOfCOMMENTGRAPHICS_EXPR(
			    commentgraphics_expr, commentgraphics_list);
		    } break;

		    case KW_KEYWORDDISPLAY: {
			KEYWORDDISPLAY_EXPR *keyworddisplay_expr = new KEYWORDDISPLAY_EXPR();
			keyworddisplay_expr->read_in(arg_namescope);
			keyworddisplay_list = new ListOfKEYWORDDISPLAY_EXPR(
			    keyworddisplay_expr, keyworddisplay_list);
		    } break;

		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(arg_namescope);

			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			USERDATA_EXPR *userdata_expr = new USERDATA_EXPR();
			userdata_expr->read_in(arg_namescope);

			userdata_list = new ListOfUSERDATA_EXPR(
			    userdata_expr, userdata_list);
		    } break;

		    default:  {
			pe(1, "portimplementation expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
PORTIMPLEMENTATION_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(portimplementation\n");
	printf("%s", print_line);

	nameref->print(arg_indent + 1);

	if (connectlocation != NULL)	connectlocation->print(arg_indent + 1);

	ListOfFIGURE_EXPR *tfigure_list = figure_list;
	while (tfigure_list != NULL) {
		tfigure_list->expr->print(arg_indent + 1);
		tfigure_list = tfigure_list->next;
	}

	ListOfINSTANCE_EXPR *tinstance_list = instance_list;
	while (tinstance_list != NULL) {
		tinstance_list->expr->print(arg_indent + 1);
		tinstance_list = tinstance_list->next;
	}

	ListOfCOMMENTGRAPHICS_EXPR *tcommentgraphics_list = commentgraphics_list;
	while (tcommentgraphics_list != NULL) {
		tcommentgraphics_list->expr->print(arg_indent + 1);
		tcommentgraphics_list = tcommentgraphics_list->next;
	}

	ListOfKEYWORDDISPLAY_EXPR *tkeyworddisplay_list = keyworddisplay_list;
	while (tkeyworddisplay_list != NULL) {
		tkeyworddisplay_list->expr->print(arg_indent + 1);
		tkeyworddisplay_list = tkeyworddisplay_list->next;
	}

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfPORTIMPLEMENTATION_EXPR::ListOfPORTIMPLEMENTATION_EXPR(
    PORTIMPLEMENTATION_EXPR *arg_expr, ListOfPORTIMPLEMENTATION_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

PORTREF_EXPR::PORTREF_EXPR()
    : resolved_name(NULL)
{
}

PORTREF_EXPR::~PORTREF_EXPR()
{
	if (resolved_name != NULL) delete resolved_name;
}

rc_t
PORTREF_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// nameRef
	portnameref = new NAMEREF(PORT_NAMECLASS);
	if (portnameref->read_in(arg_namescope) != RC_NOMINAL) {
	    pe(1, "portref: expected name\n");
	}
	// don't do lookup now


	// maybe instance ref
	instanceref = NULL;
	TOKEN *t = ef->read_token();
	if (t->get_type() == LPAR) {
		delete t;

		t = ef->read_token();
		if (t->get_type() != KW_INSTANCEREF) {
			pe(1, "portref expr: expected instanceref");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}

		instanceref = new INSTANCEREF_EXPR();
		instanceref->read_in(arg_namescope);

		t = ef->read_token();
	}
	if (t->get_type() != RPAR)  {
		pe(1, "portref expr: junk at end\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	// now resolve the name
	// if there is no instanceref, then resolve the port locally
	if (instanceref == NULL) {
		portnamedef = arg_namescope->lookup(portnameref);
		if (portnamedef == NULL) {
			pe(1, "portref expr: can't lookup port locally");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}

	} else {
		// the instance ref actually resolves to a view,
		// curiously enough.  One more level of indirection 
		// than usual here.
		INSTANCE_EXPR *instance = NULL;
		instanceref->instancenamedef->get_where_defined(&instance);
		if (instance == NULL)  {
			pe(1, "portref expr: get_where_defined failed\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		VIEWREF_EXPR *viewref = instance->viewref;
		VIEW_EXPR *view = NULL;
		viewref->viewnamedef->get_where_defined(&view);
		if (view == NULL)  {
			pe(1, "portref expr: can\'t find view\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}

		portnamedef = view->namescope->lookup(portnameref);
		if (portnamedef == NULL)  {
			pe(1, "portref expr: get_where_defined failed\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
	}
	
	resolved_name = portnamedef->get_stringvalue();
	return RC_NOMINAL;
}

void
PORTREF_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(portref\n");
	printf("%s", print_line);

	sprintf(p, "  %s\n", portnameref->get_identifier());
	printf("%s", print_line);

	if (instanceref != NULL) {
		instanceref->print(arg_indent + 1);
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfPORTREF_EXPR::ListOfPORTREF_EXPR(
    PORTREF_EXPR *arg_expr, ListOfPORTREF_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}


///////////////////////////////////////////////////////

PROPERTY_EXPR::PROPERTY_EXPR()
{
}

rc_t
PROPERTY_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// namedef
	namedef = new NAMEDEF(PROPERTY_NAMECLASS, this);
	if (namedef->read_in(arg_namescope) != RC_NOMINAL) {
		pe(1, "property expr: expected namedef\n");
	}
	
	rc_t rc = arg_namescope->insert(namedef);
	if (rc != RC_NOMINAL) {

		// BUG...
		// it is legal for a property to override a property
		// inherited from a larger scope, but not to have two
		// properties of the same name within the same scope.
		// So this test isn't quite right.  Really need 
		// a different variety of insert.	
		// Right now, we may allow some erroneous cases
		// to slip through.  

	}

	is_ignorable = false;
	if (SUE::IGNORE_PROPERTY_LIST != NULL) {
		char *prop_name_str = namedef->get_stringvalue();
		ListOfCHARSTAR *ignore_list = SUE::IGNORE_PROPERTY_LIST;
		while (ignore_list != NULL) {
			if (strcmp(prop_name_str, ignore_list->str) == 0) {
				is_ignorable = true;
				ef->skip_expr();
				return RC_NOMINAL;
			}
			ignore_list = ignore_list->next;
		}
	}
	
	namescope = new NAMESCOPE(arg_namescope, KW_PROPERTY, this);

	// typed value
	TOKEN *t = ef->read_token();
	if (t->get_type() != LPAR) {
		pe(1, "property expr: expected typed value");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != STRING) {
		pe(1, "property expr: expected typed value");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	char *typestr = t->get_string();
	delete t;

	t = ef->read_token();
	if (strcmp(typestr, "boolean") == 0) {
		value_type = BOOLEAN_PV;

		// BUG... boolean expressions are actually more
		// complicated than this (array values are permitted)

		// caveat! wierd use of t... smells bad, tastes good...
		if (t->get_type() != LPAR) {
			pe(1, "property boolean expr: wanted lpar");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		t = ef->read_token();
		if (t->get_type() != STRING)  {
		    pe(1, "typedValue: expected boolean value");
		    delete t;
		    ef->skip_expr();
		    return RC_FAILED;
		   }
		char *boolstr = t->get_string();
		if (strcmp(boolstr, "true") == 0) boolean_value = true;
		else if (strcmp(boolstr, "false") == 0) boolean_value = false;
		else if (strcmp(boolstr, "TRUE") == 0) boolean_value = true;
		else if (strcmp(boolstr, "FALSE") == 0) boolean_value = false;
		else  {
			pe(1, "typedValue: expected boolean value");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete boolstr;
		delete t;

		t = ef->read_token();
		if (t->get_type() != RPAR) {
			pe(1, "property boolean expr: wanted rpar");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}

	} else if (strcmp(typestr, "integer") == 0) {
		value_type = INTEGER_PV;
		if (t->get_type() != INTEGER)  {
		    pe(1, "typedValue: expected integer value");
		    delete t;
		    ef->skip_expr();
		    return RC_FAILED;
		   }
		integer_value = t->get_integer();

	} else if (strcmp(typestr, "miNoMax") == 0) { 
		pe(0, "typedValue: miNoMax value not supported, taking nominal value\n");
		value_type = NUMBER_PV;

		if (t->get_type() != LPAR) {
			pe(1, "property miNoMax expr: wanted lpar");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		t = ef->read_token();
		if (t->get_type() != STRING) {
			pe(1, "property miNoMax expr: wanted name string");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;		

		t = ef->read_token();
		if (t->get_type() != LPAR) {
			pe(1, "property miNoMax expr: wanted lo expression");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		ef->skip_expr();
		delete t;

		rc_t rc = read_number();
		if (rc != RC_NOMINAL) return rc;
		t = ef->read_token();
		if (t->get_type() != LPAR) {
			pe(1, "property miNoMax expr: wanted nominal expression");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		t = ef->read_token();
		if (t->get_type() != LPAR) {
			pe(1, "property miNoMax expr: wanted max expression");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		ef->skip_expr();
		delete t;

		t = ef->read_token();
		if (t->get_type() != RPAR) {
			pe(1, "property miNoMax value expr: junk at end");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		t = ef->read_token();
		if (t->get_type() != RPAR) {
			pe(1, "property miNoMax expr: junk at end");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		t = ef->read_token();
		if (t->get_type() != RPAR) {
			pe(1, "property expr: junk at end");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		return RC_NOMINAL;

	} else if (strcmp(typestr, "number") == 0) {
		value_type = NUMBER_PV;
		rc_t rc = read_number();
		if (rc != RC_NOMINAL) return rc;

		t = ef->read_token();
		if (t->get_type() != RPAR) {
			pe(1, "property number expr: junk at end");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}

	} else if (strcmp(typestr, "point") == 0) {
		value_type = POINT_PV;
		if (t->get_type() != LPAR) {
			pe(1, "typedValue: expected point value\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
		t = ef->read_token();
		if (t->get_type() != KW_PT) {
			pe(1, "typedValue: expected point value\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		pt_value = new PT_EXPR();
		pt_value->read_in(namescope);

	} else if (strcmp(typestr, "string") == 0) {
		value_type = STRING_PV;
		if (t->get_type() == LPAR) {
			delete t;
			t = ef->read_token();
			if (t->get_type() != KW_STRINGDISPLAY) {
				pe(1, "property expr, string type: expected stringdisplay expr");
				delete t;
				ef->skip_expr();
				return RC_FAILED;
			}
			STRINGDISPLAY_EXPR *stringdisplay_expr =  new STRINGDISPLAY_EXPR();
			stringdisplay_expr->read_in(namescope);
			string_value = stringdisplay_expr->string;
		}
		else {
			if (t->get_type() != STRING)		 {
				pe(1, "typedValue: expected string value\n");
				delete t;
				ef->skip_expr();
				return RC_FAILED;
			}
			string_value = t->get_string();
		}

	} else  {
		pe(1, "typedValue expr: unknown type\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	
	delete typestr;
	delete t;

	t = ef->read_token();
	if (t->get_type() != RPAR) {
		pe(1, "property typedValue expr: junk at end");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	// lists of things
	property_list = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "property expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_OWNER: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_UNIT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(namescope);
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default: {
			pe(1, "property expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		    } break;
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
PROPERTY_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(property\n");
	printf("%s", print_line);
	namedef->print(arg_indent + 1);

	switch (value_type) {
	    case BOOLEAN_PV:
		sprintf(p, "  (boolean %s)\n", 
		    boolean_value ? "true" : "false");
		break;

	    case INTEGER_PV:
		sprintf(p, "  (integer %d)\n", integer_value); 
		break;

	    case NUMBER_PV:
		sprintf(p, "  (number (e %d %d))\n", 
		    number_mantissa, number_exponent);
		break;

	    case POINT_PV:
		pt_value->print(arg_indent + 1);
		break;

	    case STRING_PV:
		sprintf(p, "  (string %s)\n", string_value); 
		break;
	}
	printf("%s", print_line);

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}


rc_t
PROPERTY_EXPR::read_number() 
{		
	EDIF_FILE *ef = EDIF_FILE::current_file;

	TOKEN *t = ef->read_token();
	switch (t->get_type()) {
	    case KW_E:
		t = ef->read_token();
		if (t->get_type() != INTEGER) {
			pe(1, "property number expr: wanted mantissa");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		number_mantissa = t->get_integer();
		delete t;		

		t = ef->read_token();
		if (t->get_type() != INTEGER) {
			pe(1, "property number expr: wanted exponent");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		number_exponent = t->get_integer();
		delete t;

		number_value = number_mantissa;
		if (number_exponent < -1) {
			for (int i = number_exponent; i < 0; i++) {
				number_value /= 10.0;
			}
		} else if (number_exponent > 1) {
			for (int i = number_exponent; i > 0; i--) {
				number_value *= 10.0;
			}
		}

		break;		

	    default:
		pe(1, "property number expr: wanted e expr");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	return RC_NOMINAL;
}

char *
PROPERTY_EXPR::get_value_str()
{
#define MAX_VALSTRLEN	100
	char	tstr[MAX_VALSTRLEN];

	switch (value_type) {
	    case BOOLEAN_PV: {
		if (boolean_value == true)	return strdup("true");
		else				return strdup("false");
	    } break;

	    case INTEGER_PV: {
		sprintf(tstr, "%d", integer_value);
		if (strlen(tstr) >= MAX_VALSTRLEN) {
			printf("PROPERTY_EXPR::get_value_str: overflowed integer value str\n");
			exit(-1);
		}
		return strdup(tstr);
	    } break;

	    case NUMBER_PV: {
		sprintf(tstr, "%f", number_value);
		// sprintf(tstr, "{%d Exp %d}", number_mantissa, number_exponent);
		char *p = tstr + strlen(tstr) - 1;
		while (p > tstr && *p == '0') {
			*p-- = '\0';
		}
		if (p > tstr && *p == '.') {
			*p = '\0';
		}
		return strdup(tstr);
	    } break;

	    case POINT_PV: {
		sprintf(tstr, "{%d %d}", pt_value->xvalue, pt_value->yvalue);
		if (strlen(tstr) >= MAX_VALSTRLEN) {
			printf("PROPERTY_EXPR::get_value_str: overflowed integer value str\n");
			exit(-1);
		}
		return strdup(tstr);
	    } break;

	    case STRING_PV: {
		return strdup(string_value);
	    } break;

	    default : {
		return strdup("PROPERTY_EXPR::get_value_str: not implemented\n");
	    } break;
	};

	// not reached
	return strdup("PROPERTY_EXPR::get_value_str: not reached\n");
}

ListOfPROPERTY_EXPR::ListOfPROPERTY_EXPR(
    PROPERTY_EXPR *arg_expr, ListOfPROPERTY_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

PT_EXPR::PT_EXPR()
{
}

rc_t
PT_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	if (t->get_type() != INTEGER)  {
		pe(1, "pt expr: expected integer\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	xvalue = t->get_integer();
	delete t;

	t = ef->read_token();
	if (t->get_type() != INTEGER)  {
		pe(1, "pt expr: expected integer\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	// y value gets sign flipped
	yvalue = -(t->get_integer());
	delete t;

	t = ef->read_token();
	if (t->get_type() != RPAR) {
		pe(1, "pt expr: junk at the end\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	return RC_NOMINAL;
}

void
PT_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(pt %d %d)\n", xvalue, yvalue);
	printf("%s", print_line);

}

ListOfPT_EXPR::ListOfPT_EXPR(
    PT_EXPR *arg_expr, ListOfPT_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

ListOfPT_EXPR::~ListOfPT_EXPR()
{
	if (next) delete next;
}  


///////////////////////////////////////////////////////

RECTANGLE_EXPR::RECTANGLE_EXPR()
{
}

rc_t
RECTANGLE_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	if (t->get_type() != LPAR)  {
		pe(1, "rectangle expr: expected pt");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_PT)  {
		pe(1, "rectangle expr: expected pt");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	corner1 = new PT_EXPR();
	corner1->read_in(arg_namescope);
	delete t;

	t = ef->read_token();
	if (t->get_type() != LPAR)  {
		pe(1, "rectangle expr: expected pt");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_PT) {
		pe(1, "rectangle expr: expected pt");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	corner2 = new PT_EXPR();
	corner2->read_in(arg_namescope);
	delete t;

	// lists of things
	property_list = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "rectangle expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(arg_namescope);
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    default:  {
			pe(1, "rectangle expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
RECTANGLE_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(rectangle\n");
	printf("%s", print_line);

	if (corner1 != NULL) {
		corner1->print(arg_indent + 1);
	}

	if (corner2 != NULL) {
		corner2->print(arg_indent + 1);
	}

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfRECTANGLE_EXPR::ListOfRECTANGLE_EXPR(
    RECTANGLE_EXPR *arg_expr, ListOfRECTANGLE_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

RENAME_EXPR::RENAME_EXPR()
{
}

rc_t
RENAME_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	TOKEN *t = ef->read_token();
	if (t->get_type() == LPAR) {
		delete t;

		t = ef->read_token(); 
		if (t->get_type() != KW_NAME)  {
			pe(1, "rename expr: expected identifier or name");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		name = new NAME_EXPR();
		name->read_in(arg_namescope);
		identifier = NULL;

	} else {
		name = NULL;
		identifier = t->get_string();
	}
	
	t = ef->read_token();
	if (t->get_type() == LPAR) {
		delete t;

		t = ef->read_token(); 
		if (t->get_type() != KW_STRINGDISPLAY)  {
			pe(1, "rename expr: expected string or stringdisplay");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		stringdisplay = new STRINGDISPLAY_EXPR();
		stringdisplay->read_in(arg_namescope);
		string = NULL;

	} else {
		stringdisplay = NULL;
		string = t->get_string();
	}
	
	delete t;
	
	t = ef->read_token();
	if (t->get_type() != RPAR)  {
		delete t;
		ef->skip_expr();
		if (SUE::TANNER_RENAME_BUG == true) {
			pe(0, "tanner rename bug ignored");
			// also skip out of the enclosing namedef_expr
			ef->skip_expr();
		} else {
			pe(1, "rename expr: junk at the end\n");
			return RC_FAILED;
		}
	}

	return RC_NOMINAL;
}

void
RENAME_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(rename\n");
	printf("%s", print_line);

	if (name != NULL)
		name->print(arg_indent + 1);

	if (string != NULL) {
		sprintf(p, "  %s)\n", string);
		printf("%s", print_line);
	}

	if (identifier != NULL) {
		sprintf(p, "  %s)\n", identifier);
		printf("%s", print_line);
	}

	if (stringdisplay != NULL) 
		stringdisplay->print(arg_indent + 1);

}


///////////////////////////////////////////////////////

STRINGDISPLAY_EXPR::STRINGDISPLAY_EXPR()
{
}

rc_t
STRINGDISPLAY_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	if (t->get_type() != STRING)  {
	    pe(1, "stringDisplay expr: expected name\n");
	    delete t;
	    ef->skip_expr();
	    return RC_FAILED;
	   }

	string = t->get_string();
	delete t;

	// lists of things
	display_list = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "stringdisplay expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_DISPLAY: {
			DISPLAY_EXPR *display_expr = new DISPLAY_EXPR();
			display_expr->read_in(arg_namescope);
			display_list = new ListOfDISPLAY_EXPR(
			    display_expr, display_list);
		    } break;

		    default:  {
			pe(1, "stringdisplay expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
STRINGDISPLAY_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(stringdisplay\n");
	printf("%s", print_line);

	sprintf(p, "  %s\n", string);
	printf("%s", print_line);

	ListOfDISPLAY_EXPR *tdisplay_list = display_list;
	while (tdisplay_list != NULL) {
		tdisplay_list->expr->print(arg_indent + 1);
		tdisplay_list = tdisplay_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfSTRINGDISPLAY_EXPR::ListOfSTRINGDISPLAY_EXPR(
    STRINGDISPLAY_EXPR *arg_expr, ListOfSTRINGDISPLAY_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

SYMBOL_EXPR::SYMBOL_EXPR()
{
}

rc_t
SYMBOL_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// lists of things
	boundingbox = NULL;
	portimplementation_list = NULL;
	figure_list = NULL;
	annotate_list = NULL;
	commentgraphics_list = NULL;
	property_list = NULL;
	TOKEN *t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR)  {
			pe(1, "symbol expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_BOUNDINGBOX: {
			if (boundingbox)
				pe(1, "symbol expr: additional boundingbox? ignore it\n");
			boundingbox = new BOUNDINGBOX_EXPR();
			boundingbox->read_in(arg_namescope);
		    } break;

		    case KW_PAGESIZE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PROPERTYDISPLAY: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_KEYWORDDISPLAY: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PARAMETER: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PORTIMPLEMENTATION: {
			PORTIMPLEMENTATION_EXPR *portimplementation_expr = new PORTIMPLEMENTATION_EXPR();
			portimplementation_expr->read_in(arg_namescope);
			portimplementation_list = new ListOfPORTIMPLEMENTATION_EXPR(
			    portimplementation_expr, portimplementation_list);
		    } break;

		    case KW_FIGURE: {
			FIGURE_EXPR *figure_expr = new FIGURE_EXPR();
			figure_expr->read_in(arg_namescope);
			figure_list = new ListOfFIGURE_EXPR(
			    figure_expr, figure_list);
		    } break;

		    case KW_ANNOTATE: {
			ANNOTATE_EXPR *annotate_expr = new ANNOTATE_EXPR();
			annotate_expr->read_in(arg_namescope);
			annotate_list = new ListOfANNOTATE_EXPR(
			    annotate_expr, annotate_list);
		    } break;

		    case KW_INSTANCE: {
			INSTANCE_EXPR *instance_expr = new INSTANCE_EXPR();
			instance_expr->read_in(arg_namescope);
			instance_list = new ListOfINSTANCE_EXPR(
			    instance_expr, instance_list);
		    } break;

		    case KW_COMMENTGRAPHICS: {
			COMMENTGRAPHICS_EXPR *commentgraphics_expr = new COMMENTGRAPHICS_EXPR();
			commentgraphics_expr->read_in(arg_namescope);
			commentgraphics_list = new ListOfCOMMENTGRAPHICS_EXPR(
			    commentgraphics_expr, commentgraphics_list);
		    } break;

		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(arg_namescope);
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default:  {
			pe(1, "symbol expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
SYMBOL_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(symbol\n");
	printf("%s", print_line);

	if (boundingbox != NULL) {
		boundingbox->print(arg_indent + 1);
	}

	ListOfPORTIMPLEMENTATION_EXPR *tportimplementation_list = portimplementation_list;
	while (tportimplementation_list != NULL) {
		tportimplementation_list->expr->print(arg_indent + 1);
		tportimplementation_list = tportimplementation_list->next;
	}

	ListOfFIGURE_EXPR *tfigure_list = figure_list;
	while (tfigure_list != NULL) {
		tfigure_list->expr->print(arg_indent + 1);
		tfigure_list = tfigure_list->next;
	}

	ListOfANNOTATE_EXPR *tannotate_list = annotate_list;
	while (tannotate_list != NULL) {
		tannotate_list->expr->print(arg_indent + 1);
		tannotate_list = tannotate_list->next;
	}

	ListOfINSTANCE_EXPR *tinstance_list = instance_list;
	while (tinstance_list != NULL) {
		tinstance_list->expr->print(arg_indent + 1);
		tinstance_list = tinstance_list->next;
	}

	ListOfCOMMENTGRAPHICS_EXPR *tcommentgraphics_list = commentgraphics_list;
	while (tcommentgraphics_list != NULL) {
		tcommentgraphics_list->expr->print(arg_indent + 1);
		tcommentgraphics_list = tcommentgraphics_list->next;
	}

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfSYMBOL_EXPR::ListOfSYMBOL_EXPR(
    SYMBOL_EXPR *arg_expr, ListOfSYMBOL_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

TECHNOLOGY_EXPR::TECHNOLOGY_EXPR()
{
}

rc_t
TECHNOLOGY_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// numberdefinition
	TOKEN *t = ef->read_token();
	if (t->get_type() != LPAR)  {
		pe(1, "technology expr: expected numberdefinition");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_NUMBERDEFINITION) {
		pe(1, "technology expr: expected numberdefinition");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	// not implemented
	ef->skip_expr();
	delete t;
	
	// lists of things
	figuregroup_list = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR)  {
			pe(1, "technology expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;

		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_FABRICATE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_SIMULATIONINFO: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_PHYSICALDESIGNRULE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_CONSTANT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_CONSTRAINT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_BLOCK: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_IF: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_ITERATE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_WHILE: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_FIGUREGROUP: {
			FIGUREGROUP_EXPR *figuregroup_expr = new FIGUREGROUP_EXPR();
			figuregroup_expr->read_in(arg_namescope);
			figuregroup_list = new ListOfFIGUREGROUP_EXPR(
			    figuregroup_expr, figuregroup_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default:  {
			pe(1, "technology expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
TECHNOLOGY_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(technology\n");
	printf("%s", print_line);

	ListOfFIGUREGROUP_EXPR *tfiguregroup_list = figuregroup_list;
	while (tfiguregroup_list != NULL) {
		tfiguregroup_list->expr->print(arg_indent + 1);
		tfiguregroup_list = tfiguregroup_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}


///////////////////////////////////////////////////////

TRANSFORM_EXPR::TRANSFORM_EXPR()
{
}

rc_t
TRANSFORM_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	// BUG...I don't understand what is format of scale factors;
	// ...string "1/1"? ...so I hope there never is one.
	orientation = ORIENTATION_NOT_SPECIFIED;
	origin = NULL;

	if (t->get_type() == RPAR) return RC_NOMINAL;
	if (t->get_type() != LPAR)  {
		pe(1, "transform expr: expecte expr");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;
	
	t = ef->read_token();
	if (t->get_type() == KW_SCALEX) {
		delete t;
		// NOT IMPLEMENTED
		printf("warning, \"scaleY\" support not implemented\n");
		ef->skip_expr();
		t = ef->read_token();
		if (t->get_type() != LPAR)  {
			pe(1, "transform expr: expecte expr");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
		t = ef->read_token();
	}
	if (t->get_type() == KW_SCALEY) {
		delete t;
		// NOT IMPLEMENTED
		printf("warning, \"scaleX\" support not implemented\n");
		ef->skip_expr();
		t = ef->read_token();
		if (t->get_type() == RPAR) {
			delete t;
			return RC_NOMINAL;
		}
		if (t->get_type() != LPAR)  {
			pe(1, "transform expr: expecte expr");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
		t = ef->read_token();
	}

	if (t->get_type() == KW_DELTA) {
		delete t;
		// NOT IMPLEMENTED
		printf("warning, \"delta\" support not implemented\n");
		ef->skip_expr();
		t = ef->read_token();
		if (t->get_type() == RPAR) {
			delete t;
			return RC_NOMINAL;
		}
		if (t->get_type() != LPAR)  {
			pe(1, "transform expr: expecte expr");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
		t = ef->read_token();
	}

	if (t->get_type() == KW_ORIENTATION) {
		delete t;
		t = ef->read_token();
		if (t->get_type() != STRING)  {
		    pe(1, "orientation expr: expected string");
		    delete t;
		    ef->skip_expr();
		    return RC_FAILED;
		   }
		 
		// BUG... this is duplicate code.
		// should have a decoder for all the various]
		// enum types, I guess.
		char *tstring = t->get_string();
		if (strcmp(tstring, "R0") == 0) orientation = R0;
		else if (strcmp(tstring, "R90") == 0) orientation = R90;
		else if (strcmp(tstring, "R180") == 0) orientation = R180;
		else if (strcmp(tstring, "R270") == 0) orientation = R270;
		else if (strcmp(tstring, "MX") == 0) orientation = MX;
		else if (strcmp(tstring, "MY") == 0) orientation = MY;
		else if (strcmp(tstring, "MYR90") == 0) orientation = MXR90;
		else if (strcmp(tstring, "MXR90") == 0) orientation = MYR90;
		else  {
			pe(1, "orientation expr: don\'t recognize type");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete tstring;

		delete t;
		t = ef->read_token();
		if (t->get_type() != RPAR) {
		    pe(1, "orientation expr: junk at end");
		    delete t;
		    ef->skip_expr();
		    return RC_FAILED;
		   }

		delete t;
		t = ef->read_token();
		if (t->get_type() == RPAR) return RC_NOMINAL;
		if (t->get_type() != LPAR) {
		    pe(1, "transform expr: expected expr");
		    delete t;
		    ef->skip_expr();
		    return RC_FAILED;
		   }

		delete t;
		t = ef->read_token();
	}

	if (t->get_type() == KW_ORIGIN) {
		origin = new ORIGIN_EXPR();
		origin->read_in(arg_namescope);
	} else  {
		pe(1, "transform expr: expected origin expr");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
				
	delete t;
	t = ef->read_token();
	if (t->get_type() != RPAR) {
	    pe(1, "transform expr: junk at end");
	    delete t;
	    ef->skip_expr();
	    return RC_FAILED;
	   }

	return RC_NOMINAL;
}


void
TRANSFORM_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(transform\n");
	printf("%s", print_line);

	if (orientation != ORIENTATION_NOT_SPECIFIED) {
		// BUG... this is also duplicate code
		switch (orientation) {
	            case R0:
			sprintf(p, "  (orientation R0)\n");
			break;
	            case R90:
			sprintf(p, "  (orientation R90)\n");
			break;
	            case R180:
			sprintf(p, "  (orientation R180)\n");
			break;
	            case R270:
			sprintf(p, "  (orientation R270)\n");
			break;
	            case MX:
			sprintf(p, "  (orientation MX)\n");
			break;
	            case MY:
			sprintf(p, "  (orientation MY)\n");
			break;
	            case MXR90:
			sprintf(p, "  (orientation MXR90)\n");
			break;
	            case MYR90:
			sprintf(p, "  (orientation MYR90)\n");
			break;
	            default:
			sprintf(p, "(orientation <unknown>)\n");
			break;
		}
	}
	printf("%s", print_line);

	if (origin) origin->print(arg_indent + 1);

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfTRANSFORM_EXPR::ListOfTRANSFORM_EXPR(
    TRANSFORM_EXPR *arg_expr, ListOfTRANSFORM_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

USERDATA_EXPR::USERDATA_EXPR()
{
}

rc_t
USERDATA_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	if (t->get_type() != KW_ORIENTATION)  {
		pe(1, "userdata expr: expected keyword 'orientation'");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	identifier = t->get_string(); 
	if (strcmp(t->get_string(), "orientation") != 0)  {
		pe(1, "userdata expr: miscompare: expected keyword 'orientation'");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;
	
	t = ef->read_token();
	if (t->get_type() != STRING)  {
		pe(1, "userdata expr: expected string");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	char *tstring = t->get_string();
	if (strcmp(tstring, "R0") == 0) orientation = R0;
	else if (strcmp(tstring, "R90") == 0) orientation = R90;
	else if (strcmp(tstring, "R180") == 0) orientation = R180;
	else if (strcmp(tstring, "R270") == 0) orientation = R270;
	else if (strcmp(tstring, "MX") == 0) orientation = MX;
	else if (strcmp(tstring, "MY") == 0) orientation = MY;
	else if (strcmp(tstring, "MYR90") == 0) orientation = MXR90;
	else if (strcmp(tstring, "MXR90") == 0) orientation = MYR90;
	else  {
		pe(1, "userdata expr: don\'t recognize type");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete tstring;

	delete t;
	t = ef->read_token();
	if (t->get_type() != RPAR) {
	    pe(1, "userdata expr: junk at end");
	    delete t;
	    ef->skip_expr();
	    return RC_FAILED;
	   }

	return RC_NOMINAL;
}

ListOfUSERDATA_EXPR::ListOfUSERDATA_EXPR(
    USERDATA_EXPR *arg_expr, ListOfUSERDATA_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

ListOfUSERDATA_EXPR::~ListOfUSERDATA_EXPR()
{
	if (next) delete next;
}  



///////////////////////////////////////////////////////

VIEW_EXPR::VIEW_EXPR()
{
}

rc_t
VIEW_EXPR::read_in(NAMESCOPE *arg_namescope) 
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// namedef
	namedef = new NAMEDEF(VIEW_NAMECLASS, this);
	if (namedef->read_in(arg_namescope) != RC_NOMINAL) {
		pe(1, "view expr: expected namedef\n");
	}
	
	rc_t rc = arg_namescope->insert(namedef);
	if (rc != RC_NOMINAL) {
		pe(1, "view expr: name in use %s\n");
	}
	namescope = new NAMESCOPE(arg_namescope, KW_VIEW, this);

	// viewType
	TOKEN *t = ef->read_token();
	if (t->get_type() != LPAR) {
		pe(1, "view expr: expected viewType");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_VIEWTYPE) {
		pe(1, "view expr: expected viewType");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != STRING)  {
		pe(1, "view expr: expected type");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	char *tstr = t->get_string();

	if (strcmp(tstr, "BEHAVIOR") == 0)		viewtype = BEHAVIOR;
	else if (strcmp(tstr, "DOCUMENT") == 0)		viewtype = DOCUMENT;
	else if (strcmp(tstr, "GRAPHIC") == 0)		viewtype = GRAPHIC;
	else if (strcmp(tstr, "LOGICMODEL") == 0)	viewtype = LOGICMODEL;
	else if (strcmp(tstr, "MASKLAYOUT") == 0)	viewtype = MASKLAYOUT;
	else if (strcmp(tstr, "NETLIST") == 0)		viewtype = NETLIST;
	else if (strcmp(tstr, "PCBLAYOUT") == 0)	viewtype = PCBLAYOUT;
	else if (strcmp(tstr, "SCHEMATIC") == 0)	viewtype = SCHEMATIC;
	else if (strcmp(tstr, "STRANGER") == 0)		viewtype = STRANGER;
	else if (strcmp(tstr, "SYMBOLIC") == 0)		viewtype = SYMBOLIC;
	else  {
		pe(1, "view expr: don't recognize type name");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}

	if (viewtype != GRAPHIC && viewtype != SCHEMATIC) {
		pe(0, "view expr: we don't do anyting with this view type");
		printf("    ...viewtype \"%s\"\n", tstr);
	}

	delete tstr;
	delete t;

	t = ef->read_token();
	if (t->get_type() != RPAR) {
		pe(1, "cellType expr: junk at the end\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	// interface
	t = ef->read_token();
	if (t->get_type() != LPAR)  {
		pe(1, "view expr: expected interface");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() != KW_INTERFACE) {
		pe(1, "view expr: expected interface");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	interface = new INTERFACE_EXPR();
	interface->read_in(namescope);
	delete t;


	// lists of things
	property_list = NULL;
	status = NULL;
	contents = NULL;
	t = ef->read_token();
	while (t->get_type() != RPAR) {
		if (t->get_type() != LPAR) {
			pe(1, "view expr: expected expression\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		delete t;
	
		t = ef->read_token();
		switch (t->get_type()) {
		    case KW_STATUS: {
			if (status != NULL)
			    pe(1, "view expr: additional status? ignore it...\n"); 
			status++;
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_CONTENTS: {
			if (contents)
				pe(1, "view expr: additional contents? ignore it\n");
			contents = new CONTENTS_EXPR();
			contents->read_in(namescope);
		    } break;

		    case KW_PROPERTY: {
			PROPERTY_EXPR *property_expr = new PROPERTY_EXPR();
			property_expr->read_in(namescope);
			property_list = new ListOfPROPERTY_EXPR(
			    property_expr, property_list);
		    } break;

		    case KW_COMMENT: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    case KW_USERDATA: {
			// NOT IMPLEMENTED
			ef->skip_expr();
		    } break;

		    default:  {
			pe(1, "view expr: illegal expression type\n"); 
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}
		}
		delete t;
		t = ef->read_token();
	}
	return RC_NOMINAL;
}

void
VIEW_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(view\n");
	printf("%s", print_line);
	namedef->print(arg_indent + 1);

	switch (viewtype) {
	    case BEHAVIOR:
		sprintf(p, "  BEHAVIOR\n");
		break;
	    case DOCUMENT:
		sprintf(p, "  DOCUMENT\n");
		break;
	    case GRAPHIC:
		sprintf(p, "  GRAPHIC\n");
		break;
	    case LOGICMODEL:
		sprintf(p, "  LOGICMODEL\n");
		break;
	    case MASKLAYOUT:
		sprintf(p, "  MASKLAYOUT\n");
		break;
	    case NETLIST:
		sprintf(p, "  NETLIST\n");
		break;
	    case PCBLAYOUT:
		sprintf(p, "  PCBLAYOUT\n");
		break;
	    case SCHEMATIC:
		sprintf(p, "  SCHEMATIC\n");
		break;
	    case STRANGER:
		sprintf(p, "  STRANGER\n");
		break;
	    case SYMBOLIC:
		sprintf(p, "  SYMBOLIC\n");
		break;
	}
	printf("%s", print_line);

	if (interface != NULL)	interface->print(arg_indent + 1);

	if (contents != NULL)	contents->print(arg_indent + 1);

	ListOfPROPERTY_EXPR *tproperty_list = property_list;
	while (tproperty_list != NULL) {
		tproperty_list->expr->print(arg_indent + 1);
		tproperty_list = tproperty_list->next;
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

ListOfVIEW_EXPR::ListOfVIEW_EXPR(
    VIEW_EXPR *arg_expr, ListOfVIEW_EXPR *arg_next)
    : expr(arg_expr), next(arg_next)
{
}

///////////////////////////////////////////////////////

VIEWREF_EXPR::VIEWREF_EXPR()
{
}

rc_t
VIEWREF_EXPR::read_in(NAMESCOPE *arg_namescope)
{
	EDIF_FILE *ef = EDIF_FILE::current_file;

	// nameRef
	viewnameref = new NAMEREF(VIEW_NAMECLASS);
	if (viewnameref->read_in(arg_namescope) != RC_NOMINAL) {
	    pe(1, "cell portimpelemntation: expected name\n");
	   }
	// don't do lookup now

	// maybe cellref
	TOKEN *t = ef->read_token();
	if (t->get_type() == LPAR) {
		delete t;

		t = ef->read_token();
		if (t->get_type() != KW_CELLREF) {
			pe(1, "viewref expr: expected cellref");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}

		cellref = new CELLREF_EXPR();
		cellref->read_in(arg_namescope);
		delete t;

		t = ef->read_token();
	}
	if (t->get_type() != RPAR)  {
		pe(1, "cellref expr: junk at end\n");
		delete t;
		ef->skip_expr();
		return RC_FAILED;
	}
	delete t;

	// now resolve the name
	// if there is no cellref, then resolve the view locally
	if (cellref == NULL) {
		viewnamedef = arg_namescope->lookup(viewnameref);
		if (viewnamedef == NULL) {
			pe(1, "viewref expr: can't lookup view locally");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}

	} else {
		CELL_EXPR *cell = NULL;
		cellref->cellnamedef->get_where_defined(&cell);
		if (cell == NULL)  {
			pe(1, "viewref expr: get_where_defined failed\n");
			delete t;
			ef->skip_expr();
			return RC_FAILED;
		}

		viewnamedef = cell->namescope->lookup(viewnameref);
		if (viewnamedef == NULL) return 
			pe(1, "viewref expr: get_where_defined failed\n");
	}
	
	return RC_NOMINAL;
}

void
VIEWREF_EXPR::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	sprintf(p, "(viewref\n");
	printf("%s", print_line);

	sprintf(p, "  %s\n", viewnameref->get_identifier());
	printf("%s", print_line);

	if (cellref != NULL) {
		cellref->print(arg_indent + 1);
	}

	sprintf(p, ")\n");
	printf("%s", print_line);
}

///////////////////////////////////////////////////////

