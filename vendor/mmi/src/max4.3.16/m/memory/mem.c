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
#include "mem.h"

#ifdef __linux__
#  include "malloc.h" /* for ptrdiff_t */
#endif

#ifdef __hpux__
#  define __need_ptrdiff_t
#  include <stddef.h>
#endif


typedef struct mem_free_item *mem_free_item;
typedef struct mem_block *mem_block;
typedef struct mem_trace_info *mem_trace_info;


struct mem_free_item {
  mem_free_item next;
};


struct mem_block {
  mem_block next;
  mem_block prev;
  mem_group group;
  ptrdiff_t num_words;
  int storage[1];
};


struct mem_trace_info {
  mem_trace_info next;
  mem_trace_info prev;
  const char *file;
  mem_group group;
  int line;
  int alloc_num;
  ptrdiff_t size;
};


static int mem_tracing = 0;
static struct mem_trace_info mem_trace_info_head
  = { &mem_trace_info_head, &mem_trace_info_head, "", NULL, 0, -1, 0 };
  

#define MEM_MALLOC_OVERHEAD    8
#define MEM_MAX_ALLOC        512
#define MEM_BLOCK_BITS        11
#define MEM_BLOCK_ALIGN        ( 1 << MEM_BLOCK_BITS)
#define MEM_BLOCK_MASK         (-1 << MEM_BLOCK_BITS)
#define MEM_BLOCK_HEADER_SIZE  (sizeof (struct mem_block) - sizeof (int))
#define MEM_BLOCK_ALLOC        (MEM_BLOCK_ALIGN - MEM_MALLOC_OVERHEAD)
#define MEM_BLOCK_STORAGE_SIZE (MEM_BLOCK_ALLOC - MEM_BLOCK_HEADER_SIZE)

static unsigned int *mem_block_table = NULL;
static unsigned int  mem_block_table_size = 0;
static unsigned int  mem_trace_alloc_count = 0;

static mem_group mem_current_group = NULL;


struct mem_group_s {
  mem_group next;
  mem_group prev;

  int alignment;

  int group_size;
  int in_use;
  int free;
  int allocated;
  int regular_blocks;
  int odd_blocks;

  int size_map[MEM_MAX_ALLOC / sizeof (int) + 1];
  mem_free_item free_list[MEM_MAX_ALLOC / sizeof (int) + 1];
  void (*out_of_memory_fun) (void);
  struct mem_block block_head;
  char name[1];
};


struct {
  mem_group next;
  mem_group prev;
} mem_group_dll_head = { (mem_group) &mem_group_dll_head,
			 (mem_group) &mem_group_dll_head };


#ifdef __hpux__


static mem_block mem_free_blocks = NULL;
static size_t mem_page_size;


static
void
mem_free_aligned_block (mem_block block)
{
  block->next = mem_free_blocks;
  mem_free_blocks = block;
}


static
void *
memalign (size_t alignment, size_t size)
{
  void *result;

  if ( mem_free_blocks == NULL ) {
    void *cur_brk = sbrk (0);
    size_t page_mask = mem_page_size - 1;
    size_t roundup = mem_page_size - ((size_t)cur_brk & page_mask);
    char *page;
    int i;

    if ( roundup < mem_page_size ) {
      sbrk (roundup);
    }

    page = sbrk (mem_page_size);

    ASSERT (((size_t) page & page_mask) == 0);

    for ( i = 0; i < mem_page_size; i += alignment ) {
      mem_block block = (mem_block) (page + i);
      mem_free_aligned_block (block);
    }
  }

  result = mem_free_blocks;
  mem_free_blocks = mem_free_blocks->next;

  return result;
}


#else /* not __hpux__ */


static
void
mem_free_aligned_block (mem_block block)
{
  free (block);
}


#endif /* not __hpux__ */


static
void
mem_init (void)
{
#ifdef __hpux__
  mem_page_size = sysconf (_SC_PAGE_SIZE);
#endif __hpux__

  mem_block_table_size = 1024;
  mem_block_table = calloc (mem_block_table_size, sizeof (int));

  mem_current_group = mem_group_create ("default", 4);
}


static
void
mem_out_of_memory (void)
{
  fprintf (stderr, "Out of memory.\n");
  exit (1);
}


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
mem_register_block (mem_block block, int flag)
{
  unsigned int block_index = ((ptrdiff_t) block >> MEM_BLOCK_BITS);
  unsigned int offset = block_index >> 5;
  unsigned int bit = block_index & 0x1f;
  unsigned int mask = 1 << bit;

  if ( offset >= mem_block_table_size ) {
    unsigned int i;
    unsigned int old_table_size = mem_block_table_size;

    mem_block_table_size = power_2_roundup (offset);
    mem_block_table = realloc (mem_block_table,
			       mem_block_table_size * sizeof (int));

    for ( i = old_table_size; i < mem_block_table_size; i++ ) {
      mem_block_table[i] = 0;
    }
  }

  if ( flag )
    mem_block_table[offset] |= mask;
  else
    mem_block_table[offset] &= ~mask;
}


static
mem_block
mem_block_of_pointer (void *ptr)
{
  unsigned int block_index = ((ptrdiff_t) ptr) >> MEM_BLOCK_BITS;
  unsigned int offset = block_index >> 5;
  unsigned int bit = block_index & 0x1f;
  unsigned int mask = 1 << bit;
  mem_block block;

  if ( offset >= mem_block_table_size ||
       ! (mem_block_table[offset] & mask) ) {
    block = (mem_block) (((ptrdiff_t) ptr) - MEM_BLOCK_HEADER_SIZE);
  }
  else {
    block = (mem_block) (((ptrdiff_t) ptr) & MEM_BLOCK_MASK);
  }

  return block;
}


static
void
mem_dll_insert (mem_group group, mem_block block)
{
  mem_block head = &(group->block_head);

  block->next = head;
  block->prev = head->prev;
  head->prev->next = block;
  head->prev = block;
}


static
void
mem_dll_delete (mem_block block)
{
  block->prev->next = block->next;
  block->next->prev = block->prev;

  block->next = NULL;
  block->prev = NULL;
}


static
mem_free_item
mem_alloc_items (mem_group group, int num_words)
{
  mem_block block = memalign (MEM_BLOCK_ALIGN, MEM_BLOCK_ALLOC);

  group->regular_blocks++;
  group->allocated += MEM_BLOCK_ALLOC + MEM_MALLOC_OVERHEAD;

  block->group = group;
  block->num_words = num_words;

  mem_dll_insert (group, block);

  mem_register_block (block, 1);

  {
    int i;
    int *storage = block->storage;
    int storage_size = MEM_BLOCK_STORAGE_SIZE / sizeof (int); 

    for ( i = 0; i + num_words < storage_size; i += num_words ) {
      mem_free_item item = (mem_free_item) storage + i;
      mem_free_item next = (mem_free_item) storage + i + num_words;

      group->free += num_words * sizeof (int);

      if ( i + 2*num_words < storage_size ) {
	item->next = next;
      }
      else {
	item->next = NULL;
      }
    }

    return (mem_free_item) storage;
  }
}


static
void
mem_free_internal (void *ptr, mem_block block)
{
  int num_words = block->num_words;
  mem_group group = block->group;

  group->in_use -= num_words * sizeof (int);

  if ( num_words * sizeof (int) > MEM_MAX_ALLOC ) {
    mem_dll_delete (block);
    free (block);

    group->allocated -= ( MEM_BLOCK_HEADER_SIZE + 
			  num_words * sizeof (int) + 
			  MEM_MALLOC_OVERHEAD );
    group->odd_blocks--;
  }
  else {
    mem_group group = block->group;
    mem_free_item item = (mem_free_item) ptr;

    item->next = group->free_list[num_words];
    group->free_list[num_words] = item;

    group->free += num_words * sizeof (int);
  }
}


mem_group
mem_group_create (char *name, int align)
{
  int i;
  int alignment = (align + 3) & 0xfffffffc;
  int name_len = strlen (name);
  mem_group group = malloc (sizeof (*group) + name_len);

  group->next = (mem_group) &mem_group_dll_head;
  group->prev = mem_group_dll_head.prev;
  mem_group_dll_head.prev->next = group;
  mem_group_dll_head.prev = group;
  
  group->group_size = sizeof (*group) + name_len;

  if ( mem_block_table == NULL ) {
    mem_init ();
  }

  strcpy (group->name, name);
  group->alignment = alignment;
  group->out_of_memory_fun = mem_out_of_memory;

  group->in_use = 0;
  group->free = 0;
  group->allocated = 0;
  group->odd_blocks = 0;
  group->regular_blocks = 0;

  group->block_head.num_words = 0;
  group->block_head.group = group;
  group->block_head.next = &(group->block_head);
  group->block_head.prev = &(group->block_head);

  {
    int max_words = MEM_MAX_ALLOC / sizeof (int);
    int align_words = alignment / sizeof (int);
    int limit = 8;

    i = 1;

    group->size_map[0] = align_words;

    while ( i <= max_words ) {
      for (; i < align_words * limit && i <= max_words; i++ ) {
	int size = align_words * ((i + align_words-1) / align_words);

	if ( size <= max_words ) {
	  group->size_map[i] = size;
	}
	else {
	  group->size_map[i] = MEM_MAX_ALLOC / sizeof (int);
	}
      }

      limit *= 2;
      align_words *= 2;
    }

    for ( i = 0; i <= max_words; i++ ) {
      group->free_list[i] = NULL;
    }
  }

  return group;
}


mem_group
mem_group_set (mem_group new_group)
{
  mem_group old_group = mem_current_group;

  mem_current_group = new_group;

  return old_group;
}


void
mem_group_free_contents (mem_group group)
{
  mem_block head = &(group->block_head);
  mem_block block = head->next;

  while ( block != head ) {
    mem_block next = block->next;

    mem_register_block (block, 0);

    if ( block->num_words * sizeof (int) <= MEM_MAX_ALLOC ) {
      mem_free_aligned_block (block);
    }
    else {
      free (block);
    }

    block = next;
  }

  head->next = head;
  head->prev = head;

  {
    int i;

    for ( i = 0; i <= MEM_MAX_ALLOC / sizeof (int); i++ ) {
      group->free_list[i] = NULL;
    }
  }

  group->in_use = 0;
  group->free = 0;
  group->allocated = 0;
  group->odd_blocks = 0;
  group->regular_blocks = 0;
}


void
mem_group_free (mem_group group)
{
  mem_group_free_contents (group);

  group->prev->next = group->next;
  group->next->prev = group->prev;

  free (group);
}


mem_group
mem_group_of_pointer (void *ptr)
{
  mem_block block = mem_block_of_pointer (ptr);

  return block->group;
}


size_t
mem_size_of_allocation (void *ptr)
{
  mem_block block = mem_block_of_pointer (ptr);

  return block->num_words * sizeof (int);
}


void
mem_free (void *ptr)
{
  mem_block block = mem_block_of_pointer (ptr);

  mem_free_internal (ptr, block);
}  


void
mem_free_traced (void *ptr)
{
  if ( mem_tracing ) {
    mem_trace_info info 
      = (mem_trace_info) ((ptrdiff_t) ptr - sizeof (struct mem_trace_info));

    info->prev->next = info->next;
    info->next->prev = info->prev;

    mem_free (info);
  }
  else {
    mem_free (ptr);
  }
}  


void *
mem_malloc_from_group_traced (size_t size, mem_group group,
			      const char *file, int line)
{
  if ( mem_tracing ) {
    size_t new_size = size + sizeof (struct mem_trace_info);
    mem_trace_info info = mem_malloc_from_group (new_size, group);
    void *ptr = (void *) ((ptrdiff_t) info + sizeof (struct mem_trace_info));

    {
      mem_trace_info head = &(mem_trace_info_head);

      info->next = head;
      info->prev = head->prev;
      head->prev->next = info;
      head->prev = info;
    }

    info->file = file;
    info->line = line;
    info->group = group;
    info->size = size;
    info->alloc_num = mem_trace_alloc_count;
    mem_trace_alloc_count++;

    return ptr;
  }
  else {
    void *ptr = mem_malloc_from_group (size, group);

    return ptr;
  }
}


void *
mem_malloc_from_group (size_t size, mem_group group)
{
  int size_in_words = (size + sizeof (int) - 1) / sizeof (int);

  if ( size > MEM_MAX_ALLOC ) {
    mem_block block = malloc (MEM_BLOCK_HEADER_SIZE
			      + size_in_words * sizeof (int));

    if ( block == NULL ) {
      group->out_of_memory_fun ();
    }

    group->in_use += size_in_words * sizeof (int);
    group->allocated += ( MEM_BLOCK_HEADER_SIZE +
			  size_in_words * sizeof (int) +
			  MEM_MALLOC_OVERHEAD );
    group->odd_blocks++;

    block->group = group;
    block->num_words = size_in_words;

    mem_dll_insert (group, block);

    {
      void *ptr = block->storage;

      return ptr;
    }
  }
  else {
    int num_words = group->size_map [size_in_words];
    mem_free_item item = group->free_list [num_words];

    if ( item == NULL ) {
      item = mem_alloc_items (group, num_words);
    }

    group->in_use += num_words * sizeof (int);
    group->free -= num_words * sizeof (int);

    group->free_list[num_words] = item->next;
    return (void *) item;
  }
}


void *
mem_malloc (size_t size)
{
  void *ptr;

  if ( mem_current_group == NULL ) {
    mem_init ();
  }

  ptr = mem_malloc_from_group (size, mem_current_group);

  return ptr;
}


void *
mem_malloc_traced (size_t size, const char *file, int line)
{
  void *ptr;

  if ( mem_current_group == NULL ) {
    mem_init ();
  }

  ptr = mem_malloc_from_group_traced (size, mem_current_group, file, line);

  return ptr;
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
mem_realloc (void *ptr, size_t new_size)
{
  int num_words = (new_size + sizeof (int) - 1) / sizeof (int);
  mem_block block = mem_block_of_pointer (ptr);

  if ( block->num_words >= num_words ) {
    return ptr;
  }
  else {
    mem_group group = block->group;
    void *new_ptr = mem_malloc_from_group (num_words * sizeof (int), group);

    memcpy (new_ptr, ptr, block->num_words * sizeof (int));
    mem_free_internal (ptr, block);

    return new_ptr;
  }
}


void *
mem_realloc_traced (void *ptr, size_t new_size, const char *file, int line)
{
  void *result;

  if ( mem_tracing ) {
    mem_trace_info info 
      = (mem_trace_info) ((ptrdiff_t) ptr - sizeof (struct mem_trace_info));
    mem_trace_info new_info;
    mem_trace_info prev = info->prev;
    mem_trace_info next = info->next;

    prev->next = next;
    next->prev = prev;

    new_info = mem_realloc (info, new_size + sizeof (struct mem_trace_info));

    new_info->next = next;
    new_info->prev = prev;
    prev->next = new_info;
    next->prev = new_info;

    new_info->file = file;
    new_info->line = line;
    new_info->size = new_size;

    result = (void *) ((ptrdiff_t) new_info + sizeof (struct mem_trace_info));
  }
  else {
    result = mem_realloc (ptr, new_size);
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


void
mem_show_active (void)
{
  mem_trace_info head = &(mem_trace_info_head);
  mem_trace_info info = head->next;

  printf ("Active blocks:\n");

  printf ("address     alloc #  size  line  file\n");
  printf ("---------- -------- ----- ----- ----------\n");

  while ( info != head ) {
    printf ("0x%08x %8d  %5d %5d %s\n",
	    (ptrdiff_t) info + sizeof (struct mem_trace_info),
	    info->alloc_num, info->size, info->line, info->file);

    info = info->next;
  }

  printf ("\n");
}

void
mem_show_usage (void)
{
  mem_group g = mem_group_dll_head.next;

  while ( g != (mem_group) &mem_group_dll_head ) {
    printf ("Memory group \"%s\"\n", g->name);
    printf ("  group size     = %10d\n", g->group_size);
    printf ("  in use         = %10d\n", g->in_use);
    printf ("  allocated      = %10d\n", g->allocated);
    printf ("  regular blocks = %10d\n", g->regular_blocks);
    printf ("  odd blocks     = %10d\n", g->odd_blocks);
    printf ("\n");

    g = g->next;
  }
}

/* returns total bytes of memory on free lists */
/* added by mha, TODO have Jay incorporate into his mem.c */
unsigned long
mem_usage_free (void)
{
  mem_group g = mem_group_dll_head.next;
  unsigned long total = 0;

  while ( g != (mem_group) &mem_group_dll_head ) {
    total += g->allocated - g->in_use;
    g = g->next;
  }

  return total;
}
