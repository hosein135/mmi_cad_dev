/* 
 *     ********************************************************************* 
 *     * Copyright (C) 1988, 1990 Stanford University.                     * 
 *     * Permission to use, copy, modify, and distribute this              * 
 *     * software and its documentation for any purpose and without        * 
 *     * fee is hereby granted, provided that the above copyright          * 
 *     * notice appear in all copies.  Stanford University                 * 
 *     * makes no representations about the suitability of this            * 
 *     * software for any purpose.  It is provided "as is" without         * 
 *     * express or implied warranty.  Export of this software outside     * 
 *     * of the United States of America may require an export license.    * 
 *     ********************************************************************* 
 */

#ifdef SYS_V
#    include <sys/types.h>
#    include <unistd.h>
#endif
#include <sys/file.h>
#include <stdio.h>
#include <pwd.h>
#include "defs.h"


public	char    *cad_lib;
public	char    *cad_bin;


extern	char           *getenv();
extern	struct passwd  *getpwnam();
extern	char           *Valloc();


public void InitCAD()
  {
    char           *s;
    struct passwd  *pwd;
    int            len;

	/* first try CAD_HOME env. variable */

    s = getenv( "CAD_HOME" );
    if( s )
      {
	if( access( s, F_OK ) == 0 )
	    goto go_it;
      }

	/* try "~cad" */

    pwd = getpwnam( "cad" );
    s = (pwd) ? pwd->pw_dir : 0;
    if( s )
      {
	if( access( s, F_OK ) == 0 )
	    goto go_it;
      }

	/* default */

    s = "/projects/cad";

  go_it :

    len = strlen( s );
    cad_lib = Valloc( len + 5, 1 );
    cad_bin = Valloc( len + 5, 1 );
    (void) sprintf( cad_lib, "%s/lib", s );
    (void) sprintf( cad_bin, "%s/bin", s );
  }
