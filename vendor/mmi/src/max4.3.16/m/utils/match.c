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



/* match.c -
 *
 *	String matching operations.
 *
 *     ********************************************************************* 
 *     * Copyright (C) 1985, 1990 Regents of the University of California. * 
 *     * Permission to use, copy, modify, and distribute this              * 
 *     * software and its documentation for any purpose and without        * 
 *     * fee is hereby granted, provided that the above copyright          * 
 *     * notice appear in all copies.  The University of California        * 
 *     * makes no representations about the suitability of this            * 
 *     * software for any purpose.  It is provided "as is" without         * 
 *     * express or implied warranty.  Export of this software outside     * 
 *     * of the United States of America may require an export license.    * 
 *     *********************************************************************
 */

#ifndef lint
static char rcsid[] = "$Header: match.c,v 6.0 90/08/28 19:01:10 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "message.h"
#include "utils.h"


/*
 * ----------------------------------------------------------------------------
 *
 * Match --
 *
 * 	Sees if two strings match, using csh-like pattern matching.
 *
 * Results:
 *	TRUE is returned if the two strings match, FALSE is returned
 *	if they don't.  The first string, pattern, can contain the
 *	special characters *, ?, \, and [], which are matched as by
 *	the csh.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

int
Match(register char *pattern, register char *string)
                           	/* csh-like pattern. */
                          	/* String to check for match against pattern.*/
{
    char c2;

    while (TRUE)
    {
	/* See if we're at the end of both pattern and string.  If
	 * so, we succeeded.  If we're at the end of pattern, but not
	 * of string, we failed.
	 */
	
	if (*pattern == 0)
	{
	    if (*string == 0) return TRUE;
	    else return FALSE;
	}
	if ((*string == 0) && (*pattern != '*')) return FALSE;

	/* Check for a "*" as the next pattern character.  It matches
	 * any substring.  We handle this by calling ourselves
	 * recursively for each postfix of string, until either we
	 * match or we reach the end of the string.
	 */
	
	if (*pattern == '*')
	{
	    pattern += 1;
	    if (*pattern == 0) return TRUE;
	    while (*string != 0)
	    {
		if (Match(pattern, string)) return TRUE;
		string += 1;
	    }
	    return FALSE;
	}
    
	/* Check for a "?" as the next pattern character.  It matches
	 * any single character.
	 */

	if (*pattern == '?') goto thisCharOK;

	/* Check for a "[" as the next pattern character.  It is followed
	 * by a list of characters that are acceptable, or by a range
	 * (two characters separated by "-").
	 */
	
	if (*pattern == '[')
	{
	    pattern += 1;
	    while (TRUE)
	    {
		if ((*pattern == ']') || (*pattern == 0)) return FALSE;
		if (*pattern == *string) break;
		if (pattern[1] == '-')
		{
		    c2 = pattern[2];
		    if (c2 == 0) return FALSE;
		    if ((*pattern <= *string) && (c2 >= *string)) break;
		    if ((*pattern >= *string) && (c2 <= *string)) break;
		    pattern += 2;
		}
		pattern += 1;
	    }
	    while ((*pattern != ']') && (*pattern != 0)) pattern += 1;
	    goto thisCharOK;
	}
    
	/* If the next pattern character is '\', just strip off the '\'
	 * so we do exact matching on the character that follows.
	 */
	
	if (*pattern == '\\')
	{
	    pattern += 1;
	    if (*pattern == 0) return FALSE;
	}

	/* There's no special character.  Just make sure that the next
	 * characters of each string match.
	 */
	
	if (*pattern != *string) return FALSE;

	thisCharOK: pattern += 1;
	string += 1;
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * MatchPlainTextQ --
 *
 * 	If pattern is equivalent to plain text (no wild cards), returns
 *      plain text version, otherwise NULL.
 *
 * ----------------------------------------------------------------------------
 */
char *MatchPlainTextQ(char *pattern,  /* pattern to examine/convert */
		      char *buf,      /* buffer to write result to */
		      int bufSize)    /* buffer size */
{
  char *in = pattern;
  char *out = buf;
  char *bufEnd = buf+bufSize-1;

  while(*in && out<bufEnd)
  {
    char c = *in;

    /* if wild card, return null */
    if(c == '*' || c == '?' || c == '[' || c == ']' ) return NULL;

    /* strip quote */
    if(c == '\\')
    {
      in++;
      if(!*in) return NULL;
      c = *in;
    }

    /* copy char */
    *out++ = *in++;
  }

  if(out==bufEnd) return NULL;
  *out = '\0';
  return buf;
}
