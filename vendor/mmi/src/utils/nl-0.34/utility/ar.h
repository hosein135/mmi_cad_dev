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

#include <stdlib.h>


typedef struct ar_s *ar;

typedef int (*ar_compare_fn_t) (void *, void *);

extern size_t ar_size (ar);
extern size_t ar_elt_size (ar);
extern void * ar_data (ar);
extern int    ar_offset (ar);
extern ar     ar_alloc (size_t, size_t);
extern ar     ar_alloc_from_group (size_t, size_t, mem_group);
extern ar     ar_alloc_with_offset (size_t, size_t, int);
extern ar     ar_alloc_with_offset_from_group (size_t, size_t, int, mem_group);
extern ar     ar_copy (ar);
extern void   ar_free (ar);
extern void   ar_make_size (ar, size_t);
extern size_t ar_grow (ar, int);
extern void   ar_set (ar, int, void *);
extern size_t ar_add (ar, void *);
extern void * ar_addr_of (ar, int);
extern void   ar_ref (ar, int, void *);
extern void   ar_remove_element (ar, void *);
extern void   ar_remove_indexed_element (ar, int);
extern void   ar_append (ar, ar);
extern void   ar_init (ar, void *);
extern int    ar_compare_int (void *, void *);
extern int    ar_compare_string (void *, void *);
extern void   ar_sort (ar, ar_compare_fn_t);
extern void   ar_reverse (ar);


#define AR_NEW(size, type)     ( ar_alloc (size, sizeof (type)) )
#define AR_GNEW(size, type, g) ( ar_alloc_from_group (size, sizeof (type), g) )

#define AR_REF(a, type, idx)  ( ((type **) (a))[0][idx] )


#define ar_for_all_pointers(a, elt_ptr) \
  { ar __a = (a); \
    int __num_elts = ar_size (__a); \
    int __elt_size = ar_elt_size (__a); \
    int __offset = ar_offset (__a); \
    int __start = __elt_size * __offset; \
    int __limit = __elt_size * (__offset + __num_elts); \
    char *__data = ar_data (__a); \
    void *elt_ptr; \
    int __index; \
    for ( __index = __start; \
          __index < __limit && (elt_ptr = (void *)(__data + __index), 1); \
          __index += __elt_size )


#define ar_for_all_common_internal(a, type, elt, index, start, stop, incr) \
  { ar __a = (a); \
    int __num_elts = ar_size (__a); \
    int __offset = ar_offset (__a); \
    int __limit = __offset + __num_elts; \
    type *__data = ar_data (__a); \
    int index; \
    type elt; \
    ASSERT (ar_elt_size (__a) == sizeof (type)); \
    for ( index = start; \
	  (index stop) && (elt = __data[index], 1); \
          index incr )


#define ar_for_all_internal(a, type, elt, index) \
   ar_for_all_common_internal(a, type, elt, index, __offset, < __limit, ++)


#define ar_for_all_reverse_internal(a, type, elt, index) \
   ar_for_all_common_internal(a, type, elt, index, __limit-1, >= __offset, --)


#define ar_for_all(a, type, elt) \
  ar_for_all_internal (a, type, elt, __i)


#define ar_for_all_indexed(a, type, elt, index) \
  ar_for_all_internal (a, type, elt, index)


#define ar_for_all_reverse(a, type, elt) \
  ar_for_all_reverse_internal (a, type, elt, __i)


#define ar_for_all_reverse_indexed(a, type, elt, index) \
  ar_for_all_reverse_internal (a, type, elt, index)


#define ar_begin_for {
#define ar_end_for   }
