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
#include "ar.h"
#include "hashtab.h"
#include "mem.h"


static hashtab block_table = NULL;
static ht_attr alloc_size = NULL;
static ht_attr file_names = NULL;
static ht_attr line_nums = NULL;
static ht_attr alloc_num = NULL;
static int mem_tracing = 0;
static int mem_trashing = 1;
static int mem_alloc_count = 1;
static int mem_watch_alloc = 0;


#if 0
static
void
mem_free_string_attr (void *ptr)
{
  char **s_p = (char **)ptr;

  FREE (*s_p);
}
#endif


static
void
mem_init (void)
{
  block_table = ht_alloc (256, ht_hash_ptr, NULL, NULL, NULL);

  alloc_size = ht_new_attribute (block_table, sizeof (int), NULL, NULL);
  file_names = ht_new_attribute (block_table, sizeof (char *), NULL, NULL);
  line_nums = ht_new_attribute (block_table, sizeof (int), NULL, NULL);
  alloc_num = ht_new_attribute (block_table, sizeof (int), NULL, NULL);
}


static
void
mem_trash_block (void *ptr, int size, int is_free)
{
  int i;
  char *block = ptr;

  for ( i = 0; i < size; i++ ) {
    if ( is_free )
      block[i] = 0xf0;
    else
      block[i] = 0xa5;
  }
}


static
void
mem_trace_alloc (void *ptr, int size, char *file, int line, int trash_it)
{
  if ( mem_tracing ) {
    ht_entry hte;

    mem_tracing = 0;

    if ( mem_trashing && trash_it ) {
      mem_trash_block (ptr, size, 0);
    }

    if ( block_table == NULL ) {
      mem_init ();
    }

    if ( mem_alloc_count == mem_watch_alloc ) {
      /* Set a breakpoint here */
      int x = 0;
      x++;
    }

    hte = ht_insert (block_table, ptr);

    {
      ht_set_attribute_for_entry (alloc_size, hte, &size);
      ht_set_attribute_for_entry (file_names, hte, &file);
      ht_set_attribute_for_entry (line_nums, hte, &line);
      ht_set_attribute_for_entry (alloc_num, hte, &mem_alloc_count);
    }

    mem_alloc_count++;

    mem_tracing = 1;
  }
}
  
    
static
void
mem_trace_free (void *ptr, int trash_it)
{
  if ( mem_tracing ) {
    ht_entry hte;

    mem_tracing = 0;

    if ( mem_trashing && trash_it ) {
      int size;

      ht_get_attribute (alloc_size, ptr, &size);

      mem_trash_block (ptr, size, 1);
    }

    hte = ht_delete (block_table, ptr);
    ASSERT (hte != ht_null);

    mem_tracing = 1;
  }
}
  
    
void *
mem_malloc (size_t size, char *file, int line)
{
  void *ptr = malloc (size);

  if ( ptr == NULL ) {
    fprintf (stderr, "Out of memory.\n");
    abort ();
  }

  mem_trace_alloc (ptr, size, file, line, 1);

  return ptr;
}


void *
mem_realloc (void *old, size_t size, char *file, int line)
{
  void *ptr = realloc (old, size);

  if ( ptr == NULL ) {
    fprintf (stderr, "Out of memory.\n");
    abort ();
  }

  if ( ptr != old ) {
    mem_trace_free (old, 0);
    mem_trace_alloc (ptr, size, file, line, 0);
  }

  return ptr;
}


char *
mem_strdup (char *s, char *file, int line)
{
  char *str = strdup (s);

  mem_trace_alloc (str, strlen (s), file, line, 0);

  return str;
}


void
mem_free (void *ptr)
{
  mem_trace_free (ptr, 1);
  free (ptr);
}

    
void
mem_show_active (void)
{
  printf ("Active blocks:\n");

  printf ("address     alloc #  size  line  file\n");
  printf ("---------- -------- ----- ----- ----------\n");

  ht_for_all_entries (block_table, ent) {
    void *key = ht_get_key (block_table, ent);
    int size;
    char *file;
    int line;
    int alloc;

    ht_get_attribute_for_entry (alloc_size, ent, &size);
    ht_get_attribute_for_entry (file_names, ent, &file);
    ht_get_attribute_for_entry (line_nums, ent, &line);
    ht_get_attribute_for_entry (alloc_num, ent, &alloc);

    printf ("0x%08x %8d  %5d %5d %s\n", (unsigned int) key,
	    alloc, size, line, file);
  } ht_end_for;

  printf ("\n");
}
