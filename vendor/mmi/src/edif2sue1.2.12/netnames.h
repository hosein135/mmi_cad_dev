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

#ifndef netname_h
#define netname_h

#define BUS_COMBINE_YINCR	20
#define BUS_COMBINE_XINCR	240

#include <util.h>
#include <stdlib.h>

// This stuff reads Cadence "iterated names" as used for 
// wire bundles.
//
// expr2 :=
//	< * number > expr1
//	expr1 
//	expr1 , expr2
//	
// expr1 :=
//	name 
//	name < sscr2 >		...array subscripts are <...> 
//	( expr2 )
//	
// sscr2 :=
//	sscr1 * number
//	sscr1
//	sscr1 , sscr2
//
// sscr1 :=
//	( sscr2 )
//	number
//	number : number
//	number : number : number 
//
// name :=
//	[a-zA-Z][a-z A-Z 0-9 '-' '_' ...]+
//
// number :=
//	[0-9]+
//

class NETNAME {
	class EXPR;
	class SUBSCRIPT;

    public:
	// this is the string that defines the net from EDIF;
	// it may be a complex name (that is, the description of a bus)
	char *		name;

	// ...parse first, please...
	// if the name is simple (a single wire, possibly with a
	// simple numeric subscript), return a strdup of it
	// using sueish characters
	// else, return NULL 
	char *		get_simple_name();	

	// ...parse first, please...
	// how many inputs for buscombiner?
	int		get_width();

	// after parsing the name, the expression represents the
	// list of simple (single-wire) names that the original
	// name defines
	// width > 1 => this *is* a complex name.
	rc_t		parse();
	EXPR *		expr;

	// this is the alias we will use for this net;
	// like, "buscombine_256"
	char *		generated_name;


		NETNAME(char *);
		~NETNAME();

	// hose the list of simple net names out to the buscombiner inputs
	// ...obviously this has to dovetail with the buscombiner 
	// generator in sue.cc
	// the return value is the next y-value 
	int		generate_name_nets(FILE *, int x, int y);


	// helper classes to do parsing according to
	// the grammer given above

	class EXPR {
		// class EXPR combines data members of expr2 and expr1 

	    public:
			EXPR() 
			    : next(NULL), multiplier(1), expr(NULL),
			    name(NULL), subscript(NULL)
			{
			}

			~EXPR()
			{
				if (subscript)	delete subscript;
				if (next)	delete next;
			}

		// ..list expr
		EXPR *	next;

		// ..multiplier expr
		// multiplier == -1 and expr == NULL if invalid.
		// multiplier applies to expr, if present
		int	multiplier;
		EXPR *	expr;
	
		// ..named expr
		// name is not valid if multiplier is present
		char *	name;

		// ..named with array
		// array applies to name
		SUBSCRIPT *subscript;

			// for all the following:
			// scan the char stream at p (until endp)
			// for the whatnot we are getting; if found,
			// advance p to the character past the whatnot; 
			// otherwise, leave it alone.
			// Leading whitespace is trimmed.

			// all our tokens except strings and numbers
			// are single characters, and we know what we
			// are looking for, so just test whether the next
			// token is indeed what we said.  Note that the 
			// the pointer is advanced or not as above.
		static BOOLEAN	token_is(char, char **p, char *endp);
			
			// make a new expression and put the pointer
			// to it where I said
		static rc_t	get_expr2(EXPR**, char **, char *);

			// ... similar...
		static rc_t	get_expr1(EXPR**, char **, char *);
		static rc_t	get_sscr2(SUBSCRIPT **, char **, char *);
		static rc_t	get_sscr1(SUBSCRIPT **, char **, char *);

		static rc_t	get_number(int*, char **, char *);
		static rc_t	get_name(char**, char **, char *);

		rc_t		generate_name_nets(FILE *, int x, int *y);
		rc_t		get_width(int *);
		rc_t		print_nets();
	};


	class SUBSCRIPT {
	    public:
			SUBSCRIPT() 
			    : range_from(0), range_to(0), range_incr(1),
			    subscript(NULL), multiplier(1), next(NULL)
			{
			}

			~SUBSCRIPT()
			{
				if (subscript)	delete subscript;
				if (next)	delete next;
			}

		// range is valid if and only if subscript == NULL
		// (...note that any values of range *could* be valid)

		int	range_from;
		int	range_to;
		int	range_incr;

		SUBSCRIPT	*subscript;

		// applies to subscript if present, else range
		int	multiplier;
	
		SUBSCRIPT	*next;

		rc_t		generate_name_nets(FILE *, 
				    int x, int *y, char *base_name);
		rc_t		get_width(int *);
		rc_t		print_nets(char *base_name);
	};
};


class ListOfNETNAME {
    public:
		ListOfNETNAME(NETNAME *, ListOfNETNAME *);
		~ListOfNETNAME();

	NETNAME		*netname;
	ListOfNETNAME	*next;
};








#endif
