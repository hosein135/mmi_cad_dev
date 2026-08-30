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

#include "port.h"


main ()
{
  char word[64];
  int word_count = 0;
  int byte_count = 0;
  int line_count = 0;
  int word_table[65536];

  printf ("#include \"namegen_int.h\"\n\n");

  printf ("const char *namegen_bytes = \n  \"");

  while ( scanf ("%s", &word) == 1 ) {
    int i = -1;

    if ( line_count > 50 ) {
      printf ("\"\n  \"");
      line_count = 0;
    }

    printf ("%s\\0", word);

    word_table[word_count] = byte_count;

    byte_count += strlen (word) + 1;
    line_count += strlen (word) + 1;
    word_count++;
  }

  printf ("\";\n\n");

  printf ("int namegen_num_words = %d;\n\n", word_count);

  {
    int i;

    printf ("int namegen_offsets[] = {");

    for ( i = 0; i < word_count; i++ ) {
      if ( i > 0 ) {
	putchar (',');
      }
	  
      printf ("\n  %d", word_table[i]);
    }

    printf ("\n};\n");
  }
}
