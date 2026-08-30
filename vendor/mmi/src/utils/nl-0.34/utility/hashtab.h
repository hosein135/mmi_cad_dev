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

typedef unsigned int ht_entry;
typedef struct hashtab_s *hashtab;
typedef struct ht_attribute *ht_attr;

typedef int   (*ht_hash_fn_t) (void *);
typedef int   (*ht_compare_fn_t) (void *, void *);
typedef void *(*ht_copy_fn_t) (void *);
typedef void  (*ht_free_fn_t) (void *);

extern hashtab  ht_alloc_from_group (int, ht_hash_fn_t, ht_compare_fn_t,
				     ht_copy_fn_t, ht_free_fn_t, mem_group);
extern hashtab  ht_alloc (int, ht_hash_fn_t, ht_compare_fn_t,
			  ht_copy_fn_t, ht_free_fn_t);
extern void     ht_free (hashtab);
extern int      ht_size (hashtab);
extern void *   ht_get_key (hashtab, ht_entry);
extern ht_entry ht_lookup (hashtab, void *);
extern ht_entry ht_insert (hashtab, void *);
extern ht_entry ht_delete (hashtab, void *);
extern ht_entry ht_replace (hashtab, void *, void *);
extern int      ht_hash_string (void *);
extern int      ht_hash_int (int);
extern int      ht_hash_ptr (void *);
extern int      ht_compare_string (void *, void *);
extern void *   ht_copy_string (void *);
extern void     ht_free_string (void *);
extern ht_attr  ht_new_attribute (hashtab, int, void *, ht_free_fn_t);
extern void     ht_get_attribute (ht_attr, void *, void *);
extern void     ht_set_attribute (ht_attr, void *, void *);
extern void     ht_get_attribute_for_entry (ht_attr, ht_entry, void *);
extern void     ht_set_attribute_for_entry (ht_attr, ht_entry, void *);
extern void     ht_free_attribute (ht_attr);
extern ht_entry ht_first_entry (hashtab);
extern ht_entry ht_next_entry (hashtab, ht_entry);

#define ht_null ((ht_entry) (0x7fffffff))


#define ht_for_all_entries(table, ent) \
  { \
    ht_entry ent; \
    for ( ent = ht_first_entry (table); \
          ent != ht_null; \
	  ent = ht_next_entry (table, ent) )

#define ht_end_for }

