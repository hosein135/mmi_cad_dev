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
#include "ar.h"


struct ar_s {
  char *data;
  size_t num_elts;
  size_t elt_size;
  size_t alloc_size;
  int offset;
};


#define AR_ADDR_OF(a, idx, elt_size) &((a)->data[(idx)*elt_size])


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


ar
ar_alloc_with_offset_from_group (size_t num_elem, size_t elt_size, int offset,
				 mem_group group)
{
  unsigned int pow2num_elem = power_2_roundup (num_elem);
  int alloc_size = pow2num_elem * elt_size;
  ar result;
  char *storage;

  if ( group != NULL ) {
    result = GMALLOC (sizeof (*result), group);
    storage = GMALLOC (alloc_size, group);
  }
  else {
    result = MALLOC (sizeof (*result));
    storage = MALLOC (alloc_size);
  }

  result->data = storage - offset * elt_size;

  result->elt_size = elt_size;
  result->num_elts = 0;
  result->alloc_size = pow2num_elem;
  result->offset = offset;

  return result;
}


ar
ar_alloc_with_offset (size_t num_elem, size_t elt_size, int offset)
{
  ar result
    = ar_alloc_with_offset_from_group (num_elem, elt_size, offset, NULL);
  return result;
}


ar
ar_copy (ar a)
{
  int offset = a->offset;
  int num_elts = a->num_elts;
  int elt_size = a->elt_size;
  ar result = ar_alloc_with_offset (num_elts, elt_size, offset);
  char *a_start = AR_ADDR_OF (a, offset, elt_size);
  char *result_start = AR_ADDR_OF (result, offset, elt_size);

  memcpy (result_start, a_start, num_elts * elt_size);
  result->num_elts = num_elts;

  return result;
}


ar
ar_alloc (size_t num_elem, size_t elt_size)
{
  ar result = ar_alloc_with_offset_from_group (num_elem, elt_size, 0, NULL);
  return result;
}


ar
ar_alloc_from_group (size_t num_elem, size_t elt_size, mem_group group)
{
  ar result = ar_alloc_with_offset_from_group (num_elem, elt_size, 0, group);
  return result;
}


void
ar_free (ar a)
{
  char *storage = AR_ADDR_OF (a, a->offset, a->elt_size);
  FREE (storage);
  FREE (a);
}


size_t
ar_size (ar a)
{
  return a->num_elts;
}


size_t
ar_elt_size (ar a)
{
  return a->elt_size;
}


void *
ar_data (ar a)
{
  return a->data;
}


int
ar_offset (ar a)
{
  return a->offset;
}


void
ar_make_size (ar a, size_t size)
{
  if ( size > a->alloc_size ) {
    size_t new_alloc = a->alloc_size;
    char *storage = AR_ADDR_OF (a, a->offset, a->elt_size);

    do {
      new_alloc *= 2;
    } while ( new_alloc < size );
    
    storage = REALLOC (a->data, new_alloc * a->elt_size);
    a->data = storage - a->offset * a->elt_size;
    a->alloc_size = new_alloc;
  }

  a->num_elts = size;
}


size_t
ar_grow (ar a, int amount)
{
  size_t new_size = a->num_elts + amount;

  ar_make_size (a, new_size);

  return new_size;
}
     

void
ar_set (ar a, int idx, void *elt)
{
  void *dest = AR_ADDR_OF (a, idx, a->elt_size);

  memcpy (dest, elt, a->elt_size);
}


size_t
ar_add (ar a, void *elt)
{
  size_t size = ar_grow (a, 1);
  size_t idx = size - 1;
  void *dest = AR_ADDR_OF (a, idx, a->elt_size);

  memcpy (dest, elt, a->elt_size);

  return idx;
}


void *
ar_addr_of (ar a, int idx)
{
  return AR_ADDR_OF (a, idx, a->elt_size);
}


void
ar_ref (ar a, int idx, void *elt)
{
  void *src = AR_ADDR_OF (a, idx, a->elt_size);

  memcpy (elt, src, a->elt_size);
}


void
ar_remove_element (ar a, void *elt)
{
  int i;
  int size = a->num_elts;
  int offset = a->offset;
  int limit = a->offset + size;
  int elt_size = a->elt_size;
  char *ar_elt = NULL;

  for ( i = offset; i < limit; i++ ) {
    int flag;

    ar_elt = AR_ADDR_OF (a, i + offset, elt_size);
    flag = memcmp (ar_elt, elt, elt_size);

    if ( flag == 0 ) {
      memmove (ar_elt, ar_elt + elt_size, (size - i) * elt_size);
      a->num_elts = size - 1;
      return;
    }
  }

  ASSERT (0);
}


void
ar_remove_indexed_element (ar a, int index)
{
  int size = a->num_elts;
  int elt_size = a->elt_size;
  void *removed_elt = AR_ADDR_OF (a, index, elt_size);
  void *last_elt = AR_ADDR_OF (a, size-1, elt_size);

  memcpy (removed_elt, last_elt, elt_size);

  a->num_elts--;
}


void
ar_append (ar a1, ar a2)
{
  size_t a1_size = a1->num_elts;
  size_t a2_size = a2->num_elts;
  size_t elt_size = a1->elt_size;
  char *dest;
  char *src = a2->data - a2->offset * elt_size;
  size_t length = a2_size * elt_size;

  ASSERT (elt_size == a2->elt_size);

  ar_make_size (a1, a1_size + a2_size);

  dest = a1->data + (a1_size - a1->offset) * elt_size;

  memcpy (dest, src, length);
}


void
ar_init (ar a, void *init)
{
  int i;
  int elt_size = a->elt_size;
  int offset = a->offset;
  char *start = AR_ADDR_OF (a, offset, elt_size);
  int limit = elt_size * a->num_elts;

  for ( i = 0; i < limit; i += elt_size ) {
    memcpy (start + i, init, elt_size);
  }
}


int
ar_compare_int (void *p, void *q)
{
  int x = *(int *)p;
  int y = *(int *)q;

  if ( x > y )
    return 1;
  else if ( x < y )
    return -1;
  else
    return 0;
}


int
ar_compare_string (void *p, void *q)
{
  char **s1_p = p;
  char **s2_p = q;
  int result = strcmp (*s1_p, *s2_p);
  return result;
}


void
ar_sort (ar a, ar_compare_fn_t compare_fn)
{
  void *base = AR_ADDR_OF (a, a->offset, a->elt_size);
  int nel = a->num_elts;
  int width = a->elt_size;
  typedef int (*compar_t)(const void *, const void *);
  compar_t compar;

  if ( compare_fn == NULL ) {
    compar = (compar_t) ar_compare_int;
  }
  else {
    compar = (compar_t) compare_fn;
  }

  qsort (base, nel, width, compar);
}


void
ar_reverse (ar a)
{
  int i;
  char *data = a->data;
  size_t size = a->num_elts;
  char *tmp = alloca (a->elt_size);
  size_t elt_size = a->elt_size;

  for ( i = 0; i < size/2; i++ ) {
    int j = size - i - 1;
    memcpy (tmp, data + i*elt_size, elt_size);
    memcpy (data + i*elt_size, data + j*elt_size, elt_size);
    memcpy (data + j*elt_size, tmp, elt_size);
  }
}


#ifdef TEST

main()
{
  int i;
  ar a = AR_NEW (256, double);

  for ( i = 0; i < 50000; i++ ) {
    double d = i;
    ar_add (a, &d);
  }

  {
    int i;
    double e;

    ar_for_all_indexed (a, double, e, i) {
      if ( i % 100 == 0 )
	printf ("a[%d] = %lf\n", i, AR_REF (a, double, i));
    } ar_end_for;
  }

  {
    double d = -867.5309;

    ar_make_size (a, 100);
    ar_init (a, &d);
  }


  {
    int i;
    double e;

    ar_for_all_indexed (a, double, e, i) {
      printf ("a[%d] = %lf\n", i, AR_REF (a, double, i));
    } ar_end_for;
  }

}

#endif

    
