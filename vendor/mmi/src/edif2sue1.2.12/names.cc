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
#include <stdlib.h>	// for malloc

rc_t pe(int serverity, char *arg_str);
extern char	print_line[];
extern char *	endp;


///////////////////////////////////////////////////////

NAMEDEF::NAMEDEF(NAMECLASS arg_nameclass, void *arg_where_defined)
    : identifier(NULL), rename(NULL), name(NULL), 
    nameclass(arg_nameclass), where_defined(arg_where_defined),
    is_array(false), array_size(0)
{
}

rc_t
NAMEDEF::uniquify()
{
	static int uniquifier = 7700;

	if (identifier == NULL) {
		// we could figure out how to do this...
		return RC_FAILED;
	}

	char* new_id = new char[strlen(identifier) + 6];
	sprintf(new_id, "%s__%d", identifier, uniquifier);
	
	delete identifier;
	identifier = new_id;

	return RC_NOMINAL;

}


rc_t 
NAMEDEF::read_in(NAMESCOPE *arg_namescope) 
{
	// unlike the regular read_in stuff, the first token got
	// will be the first token of the nameDef, which 
	// might be a STRING or an LPAR RNAME ...
	identifier = NULL;
	rename = NULL;
	name = NULL;


	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	if (t->get_type() != LPAR) {
		identifier = t->get_string();
		if (identifier == NULL)
			return pe(1, "nameDef: expected string or name or rename\n");
		delete t;

		return RC_NOMINAL;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() == KW_RENAME) {
		rename = new RENAME_EXPR();
		if (rename->read_in(arg_namescope) != RC_NOMINAL)
			return pe(1, "nameDef: expected rename\n");

	} else if (t->get_type() == KW_NAME) { 
		name = new NAME_EXPR();
		if (name->read_in(arg_namescope) != RC_NOMINAL)
			return pe(1, "nameDef: expected name_expr\n");

	} else if (t->get_type() == KW_ARRAY) { 
		delete t;

		NAMEDEF *tnamedef = new NAMEDEF(nameclass, where_defined);
		if (tnamedef->read_in(arg_namescope) != RC_NOMINAL)
			return pe(1, "nameDef array: expected nameDef\n");
		if (tnamedef->is_array == true)
			return pe(1, "nested arrays not supported\n");
		*this = *tnamedef;
		delete tnamedef;
		is_array = true;

		t = ef->read_token();
		if (t->get_type() != INTEGER)	
			return pe(1, "nameDef expr: expected integer array size\n");
		array_size = t->get_integer();
		delete t;

		t = ef->read_token();
		if (t->get_type() != RPAR)	
			return pe(1, "nameDef expr: multi-dim arrays not supported (or junk at end?)\n");
		delete t;

	} else 
		return pe(1, "nameDef: expected string or name or rename or array\n");

	return RC_NOMINAL;
}

void
NAMEDEF::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	if (identifier != NULL) {	
		sprintf(p, "%s\n", identifier);
		printf("%s", print_line);
		return;
	}

	if (rename != NULL) {
		// don't increase indent in this case	
		rename->print(arg_indent);
	}

	if (name != NULL) {	
		// don't increase indent in this case	
		name->print(arg_indent);
	}

}

rc_t
NAMEDEF::get_where_defined(PORT_EXPR **arg_retval)
{
	if (nameclass != PORT_NAMECLASS) {
		*arg_retval = NULL;
		return RC_INVALID;
	}

	*arg_retval = (PORT_EXPR *)where_defined;
	return RC_NOMINAL;
}

rc_t
NAMEDEF::get_where_defined(CELL_EXPR **arg_retval)
{
	if (nameclass != CELL_NAMECLASS) {
		*arg_retval = NULL;
		return RC_INVALID;
	}

	*arg_retval = (CELL_EXPR *)where_defined;
	return RC_NOMINAL;
}

rc_t
NAMEDEF::get_where_defined(INSTANCE_EXPR **arg_retval)
{
	if (nameclass != INSTANCE_NAMECLASS) {
		*arg_retval = NULL;
		return RC_INVALID;
	}

	*arg_retval = (INSTANCE_EXPR *)where_defined;
	return RC_NOMINAL;
}

rc_t
NAMEDEF::get_where_defined(LIBRARY_EXPR **arg_retval)
{
	if (nameclass != LIBRARY_NAMECLASS) {
		*arg_retval = NULL;
		return RC_INVALID;
	}

	*arg_retval = (LIBRARY_EXPR *)where_defined;
	return RC_NOMINAL;
}

rc_t
NAMEDEF::get_where_defined(VIEW_EXPR **arg_retval)
{
	if (nameclass != VIEW_NAMECLASS) {
		*arg_retval = NULL;
		return RC_INVALID;
	}

	*arg_retval = (VIEW_EXPR *)where_defined;
	return RC_NOMINAL;
}




char *
NAMEDEF::get_identifier()
{
	// one of {identifier, name, rename} is required

	if (identifier != NULL)
		return identifier;

	if (name != NULL)
		return name->identifier;

	if (rename->identifier != NULL)
		return rename->identifier;
	// ....................////////// 

	if (rename->name != NULL)
		return rename->name->identifier;

	printf("NAMEDEF::get_name....something strange or new\n");
	exit(-1);
}	

char *
NAMEDEF::get_stringvalue()
{
	// one of {identifier, name, rename} is required
	char *str = NULL;
	char *outstr = NULL;
	char *tempstr = NULL;

	if (identifier != NULL)
		str = identifier;

	else if (name != NULL)
		str = name->identifier;

	else if (rename->string != NULL)
		str = rename->string;
	// ...................////// (...not identifier)

	else if (rename->stringdisplay != NULL)
		str = rename->stringdisplay->string;

	else {
		printf("get namedef stringvalue failed\n");
		exit (-1);
	}

	// remove enclosing quotes, if any
	if (str[0] == '\"') {
		outstr = strdup(str + 1);
		char *p = outstr + strlen(outstr) - 1;
		if (*p != '\"')	{
			printf("quoted string not closed??? >>>%s<<<\n", str);
			exit(-1);
		}
		*p = '\0';
	} else {
		outstr = strdup(str);
	}

//	// add array brackets
//	if (is_array == true) {
//		str = outstr;
//		if (array_size > 9999) {
//			printf("array too large for allocated space %d\n", array_size);
//			exit(-1);
//		}
//		outstr = new char[strlen(str) + 10];
//		sprintf(outstr, "%s[%d:0]", str, array_size - 1);
//		delete str;
//	}

	// spaces just cause a lot of trouble.
	// & we don't like question marks much either
	char *p = outstr;
	while (*p != '\0') {
		if (*p == ' ') *p = '_';
		if (*p == '?') *p = '_';
		p++;
	}
//	if (*p == ' ') {
//		tempstr = new char[strlen(outstr + 3)];
//		char *r = tempstr;
//		*r++ = '{';
//		while (*p != '\0')	*r++ = *p++;
//		*r++ = '}';
//		*r = '\0';
//		// delete outstr;
//		outstr = tempstr;
//	}
				
	// all done
	return outstr;
}	

ListOfNAMEDEF::ListOfNAMEDEF(
    NAMEDEF *arg_namedef, ListOfNAMEDEF *arg_next)
    : namedef(arg_namedef), next(arg_next)
{
}



///////////////////////////////////////////////////////

NAMEREF::NAMEREF(NAMECLASS arg_nameclass)
    : nameclass(arg_nameclass)
{
}

rc_t 
NAMEREF::read_in(NAMESCOPE *arg_namescope) 
{
	// unlike the regular read_in stuff, the first token got
	// will be the first token of the nameRef, which 
	// might be a STRING or an LPAR RNAME ...
	identifier = NULL;
	name = NULL;

	EDIF_FILE *ef = EDIF_FILE::current_file;
	TOKEN *t = ef->read_token();

	// note... there might be an identifier which is equal
	// to a keyord, like "(cell instance ... )";
	// so anything that isn't an expr, we take as a string...
	if (t->get_type() != LPAR) {
		identifier = t->get_string();
		delete t;
		name = NULL;
		return RC_NOMINAL;
	}
	delete t;

	t = ef->read_token();
	if (t->get_type() == KW_NAME) { 
		name = new NAME_EXPR();
		if (name->read_in(arg_namescope) != RC_NOMINAL)
			return pe(1, "nameRef: expected name_expr\n");

	} else if (t->get_type() == KW_ARRAY) { 
		// NOT SUPPORTED
		printf("warning: ARRAY EXPRESSION IN NAMEDEF\n");
		identifier = "array expression";
		ef->skip_expr();

	} else 
		return pe(1, "nameRef: expected string or name or array\n");

	return RC_NOMINAL;
}

void
NAMEREF::print(int arg_indent)
{
	char *p = print_line;
	for (int i = 0; i < arg_indent; i++) {
		*p++ = ' '; *p++ = ' ';
	}

	if (identifier != NULL) {	
		sprintf(p, "%s\n", identifier);
		printf("%s", print_line);
		return;
	}

	if (name != NULL) {	
		name->print(arg_indent +1);
	}

}	

char *
NAMEREF::get_identifier() 
{
	if (identifier != NULL) return identifier;

	if (name != NULL)	return name->identifier;

	printf("NAMEDEF::get_identifier....something strange or new\n");
	exit(-1);
}

///////////////////////////////////////////////

NAMESCOPE::NAMESCOPE(NAMESCOPE *arg_namescope, TOKEN_TYPE arg_kw,
    void* arg_backpointer)
    : enclosing_namescope(arg_namescope), namedef_list(NULL),
    backpointer_type(arg_kw), backpointer(arg_backpointer)
{
}

rc_t
NAMESCOPE::insert(NAMEDEF *arg_namedef)
{
	char *identifier = arg_namedef->get_identifier();
	NAMEDEF *tnamedef = lookup_by_str(
	    identifier, arg_namedef->nameclass);
//	if (tnamedef != NULL) {
//		if (SUE::UNIQUIFY_DUPLICATE_NAMES == true) {
//			rc_t rc = arg_namedef->uniquify();
//			if (rc != RC_NOMINAL) {
// 				return rc;
// 			}
// 		} else {
// 			return RC_INUSE;
// 		}
// 	}

	if (tnamedef != NULL) {
		rc_t rc = arg_namedef->uniquify();
	}

	namedef_list = new ListOfNAMEDEF(arg_namedef, namedef_list);
	return RC_NOMINAL;
}

NAMEDEF *
NAMESCOPE::lookup(NAMEREF *arg_nameref)
{
	char *identifier = arg_nameref->get_identifier();
	NAMEDEF *tnamedef = lookup_by_str(
	    identifier, arg_nameref->nameclass);
	return tnamedef;
}
	
NAMEDEF *
NAMESCOPE::lookup_by_str(char *arg_identifier, NAMECLASS arg_class)
{
	ListOfNAMEDEF *tnamedef_list = namedef_list;
	while (tnamedef_list != NULL) {
		NAMEDEF *namedef = tnamedef_list->namedef;

		if (namedef->nameclass == arg_class &&
		    strcmp(namedef->get_identifier(), arg_identifier) == 0) {
			return namedef;
		}
		tnamedef_list = tnamedef_list->next;
	}

	if (enclosing_namescope != NULL)
		return enclosing_namescope->
		    lookup_by_str(arg_identifier, arg_class);

	return NULL;
}	
