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

#ifndef util_h
#define util_h

#include	<stdio.h>
#include	<string.h>
#include	<ctype.h>
#include	<errno.h>

typedef int	BOOLEAN;
#define	true	1
#define false	0

enum rc_t {
	RC_NOMINAL,	// it worked as expected, normal results produced
	RC_INVALID,	// what you said was wrong
	RC_EXCEPTION,	// ...was OK, but turns out to be a special case
	RC_FAILED,	// ...was OK, but it didn't work (generic)
	RC_NOTSPECIFIED,// ...didn't work & here's a clue 
	RC_NOTFOUND,
	RC_INUSE,
	RC_BADSYNTAX,
	RC_CONVERTED,
	RC_NOTCONVERTED
};

class ListOfCHARSTAR {
    public:
		ListOfCHARSTAR(char *, ListOfCHARSTAR *);
		~ListOfCHARSTAR();

	char *		str;
	ListOfCHARSTAR *next;
};

// EDIF stuff
#include	<token.h>
#include	<files.h>
#include	<names.h>
#include	<expressions.h>

#include	<netnames.h>
#include	<sue.h>


#endif

