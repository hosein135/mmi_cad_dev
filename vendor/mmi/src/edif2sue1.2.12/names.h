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

#ifndef names_h
#define names_h


enum NAMECLASS {		// ...nameDefs appear in expr types:
				// (nameRefs appear in various places...)
	ILLEGAL_NAMECLASS,
	CELL_NAMECLASS,		// cell
	DESIGN_NAMECLASS,	// design
	EDIF_NAMECLASS,		// edif
	FIGUREGROUP_NAMECLASS,	// figureGroup
	FORMAL_NAMECLASS,	// formal
	INSTANCE_NAMECLASS,	// instance, page
	KEYWORD_NAMECLASS,	// keywordAlias, keywordDefine
	LAYER_NAMECLASS,	// fabricate
	LIBRARY_NAMECLASS,	// external, library
	LOGIC_NAMECLASS,	// logicValue, vaveValue
	NET_NAMECLASS,		// net, netBundle
	PORT_NAMECLASS,		// logicPort, offPageConnector, port, 
				//	portBundle, portListAlias
	PROPERTY_NAMECLASS,	// property
	RULE_NAMECLASS,		// enclosureDistance, figureArea, 
				//	figurePerimeter, figureWidth, 
				//	interFigureGroupSpacing, 
				//	intraFigureGroupSpacing, notAllowed,
				//	 notchSpacing, overhangDistance, 
				//	overlapDistance, rectangleSize
	SIMULATE_NAMECLASS,	// simulate
	VALUE_NAMECLASS,	// constant, parameter, variable
	VIEW_NAMECLASS		// view
};

///////////////////////////////////////////////////////
// nameDef & nameRef don't work like <whatnot>_EXPR classes.

class NAMEDEF {
    public:
		NAMEDEF(NAMECLASS, void *where_defined);

	char *		identifier;
	class RENAME_EXPR *rename;
	class NAME_EXPR *name;

	NAMECLASS	nameclass;	

	BOOLEAN		is_array;
	int		array_size;

	// to support the option to uniquify duplicate names
	// ... there aren't suppozzed to *be* any, but *some*
	// people evidently don't know that.
	rc_t	uniquify();

	rc_t	read_in(class NAMESCOPE *);
	void	print(int);

    private:
	// well shucks.  a void *. 
	// a "class EXPR *" isn't any better.
	// I *do* know what kind of thing this is depending on 
	// the nameclass, so I can provide some strongly typed
	// accessor functions.
	// gcc (c++?) doesn't support methods differentiated
	// by return type (whyever not?), so I have to make
	// return parameter.  a minor ugliness.
	void *		where_defined;
    public:
	// RFE... need one of these for each NAMECLASS.
	rc_t		get_where_defined(class CELL_EXPR **);
	rc_t		get_where_defined(class INSTANCE_EXPR **);
	rc_t		get_where_defined(class LIBRARY_EXPR **);
	rc_t		get_where_defined(class PORT_EXPR **);
	rc_t		get_where_defined(class VIEW_EXPR **);


	// the "originalname" is probably the name from whatever
	// source CAD system; it may contain we-don't-like-them
	// characters.  Therefore EDIF supports "renaming" as
	// part of a nameDef (see the BNF in The Book:
	//	nameDef ::= identifer | name | rename
	//	nameRef ::= identifer | name
	// (... name ::= '(' 'name' identifer {display} ')' ...)
	//
	// So we want to resolve a nameRef by comparing *identifiers*
	// (and nameclass, of course...).
	// PROBABLY when we are outputing, we want to use the stringvalue.
	// In the nameRef case, we have to look into the nameDef to 
	// notice whether there is a rename or not. 
	//
	
	// NOTE: this function returns a pointer into some
	// class instance; don't delete them.
	char *		get_identifier();

	// NOTE: this function mangles the name as stored;
	// it removes the enclosing quotes, if any, and
	// replaces unloveable characters ("#") with '%'
	// The return value is a strdup, and it *should* be
	// deleted.	
	char *		get_stringvalue();
};

class ListOfNAMEDEF {
    public:
		ListOfNAMEDEF(NAMEDEF *, ListOfNAMEDEF *);

	NAMEDEF *	namedef;
	ListOfNAMEDEF *	next;
};

// WARNING... the usual style of read_in method doesn't work right, since
// instance of a nameRef might be either a string or an name expr;
// have to imbed a special hackware constructor in the enclosing
// <nameRef'd expr type>::read_in method.... eg, see
//	FIGURE_EXPR::read_in
//	DISPLAY_EXPR.read_in
//

class NAMEREF {
    public:
		NAMEREF(NAMECLASS);

	char *		identifier;
	class NAME_EXPR *name;
	NAMECLASS	nameclass;	

	rc_t		read_in(class NAMESCOPE *);
	void		print(int);

	// see note in class NAMEDEF
	// RFE....probably neater & cleaner to keep the resolving
	// nameDef in here.  But I am keeping it in the exprs.
	char *		get_identifier();
};

// NOTE: The Book says that "the scope of a name is ... within
// a certain construct, such as library, cell, or view."  It isn't
// explicit about which constructs define name scopes, or whether
// the selection of an enclosing name scope depends on the name class.
// We will Boldly Assume that all named constructs define a name
// scope, and a name definition should be inserted into the 
// smallest enclosing scope regardless of name class.
//
// The EDIF Technical Center assures me that shadowing *is* allowed,
// although the language in the documentation suggests otherwise.

class NAMESCOPE {
    public:

		NAMESCOPE(NAMESCOPE *enclosing_namescope, 
		    TOKEN_TYPE, void* backpointer);
	
	NAMESCOPE *	enclosing_namescope;
	ListOfNAMEDEF * namedef_list;
	
	// just for debugging
	TOKEN_TYPE	backpointer_type;
	void *		backpointer;


	rc_t		insert(NAMEDEF *);
	NAMEDEF *	lookup(NAMEREF *);

    private:
	NAMEDEF *	lookup_by_str(char *, NAMECLASS);
};

#endif
