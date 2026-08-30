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
#include "unparse.h"
#include "mem.h"


struct unparse_fp {
  FILE *fp;
  int   column;
  int   indent;
  int   line_limit;
  int   start_column;
  int   space_before;
  char *buffer;
  int   buffer_size;
  int   buffer_pos;
  int   buffer_indent;
  int   bol;
};


static unsigned int power_2_roundup (unsigned int);
static void unparse_flush_buffer (unparse_fp, int);
static void unparse_append_to_buffer (unparse_fp, char *);



static
unsigned int
power_2_roundup (unsigned int n)
{
  unsigned int x = n;
  unsigned int result = 1;

  while ( x > 0 ) {
    result <<= 1;
    x >>= 1;
  };

  return result;
}


static
void
unparse_flush_buffer (unparse_fp ufp, int force_newline)
{
  int i;
  int need = ufp->start_column + ufp->space_before + ufp->buffer_pos;

  if ( force_newline || need > ufp->line_limit ) {
    fputc ('\n', ufp->fp);

    ufp->column = 0;
    ufp->start_column = 0;
  }

  if ( ufp->start_column == 0 ) {
    if ( ufp->buffer_pos > 0 ) {
      for ( i = 0; i < ufp->buffer_indent; i++ ) {
	fputc (' ', ufp->fp);
      }
      ufp->column = ufp->buffer_indent + ufp->buffer_pos;
    }
  }
  else {
    for ( i = 0; i < ufp->space_before; i++ ) {
      fputc (' ', ufp->fp);
    }
  }

  fwrite (ufp->buffer, ufp->buffer_pos, 1, ufp->fp);

  ufp->start_column = ufp->column;
  ufp->buffer[0] = 0;
  ufp->buffer_pos = 0;
  ufp->space_before = 0;
  ufp->buffer_indent = ufp->indent;
}


static
void
unparse_append_to_buffer (unparse_fp ufp, char *str)
{
  int len = strlen (str);

  if ( ufp->buffer_pos + len + 1 > ufp->buffer_size ) {
    int new_size = power_2_roundup (ufp->buffer_pos + len + 1);

    ufp->buffer = REALLOC (ufp->buffer, new_size);
  }

  strcpy (ufp->buffer + ufp->buffer_pos, str);

  ufp->buffer_pos += len;
  ufp->column += len;
}


void
unparse_newline (unparse_fp ufp)
{
  unparse_flush_buffer (ufp, 0);
  unparse_flush_buffer (ufp, 1);
}


void
unparse_space (unparse_fp ufp, int n)
{
  unparse_token (ufp, "", n);
}


unparse_fp
unparse_open (FILE *fp)
{
  unparse_fp result = MALLOC (sizeof (*result));

  result->fp = fp;
  result->column = 0;
  result->indent = 0;
  result->line_limit = 79;
  result->start_column = 0;
  result->space_before = 0;
  result->buffer = MALLOC (256);
  result->buffer_size = 0;
  result->buffer_pos = 0;
  result->buffer[0] = '\0';
  result->buffer_indent = 0;
  result->bol = 1;

  return result;
}


void
unparse_close (unparse_fp ufp)
{
  unparse_flush_buffer (ufp, 0);
  
  if ( ufp->buffer )
    FREE (ufp->buffer);

  FREE (ufp);
}


int
unparse_indent (unparse_fp ufp)
{
  return ufp->indent;
}


void
unparse_set_indent (unparse_fp ufp, int indent)
{
  ufp->indent = indent;
}


int
unparse_line_limit (unparse_fp ufp)
{
  return ufp->line_limit;
}


void
unparse_set_line_limit (unparse_fp ufp, int n)
{
  ufp->line_limit = n;
}


int
unparse_column (unparse_fp ufp)
{
  return ufp->column;
}


void
unparse_flush (unparse_fp ufp)
{
  unparse_flush_buffer (ufp, 0);
}


void
unparse_token (unparse_fp ufp, char *str, int space_before)
{
  if ( space_before >= 0 ) {
    unparse_flush_buffer (ufp, 0);

    if ( ufp->start_column > 0 ) {
      ufp->space_before = space_before;
      ufp->column += space_before;
    }
  }

  unparse_append_to_buffer (ufp, str);
}


void
unparse_int (unparse_fp ufp, int x, int space_before)
{
  static char buf[32];

  sprintf (buf, "%d", x);

  unparse_token (ufp, buf, space_before);
}


void
unparse_float (unparse_fp ufp, float f, int space_before)
{
  static char buf[32];

  sprintf (buf, "%f", f);

  unparse_token (ufp, buf, space_before);
}


void
unparse_double (unparse_fp ufp, double d, int space_before)
{
  static char buf[32];

  sprintf (buf, "%e", d);

  unparse_token (ufp, buf, space_before);
}
