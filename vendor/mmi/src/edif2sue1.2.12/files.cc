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

#include <stdlib.h>	// for strtol

#include <util.h>

///////////////////////////////////////////////////////////

EDIF_FILE *EDIF_FILE::current_file = 0;


EDIF_FILE::EDIF_FILE(char *arg_name)
    : name(arg_name), fd(NULL), top_expr(NULL)
{
}

rc_t
EDIF_FILE::parse()
{
	current_file = this;

	TOKEN *t = read_token();
	if (t->get_type() != LPAR) {
		printf("file doesn\'t start with expression (LPAR)\n");
		delete t;
		return RC_FAILED;
	}
	delete t;	

	t = read_token();
	if (t->get_type() != KW_EDIF) {
		printf("file doesn\'t start with edif expression (KW_EDIF)\n");
		delete t;
		return RC_FAILED;
	}
	delete t;	

	EDIF_EXPR *edif_expr = new EDIF_EXPR();
	rc_t rc = edif_expr->read_in(NULL);
	if (rc != RC_NOMINAL) {
		printf("EDIF_FILE::parse fails\n");
		current_file = NULL;
		return rc;
	}

	current_file = NULL;
	top_expr = edif_expr;
	return RC_NOMINAL;
}


rc_t
EDIF_FILE::open()
{
	fd = fopen(name, "r");
	if (fd == NULL) {
		printf("open edif file \"%s\" failed, errno %d\n",
		    name, errno);
		return RC_FAILED;
	}
	lineno = 1;
	return RC_NOMINAL;
}

rc_t
EDIF_FILE::close()
{
	if (fd == NULL) {
		return RC_INVALID;
	}
	fclose(fd);
	fd = NULL; 
}	

EDIF_EXPR *
EDIF_FILE::get_top_expr()
{
	return top_expr;
}

int
EDIF_FILE::get_lineno()
{
	return lineno;
}

TOKEN *
EDIF_FILE::read_token()
{
	char c;
	char *ptr;

// ... there is an actual string of length 3800 in 
// library Ib (portorder property)
#define	SVAL_SIZE		5000
	char	sval[SVAL_SIZE+3];

	// skip leading whitespace
	while(1) {
		c = getc(fd);
		if (c == '\n')	lineno++;
		if (c == EOF)	return new TOKEN(ENDOFFILE, "EOF");
		if (!isspace(c))	break;
	}

	// parens
	if (c == '(')	return new TOKEN(LPAR, "LPAR");
	if (c == ')')	return new TOKEN(RPAR, "RPAR");

	// remove enclosing double-quotes, if any
	if (c == '\"') {
		ptr = sval;
		// *ptr++ = '\"';
		int char_counter = 1;
		while (1) {
			c = getc(fd);
			if (c == EOF) {
				printf("read_token: EOF in quoted string\n");
				return new TOKEN(INVALID, "INVALID");
			}
			// XXX ... should handle all the "special characters"...?
			// will any others cause problems?
			if (c == '#') {
				// XXX ... should do "ascii escape"... "%35%"
				// ... but sue has a problem with that also...
				continue;
			}			  
			if (c == '\n')	lineno++;
			if (c == '"')	break;
			if (char_counter++ < SVAL_SIZE) *ptr++ = c; 
		}
		// *ptr++ = '"';
		*ptr = '\0';
		if (char_counter >= SVAL_SIZE) {
			printf("encountered oversize string, length %d"
			    " truncated to length %d as follows:\n\n%s\n\n",
			    char_counter, SVAL_SIZE, sval);
		}
		char *string = strdup(sval);
		if (string == NULL) {
			printf("can\'t duplicate string???\n");
			return new TOKEN(INVALID, "INVALID");
		}
		return new TOKEN(string);
	}

	// so it's a string
	// BUG... we don't do number values
	// BUG... maybe we should check for legal character set

	ptr = sval;
	*ptr++ = c;
	int char_counter = 1;
	while (1) {
		c = getc(fd);
		if (c == '\n')		lineno++;
		if (isspace(c))		break;
		if (c == EOF)		break; 
		if (c == '('  ||  c == ')') {
			ungetc(c, fd);
			break;	
		}
		if (c == '"') {
			printf("read_token: double quote in string?\n");
		}
		if (char_counter++ < SVAL_SIZE) *ptr++ = c; 
	}
	if (char_counter >= SVAL_SIZE) {
		printf("encountered oversize string, length %x"
		    " truncated to length %d as follows:\n\n%s\n\n",
		    char_counter, SVAL_SIZE, sval);
	}
	*ptr = '\0';

	// printf("read token \"%s\"\n", sval);

	// check for collisions with string used to generate 
	// unique netnames
	if (strstr(sval, SUE::buscombine_namestr) != 0) {
		printf("unique namestring %s is used in input file line %d\n",
		    SUE::buscombine_namestr, get_lineno());
		exit(-1);
	}

	// is this string a keyword?
	// RFE... this could be more efficient, if we care...
	switch (sval[0]) {
	    case 'a':
		if (strcmp(sval, "arc") == 0)		
					return new TOKEN(KW_ARC, sval);
		if (strcmp(sval, "annotate") == 0)	
					return new TOKEN(KW_ANNOTATE, sval);
		if (strcmp(sval, "array") == 0)		
					return new TOKEN(KW_ARRAY, sval);
		if (strcmp(sval, "acload") == 0)
					return new TOKEN(KW_ACLOAD, sval);
		if (strcmp(sval, "arrayRelatedInfo") == 0)
					return new TOKEN(KW_ARRAYRELATEDINFO, sval);
		if (strcmp(sval, "assign") == 0)
					return new TOKEN(KW_ASSIGN, sval);
		break;

	    case 'b':
		if (strcmp(sval, "boundingBox") == 0)	
					return new TOKEN(KW_BOUNDINGBOX, sval);
		if (strcmp(sval, "borderPattern") == 0)
					return new TOKEN(KW_BORDERPATTERN, sval);
		if (strcmp(sval, "borderWidth") == 0)
					return new TOKEN(KW_BORDERWIDTH, sval);
		if (strcmp(sval, "block") == 0)
					return new TOKEN(KW_BLOCK, sval);
		break;

	    case 'c':
		if (strcmp(sval, "cell") == 0)		
					return new TOKEN(KW_CELL, sval);
		if (strcmp(sval, "cellType") == 0)	
					return new TOKEN(KW_CELLTYPE, sval);
		if (strcmp(sval, "circle") == 0)	
					return new TOKEN(KW_CIRCLE, sval);
		if (strcmp(sval, "comment") == 0)	
					return new TOKEN(KW_COMMENT, sval);
		if (strcmp(sval, "commentGraphics") == 0) 
					return new TOKEN(KW_COMMENTGRAPHICS, sval);
		if (strcmp(sval, "connectLocation") == 0) 
					return new TOKEN(KW_CONNECTLOCATION, sval);
		if (strcmp(sval, "contents") == 0)	
					return new TOKEN(KW_CONTENTS, sval);
		if (strcmp(sval, "cellType") == 0)
					return new TOKEN(KW_CELLTYPE, sval);
		if (strcmp(sval, "color") == 0)
					return new TOKEN(KW_COLOR, sval);
		if (strcmp(sval, "comment") == 0)
					return new TOKEN(KW_COMMENT, sval);
		if (strcmp(sval, "cornerType") == 0)
					return new TOKEN(KW_CORNERTYPE, sval);
		if (strcmp(sval, "criticality") == 0)
					return new TOKEN(KW_CRITICALITY, sval);
		if (strcmp(sval, "constant") == 0)
					return new TOKEN(KW_CONSTANT, sval);
		if (strcmp(sval, "constraint") == 0)
					return new TOKEN(KW_CONSTRAINT, sval);
		if (strcmp(sval, "curve") == 0)
					return new TOKEN(KW_CURVE, sval);
		if (strcmp(sval, "cellRef") == 0)
					return new TOKEN(KW_CELLREF, sval);
		break;

	    case 'd':	
		if (strcmp(sval, "delta") == 0)	
					return new TOKEN(KW_DELTA, sval);
		if (strcmp(sval, "design") == 0)	
					return new TOKEN(KW_DESIGN, sval);
		if (strcmp(sval, "direction") == 0)	
					return new TOKEN(KW_DIRECTION, sval);
		if (strcmp(sval, "display") == 0)	
					return new TOKEN(KW_DISPLAY, sval);
		if (strcmp(sval, "dot") == 0)		
					return new TOKEN(KW_DOT, sval);
		if (strcmp(sval, "dcFaninLoad") == 0)
					return new TOKEN(KW_DCFANINLOAD, sval);
		if (strcmp(sval, "dcFanoutLoad") == 0)
					return new TOKEN(KW_DCFANOUTLOAD, sval);
		if (strcmp(sval, "dcMaxFanin") == 0)
					return new TOKEN(KW_DCMAXFANIN, sval);
		if (strcmp(sval, "dcMaxFanout") == 0)
					return new TOKEN(KW_DCMAXFANOUT, sval);
		if (strcmp(sval, "design") == 0)
					return new TOKEN(KW_DESIGN, sval);
		if (strcmp(sval, "designator") == 0)
					return new TOKEN(KW_DESIGNATOR, sval);
		if (strcmp(sval, "designator") == 0)
					return new TOKEN(KW_DESIGNATOR, sval);
		break;

	    case 'e':
		if (strcmp(sval, "edif") == 0)		
					return new TOKEN(KW_EDIF, sval);
		if (strcmp(sval, "edifLevel") == 0)	
					return new TOKEN(KW_EDIFLEVEL, sval);
		if (strcmp(sval, "external") == 0)	
					return new TOKEN(KW_EXTERNAL, sval);
		if (strcmp(sval, "edifVersion") == 0)	
					return new TOKEN(KW_EDIFVERSION, sval);
		if (strcmp(sval, "edifLevel") == 0)
					return new TOKEN(KW_EDIFLEVEL, sval);
		if (strcmp(sval, "endType") == 0)
					return new TOKEN(KW_ENDTYPE, sval);
		if (strcmp(sval, "external") == 0)
					return new TOKEN(KW_EXTERNAL, sval);
		if (strcmp(sval, "e") == 0)
					return new TOKEN(KW_E, sval);
		break;

	    case 'E':
		if (strcmp(sval, "E") == 0)
					return new TOKEN(KW_E, sval);

		// bad capitalization from Tanner
		if (strcmp(sval, "EDIF") == 0)		
					return new TOKEN(KW_EDIF, sval);
		if (strcmp(sval, "EDIFLevel") == 0)	
					return new TOKEN(KW_EDIFLEVEL, sval);
		if (strcmp(sval, "EDIFVersion") == 0)	
					return new TOKEN(KW_EDIFVERSION, sval);
		if (strcmp(sval, "EDIFLevel") == 0)
					return new TOKEN(KW_EDIFLEVEL, sval);

		break;


	    case 'f':
		if (strcmp(sval, "figure") == 0)	
					return new TOKEN(KW_FIGURE, sval);
		if (strcmp(sval, "figureGroup") == 0)	
					return new TOKEN(KW_FIGUREGROUP, sval);
		if (strcmp(sval, "figureGroupOverride") == 0) 
					return new TOKEN(KW_FIGUREGROUPOVERRIDE, sval);
		if (strcmp(sval, "fillPattern") == 0)
					return new TOKEN(KW_FILLPATTERN, sval);
		if (strcmp(sval, "follow") == 0)
					return new TOKEN(KW_FOLLOW, sval);
		if (strcmp(sval, "fabricate") == 0)
					return new TOKEN(KW_FABRICATE, sval);
		break;

	    case 'i':
		if (strcmp(sval, "instance") == 0)	
					return new TOKEN(KW_INSTANCE, sval);
		if (strcmp(sval, "instanceRef") == 0)	
					return new TOKEN(KW_INSTANCEREF, sval);
		if (strcmp(sval, "interface") == 0)	
					return new TOKEN(KW_INTERFACE, sval);
		if (strcmp(sval, "includeFigureGroup") == 0)
					return new TOKEN(KW_INCLUDEFIGUREGROUP, sval);
		if (strcmp(sval, "if") == 0)
					return new TOKEN(KW_IF, sval);
		if (strcmp(sval, "iterate") == 0)
					return new TOKEN(KW_ITERATE, sval);
		break;

	    case 'j':
		if (strcmp(sval, "justify") == 0)	
					return new TOKEN(KW_JUSTIFY, sval);
		if (strcmp(sval, "joined") == 0)
					return new TOKEN(KW_JOINED, sval);
		if (strcmp(sval, "joined") == 0)
					return new TOKEN(KW_JOINED, sval);
		break;

	    case 'k':
		if (strcmp(sval, "keywordDisplay") == 0) 
					return new TOKEN(KW_KEYWORDDISPLAY, sval);
		if (strcmp(sval, "keywordMap") == 0)	
					return new TOKEN(KW_KEYWORDMAP, sval);
		break;

	    case 'l':
		if (strcmp(sval, "libraryRef") == 0)	
					return new TOKEN(KW_LIBRARYREF, sval);
		if (strcmp(sval, "library") == 0)	
					return new TOKEN(KW_LIBRARY, sval);
		if (strcmp(sval, "logicPort") == 0)
					return new TOKEN(KW_LOGICPORT, sval);
		break;

	    case 'm':
		if (strcmp(sval, "mustJoin") == 0)
					return new TOKEN(KW_MUSTJOIN, sval);
		break;

	    case 'n':
		if (strcmp(sval, "name") == 0)		
					return new TOKEN(KW_NAME, sval);
		if (strcmp(sval, "net") == 0)		
					return new TOKEN(KW_NET, sval);
		if (strcmp(sval, "netBundle") == 0)
					return new TOKEN(KW_NETBUNDLE, sval);
		if (strcmp(sval, "netDelay") == 0)
					return new TOKEN(KW_NETDELAY, sval);
		if (strcmp(sval, "numberDefinition") == 0)
					return new TOKEN(KW_NUMBERDEFINITION, sval);
		break;

	    case 'o':
		if (strcmp(sval, "offPageConnector") == 0)
					return new TOKEN(KW_OFFPAGECONNECTOR, sval);
		// NOTE: "openShape" is correct, but "openshape"
		// is what is used in the Equator files.
		if (strcmp(sval, "openshape") == 0)
					return new TOKEN(KW_OPENSHAPE, sval);
		if (strcmp(sval, "openShape") == 0)
					return new TOKEN(KW_OPENSHAPE, sval);
		if (strcmp(sval, "orientation") == 0)	
					return new TOKEN(KW_ORIENTATION, sval);
		if (strcmp(sval, "origin") == 0)	
					return new TOKEN(KW_ORIGIN, sval);
		if (strcmp(sval, "owner") == 0)
					return new TOKEN(KW_OWNER, sval);
		break;

	    case 'p':
		if (strcmp(sval, "page") == 0)		
					return new TOKEN(KW_PAGE, sval);
		if (strcmp(sval, "path") == 0)		
					return new TOKEN(KW_PATH, sval);
		if (strcmp(sval, "pointList") == 0)		
					return new TOKEN(KW_POINTLIST, sval);
		if (strcmp(sval, "port") == 0)		
					return new TOKEN(KW_PORT, sval);
		if (strcmp(sval, "portRef") == 0)		
					return new TOKEN(KW_PORTREF, sval);
		if (strcmp(sval, "property") == 0)	
					return new TOKEN(KW_PROPERTY, sval);
		if (strcmp(sval, "portImplementation") == 0) 
					return new TOKEN(KW_PORTIMPLEMENTATION, sval);
		if (strcmp(sval, "pageSize") == 0)
					return new TOKEN(KW_PAGESIZE, sval);
		if (strcmp(sval, "paramater") == 0)
					return new TOKEN(KW_PARAMETER, sval);
		if (strcmp(sval, "paramaterAssign") == 0)
					return new TOKEN(KW_PARAMATERASSIGN, sval);
		if (strcmp(sval, "pathWidth") == 0)
					return new TOKEN(KW_PATHWIDTH, sval);
		if (strcmp(sval, "polygon") == 0)
					return new TOKEN(KW_POLYGON, sval);
		if (strcmp(sval, "portInstance") == 0)
					return new TOKEN(KW_PORTINSTANCE, sval);
		if (strcmp(sval, "propertyDisplay") == 0)
					return new TOKEN(KW_PROPERTYDISPLAY, sval);
		if (strcmp(sval, "pt") == 0)
					return new TOKEN(KW_PT, sval);
		if (strcmp(sval, "permutable") == 0)
					return new TOKEN(KW_PERMUTABLE, sval);
		if (strcmp(sval, "portBundle") == 0)
					return new TOKEN(KW_PORTBUNDLE, sval);
		if (strcmp(sval, "physicalDesignRule") == 0)
					return new TOKEN(KW_PHYSICALDESIGNRULE, sval);
		if (strcmp(sval, "protectionFrame") == 0)
					return new TOKEN(KW_PROTECTIONFRAME, sval);
		break;

	    case 'r':
		if (strcmp(sval, "rename") == 0)	
					return new TOKEN(KW_RENAME, sval);
		if (strcmp(sval, "rectangle") == 0)
					return new TOKEN(KW_RECTANGLE, sval);
		break;
	
	    case 's':
		if (strcmp(sval, "scaleX") == 0)	
					return new TOKEN(KW_SCALEX, sval);
		if (strcmp(sval, "scaleY") == 0)	
					return new TOKEN(KW_SCALEY, sval);
		if (strcmp(sval, "shape") == 0)	
					return new TOKEN(KW_SHAPE, sval);
		if (strcmp(sval, "status") == 0)	
					return new TOKEN(KW_STATUS, sval);
		if (strcmp(sval, "stringDisplay") == 0) 
					return new TOKEN(KW_STRINGDISPLAY, sval);
		if (strcmp(sval, "section") == 0)
					return new TOKEN(KW_SECTION, sval);
		if (strcmp(sval, "simulationInfo") == 0)
					return new TOKEN(KW_SIMULATIONINFO, sval);
		if (strcmp(sval, "simulate") == 0)
					return new TOKEN(KW_SIMULATE, sval);
		if (strcmp(sval, "status") == 0)
					return new TOKEN(KW_STATUS, sval);
		if (strcmp(sval, "symbol") == 0)
					return new TOKEN(KW_SYMBOL, sval);
		break;

	    case 't':
		if (strcmp(sval, "technology") == 0)	
					return new TOKEN(KW_TECHNOLOGY, sval);
		if (strcmp(sval, "textHeight") == 0)	
					return new TOKEN(KW_TEXTHEIGHT, sval);
		if (strcmp(sval, "transform") == 0)	
					return new TOKEN(KW_TRANSFORM, sval);
		if (strcmp(sval, "technology") == 0)
					return new TOKEN(KW_TECHNOLOGY, sval);
		if (strcmp(sval, "timing") == 0)
					return new TOKEN(KW_TIMING, sval);
		break;

	    case 'u':
		if (strcmp(sval, "unit") == 0)
					return new TOKEN(KW_UNIT, sval);
		if (strcmp(sval, "unused") == 0)
					return new TOKEN(KW_UNUSED, sval);
		if (strcmp(sval, "userData") == 0)
					return new TOKEN(KW_USERDATA, sval);
		break;

	    case 'v':
		if (strcmp(sval, "view") == 0)		
					return new TOKEN(KW_VIEW, sval);
		if (strcmp(sval, "viewRef") == 0)		
					return new TOKEN(KW_VIEWREF, sval);
		if (strcmp(sval, "viewType") == 0)	
					return new TOKEN(KW_VIEWTYPE, sval);
		if (strcmp(sval, "viewList") == 0)
					return new TOKEN(KW_VIEWLIST, sval);
		if (strcmp(sval, "viewMap") == 0)
					return new TOKEN(KW_VIEWMAP, sval);
		if (strcmp(sval, "viewRef") == 0)
					return new TOKEN(KW_VIEWREF, sval);
		if (strcmp(sval, "visible") == 0)
					return new TOKEN(KW_VISIBLE, sval);
		if (strcmp(sval, "variable") == 0)
					return new TOKEN(KW_VARIABLE, sval);
		break;

	    case 'w':
		if (strcmp(sval, "when") == 0)
					return new TOKEN(KW_WHEN, sval);
		if (strcmp(sval, "weakJoined") == 0)
					return new TOKEN(KW_WEAKJOINED, sval);
		if (strcmp(sval, "while") == 0)
					return new TOKEN(KW_WHILE, sval);
		break;

	    default:
		break;
	}
	// not keword, just regular

	// maybe an integer?
	ptr = sval;
	char *endp = NULL;
	int value = (int)strtol(ptr, &endp, 10);
	if (*endp == '\0') {

		if (SUE::SCALE_COORDS == true) {
			value *= SUE::scale_coords_factor;
		}

		// I ate the whole string!
		return new TOKEN(value);
	}

	// ...must be just a regular string thing.
	char *string = strdup(sval);
	if (string == NULL) {
		printf("cant duplicate string???\n");
		return new TOKEN(INVALID, "INVALID");
	}
	return new TOKEN(string);
}

void
EDIF_FILE::skip_expr()
{
	int depth = 1;	// we are just inside an expression;
			// when depth gets back to 0, we are done.
	while (depth > 0) {
		TOKEN *t = read_token();
		switch (t->get_type()) {
		    case LPAR:	depth++;	break;
		    case RPAR:	depth--;	break;
		    default:			break;
		}
		delete t;
	}
	return;
}
