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

#ifndef	files_h
#define files_h

///////////////////////////////////////////////////////////

class EDIF_FILE {
    public:
		EDIF_FILE(char *name);

	// the file is treated as a stream (fopen'd)
	rc_t	open();
	rc_t	close();

	// read an EDIF-expression from the file
	// (that should span the file)
	rc_t	parse();
	
	// if and only if parse succeeds, "top_expr"
	// will point to the top of the expression tree
	class EDIF_EXPR *	get_top_expr();  

	// kind of a hack; so we can call read_token from
	// xxx_EXPR::read_in() with minimum fuss
	static EDIF_FILE *	current_file;	

	int	get_lineno();

    private:
	char *	name;
	FILE *	fd;		// valid & open <==> fd != 0	
	int	lineno;	// current line number during parse
				// (for error reporting)
	
	EDIF_EXPR *		top_expr;

    public:
	// parse() uses read_token() to step through the file
	// read_token() uses getc to pull chars from the 
	// file building up a valid EDIF token, & allocates
	// & returns a corresponding TOKEN instance; see
	// comment on class TOKEN.
	// note... caller is responsible for deleting TOKEN.
	TOKEN *		read_token();

	// while parsing, skip past the end of the current 
	// expression; that is, we don't want to parse it, just
	// count parens until we finish it.
	void		skip_expr();	

};



#endif
