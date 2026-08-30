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



/*
 * string.c --
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
static char rcsid[] = "$Header: strdup.c,v 6.0 90/08/28 19:01:25 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <ctype.h>
#include "magic.h"
#include "memory.h"
#include "ihash.h"
#include "utils.h"


/*
 * ----------------------------------------------------------------------------
 * StrDup --
 *
 * Return a malloc'd copy of a string.
 *
 * Results:
 *	Returns a pointer to a newly malloc'd character array just
 *	large enough to hold the supplied string and its trailing
 *	null byte, which contains a copy of the supplied string.
 *
 * Side effects:
 *	MALLOC's a character array large enough to hold str, and
 *	copies str into it, unless str is NULL.  If str is NULL, no
 *	MALLOC is done.  Also, if oldstr is non-NULL, then a) if
 *	*oldstr is not NULL, frees the storage allocated to oldstr,
 *	and b) sets *oldstr to the new string allocated, or to
 *	NULL if str is NULL.
 * ----------------------------------------------------------------------------
 */

char *
StrDup(char **oldstr, char *str)
{
    char *newstr;

    if (str != NULL)
    {
	MALLOC_TAG(char *, newstr, strlen(str) + 1, str);
	(void) strcpy(newstr, str);
    }
    else newstr = NULL;
    if (oldstr != (char **) NULL)
    {
	if (*oldstr != NULL)
	    FREE_TAG(*oldstr, *oldstr);
	*oldstr = newstr;
    }

    return (newstr);
}


/*
 * ----------------------------------------------------------------------------
 * StrIsWhite:
 *
 *	Check to see if a string is all white space or is a comment.
 *
 * Results:
 *	True if it is all white, false otherwise.
 *
 * Side effects:
 *	none.
 * ----------------------------------------------------------------------------
 */

int
StrIsWhite(char *line, int commentok)
               
                   	/* TRUE means # comments are considered all-white */
{
    if ( (*line == '#') && commentok)
	return TRUE;
    while(*line)
    {
	if ( !isspace(*line) && (*line != '\n') )
	    return FALSE;
	line++;
    }
    return TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * StrIsInt --
 *
 * 	Check a string for being an integer.
 *
 * Results:
 *	TRUE if the string is a well-formed integer, FALSE otherwise.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */
int
StrIsInt(char *s)
{
    if (*s == '-' || *s == '+') s++;
    while (*s)
	if (!isdigit(*s++))
	    return (FALSE);

    return (TRUE);
}


/*
 * ----------------------------------------------------------------------------
 *
 * StrIsDecimal --
 *
 * 	Check a string for being a valid decimal number.
 *
 * Results:
 *	TRUE if the string is a well-formed float without exponential
 *      notation, FALSE otherwise.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */
int
StrIsDecimal(char *s)
{
    if (*s == '-' || *s == '+') s++;
    while (*s && *s!='.')
    {
	if (!isdigit(*s++)) return (FALSE);
    }
    if (*s=='.') s++;
    while (*s)
    {
        if (!isdigit(*s++)) return (FALSE);
    }
    return (TRUE);
}


/*
 * ----------------------------------------------------------------------------
 *
 * StrToLower --
 *
 * 	Convert string to all lowercase.
 *
 * ----------------------------------------------------------------------------
 */
void
StrToLower(char *s)
{
  while (*s)
  {
    *s = tolower(*s);
    s++;
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * StrToUpper --
 *
 * 	Convert string to all lowercase.
 *
 * ----------------------------------------------------------------------------
 */
void
StrToUpper(char *s)
{
  while (*s)
  {
    *s = toupper(*s);
    s++;
  }
}



/*
 * ----------------------------------------------------------------------------
 *
 * StrCheckChars --
 *
 * 	Checks that a string is contains:
 *         1.  no non-ASCII characters.,
 *         2.  no control chars.
 *         3.  no chars in illegal list (passed as arg).
 *
 * Results:
 *	TRUE if string is OK, else FALSE.
 *
 * Side effects:
 *	If msg non-null, generates error messages for illegal chars.
 *
 * ----------------------------------------------------------------------------
 */

bool
StrCheckChars(char *string, 
                 		/* String to check for illegal chars. */
	      char *illegal, 
                  		/* additional illegal chars 
				 * (non-ASCII and control chars are
				 *  always illegal.)
				 */
	      char *msg)
              			/* If NULL no error messages are generated.
                                 * 
				 * If non-NULL, used to identify string
				 * in error messages (e.g. "Label name")
				 */
{
  char *p, *bad;

  for (p = string; *p != 0; p++)
  {
    if (!isascii(*p)) goto error;
    if (iscntrl(*p)) goto error;
    
    for (bad = illegal; *bad != 0; bad++)
    {
      if (*bad == *p) goto error;
    }
  }
  return TRUE;

 error:
  if(!msg) return FALSE;

  if (!isascii(*p) || iscntrl(*p))
  {
    MsgErrorF("%s contains illegal control character 0x%x\n",
	      msg, *p);
  }
  else 
  {
    MsgErrorF("%s contains illegal character \"%c\"\n",
	      msg, *p);
  }

  return FALSE;
}



/*
 * ----------------------------------------------------------------------------
 *
 * StrPropGet --
 *
 * extract property value from gcell like name (e.g. #via!-x_cuts!4!-y_cuts!4)
 *
 * Results: buf if property found, else NULL.
 *
 * ----------------------------------------------------------------------------
 */
char *StrPropGet(char *name, char *prop, char *buf)
{
  char *p;

  for(p=name; *p!='\0'; p++)
  {
    /* match ? */ 
    if(*p=='!' && 
       strncmp(p+1,prop,strlen(prop)) == 0 &&
       *(p+strlen(prop)+1) == '!')
    {
      char *r = buf;

      /* copy value to buf */
      p += strlen(prop)+2;
      while(*p!='\0' && *p!='!') *r++ = *p++;
      *r = '\0';

      return buf;
    }
  }
  
  /* prop not found */
  return NULL;
}


/*
 * ----------------------------------------------------------------------------
 *
 * StrPropAdd --
 *
 * add property to end of gcell like name (e.g. #via!-x_cuts!4!-y_cuts!4)
 *
 * Results: buf 
 *
 * ----------------------------------------------------------------------------
 */
char *StrPropAdd(char *name, char *prop, char *value, char *buf)
{

  sprintf(buf,"%s!%s!%s",
	  name,
	  prop,
	  value);

  return buf;
}


/*
 * ----------------------------------------------------------------------------
 *
 * StrPropSet --
 *
 * create string with given property set to given value;
 * (replaces preexisting property value, if any)
 *
 * ----------------------------------------------------------------------------
 */
char *StrPropSet(char *name, char *prop, char *value, char *buf)
{
  char *p;
  char *r = buf;

  /* copy input name up to matching property */
  for(p=name; *p!='\0'; *r++=*p++)
  {
    /* match ? */ 
    if(*p=='!' && 
       strncmp(p+1,prop,strlen(prop)) == 0 &&
       *(p+strlen(prop)+1) == '!')
    {
      /* skip prop name and value in input */
      p += strlen(prop)+2;
      while(*p!='\0' && *p!='!') p++;

      break;
    }
  }

  /* add prop/value to result */
  *r++='!';
  while(*prop!='\0') *r++=*prop++;
  *r++='!';
  while(*value!='\0') *r++=*value++;

  /* copy tail of input name */
  while(*p!='\0') *r++=*p++;

  /* terminate result string */
  *r = '\0';

  return buf;
}


/*
 * ----------------------------------------------------------------------------
 *
 * StrQuote --
 *
 * turn string into C like quoted string
 * (adds double quotes and escapes as required) 
 *
 * Returns:  pointer to end of result string (the '\0').
 *
 * ----------------------------------------------------------------------------
 */
char *StrQuote(char *s,   /* input string */ 
	       char *result) /* results stored here */
{
  char *p;

  p = result;
  *p++ = '"';

  while(*s!='\0') {
    switch(*s) {
      case '\\':	*p++ = '\\';	*p++ = '\\';	break;
      case '\a':  	*p++ = '\\';	*p++ = 'a';	break;
      case '\b':  	*p++ = '\\';	*p++ = 'b';	break;
      case '\f':  	*p++ = '\\';	*p++ = 'f';	break; 
      case '\n':  	*p++ = '\\';	*p++ = 'n';	break;
      case '\r':  	*p++ = '\\';	*p++ = 'r';	break;
      case '\t':  	*p++ = '\\';	*p++ = 't';	break;
      case '\v':  	*p++ = '\\';	*p++ = 'v';	break;

      default: 
	*p++ = *s;
	break;
    } 
    s++;
  }

  *p++ = '"';

  /* terminate result */
  *p = '\0';

  return p;
}  


/*
 * ----------------------------------------------------------------------------
 *
 * StrQuoteParse --
 *
 * Inverse of StrQuote().
 * Parses C-like double quoted string from beginning of input string.
 *
 * Returns: 
 *  Pointer into input just past end of string parsed, 
 *  NULL on parse error.
 *
 * ----------------------------------------------------------------------------
 */
char *StrQuoteParse(char *s,  /* input string */
		    char *result /* results stored here */)
{
  char *p = result;

  /* skip past any initial white space */
  while (isspace(*s)) s++;

  /* skip initial double quote */
  if (*s != '"') return NULL;
  s++;
  
  while (*s!='\0' && *s!='"') {
    if (*s == '\\') {
      switch (*(++s)) {
        case '\\':  *p++ = '\\';  break;
        case 'a':   *p++ = '\a';  break;
        case 'b':   *p++ = '\b';  break;
        case 'f':   *p++ = '\f';  break;
        case 'n':   *p++ = '\n';  break;
        case 'r':   *p++ = '\r';  break;
        case 't':   *p++ = '\t';  break;
        case 'v':   *p++ = '\v';  break;
        default:
	  return NULL;  /* unknown escape sequence */
      }
      s++;

    } else {
      *p++ = *s++;
    }
  }

  /* skip final double quote */
  if (*s != '"') return NULL;
  s++;

  /* terminate string */
  *p = '\0';

  return s;
}  


/*
 * ----------------------------------------------------------------------------
 *
 * StrQuoteSafe --
 *
 * like StrQuote but assures that output string doesn't 
 * extend past end of buffer, assuming that caller has
 * passed its size correctly
 *
 * Returns:  pointer to end of result string (the '\0')
 *	or NULL if overrun has occurred
 *
 * ----------------------------------------------------------------------------
 */
char *StrQuoteSafe(char *s,   /* input string */ 
	       char *result, /* results stored here */
	       unsigned resultSize)	/* available size of results */
{
  char *p = result;
  char *endp = result + resultSize - 2; /*... close quote && '\0' */

  *p++ = '"';

  while(*s != '\0' && p <= endp) {
    switch(*s) {
      case '\\':	*p++ = '\\';	*p++ = '\\';	break;
      case '\a':  	*p++ = '\\';	*p++ = 'a';	break;
      case '\b':  	*p++ = '\\';	*p++ = 'b';	break;
      case '\f':  	*p++ = '\\';	*p++ = 'f';	break;
      case '\n':  	*p++ = '\\';	*p++ = 'n';	break;
      case '\r':  	*p++ = '\\';	*p++ = 'r';	break;
      case '\t':  	*p++ = '\\';	*p++ = 't';	break;
      case '\v':  	*p++ = '\\';	*p++ = 'v';	break;

      default: 
	*p++ = *s;
	break;
    } 
    s++;
  }

  if (p > endp) {
	/* overrun will occurr if we add closing characters */
	return NULL;
  }

  *p++ = '"';

  /* terminate result */
  *p = '\0';

  return p;
}  

/* used below to build string map (hash) table 
 * should not be referenced outside of these routines!
 */
typedef struct stringmap
{
  char *sm_from;
  char *sm_to;
  struct strmap *sm_hashLink; /* hash table link */
} StringMap;


/* ----------------------------------------------------------------------------
 *
 * StrMapInit --
 *
 * Initalize string mapping table.
 *
 * returns opaque pointer to new map table.
 *
 * ----------------------------------------------------------------------------
 */
void *
StrMapInit(void)
{
  IHashTable *map = 
    IHashInit(256, 
	      OFFSET(StringMap,sm_from), /* key */ 
	      OFFSET(StringMap,sm_hashLink),
	      IHashStringPKeyHash, 
	      IHashStringPKeyEq); 

  /* defer actual initialization until first map added, 
   * to make efficient when no maps present.  
   */
  return (void *) map;
}


/* ----------------------------------------------------------------------------
 *
 * StrMapFree --
 *
 * Deallocate string map table. 
 *
 * ----------------------------------------------------------------------------
 */

static void strMapFreeFunc(void *entry)
{
  StringMap *sm = entry;

  FREE_TAG(sm->sm_from, sm->sm_from);
  FREE_TAG(sm->sm_to, sm->sm_to);
  FREE_TAG(sm,"StringMap");
}

void
StrMapFree(void *map)
{
  IHashTable *table = (IHashTable *) map;

  IHashEnum(table, strMapFreeFunc);
  IHashFree(table);
}


/* ----------------------------------------------------------------------------
 *
 * StrMapAdd --
 *
 * Add an entry to the string map 
 *
 * ----------------------------------------------------------------------------
 */
void
StrMapAdd(void *map, char *from, char *to)
{
  StringMap *sm;

  MALLOC_TAG(char *, sm, sizeof(StringMap), "StringMap");
  sm->sm_from = StrDup(NULL, from);
  sm->sm_to = StrDup(NULL, to);

  IHashAdd((IHashTable *) map, sm);
}


/* ----------------------------------------------------------------------------
 *
 * StrMapLookup --
 *
 * Lookup name map.
 *
 * ----------------------------------------------------------------------------
 */
char *
StrMapLookup(void *map, char *from)
{
  StringMap *sm = IHashLookUp((IHashTable *) map, &from);

  return sm ? sm->sm_to : NULL;
}









