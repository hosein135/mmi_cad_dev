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

#include <stdio.h>


main (int argc, char *argv[])
{
  int i;

  for ( i = 1; i < argc; i++ ) {
    FILE *ifp = fopen (argv[i], "r");

    if ( ifp == NULL ) {
      fprintf (stderr, "Cannot open %s for reading.\n", argv[i]);
      exit (1);
    }
    else {
      char c = getc (ifp);
      int count = 0;

      printf ("\n/* %s */\n", argv[i]);

      while ( !feof (ifp) ) {
	printf ("0x%02x, ", c);
	count++;

	c = getc (ifp);

	if ( !feof (ifp) ) {
	  if ( count == 13 ) {
	    printf ("\n");
	    count = 0;
	  }
	}
      }
    }

    printf ("\n");
    fclose (ifp);
  }

  return 0;
}
