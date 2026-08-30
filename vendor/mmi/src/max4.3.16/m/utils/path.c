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



/* path.c
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
 *
 * This file contains routines that implement a path mechanism, whereby
 * several places may be searched for files.
 */

#ifndef lint
static char rcsid[] = "$Header: path.c,v 6.0 90/08/28 19:01:11 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <pwd.h>
#include <ctype.h>
#include <sys/param.h>
#include "magic.h"
#include "hash.h"
#include "memory.h"
#include "utils.h"

/* Library routines: */

extern char *getenv(const char *);

/* A hash table is used to keep track of the logins we've
 * already looked up.
 */

static HashTable loginTable;
static noTable = TRUE;

/* Limit on how long a single file name may be: */
#define MAXSIZE MAXPATHLEN


/*-------------------------------------------------------------------
 * paTildeExpandEntry --
 *	This routine converts tilde notation into standard directory names.
 *
 *      NOTE:  Designed for use with search paths,
 *             see PaTildeExpand() below.
 *
 * Results:
 *	If the conversion was done successfully, then the return value
 *	is the number of bytes of space left in the destination area.
 *	If a user name couldn't be found in the password file, then
 *	-1 is returned.
 *
 * Side Effects:
 *	If the first character of the string indicated by psource is a
 *	tilde ("~") then the subsequent user name is converted to a login
 *	directory name and stored in the string indicated by dest.  Then
 *	remaining characters in the file name at psource are copied to
 *	pdest (the file name is terminated by white space, a null character,
 *	or a colon) and psource is updated.  Upon return, psource points
 *	to the terminating character in the source file name, and pdest
 *	points to the null character terminating the expanded name.
 *	If a tilde cannot be converted because the user name cannot
 *	be found, psource is still advanced past the current entry, but
 *	nothing	is stored at the destination.  At most size characters
 *	(including the terminating null character) will be stored at pdest.
 *	Note:  the name "~" with no user name expands to the home directory.
 *
 *-------------------------------------------------------------------
 */

static int
paTildeExpandEntry(char **psource, 
                   		/* Pointer to a pointer to the source string */
		   char **pdest, 
                 		/* Pointer to a ptr to dest string area. */
		   int size)
             			/* Number of bytes available at pdest */

{
    register char *ps, *pd;
    struct passwd *passwd, *getpwnam(const char *);
    char userName[100], *string, *newEntry;
    HashEntry *h;
    int length,i;

    size -= 1;
    ps = *psource;
    if (*ps == '~')
    {
	/* Strip off the login name from the front of the file name. */

	pd = userName;
	for (i=0; ; i++)
	{
	    *pd = *++ps;
	    if (isspace(*pd) || (*pd=='\0') || (*pd=='/') || (*pd==':'))
		break;
	    if (i < 99) pd++;
	}
	*pd = '\0';

	/* Lookup the login name in the hash table.  Create a hash
	 * table if we don't have one already.
	 */

	if (noTable)
	{
	    HashInit(&loginTable, 16, 0);
	    noTable = FALSE;
	}
	h = HashFind(&loginTable, userName);
	string = HashGetValue(h);
	if (string != 0) goto gotname;

	/* We haven't seen this name before.  Look it up in the
	 * password file.  If the name is "~", then just use the
	 * home directory.  
	 */

	if (strcmp(userName, "") == 0) 
	    string = getenv("HOME");
	else
	{
	  passwd = getpwnam(userName);
	  if (passwd != NULL) string = passwd->pw_dir;

	}
	if (string != NULL)
	{
	    MALLOC(char *, newEntry, strlen(string) + 1);
	    (void) strcpy(newEntry, string);
	    HashSetValue(h, newEntry);
	}
	else
	{
	    /* No login entry.  Skip the rest of the file name. */

	    while ((*ps != '\0') && !isspace(*ps) && (*ps != ':')) ps++;
	    *psource = ps;
	    return -1;
	}

	gotname: length = strlen(string);
	if (length > size) length = size;
	(void) strncpy(*pdest, string, length+1);
	size -= length;
	pd = *pdest+length;
    }
    else
    {
	/* No tilde to expand.  As a minor convenience, check to see
	 * if the first two characters of the name are "./".  If so,
	 * then just skip over them.
	 */

	while (ps[0] == '.')
	{
	    if (ps[1] == '/') ps += 2;
	    else
	    {
		if ((ps[1] == 0) || (ps[1] == ':') || isspace(ps[1]))
		    ps += 1;
		break;
	    }
	}
        pd = *pdest;
    }

    /* Copy the rest of the directory name from the source to the dest. */

    while ((*ps != '\0') && !isspace(*ps) && (*ps != ':'))
	if (size > 0)
	{
	    *pd++ = *ps++;
	    size--;
	}
	else ps++;
    *pd = 0;
    *psource = ps;
    *pdest = pd;
    return size;
}


/*----------------- --------------------------------------------------
 * 
 * PaTildeExpand --
 *	This routine expands tilde notation in a name.
 *
 *  Results:  TRUE on success, FALSE on failure.
 *            (input just cped to destination on failure) 
 *
 *-------------------------------------------------------------------
 */
bool
PaTildeExpand(char *name, 
		                /* pathname to tilde expand */
	      char *buf, 
		                /* result goes here */   
	      int bufSize)
                   		/* max size */
{
  char *src = name;
  char *dest = buf;

  if(paTildeExpandEntry(&src, &dest, bufSize) != -1) return TRUE;

  /* couldn't expand ~ */
  strncpy(name,buf,bufSize);
  buf[bufSize-1] = '\0';
  return FALSE;
}


/*-------------------------------------------------------------------
 * PaHasExtension --
 *	Check if given name already has an extension.
 *      (i.e. part of name after final / ends in .* 
 *       (where * is not null).
 *
 * Results:
 *	TRUE if extension present, else FALSE
 *
 * Side Effects:
 *      None.
 *-------------------------------------------------------------------
 */
bool 
PaHasExtension(char *fName)
{
  char *lastPart = fName;

  /* find last part */
  for(;*fName!='\0';fName++)
  {
    if(*fName=='/') lastPart = fName;
  }

  /* look for '.' in last part */
  for(;*lastPart!='\0';lastPart++)
  {
    if(*lastPart == '.') goto dotFound;
  }
  return FALSE;

 dotFound:
  /* skip to end */
  for(;lastPart[1]!='\0';lastPart++);

  return(*lastPart != '.');

  /* no '.' found */
  return FALSE;
}
  

/*-------------------------------------------------------------------
 * PaExtendedName --
 *	if fName doesn't have extension, default extension tacked on.
 *      (A final '.' is considered to be begging the default extension)
 *
 * Results:
 *	Extended file name
 *      NOTE:  result destroyed on next call to this routine.
 *-------------------------------------------------------------------
 */
static char paExtendedNameBuf[MAXSIZE]; 

char *
PaExtendedName(char *fName, char *defExt)
{
  int length,i,extLength;

  if(defExt==NULL || PaHasExtension(fName))
  {
    return fName;
  }

  length = strlen(fName);

  if (length >= MAXSIZE)
  {
    length = MAXSIZE-1;
  }

  /* copy name to buffer */
  (void) strncpy(paExtendedNameBuf, fName, length+1);

  /* if name ends in '.', strip the '.' */
  if(paExtendedNameBuf[length-1] == '.') length = length - 1;

  /* add extension */
  i = MAXSIZE - 1 - length;
  extLength = strlen(defExt);

  if (extLength > i) 
  {
    extLength = i;
  }

  if (extLength > 0) 
  {
    (void) strncpy(&(paExtendedNameBuf[length]), defExt, extLength+1);
  }

  paExtendedNameBuf[MAXSIZE-1] = '\0';

  return paExtendedNameBuf;
}
  

/* ----------------------------------------------------------------------------
 * paNextName --
 *	This local procedure is used to step through a path, adding a
 *	directory name from the path to a file name.
 *
 * Results:
 *	The return value is a pointer to a path-extended name, or
 *	NULL if the end of the path has been reached.  If a tilde
 *	couldn't be expanded, then a zero-length string is returned.
 *
 * Side effects:
 *	The pointer at *ppath is updated to refer to the terminating
 *	character of the path entry used this time.
 * ----------------------------------------------------------------------------
 */

static char *
paNextName(char **ppath, 
                 		/* Pointer to a pointer to the next
				 * entry in the path.
				 */
	 char *file, 
               			/* Pointer to a file name. */
	 char *dest, 
               			/* Place to build result name. */
	 int size)
             			/* Size of result area. */

{
    char *p;

    /* Don't bother with NULL paths */
    if (*ppath == 0) return NULL;

    /* Skip leading blanks and colons.  Then make sure that there's
     * another entry in the path.
     */
    while (isspace(**ppath) || (**ppath == ':')) *ppath += 1;
    if (**ppath == 0) return NULL;

    /* Grab the next directory name and terminate it with a slash if
     * there isn't one there already.
     */

    p = dest;
    dest[size-1] = 0;
    size = paTildeExpandEntry(ppath, &p, size);
    if (**ppath) *ppath += 1;		 /* Skip the terminating character. */
    if (size < 0)
    {
	dest[0] = 0;
	return dest;
    }
    if ((p != dest) && (*(p-1) != '/'))
    {
	*p++ = '/';
	size -= 1;
    }
    if (size < strlen(file)) strncpy(p, file, size);
    else strcpy(p, file);
    return dest;
}


/*-------------------------------------------------------------------
 * PaOpen --
 *	This routine does a file lookup using the current path and
 *	supplying a default extension.
 *
 * Results:
 *	A pointer to a FILE, or NULL if the file couldn't be found.
 *
 * Side Effects:
 *	If ext is specified, and file has no extension (no '.' following
 *      final '/', OR ending in '.' then ext is tacked onto the end of
 *	the given file name.  
 *
 *      If the first character of the
 *	file name is "~" or "/" or if nosearch is TRUE, then we try
 *	to look up the file with the original name, doing tilde
 *	expansion of course and returning that result.  If none of 
 *	these conditions is met, we go through the path	trying to
 *	look up the file once for each path entry by prepending the
 *	path entry to the original file name. This concatenated name
 *	is stored in a static string and made available to the caller
 *	through prealName if the open succeeds.  If the entire path is
 *	tried, and still nothing works, then we try each entry in the
 *	library path next.
 *	Note: the static string will be trashed on the next call to this
 *	routine.  Also, note that no individual file name is allowed to
 *	be more than MAXSIZE characters long.  Excess characters are lost.
 *
 * Path Format:
 *	A path is a string containing directory names separated by
 *	colons or white space.  Tilde notation may be used within paths.
 *-------------------------------------------------------------------
 */

FILE *
PaOpen(char *file, 
               			/* Name of the file to be opened. */
       char *mode, 
               			/* The file mode, as given to fopen. */
       char *ext, 
              			/* The extension to be added to the file name,
				 * or NULL.  Note:  this string must include
				 * the dot (or whatever separator you use).
				 */
       char *path, 
               			/* A search path:  a list of directory names
				 * separated by colons or blanks.  To use
				 * only the working directory, use "." 
				 */
       char **pRealName)
                     		/* Pointer to a location that will be filled
				 * in with the address of the real name of
				 * the file that was successfully opened.
				 * If NULL, then nothing is stored.
				 */
{
    static char realName[MAXSIZE];

    /*
    fprintf(stderr,"DEBUG PaOpen TOP file='%s' mode='%s' ext='%s' path='%s'\n",
	    file, 
	    mode, 
	    ext, 
	    path);
    */

    if (file == NULL) return (FILE *) NULL;
    if (file[0] == '\0') return (FILE *) NULL;
    if (pRealName != NULL) (*pRealName) = realName;

    /* Add default extension to name (if no extension already) */
    file = PaExtendedName(file,ext);

    /* If the first character of the file name is a tilde, do tilde
     * expansion but don't touch a search path.
     */

    if (file[0] == '~')
    {
	char *p1 = realName;
	char *p2 = file;
	if (paTildeExpandEntry(&p2, &p1, MAXSIZE) < 0) return NULL;

	return fopen(realName, mode);
    }

    /* If we were already given a full rooted file name,
     * or a relative pathname, just use it.
     */

    if (file[0] == '/'
	    || (file[0] == '.' && (strcmp(file, ".") == 0
				|| strncmp(file, "./", 2) == 0
				|| strcmp(file, "..") == 0
				|| strncmp(file, "../", 3) == 0)))
    {
	strncpy(realName, file, MAXSIZE-1);
	realName[MAXSIZE-1] = '\0';
	return fopen(realName, mode);
    }

    /* Now try going through the path, one entry at a time. */

    while (paNextName(&path, file, realName, MAXSIZE) != NULL)
    {
      FILE *f;

      if (*realName == 0) continue;
      f = fopen(realName, mode);
      if (f != NULL) return f;
    }

    return NULL;
}


/*
 * ----------------------------------------------------------------------------
 *	PaSplitName --
 *
 *	Split a path name, into directory part, base name, and extension.
 *      e.g. for "/home/foo/bar.max":
 *            dir = "/home/foo/"
 *            base = "bar"
 *            ext = ".max"
 *
 * ----------------------------------------------------------------------------
 */
void PaSplitName(char *name,  /* name to split */
		 char *dir,   /* if non-null, dir part returned here */
		 char *base,  /* if non-null, base name returned here */
		 char *ext)   /* if non-null, extension returned here */
{
  char *lastSlash = NULL;
  char *lastDot = NULL;
  char *p, *res;

  /* find last slash */
  for(p=name; *p!='\0'; p++)
  {
    if(*p=='/') lastSlash=p;
  }

  /* find last dot (after last slash) */
  for(p=(lastSlash) ? lastSlash : name; 
      *p!='\0'; 
      p++)
  {
    if(*p=='.') lastDot=p;
  }

  /* copy path */
  if(dir)
  {
    res = dir;
    if(lastSlash)
    {
      p = name;
      while(p<=lastSlash) *(res++) = *(p++);
    }
    *res = '\0';
  }

  /* copy base */
  if(base)
  {
    res = base;
    p = lastSlash ? lastSlash+1 : name;
    while(p!=lastDot && *p!='\0') *(res++) = *(p++);
    *res = '\0';
  }

  /* copy ext */
  if(ext)
  {
    res = ext;
    if(lastDot)
    {
      p = lastDot;
      while(*p!='\0') *(res++) = *(p++);
    }
    *res = '\0';
  }
}


		 
		 






