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

#ifndef constraintsfile_h
#define constraintsfile_h

class CFTOKEN;
class ListOfCFTOKEN;
class ListOfNET;

class FIXFILE {
    public:  
			FIXFILE(char *);
			~FIXFILE();

	rc_t		read();

	rc_t		mark_fast_input(char *cellname, char *pinname);
	rc_t		mark_dont_resize_cell(char *name);
	rc_t		mark_dont_resize_path(char *pathname);
	rc_t		mark_as_flipflop(char *name);

	char *		name;
	FILE *		f;

	int		lineno;
	char		linebuf[LINEBUFSIZE];

};



class CONSTRAINTSFILE {
    public:  
			CONSTRAINTSFILE(char *);
			~CONSTRAINTSFILE();

	rc_t		read();

	// helper functions for read()
	ListOfNET *	read_input_netlist();
//	rc_t		read_input();
	rc_t		read_arrival();
	rc_t		read_inputslew();
	rc_t		read_readtechnology();
	rc_t		read_setmaxpossibilities();
	rc_t		read_setnodecapacitance();

	void		skiptoEOL();
	BOOLEAN		convert_for_units(float *, CFTOKEN *);

	CFTOKEN *	get_token();
	void		unget_token(CFTOKEN *);

	char *		name;
	FILE *		f;

	int		lineno;

	ListOfCFTOKEN *	ungotten_tokenlist;
};


enum CFTOKEN_TYPE {
	CFINVALID = 4000,
	CFENDOFFILE,	// parse problems when "EOF"; don't get mixed up
	CFENDOFLINE,

	CFSTRING,
	CFINTEGER,
	CFFLOAT,

	CFLSQUARE, CFRSQUARE,
	CFSTAR,
	CFPLUS,
	CFCOLON,
	CFSHARP,
	CFUP, CFDOWN,

	CF_ARRIVAL,
	CF_BLOCKPATH,
	CF_CONSTANT,
	CF_INPUT,
	CF_INPUTSLEW,
	CF_READCAPACITANCES,
	CF_READCELLLIBRARY,
	CF_SETNODECAPACITANCE,
	CF_SETMAXPOSSIBILITIES,
	CF_TOPLEVELCELL
};



class CFTOKEN {
    public:
		CFTOKEN(CFTOKEN_TYPE);
		CFTOKEN(CFTOKEN_TYPE, char *);
		CFTOKEN(CFTOKEN_TYPE, int);
		CFTOKEN(CFTOKEN_TYPE, float);
		~CFTOKEN();

	char *		get_string();
	int		get_integer();
	float		get_float();
	char *		get_constant();

	char *		get_string_for_type();

	CFTOKEN_TYPE	type;
	char *		string;
	int		integer;
	float		floater;
};

class ListOfCFTOKEN {
    public:
			ListOfCFTOKEN(CFTOKEN *, ListOfCFTOKEN *);
			~ListOfCFTOKEN();
	
	CFTOKEN *	cftoken;
	ListOfCFTOKEN *	next;
};


#endif
