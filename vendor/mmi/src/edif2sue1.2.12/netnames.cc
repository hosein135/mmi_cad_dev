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
#include <stdlib.h>


NETNAME::NETNAME(char *arg_name) 
    :  name(NULL), generated_name(NULL)
{
	// this netname stuff is all cadence specific.
	// there is possible confusion with more correct array notation
	//
	// also, the following hack used to be in NAMEDEF::get_stringvalue,
	// but it is another Ugly Cadence Hack.
	//
	// this guy has a bad habit of trailing '#'
	// which confuses tcl.  
	// BUG... pretty hackish fix
	// 
	// char *p = outstr + strlen(outstr) -1;
	// if (*p == '#')	*p = '\0';
	// 

	name = strdup(arg_name);
}

NETNAME::~NETNAME() 
{
	// delete name;
	// if (generated_name != NULL) delete generated_name;

	// BUG....
	// need to descend the tree & // delete substructures
}

rc_t
NETNAME::parse() {

	if (*name == '\0')	return RC_INVALID;

	char *p = name;
	char *endp = name + strlen(name);
	
	// strip enclosing {}, if any
	if (*p == '{') {
		if (*(endp - 1) != '}')		SUE::exxit(101, "");

		p++;
		endp--;
	}

	return EXPR::get_expr2(&expr, &p, endp); 
}

char *
NETNAME::get_simple_name()
{
	if (expr->next)			return NULL;
	if (expr->multiplier != 1)	return NULL;

	SUBSCRIPT *ss = expr->subscript;

	// this is a single wire with an uninflected name
	if (ss == NULL)	return strdup(name);
	
	if (ss->next)			return NULL;
	if (ss->multiplier != 1)	return NULL;

	// this is a single wire with a subscripted name
	if (ss->range_from == ss->range_to) {
		char *retstr = (char *)malloc(strlen(name) + 20);
		sprintf(retstr, "%s[%d]", expr->name, ss->range_from);
		return retstr;
	}

	// this is a bundle of wires with a subscript-range
	// name that Sue knows how to handle
	// ...we don't care what direction the subscripts run any more.

	if ( // ss->range_from > ss->range_to &&
	    ss->range_incr == 1) {

		char *retstr = (char *)malloc(strlen(name) + 20);
		sprintf(retstr, "%s[%d:%d]", expr->name, ss->range_from,
		    ss->range_to);
		return retstr;
	}

	return NULL;
}

int
NETNAME::get_width() 
{
	int width = 0;
	expr->get_width(&width);
	return width;
}

int
NETNAME::generate_name_nets(FILE *out, int x_origin, int arg_y_top)
{
	int y_top = arg_y_top;
	expr->generate_name_nets(out, x_origin, &arg_y_top);
	return y_top;
}

rc_t
NETNAME::EXPR::get_expr2(EXPR**arg_exprp, char** arg_pp, char *endp) 
{

	char *p = *arg_pp;
	EXPR *expr = NULL;
	rc_t rc;

	if (token_is('<', &p, endp)) {
		if (!token_is('*', &p, endp))	SUE::exxit(102, "");
		expr = new EXPR();

		rc = get_number(&expr->multiplier, &p, endp);
		if (rc != RC_NOMINAL)	SUE::exxit(103, "");

		if (!token_is('>', &p, endp))	SUE::exxit(104, "");

		rc = get_expr1(&expr->expr, &p, endp);
		if (rc != RC_NOMINAL)	SUE::exxit(105, "");

	} else if (token_is('[', &p, endp)) {
		if (!token_is('*', &p, endp))	SUE::exxit(1021, "");
		expr = new EXPR();

		rc = get_number(&expr->multiplier, &p, endp);
		if (rc != RC_NOMINAL)	SUE::exxit(1031, "");

		if (!token_is(']', &p, endp))	SUE::exxit(1041, "");

		rc = get_expr1(&expr->expr, &p, endp);
		if (rc != RC_NOMINAL)	SUE::exxit(1051, "");

	} else { 
		rc = get_expr1(&expr, &p, endp);
		if (rc != RC_NOMINAL)	SUE::exxit(106, "");
	}

	if (token_is(',', &p, endp)) {
		rc = get_expr2(&expr->next, &p, endp);
		if (rc != RC_NOMINAL)	SUE::exxit(107, "");
	}

	*arg_exprp = expr;
	*arg_pp = p;

	return RC_NOMINAL;
}

rc_t
NETNAME::EXPR::get_expr1(EXPR **arg_exprp, char **arg_pp, char *endp)
{
	char *p = *arg_pp;
	EXPR *expr = NULL;
	rc_t rc;

	if (token_is('(', &p, endp)) {
		rc = get_expr2(&expr, &p, endp);
		if (rc != RC_NOMINAL)	SUE::exxit(108, "");

		if (!token_is(')', &p, endp))	SUE::exxit(109, "");  

	} else {
		expr = new EXPR();

		rc = get_name(&expr->name, &p, endp);
		if (rc != RC_NOMINAL)	SUE::exxit(110, "expr->name");

		if (token_is('<', &p, endp)) {
			rc = get_sscr2(&expr->subscript, &p, endp);
			if (rc != RC_NOMINAL)	SUE::exxit(111, "");
			if (!token_is('>', &p, endp))	SUE::exxit(112, "");
		}
	}

	*arg_exprp = expr;
	*arg_pp = p;

	return RC_NOMINAL;
}

BOOLEAN
NETNAME::EXPR::token_is(char arg_token, char **argpp, char *endp)
{
	char *p = *argpp;
	while (p < endp && *p == ' ') 	p++;

	if (p >= endp) return false;
	if (arg_token == *p) {
		*argpp = ++p;
		return true;
	}

	return false;
}

rc_t
NETNAME::EXPR::get_name(char **arg_namep, char **argpp, char *endp)
{
	char *p = *argpp;
	while (p < endp && *p == ' ') 	p++;
	char *r = p;

	if (p >= endp || 
	      (*r != '&'	&& 
	       !isalpha(*r)	&&
	       !isdigit(*r)	&&
	       *r != '_'	  ))	return RC_NOTFOUND;

	r++;
	while (r < endp && 
	    (isalpha(*r)   || 
	     isdigit(*r)   ||
 	     *r == '\''	   ||
 	     *r == '_'	   ||
	     *r == '-'       )) {
		r++;
	}

	int namesize = r - p;
	*arg_namep = new char[namesize + 1];
	strncpy(*arg_namep, p, namesize);
	(*arg_namep)[namesize] = '\0';

	*argpp = r;
	return RC_NOMINAL;
}

rc_t
NETNAME::EXPR::get_number(int *arg_numberp, char **argpp, char *endp)
{
	char *p = *argpp;
	while (p < endp && *p == ' ')	p++;
	
	char *r = NULL;
	int number = strtol(p, &r, 10);
	if (r == NULL)	return RC_NOTFOUND;

	*arg_numberp = number;
	*argpp = r;
	return RC_NOMINAL; 	
}	



rc_t
NETNAME::EXPR::get_sscr2(SUBSCRIPT**arg_sscrp, char** arg_pp, char *endp) {

	char *p = *arg_pp;
	SUBSCRIPT *sscr = NULL;
	rc_t rc;

	rc = get_sscr1(&sscr, &p, endp);
	if (rc != RC_NOMINAL)	SUE::exxit(113, "");

	if (token_is('*', &p, endp)) {
		rc = get_number(&sscr->multiplier, &p, endp);
		if (rc != RC_NOMINAL)	SUE::exxit(114, "");
	}

	if (token_is(',', &p, endp)) {
		rc = get_sscr2(&sscr->next, &p, endp);
		if (rc != RC_NOMINAL)	SUE::exxit(115, "");
	}

	*arg_sscrp = sscr;
	*arg_pp = p;

	return RC_NOMINAL;
}

rc_t
NETNAME::EXPR::get_sscr1(SUBSCRIPT **arg_sscrp, char **arg_pp, char *endp)
{
	char *p = *arg_pp;
	SUBSCRIPT *sscr = new SUBSCRIPT();
	rc_t rc;

	if (token_is('(', &p, endp)) {
		rc = get_sscr2(&sscr->subscript, &p, endp);
		if (rc != RC_NOMINAL)	SUE::exxit(116, "");

		if (!token_is(')', &p, endp))	SUE::exxit(117, "");  

	} else {
		rc = get_number(&sscr->range_from, &p, endp);
		if (rc != RC_NOMINAL)	SUE::exxit(118, "");

		if (token_is(':', &p, endp)) {
			rc = get_number(&sscr->range_to, &p, endp);
			if (rc != RC_NOMINAL)	SUE::exxit(119, "");

			if (token_is(':', &p, endp)) {
				rc = get_number(&sscr->range_incr, &p, endp);
				if (rc != RC_NOMINAL)	SUE::exxit(120, "");
			}
		} else {
			sscr->range_to = sscr->range_from;
		}
	}

	*arg_sscrp = sscr;
	*arg_pp = p;

	return RC_NOMINAL;
}

rc_t
NETNAME::EXPR::print_nets()
{
	if (expr != NULL && subscript != NULL) {
		printf("BOGUS %n subscript AND expr???\n");
		return RC_BADSYNTAX;
	}

	for (int i = 0; i < multiplier; i++) {
		if (subscript) 		subscript->print_nets(name);
		else if (expr)		expr->print_nets();
		else			printf("net %s\n", name);
	}
 		
	if (next)			next->print_nets();

	return RC_NOMINAL;
}

rc_t
NETNAME::SUBSCRIPT::print_nets(char *name)
{
	if (multiplier <= 0)	printf("BOGUS %n multiplier %d??\n", name, multiplier);

	// in this case we iterate the group described by the subscript
	// (which used to be in parens)

	if (subscript)	for (int i = 0; i < multiplier; i++) {
		subscript->print_nets(name);
	}

	// this is the "ordinary" case; iterate each net in the range 
	// ...range is increasing...
	else if (range_from <= range_to) {

		if (range_to < range_from) {
			printf("BOGUS %n no entries? from %d to %d incr %d\n",
			    name, range_from, range_to, range_incr);
			return RC_BADSYNTAX;
		}
		
		for (int n = range_from; n <= range_to; n += range_incr) {
			for (int i = 0; i < multiplier; i++) {
				printf("net %s[%d]\n", name, n);
			}
		}
	}

	// ...range is decreasing...		
	else if (range_from > range_to) {

		 if (range_to > range_from) {
			printf("BOGUS %n no entries? from %d to %d incr %d\n",
			    name, range_from, range_to, range_incr);
			return RC_BADSYNTAX;
		}

		for (int n = range_from; n >= range_to; n -= range_incr) {
			for (int i = 0; i < multiplier; i++) {
				printf("net %s[%d]\n", name, n);
			}
		}
	}
		
	else 	printf("BOGUS %n incr is 0???\n", name);


	if (next)	next->print_nets(name);

	return RC_NOMINAL;
}


rc_t
NETNAME::EXPR::generate_name_nets(FILE *out, int x_origin, int *y_top)
{
	if (expr != NULL && subscript != NULL) {
		printf("BOGUS %n subscript AND expr???\n");
		return RC_BADSYNTAX;
	}

	for (int i = 0; i < multiplier; i++) {
		if (subscript) 		subscript->generate_name_nets(out, x_origin, y_top, name);
		else if (expr)		expr->generate_name_nets(out, x_origin, y_top);
		else {
			fprintf(out,
			    "  make name_net_s -name {%s} -origin {%d %d}\n",
			    name, x_origin, *y_top);
			*y_top += BUS_COMBINE_YINCR;
		}
	}
 		
	if (next)	next->generate_name_nets(out, x_origin, y_top);

	return RC_NOMINAL;
}

rc_t
NETNAME::SUBSCRIPT::generate_name_nets(FILE *out, int x_origin, int *y_top, char *name)
{
	if (multiplier <= 0)	printf("BOGUS %n multiplier %d??\n", name, multiplier);

	// in this case we iterate the group described by the subscript
	// (which used to be in parens)

	if (subscript)	for (int i = 0; i < multiplier; i++) {
		subscript->generate_name_nets(out, x_origin, y_top, name);
	}

	// this is the "ordinary" case; iterate each net in the range 
	// ...range is increasing...
	else if (range_from <= range_to) {

		if (range_to < range_from) {
			printf("BOGUS %n no entries? from %d to %d incr %d\n",
			    name, range_from, range_to, range_incr);
			return RC_BADSYNTAX;
		}
		
		for (int n = range_from; n <= range_to; n += range_incr) {
			for (int i = 0; i < multiplier; i++) {
				fprintf(out,
				    "  make name_net_s -name {%s[%d]} -origin {%d %d}\n",
				    name, n, x_origin, *y_top);
				*y_top += BUS_COMBINE_YINCR;

			}
		}
	}

	// ...range is decreasing...		
	else if (range_from > range_to) {

		 if (range_to > range_from) {
			printf("BOGUS %n no entries? from %d to %d incr %d\n",
			    name, range_from, range_to, range_incr);
			return RC_BADSYNTAX;
		}

		for (int n = range_from; n >= range_to; n -= range_incr) {
			for (int i = 0; i < multiplier; i++) {
				fprintf(out,
				    "  make name_net_s -name {%s[%d]} -origin {%d %d}\n",
				    name, n, x_origin, *y_top);
				*y_top += BUS_COMBINE_YINCR;
			}
		}
	}
		
	else 	printf("BOGUS %n incr is 0???\n", name);


	if (next)	next->generate_name_nets(out, x_origin, y_top, name);

	return RC_NOMINAL;
}


rc_t
NETNAME::EXPR::get_width(int *width)
{
	for (int i = 0; i < multiplier; i++) {
		if (subscript) 		subscript->get_width(width);
		else if (expr)		expr->get_width(width);
		else			(*width)++;
	}
 		
	if (next)			next->get_width(width);

	return RC_NOMINAL;
}

rc_t
NETNAME::SUBSCRIPT::get_width(int *width)
{

	// in this case we iterate the group described by the subscript
	// (which used to be in parens)

	if (subscript)	for (int i = 0; i < multiplier; i++) {
		subscript->get_width(width);
	}

	// this is the "ordinary" case; iterate each net in the range 
	// ...range is increasing...
	else if (range_from <= range_to) {

		for (int n = range_from; n <= range_to; n += range_incr) {
			for (int i = 0; i < multiplier; i++) {
				(*width)++;
			}
		}
	}

	// ...range is decreasing...		
	else if (range_from > range_to) {

		for (int n = range_from; n >= range_to; n -= range_incr) {
			for (int i = 0; i < multiplier; i++) {
				(*width)++;
			}
		}
	}
		
	if (next)	next->get_width(width);

	return RC_NOMINAL;
}


ListOfNETNAME::ListOfNETNAME(NETNAME *arg_netname, ListOfNETNAME *arg_next)
    : netname(arg_netname), next(arg_next)
{
}

ListOfNETNAME::~ListOfNETNAME()
{
    // delete netname;
    // if (next != NULL) delete next;
}




// int
// main() {
// //	char *p = "a,b,<*23>c,<*16>(efg,hij)";
// //	char *p = "a,b";
// 	char *p = "a[1], b[2:3], c [4:5:2], d[7:8*3], e[(10:11)*3], f[13,14:16,13:9:-1,0]";
// //	char *p = "f[13,14:15,16:17:18,0]";
// 
// 	char *endp = p + strlen(p);
// 
// 
// 	EXPR *expr = NULL;
// 	rc_t rc = EXPR::get_expr2(&expr, &p, endp);
// 	if (rc != RC_NOMINAL) {
// 		printf("oops! ....NOW what?\n");
// 	}
// 
// 	expr->print_nets();
// 
// 	return 0;
// }
// 


