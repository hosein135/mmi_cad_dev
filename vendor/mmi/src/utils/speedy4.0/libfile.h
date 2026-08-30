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

#ifndef libfile_h
#define libfile_h

#define LINEBUFSIZE	0x1000

class LIBTOKEN;
class ListOfLIBTOKEN;
class BUSTYPE;
class ListOfBUSTYPE;
class CELL_LIBRARY;
class LIBFILE_PIN;
class ListOfLIBFILE_PIN;

class LIBFILE {
    public:
		LIBFILE(char *filename);
		~LIBFILE();

	rc_t		write_cell_to_file(CELL *);
	rc_t		write_lutable(LUTABLE *);

	rc_t		read();
	BOOLEAN		were_read_errors;

	// helper methods
	rc_t		read_lu_table_template();
	rc_t		read_cell();
	rc_t		read_pin(CELL *);
	rc_t		read_bus(CELL *);
	rc_t		read_output_pin(OUTPIN *, CELL *);
	rc_t		read_input_pin(INPIN *);
	rc_t		read_inout_pin(INPIN *, OUTPIN *, CELL *);
	OUTPINTIMING *	read_outpintiming();
	LUTABLE *	read_lu_table();
	rc_t		read_type();
	rc_t		read_ff(CELL *);

	ListOfLUTABLE *template_lutablelist;

	LIBTOKEN *	get_token();
	void		unget_token(LIBTOKEN *);

	BOOLEAN		next_is_semicolon();	// the semicolon at the end of a line is
				// treated as if it were optional. Not nice, but what can I do???
				// return true If the token *is* a semicolon, 
				// or if we are on a differnt lineno then when the token was got,
				// and unget the token.  

	BOOLEAN		ignore_quotes;	// XXX ... ugly hack due to not
					// doing tables in a general way

		// XXX ... the point of these is to skip to the end of an expression;
		// but there is some confusion about what the syntax is, since sometimes
		// the semicolons that seem to be terminators of simple expressions
		// are missing.  Perhaps our libfile generators are buggy... but 
		// Pearl reads them fine as they are.  So I accept a newline as
		// "as good as" an actual semicolon.  Ugly Wuggly.

	void		skip_to_semicolon();
	void		skip_across_body();

	void		pe(char *msg);

	// data we have to store for later....
	ListOfBUSTYPE *	bustypelist;



	ListOfLIBTOKEN *ungotten_libtokenlist;
	//

	char *		libname;	// ... as "mmi18"
	char *		name;
	FILE *		f;

	char *		rv;		// return value from fgets
	char 		linebuf[LINEBUFSIZE];	// ... return data

	char *		linep;		// cleaned up data
	int		lineno;

};

class LIBFILE_PIN {
    public:
		LIBFILE_PIN(char *name);
		~LIBFILE_PIN();

	char *			name;

	ListOfOUTPINTIMING *	outpintiminglist;
};

class ListOfLIBFILE_PIN {
    public:
		ListOfLIBFILE_PIN(LIBFILE_PIN *, ListOfLIBFILE_PIN *);
		~ListOfLIBFILE_PIN();

	LIBFILE_PIN *		libfile_pin;
	ListOfLIBFILE_PIN *	next;
};


//////////////////////////////////////////////////
enum LIBTOKEN_TYPE {
	LIBINVALID,
	LIBENDOFFILE,	// parse problems when "EOF"; don't get mixed up

	LIBSTRING,
	LIBINTEGER,
	LIBFLOAT,

	LIBLPAR, LIBRPAR,
	LIBLCURLY, LIBRCURLY,
	LIBCOLON,
	LIBSEMICOLON,
	LIBSTAR,
	LIBCOMMA,
	LIBSLASH,

	LIB_AREA,
	LIB_BASE_TYPE,
	LIB_BIT_WIDTH,
	LIB_BIT_FROM,
	LIB_BIT_TO,
	LIB_BUS,
	LIB_BUS_TYPE,
	LIB_CAPACITANCE,
	LIB_CELL,
	LIB_CELL_FALL,
	LIB_CELL_RISE,
	LIB_CLOCK,
	LIB_CLK,
	LIB_DATA_TYPE,
	LIB_DEFAULT_CELL_LEAKAGE_POWER,
	LIB_DEFAULT_OUTPUT_PIN_CAP,
	LIB_DIRECTION,
	LIB_DONT_USE,
	LIB_DOWNTO,
	LIB_FALL_CONSTRAINT,
	LIB_FALL_TRANSITION,
	LIB_FANOUT_LOAD,
	LIB_FF,
	LIB_FUNCTION,
	LIB_INDEX_1,
	LIB_INDEX_2,
	LIB_LATCH,
	LIB_LIBRARY,
	LIB_LU_TABLE_TEMPLATE,
	LIB_PIN,
	LIB_RELATED_PIN,
	LIB_RISE_CONSTRAINT,
	LIB_RISE_TRANSITION,
	LIB_TABLE_LOOKUP,
	LIB_TEST_CELL,
	LIB_TIMING,
	LIB_TIMING_SENSE,
	LIB_TIMING_TYPE,
	LIB_TYPE,
	LIB_VARIABLE_1,
	LIB_VARIABLE_2,
	LIB_VALUES
};



class LIBTOKEN {
    public:
		LIBTOKEN(LIBTOKEN_TYPE);
		LIBTOKEN(LIBTOKEN_TYPE, char *);
		LIBTOKEN(LIBTOKEN_TYPE, int);
		LIBTOKEN(LIBTOKEN_TYPE, float);
		~LIBTOKEN();

	char *		get_string();
	int		get_integer();
	BOOLEAN		is_float();
	float		get_float();
	char *		get_constant();

	char *		get_string_for_type();

	LIBTOKEN_TYPE 	type;
	char *		string;
	int		integer;
	float		floater;
};

class ListOfLIBTOKEN {
    public:
			ListOfLIBTOKEN(LIBTOKEN *, ListOfLIBTOKEN *);
			~ListOfLIBTOKEN();
	
	LIBTOKEN *	libtoken;
	ListOfLIBTOKEN *	next;
};




class BUSTYPE {
    public:
		BUSTYPE(char *name, int bit_from, int bit_to);
		~BUSTYPE();

	char *		name;
	int		bit_from;
	int		bit_to;
};

class ListOfBUSTYPE {
    public:
			ListOfBUSTYPE(BUSTYPE *, ListOfBUSTYPE *);
			~ListOfBUSTYPE();
	
	BUSTYPE *	bustype;
	ListOfBUSTYPE *	next;
};

///////////////////////////////////////////////////////


#endif
