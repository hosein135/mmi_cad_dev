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
#include "error.h"
#include "mem.h"
#include "ar.h"


typedef void io_write_fn_t (void *, FILE *);
typedef void io_read_fn_t (void *, FILE *);


static
void
io_skip_whitespace (FILE *fp)
{
  char c = getc (fp);

  while ( isspace (c) )
    c = getc (fp);

  ungetc (c, fp);
}


static
void
io_skip_string (char *str, FILE *fp)
{
  char *s = str;

  io_skip_whitespace (fp);

  while (*s) {
    char c = fgetc (fp);

    if ( c != s[0] ) {
      error ("Read error at %c", c);
    }

    s++;
  }
}


void
io_write_int (int *x_p, FILE *fp)
{
  fprintf (fp, "%d", *x_p);
  putc (' ', fp);
}


void
io_read_int (int *x_p, FILE *fp)
{
  fscanf (fp, "%d", x_p);
  getc (fp);
}


void
io_write_ar (ar *a_p, io_write_fn_t write_fun, FILE *fp)
{
  ar a = *a_p;
  int length = ar_size (a);
  int elt_size = ar_elt_size (a);
  int i;

  fprintf (fp, "[");
  io_write_int (&length, fp);
  io_write_int (&elt_size, fp);

  for ( i = 0; i < length; i++ ) {
    void *ptr = ar_addr_of (a, i);

    write_fun (ptr, fp);
  }

  fprintf (fp, "]\n");
}


void
io_read_ar (ar *a_p, io_read_fn_t read_fun, FILE *fp)
{
  int length;
  int elt_size;
  int i;
  ar a;

  io_skip_string ("[", fp);
  io_read_int (&length, fp);
  io_read_int (&elt_size, fp);

  a = ar_alloc (length, elt_size);
  ar_make_size (a, length);

  for ( i = 0; i < length; i++ ) {
    void *ptr = ar_addr_of (a, i);

    read_fun (ptr, fp);
  }

  io_skip_string ("]", fp);

  *a_p = a;
}


void
io_write_string (char **str_p, FILE *fp)
{
  char *str = *str_p;
  int length = strlen (str);

  putc ('"', fp);
  io_write_int (&length, fp);
  fwrite (str, 1, length, fp);
  putc ('"', fp);
  putc ('\n', fp);
}


void
io_read_string (char **str_p, FILE *fp)
{
  int length;
  char *result;

  io_skip_string ("\"", fp);
  io_read_int (&length, fp);
  result = MALLOC (length+1);
  fread (result, 1, length, fp);
  result[length] = 0;
  io_skip_string ("\"", fp);

  *str_p = result;
}
