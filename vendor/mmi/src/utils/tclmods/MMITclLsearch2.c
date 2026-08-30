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

#include "tclInt.h"
static char *rcsid = "$Id: MMITclLsearch2.c,v 1.2 2000/10/19 23:12:43 pat Exp $";

/*
 *----------------------------------------------------------------------
 *
 * Tcl_Lsearch2ObjCmd --
 *
 *	MMI modification: implement lsearch2.
 *      Like lsearch, but with additional options:
 * USAGE:
 *   lsearch2 [-index n] [-value] [-nocase] [-exact|-glob|-regexp] list pattern
 *
 * If -index, treat each element as a sub-list, and look
 * at the nth element.
 * If -value, return the value, not the index, and return "" if not found.
 * If -nocase, ignore case during matching.
 *
 * Note: -exact is the default, unlike lsearch!
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */


int
MMITcl_Lsearch2ObjCmd(clientData, interp, objc, objv)
    ClientData clientData;	/* Not used. */
    Tcl_Interp *interp;		/* Current interpreter. */
    int objc;			/* Number of arguments. */
    Tcl_Obj *CONST objv[];	/* Argument values. */
{
#define LS_EXACT		0
#define LS_GLOB		1
#define LS_REGEX		2
#define LS_END		-2	/* "end" value for -index option */
#define LS_NOINDEX	-1	/* no -index specified */

    char *strBytes, *patBytes;
    int optionIndex;
    int i, resultIndex, match, result, patLen, strLen;
    Tcl_Obj **elemPtrs; int listLen;
    int lsobjc; Tcl_Obj **lsobjv;

    Tcl_DString patternDstring, stringDstring;
    char *pattern, *string;

    Tcl_Obj *resultPtr;

    int f_mode = LS_EXACT;
    int f_index = LS_NOINDEX;
    int f_nocase = 0;
    int f_value = 0;

    static char *switches[] =
	    {"-exact", "-glob", "-regexp",
	    "-index", "-value", "-nocase",
	    (char *) NULL};

    resultPtr = Tcl_GetObjResult(interp);
    lsobjc = objc-1;
    lsobjv = (Tcl_Obj**) objv+1;

    if (lsobjc < 2) {
	Tcl_WrongNumArgs(interp, 1, objv, "?options? list pattern");
	return TCL_ERROR;
    }

    /*
     * Parse arguments to set up the mode for the sort.
     */

    while (lsobjc > 2) {
	if (Tcl_GetIndexFromObj(interp, lsobjv[0], switches, "lsearch2 option", 0, &optionIndex)
		!= TCL_OK) {
	    return TCL_ERROR;
	}
	switch (optionIndex) {
	    case 0:			/* -exact */
		/* We dont bother to detect the error of multiple
		 * -exact, -glob, -regexp options.
		 */
		f_mode = LS_EXACT;
		break;
	    case 1:			/* -glob */
		f_mode = LS_GLOB;
		break;
	    case 2:			/* -regexp */
		f_mode = LS_REGEX;
		break;
	    case 3:			/* -index */
		lsobjc--;
		lsobjv++;
		if (lsobjc == 2) {
		    Tcl_AppendToObj(resultPtr,
			    "\"-index\" option must be followed by list index",
			    -1);
		    return TCL_ERROR;
		}
		if (TclGetIntForIndex(interp, lsobjv[0], LS_END, &f_index)
			!= TCL_OK) {
		    return TCL_ERROR;
		}
		break;
	    case 4:			/* -value */
		f_value = 1;
		break;
	    case 5:			/* -nocase */
		f_nocase = 1;
		break;
	}
	lsobjc--;
	lsobjv++;
    }

    /*
     * Make sure the list argument is a list object and get its length and
     * a pointer to its array of element pointers.
     */

    result = Tcl_ListObjGetElements(interp, lsobjv[0], &listLen, &elemPtrs);
    if (result != TCL_OK) {
	return result;
    }


    patBytes = Tcl_GetStringFromObj(lsobjv[1], &patLen);
    if (f_nocase) {
	register char *p;
	Tcl_DStringInit(&patternDstring);
	Tcl_DStringAppend(&patternDstring, patBytes, patLen);
	pattern = Tcl_DStringValue(&patternDstring);
	for (p = pattern; *p != 0; p++) {
	    if (isupper(UCHAR(*p))) {
		*p = (char)tolower(UCHAR(*p));
	    }
	}
    } else {
	pattern = patBytes;
    }

    /* Return value */
    resultIndex = -1;

    for (i = 0; result == TCL_OK && i < listLen; i++) {
	if (f_index == LS_NOINDEX) {
	    strBytes = Tcl_GetStringFromObj(elemPtrs[i], &strLen);
	} else {
	    int subIndex;
	    Tcl_Obj **subElemPtrs; int subListLen;
	    /* The "-index" option was specified.  Treat each object as a
	     * list, extract the requested element from each list.
	     */
	    result = Tcl_ListObjGetElements(interp, elemPtrs[i],
		    &subListLen, &subElemPtrs);
	    if (result != TCL_OK) { break; }

	    if (f_index == LS_END) {
		subIndex = subListLen - 1;
	    } else {
		subIndex = f_index;
	    }
	    if (subIndex >= subListLen || subIndex < 0) {
		strBytes = "";
		strLen = 0;
	    } else {
		strBytes = Tcl_GetStringFromObj(subElemPtrs[subIndex], &strLen);
	    }
	}

	if (f_nocase) {
	    register char *p, *endp;
	    Tcl_DStringInit(&stringDstring);
	    Tcl_DStringAppend(&stringDstring, strBytes, strLen);
	    string = Tcl_DStringValue(&stringDstring);
	    endp = string + strLen;
	    for (p = string; p < endp; p++) {
		if (isupper(UCHAR(*p))) {
		    *p = (char)tolower(UCHAR(*p));
		}
	    }
	} else {
	    string = strBytes;
	}

/*printf("match mode=%d nocase=%d %s %s\n",f_mode,f_nocase,string,pattern);*/

	match = 0;
	switch (f_mode) {
	case LS_EXACT:
	    if (patLen == strLen) {
		match = (memcmp(string, pattern, (size_t) patLen) == 0);
		break;
	    }
	    continue;
	case LS_GLOB:
	    /*
	     * WARNING: will not work with data containing NULLs.
	     */
	    match = Tcl_StringMatch(string, pattern);
	    break;
	case LS_REGEX:
	    /*
	     * WARNING: will not work with data containing NULLs.
	     */
	    match = Tcl_RegExpMatch(interp, string, pattern);
	    if (match < 0) {
		result = TCL_ERROR;
	    }
	    break;
	}
	if (f_nocase) {
	    Tcl_DStringFree(&stringDstring);
	}
	if (match) {
	    resultIndex = i;
	    break;
	}
    }

    if (f_nocase) {
	Tcl_DStringFree(&patternDstring);
    }
    if (result != TCL_OK) { return result; }

    if ( f_value ) {
	/* Return value of list element */
	if ( resultIndex < 0 ) {
	    /* Not found */
	    Tcl_SetStringObj(resultPtr,"",0);
	} else {
	    char *resBytes; int resLen;
	    resBytes = Tcl_GetStringFromObj(elemPtrs[resultIndex], &resLen);
	    Tcl_SetStringObj(resultPtr,resBytes,resLen);
	}
    } else {
	/* Return index of list element */
	Tcl_SetIntObj(resultPtr, resultIndex);
    }

    return TCL_OK;
}
