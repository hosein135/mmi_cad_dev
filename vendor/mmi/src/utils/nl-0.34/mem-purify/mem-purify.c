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
#include "purify.h"
#include "mem.h"


#ifdef __linux__
#  include "malloc.h" /* for ptrdiff_t */
#endif

#ifdef __hpux__
#  define __need_ptrdiff_t
#  include <stddef.h>
#endif


typedef struct mem_trace_info *mem_trace_info;


struct mem_group_s {
  char *name;
  int alignment;
  int id;
};


struct mem_trace_info {
  const char *file;
  int line;
  int alloc_num;
  size_t size;
};
  

static int mem_trace_alloc_count = 0;
static int mem_tracing = 0;
static int mem_group_id = 1;
mem_group mem_current_group = NULL;

static mem_group mem_group_table[1024];


static
void
mem_init (void)
{
  mem_current_group = (mem_group)0x8;
  mem_current_group = mem_group_create ("default", 4);
}


mem_group
mem_group_create (char *name, int alignment)
{
  mem_group result = malloc (sizeof (*result));

  if ( mem_current_group == NULL ) {
    mem_init ();
  }

  result->name = strdup (name);
  result->alignment = alignment;
  result->id = mem_group_id;

  mem_group_table[mem_group_id] = result;

  mem_group_id++;

  return result;
}


void
mem_group_free_contents (mem_group group)
{
  purify_map_pool (group->id, (purify_pool_mapper) free);
}


void
mem_group_free (mem_group group)
{
  mem_group_free_contents (group);
  mem_group_table[group->id] = NULL;
  free (group->name);
  free (group);
}

mem_group
mem_group_get_current (void)
{
  return mem_current_group;
}


mem_group
mem_group_set (mem_group group)
{
  mem_group result = mem_current_group;

  mem_current_group = group;

  return result;
}


mem_group
mem_group_of_pointer (void *ptr)
{
  int id = purify_get_pool_id (ptr);
  mem_group result = mem_group_table[id];

  return result;
}


size_t
mem_size_of_allocation (void *ptr)
{
  mem_trace_info info = purify_get_user_data (ptr);

  return info->size;
}


void
mem_free (void *ptr)
{
  free (ptr);
}


void
mem_free_traced (void *ptr)
{
  mem_trace_info info = purify_get_user_data (ptr);

  if ( info != NULL )
    free (info);

  free (ptr);
}


void *
mem_malloc_from_group (size_t size, mem_group group)
{
  void *result = malloc (size);

  purify_set_pool_id (result, group->id);

  return result;
}


void *
mem_malloc_from_group_traced (size_t size, mem_group group,
			      const char *file, int line)
{
  void *result = mem_malloc_from_group (size, group);
  
  if ( mem_tracing ) {
    mem_trace_info info = malloc (sizeof (*info));

    info->file = file;
    info->line = line;
    info->alloc_num = mem_trace_alloc_count;
    mem_trace_alloc_count++;

    purify_set_pool_id ((char *) info, group->id);
    purify_set_user_data (result, info);
  }

  return result;
}


void *
mem_malloc (size_t size)
{
  if ( mem_current_group == NULL ) {
    mem_init ();
  }

  return mem_malloc_from_group (size, mem_current_group);
}


void *
mem_malloc_traced (size_t size, const char *file, int line)
{
  if ( mem_current_group == NULL ) {
    mem_init ();
  }

  return mem_malloc_from_group_traced (size, mem_current_group, file, line);
}


void *
mem_calloc_from_group_traced (size_t num_elem, size_t elt_size, mem_group group,
			      const char *file, int line)
{
  size_t size = num_elem * elt_size;
  void *ptr = mem_malloc_from_group_traced (size, group, file, line);

  memset (ptr, 0, size);

  return ptr;
}


void *
mem_calloc_from_group (size_t num_elem, size_t elt_size, mem_group group)
{
  size_t size = num_elem * elt_size;
  void *ptr = mem_malloc_from_group (size, group);

  memset (ptr, 0, size);

  return ptr;
}


void *
mem_calloc (size_t num_elem, size_t elt_size)
{
  size_t size = num_elem * elt_size;
  void *ptr = mem_malloc (size);

  memset (ptr, 0, size);

  return ptr;
}


void *
mem_calloc_traced (size_t num_elem, size_t elt_size, const char *file, int line)
{
  size_t size = num_elem * elt_size;
  void *ptr = mem_malloc_traced (size, file, line);

  memset (ptr, 0, size);

  return ptr;
}


void *
mem_realloc (void *ptr, size_t size)
{
  void *result = realloc (ptr, size);

  return result;
}


void *
mem_realloc_traced (void *ptr, size_t size, const char *file, int line)
{
  void *result = mem_realloc (ptr, size);

  if ( mem_tracing ) {
    if ( result != ptr ) {
      mem_trace_info info = malloc (sizeof (*info));

      info->file = file;
      info->line = line;
      info->size = size;
      info->alloc_num = mem_trace_alloc_count;
      mem_trace_alloc_count++;
      
      purify_set_user_data (result, info);
    }
  }

  return result;
}


char *
mem_strdup_from_group (char *s, mem_group group)
{
  int length = strlen (s);
  char *result = mem_malloc_from_group (length + 1, group);

  strcpy (result, s);

  return result;
}


char *
mem_strdup_from_group_traced (char *s, mem_group group,
			      const char *file, int line)
{
  int length = strlen (s);
  char *result = mem_malloc_from_group_traced (length + 1, group, file, line);

  strcpy (result, s);

  return result;
}


char *
mem_strdup (char *s)
{
  void *result = mem_strdup_from_group (s, NULL);

  return result;
}


char *
mem_strdup_traced (char *s, const char *file, int line)
{
  void *result;

  if ( mem_current_group == NULL ) {
    mem_init ();
  }
       
  result = mem_strdup_from_group_traced (s, mem_current_group, file, line);

  return result;
}


static
void
mem_show_allocation (char *ptr, int size, mem_trace_info info)
{
  printf ("0x%08x %8d  %5ld %5d %5d %s\n",
	  (ptrdiff_t) ptr, info->alloc_num, (long) info->size, size,
	  info->line, info->file);
}


static
void
mem_show_pool_active (int id)
{
  purify_map_pool (id, (purify_pool_mapper) mem_show_allocation);
}


void
mem_show_active (void)
{
  printf ("Active blocks:\n");

  printf ("            trace   trace purify\n");
  printf ("address     alloc #  size  size  line  file\n");
  printf ("---------- -------- ----- ----- ----- ----------\n");

  purify_map_pool_id (mem_show_pool_active);

  printf ("\n");
}


void
mem_show_usage (void)
{
  printf ("mem_show_usage is not implemented in the purify executable.\n");
}


