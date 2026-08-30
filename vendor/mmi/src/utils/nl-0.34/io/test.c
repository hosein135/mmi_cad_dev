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

main (int argc)
{
  ar a;
  int x;
  char *s1;
  char *s2;
  char *s3;
  int y1;
  int y2;

  if ( argc == 1 ) {
    s1 = "string 1";
    s2 = "string[2]";
    s3 = " string_3 ";

    a = ar_alloc (3, sizeof(int));
    x = 11;
    ar_add (a, &x);
    x = 22;
    ar_add (a, &x);
    x = 33;
    ar_add (a, &x);
    x = 44;
    ar_add (a, &x);
    x = 55;
    ar_add (a, &x);
    x = 66;
    ar_add (a, &x);

    y1 = 90124;
    io_write_int (&y1, stdout);
    io_write_string (&s1, stdout);
    io_write_string (&s2, stdout);
    y2 = -12;
    io_write_int (&y2, stdout);
    io_write_string (&s3, stdout);
    io_write_ar (&a, io_write_int, stdout);
  }
  else {
    io_read_int (&y1, stdin);
    io_read_string (&s1, stdin);
    io_read_string (&s2, stdin);
    io_read_int (&y2, stdin);
    io_read_string (&s3, stdin);
    io_read_ar (&a, io_read_int, stdin);

    printf ("y1 = %d\n", y1);
    printf ("y2 = %d\n", y2);
    printf ("s1 = '%s'\n", s1);
    printf ("s2 = '%s'\n", s2);
    printf ("s3 = '%s'\n", s3);
  }
}

