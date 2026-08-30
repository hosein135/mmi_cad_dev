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

#ifndef token_h
#define token_h


///////////////////////////////////////////////////////////

// TOKEN is a class representing a syntactical element of 
// a valid EDIF file.  Parens are special tokens, 
// whitespace includes EOL & EOF and integers are the usual thing.
// Strings (except quoted strings) corresponding to EDIF keywords
// are represented by tokens of type "KW_...", which have no string
// value.
// There are special pseudo-token types of INVALID and ENDOFFILE.
// RFE... should be a better documentation here of what we consider
// to be a valid string

enum TOKEN_TYPE {
	INVALID,
	ENDOFFILE,	// parse problems when "EOF"; don't get mixed up
	LPAR,
	RPAR,
	STRING,
	INTEGER,

	// here are a few things from a different part of the forest
	// maybe I *ought* to make a different enum, but then I can't
	// use "LPAR" in both without some pain.  Yuck.
	NAME_EXP, INDEX_EXP,
	LSQUARE, RSQUARE,
	LANGLE, RANGLE,
	COLON,
	STAR,
	COMMA,

	// there are many more EDIF expression types than this;
	// these are the ones we care to recognize, either as
	// interesting in themselves or as components of interesting
	// expressions..
	KW_ACLOAD,
	KW_ANNOTATE,
	KW_ARC,
	KW_ARRAY,
	KW_ARRAYRELATEDINFO,
	KW_ASSIGN,
	KW_BLOCK,
	KW_BORDERPATTERN,
	KW_BORDERWIDTH,
	KW_BOUNDINGBOX,
	KW_CELL,
	KW_CELLREF,
	KW_CELLTYPE,
	KW_CIRCLE,
	KW_COLOR,
	KW_COMMENT,
	KW_COMMENTGRAPHICS,
	KW_CONNECTLOCATION,
	KW_CONSTANT,
	KW_CONSTRAINT,
	KW_CONTENTS,
	KW_CORNERTYPE,
	KW_CRITICALITY,
	KW_CURVE,
	KW_DCFANINLOAD,
	KW_DCFANOUTLOAD,
	KW_DCMAXFANIN,
	KW_DCMAXFANOUT,
	KW_DELTA,
	KW_DESIGN,
	KW_DESIGNATOR,
	KW_DIRECTION,
	KW_DISPLAY,
	KW_DOT,
	KW_E,
	KW_EDIF,
	KW_EDIFLEVEL,
	KW_EDIFVERSION,
	KW_ENDTYPE,
	KW_EXTERNAL,
	KW_FABRICATE,
	KW_FIGURE,
	KW_FIGUREGROUP,
	KW_FIGUREGROUPOVERRIDE,
	KW_FILLPATTERN,
	KW_FOLLOW,
	KW_IF,
	KW_INCLUDEFIGUREGROUP,
	KW_INSTANCE,
	KW_INSTANCEREF,
	KW_INTERFACE,
	KW_ITERATE,
	KW_JOINED,
	KW_JUSTIFY,
	KW_KEYWORDDISPLAY,
	KW_KEYWORDMAP,
	KW_LIBRARY,
	KW_LIBRARYREF,
	KW_LOGICPORT,
	KW_MUSTJOIN,
	KW_NAME,
	KW_NET,
	KW_NETBUNDLE,
	KW_NETDELAY,
	KW_NUMBERDEFINITION,
	KW_OFFPAGECONNECTOR,
	KW_OPENSHAPE,
	KW_ORIENTATION,
	KW_ORIGIN,
	KW_OWNER,
	KW_PAGE,
	KW_PAGESIZE,
	KW_PARAMATERASSIGN,
	KW_PARAMETER,
	KW_PATH,
	KW_PATHWIDTH,
	KW_PERMUTABLE,
	KW_PHYSICALDESIGNRULE,
	KW_POINTLIST,
	KW_POLYGON,
	KW_PORT,
	KW_PORTBUNDLE,
	KW_PORTIMPLEMENTATION,
	KW_PORTINSTANCE,
	KW_PORTREF,
	KW_PROPERTY,
	KW_PROPERTYDISPLAY,
	KW_PROTECTIONFRAME,
	KW_PT,
	KW_RECTANGLE,
	KW_RENAME,
	KW_SCALEX,
	KW_SCALEY,
	KW_SECTION,
	KW_SHAPE,
	KW_SIMULATE,
	KW_SIMULATIONINFO,
	KW_STATUS,
	KW_STRINGDISPLAY,
	KW_SYMBOL,
	KW_TECHNOLOGY,
	KW_TEXTHEIGHT,
	KW_TIMING,
	KW_TRANSFORM,
	KW_UNIT,
	KW_UNUSED,
	KW_USERDATA,
	KW_VARIABLE,
	KW_VIEW,
	KW_VIEWREF,
	KW_VIEWLIST,
	KW_VIEWMAP,
	KW_VIEWTYPE,
	KW_VISIBLE,
	KW_WEAKJOINED,
	KW_WHEN,
	KW_WHILE
};


class TOKEN {
    public:
		TOKEN(TOKEN_TYPE, char *);
		TOKEN(char *);
		TOKEN(int);
		~TOKEN();

	TOKEN_TYPE	get_type();
	char *		get_string();
	int		get_integer();

    private:
	TOKEN_TYPE	type;
	char *		string;
	int		integer;
};

#endif
