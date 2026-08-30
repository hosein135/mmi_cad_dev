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
#include "mem2.h"


int
main (void)
{
  int i;
  mem_group group = mem_group_create ("the group", 4);

  for ( i = 0; i <= 512; i++ ) {
    void *x = mem_malloc_from_group (i, group);
    size_t s = mem_size_of_allocation (x);
    printf ("%3d: %08x %3d\n", i, (int) x, s);
  }

  printf ("\n");

  for ( i = 0; i <= 512; i++ ) {
    void *x = mem_malloc_from_group (i, group);
    size_t s = mem_size_of_allocation (x);
    printf ("%3d: %08x %3d\n", i, (int) x, s);
  }

  printf ("\n");

  for ( i = 0; i <= 512; i++ ) {
    void *x = mem_malloc_from_group (i, group);
    size_t s = mem_size_of_allocation (x);
    printf ("%3d: %08x %3d\n", i, (int) x, s);
  }

  printf ("\n");

  {
    void *x1, *x2, *x3;

    {
      void *x = mem_malloc_from_group (1000, group);
      size_t s = mem_size_of_allocation (x);
      printf ("   : %08x %3d\n", (int) x, s);
      x1 = x;
    }

    {
      void *x = mem_malloc_from_group (2000, group);
      size_t s = mem_size_of_allocation (x);
      printf ("   : %08x %3d\n", (int) x, s);
      x2 = x;
    }

    {
      void *x = mem_malloc_from_group (3000, group);
      size_t s = mem_size_of_allocation (x);
      printf ("   : %08x %3d\n", (int) x, s);
      x3 = x;
    }

    mem_free (x1);
    mem_free (x2);
    mem_free (x3);
  }

  {
    void *x1, *x2, *x3;

    {
      void *x = mem_malloc_from_group (1000, group);
      size_t s = mem_size_of_allocation (x);
      printf ("   : %08x %3d\n", (int) x, s);
      x1 = x;
    }

    {
      void *x = mem_malloc_from_group (2000, group);
      size_t s = mem_size_of_allocation (x);
      printf ("   : %08x %3d\n", (int) x, s);
      x2 = x;
    }

    {
      void *x = mem_malloc_from_group (3000, group);
      size_t s = mem_size_of_allocation (x);
      printf ("   : %08x %3d\n", (int) x, s);
      x3 = x;
    }

    mem_free (x1);
    mem_free (x2);
    mem_free (x3);
  }

  mem_group_free (group);

  
  group = mem_group_create ("another group", 8);

  for ( i = 0; i <= 512; i++ ) {
    void *x = mem_malloc_from_group (i, group);
    size_t s = mem_size_of_allocation (x);
    printf ("%3d: %08x %3d\n", i, (int) x, s);
    mem_free (x);
  }

  printf ("\n");

  for ( i = 0; i <= 512; i++ ) {
    void *x = mem_malloc_from_group (i, group);
    size_t s = mem_size_of_allocation (x);
    printf ("%3d: %08x %3d\n", i, (int) x, s);
    mem_free (x);
  }

  printf ("\n");

  for ( i = 0; i <= 512; i++ ) {
    void *x = mem_malloc_from_group (i, group);
    size_t s = mem_size_of_allocation (x);
    printf ("%3d: %08x %3d\n", i, (int) x, s);
    mem_free (x);
  }

  printf ("\n");

  {
    void *x = mem_malloc_from_group (1000, group);
    size_t s = mem_size_of_allocation (x);
    printf ("%3d: %08x %3d\n", i, (int) x, s);
    mem_free (x);
  }

  {
    void *x = mem_malloc_from_group (2000, group);
    size_t s = mem_size_of_allocation (x);
    printf ("%3d: %08x %3d\n", i, (int) x, s);
    mem_free (x);
  }

  {
    void *x = mem_malloc_from_group (3000, group);
    size_t s = mem_size_of_allocation (x);
    printf ("%3d: %08x %3d\n", i, (int) x, s);
    mem_free (x);
  }

  mem_group_free (group);

  
  group = mem_group_create ("another group", 16);

  for ( i = 0; i <= 512; i++ ) {
    void *x = mem_malloc_from_group (i, group);
    size_t s = mem_size_of_allocation (x);
    printf ("%3d: %08x %3d\n", i, (int) x, s);
  }

  printf ("\n");

  for ( i = 0; i <= 512; i++ ) {
    void *x = mem_malloc_from_group (i, group);
    size_t s = mem_size_of_allocation (x);
    printf ("%3d: %08x %3d\n", i, (int) x, s);
  }

  printf ("\n");

  for ( i = 0; i <= 512; i++ ) {
    void *x = mem_malloc_from_group (i, group);
    size_t s = mem_size_of_allocation (x);
    printf ("%3d: %08x %3d\n", i, (int) x, s);
  }

  printf ("\n");

  {
    void *x = mem_malloc_from_group (1000, group);
    size_t s = mem_size_of_allocation (x);
    printf ("%3d: %08x %3d\n", i, (int) x, s);
  }

  {
    void *x = mem_malloc_from_group (2000, group);
    size_t s = mem_size_of_allocation (x);
    printf ("%3d: %08x %3d\n", i, (int) x, s);
  }

  {
    void *x = mem_malloc_from_group (3000, group);
    size_t s = mem_size_of_allocation (x);
    printf ("%3d: %08x %3d\n", i, (int) x, s);
  }

  mem_group_free (group);

  return 0;
}
