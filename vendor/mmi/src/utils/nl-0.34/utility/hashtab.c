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
#include "hashtab.h"
#include "mem.h"


#  define GET_ENTRY(ht, ent)   AR_REF (ht->entries, struct hashtab_entry, ent)
#  define NEXT_ENTRY(ht)       (ar_grow (ht->entries, 1) - 1)
#  define NUM_ENTRIES(ht)      ar_size (ht->entries)
#  define BUCKET_MASK(ht)      (ar_size (ht->buckets) - 1)
#  define BUCKET_REF(ht, idx)  AR_REF (ht->buckets, ht_entry, idx)


struct hashtab_entry {
  void *key;
  unsigned int hkey;
  ht_entry next:31;
  int free:1;
};


struct ht_attribute {
  hashtab owner;
  ar array;
  void *init;
  ht_free_fn_t free_fn;
  ht_attr next;
  ht_attr prev;
};


struct hashtab_s {
  ar buckets;
  ar entries;
  struct ht_attribute attr_head;
  int size;
  ht_entry freelist;
  ht_hash_fn_t hash_fn;
  ht_compare_fn_t compare_fn;
  ht_copy_fn_t copy_fn;
  ht_free_fn_t free_fn;
};



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


hashtab
ht_alloc_from_group (int size, ht_hash_fn_t hash_fn, ht_compare_fn_t compare_fn,
		     ht_copy_fn_t copy_fn, ht_free_fn_t free_fn, mem_group g)
{
  hashtab result = GMALLOC (sizeof (*result), g);

  result->buckets
    = ar_alloc_from_group (size, sizeof (int), g);
  result->entries 
    = ar_alloc_from_group (size, sizeof (struct hashtab_entry), g);
  
  {
    int i;
    ht_entry null = ht_null;
    
    for ( i = 0; i < size; i++ ) {
      ar_add (result->buckets, &null);
    }
  }
  
  result->size = 0;

  result->attr_head.owner = result;
  result->attr_head.array = NULL;
  result->attr_head.init = NULL;
  result->attr_head.free_fn = NULL;
  result->attr_head.next = &(result->attr_head);
  result->attr_head.prev = &(result->attr_head);

  result->freelist = ht_null;

  result->hash_fn = hash_fn;
  result->compare_fn = compare_fn;
  result->copy_fn = copy_fn;
  result->free_fn = free_fn;

  return result;
}


hashtab
ht_alloc (int size, ht_hash_fn_t hash_fn, ht_compare_fn_t compare_fn,
	  ht_copy_fn_t copy_fn, ht_free_fn_t free_fn)
{
  mem_group g = mem_group_get_current ();
  hashtab result = 
    ht_alloc_from_group (size, hash_fn, compare_fn, copy_fn, free_fn, g);

  return result;
}


void
ht_free (hashtab ht)
{
  if ( ht->free_fn != NULL ) {
    ar_for_all (ht->entries, struct hashtab_entry, ent) {
      ht->free_fn (ent.key);
    } ar_end_for;
  }

  ar_free (ht->entries);

  while ( ht->attr_head.next != &(ht->attr_head) ) {
    ht_free_attribute (ht->attr_head.next);
  }

  ar_free (ht->buckets);

  FREE (ht);
}


int
ht_size (hashtab ht)
{
  return ht->size;
}


void *
ht_get_key (hashtab ht, ht_entry hte)
{
  void *result = GET_ENTRY (ht, hte).key;

  return result;
}


ht_entry
ht_next_entry (hashtab ht, ht_entry ent)
{
  int size = ar_size (ht->entries);
  ht_entry result = ent + 1;

  while ( (result < size) && GET_ENTRY(ht, result).free ) {
    result++;
  }

  if ( result >= size ) {
    return ht_null;
  }
  else {
    return result;
  }
}


ht_entry
ht_first_entry (hashtab ht)
{
  ht_entry result = ht_next_entry (ht, -1);
  return result;
}


void
ht_resize (hashtab ht)
{
#if TEST
  printf ("resizing...");
  fflush (stdout);
#endif

  {
    int i;
    int new_bucket_size = power_2_roundup (ht->size);

    ar_make_size (ht->buckets, new_bucket_size);

    for ( i = 0; i < new_bucket_size; i++ ) {
      AR_REF (ht->buckets, ht_entry, i) = ht_null;
    }
  }
    
  {
    unsigned int bucket_mask = ar_size (ht->buckets) - 1;

    ht_for_all_entries (ht, e) {
      struct hashtab_entry *ep = &(GET_ENTRY (ht, e));
      unsigned int hkey = ep->hkey;
      unsigned int bucket_index = hkey & bucket_mask;
      ht_entry *bucket_p = &(AR_REF (ht->buckets, ht_entry, bucket_index));

      ep->next = *bucket_p;
      *bucket_p = e;
    } ht_end_for;
  }
}


#if 0
void
ht_free_entry (hashtab ht, ht_entry e)
{
  struct hashtab_entry *ent = &GET_ENTRY (ht, e);

  ent->u.hkey = 0; /* Mark entry as freed. */

  if ( ht->needs_hashed == 0 ) {
    /* The hash links are good.  Rehash everybody else in the list. */
    ht_entry t = ent->next;

    while ( t != ht_null ) {
      ht_entry next = GET_ENTRY (ht, t).next;
      ht_rehash_entry (ht, t);
      t = next;
    }
  }
  ent->next = ht->free_list;
  ht->free_list = e;

  ht->num_entries--;
}
#endif


static
ht_entry
ht_alloc_entry (hashtab ht)
{
  ht_entry result;

  ht->size++;

  if ( ht->freelist != ht_null ) {
    result = ht->freelist;
    ht->freelist = GET_ENTRY (ht, result).next;
  }
  else {
    if ( ht->size > ar_size (ht->buckets) ) {
      ht_resize (ht);
    }

    result = (ht_entry) NEXT_ENTRY (ht);

    {
      ht_attr attr = ht->attr_head.next;

      while (attr != &(ht->attr_head) ) {
	ASSERT (ar_size (attr->array) == result);
	ar_make_size (attr->array, result + 1);
	attr = attr->next;
      }
    }
  }

  {
    struct hashtab_entry hte = { NULL, 0, ht_null, 0 };
    GET_ENTRY (ht, result) = hte;
  }

  {
    ht_attr attr = ht->attr_head.next;

    while ( attr != &(ht->attr_head) ) {
      ar_set (attr->array, result, attr->init);
      attr = attr->next;
    }
  }

  return result;
}


static
void
ht_free_entry (hashtab ht, ht_entry e)
{
  GET_ENTRY (ht, e).next = ht->freelist;
  GET_ENTRY (ht, e).free = 1;
  ht->freelist = e;
  ht->size--;
}


static
void
ht_do_insert (hashtab ht, ht_entry ent, void *key, unsigned int hkey)
{
  unsigned int bucket_mask = BUCKET_MASK (ht);
  unsigned int bucket_index = hkey & bucket_mask;
  ht_entry bucket_start = BUCKET_REF (ht, bucket_index);
  struct hashtab_entry hte;

  hte.hkey = hkey;
  if ( ht->copy_fn != NULL ) {
    hte.key = ht->copy_fn (key);
  }
  else {
    hte.key = key;
  }
  hte.next = bucket_start;
  hte.free = 0;
    
  GET_ENTRY (ht, ent) = hte;
  BUCKET_REF (ht, bucket_index) = ent;
}


static
ht_entry
ht_access (hashtab ht, void *key, int insert, int delete)
{
  unsigned int hkey = ht->hash_fn (key);

  {
    unsigned int bucket_mask = BUCKET_MASK (ht);
    unsigned int bucket_index = hkey & bucket_mask;
    ht_entry e = BUCKET_REF (ht, bucket_index);
    struct hashtab_entry *prev = NULL;
    struct hashtab_entry *ep = NULL;

    goto start;

    do {
    try_again:
      e = ep->next;
    start:
      if ( e == ht_null )
	goto not_found;
      prev = ep;
      ep = &(GET_ENTRY (ht, e));
    } while ( ep->hkey != hkey );

    /* maybe found it */
    {
      int match;
      void *ekey = ep->key;

      if ( ht->compare_fn != NULL ) {
	match = ht->compare_fn (key, ekey);
      }
      else {
	match = (key == ekey);
      }

      if ( match ) {
	if ( delete ) {
	  ht_entry next = ep->next;

	  if ( prev != NULL ) {
	    prev->next = next;
	  }
	  else {
	    BUCKET_REF (ht, bucket_index) = next;
	  }

	  if ( ht->free_fn != NULL ) {
	    ht->free_fn (ep->key);
	  }

	  if ( !insert ) {
	    ht_attr attr = ht->attr_head.next;

	    while ( attr != &(ht->attr_head) ) {
	      if ( attr->free_fn != NULL ) {
		void *elt_ptr = ar_addr_of (attr->array, e);
		attr->free_fn (elt_ptr);
	      }
	      attr = attr->next;
	    }

	    ht_free_entry (ht, e);
	  }
	}
	return e;
      }
      else {
	goto try_again;
      }
    }
  }

 not_found:

  if (insert) {
    ht_entry new_e = ht_alloc_entry (ht);
    /* Can't reuse these values from above because ht_alloc_entry()
       may have resized the bucket array. */

    ht_do_insert (ht, new_e, key, hkey);

    return new_e;
  }
  else {
    return ht_null;
  }
}


ht_entry
ht_lookup (hashtab ht, void *key)
{
  ht_entry result = ht_access (ht, key, 0, 0);
  return result;
}


ht_entry
ht_insert (hashtab ht, void *key)
{
  ht_entry result = ht_access (ht, key, 1, 0);
  return result;
}


ht_entry
ht_delete (hashtab ht, void *key)
{
  ht_entry result = ht_access (ht, key, 0, 1);
  return result;
}


ht_entry
ht_replace (hashtab ht, void *old_key, void *new_key)
{
  ht_entry ent = ht_access (ht, old_key, 1, 1);

  if ( ent == ht_null ) {
    return ht_null;
  }
  else {
    unsigned int hkey = ht->hash_fn (new_key);

    ht_do_insert (ht, ent, new_key, hkey);
    return ent;
  }
}


int
ht_hash_string (void *k)
{
  unsigned int x = 1;
  unsigned char *s = (unsigned char *)k;

  while ( *s ) {
    x = *s ^ ((x & 0x267) ^ (x << 9) ^ (x >> 7));
    s++;
  }

  x ^= (x >> 16);

  return x;
}


int
ht_hash_int (int n)
{
  unsigned int x = 1;
  unsigned int y = n;

  x = (y & 0xff) ^ ((x & 0x267) ^ (x << 9) ^ (x >> 7));
  y >>= 8;
  x = (y & 0xff) ^ ((x & 0x267) ^ (x << 9) ^ (x >> 7));
  y >>= 8;
  x = (y & 0xff) ^ ((x & 0x267) ^ (x << 9) ^ (x >> 7));
  y >>= 8;
  x = (y & 0xff) ^ ((x & 0x267) ^ (x << 9) ^ (x >> 7));

  x ^= (x >> 16);

  return x;
}


int
ht_hash_ptr (void *ptr)
{
  unsigned int x = 1;
  size_t y = (size_t)ptr;

  x = (y & 0xff) ^ ((x & 0x267) ^ (x << 9) ^ (x >> 7));
  y >>= 8;
  x = (y & 0xff) ^ ((x & 0x267) ^ (x << 9) ^ (x >> 7));
  y >>= 8;
  x = (y & 0xff) ^ ((x & 0x267) ^ (x << 9) ^ (x >> 7));
  y >>= 8;
  x = (y & 0xff) ^ ((x & 0x267) ^ (x << 9) ^ (x >> 7));

  if ( sizeof (void *) == 8 ) {
    y >>= 8;
    x = (y & 0xff) ^ ((x & 0x267) ^ (x << 9) ^ (x >> 7));
    y >>= 8;
    x = (y & 0xff) ^ ((x & 0x267) ^ (x << 9) ^ (x >> 7));
    y >>= 8;
    x = (y & 0xff) ^ ((x & 0x267) ^ (x << 9) ^ (x >> 7));
    y >>= 8;
    x = (y & 0xff) ^ ((x & 0x267) ^ (x << 9) ^ (x >> 7));
  }

  x ^= (x >> 16);

  return x;
}


int
ht_compare_string (void *s1, void *s2)
{
  int result = !strcmp ((char *)s1, (char *)s2);
  return result;
}


void *
ht_copy_string (void *str)
{
  void *result = (void *) STRDUP ((char *) str);

  return result;
}


void
ht_free_string (void *str)
{
  FREE (str);
}


ht_attr
ht_new_attribute (hashtab ht, int elt_size, void *init, ht_free_fn_t free_fn)
{
  int num = NUM_ENTRIES (ht);
  mem_group g = mem_group_of_pointer (ht);
  ar array = ar_alloc_from_group (num, elt_size, g);
  void *initial = GMALLOC (elt_size, g);

  if ( init != NULL ) {
    memcpy (initial, init, elt_size);
  }
  else {
    memset (initial, 0, elt_size);
  }

  ar_make_size (array, num);

  {
    int i;

    for ( i = 0; i < num; i++ ) {
      ar_set (array, i, initial);
    }
  }
  
  {
    ht_attr result = GMALLOC (sizeof (*result), g);

    result->owner = ht;
    result->array = array;
    result->init = initial;
    result->free_fn = free_fn;
    result->next = &(ht->attr_head);
    result->prev = ht->attr_head.prev;
    result->prev->next = result;
    result->next->prev = result;
  
    return result;
  }
}


void
ht_free_attribute (ht_attr attr)
{
  if ( attr->free_fn != NULL ) {
    ar_for_all_pointers (attr->array, elt_ptr) {
      attr->free_fn (elt_ptr);
    } ar_end_for;
  }

  ar_free (attr->array);

  if ( attr->free_fn != NULL ) {
    attr->free_fn (attr->init);
  }

  FREE (attr->init);

  attr->prev->next = attr->next;
  attr->next->prev = attr->prev;

  FREE (attr);
}


void
ht_set_attribute_for_entry (ht_attr attr, ht_entry ent, void *value)
{
  if ( ent == ht_null ) {
    ASSERT (0);
  }
  else {
    if ( attr->free_fn != NULL ) {
      void *addr = ar_addr_of (attr->array, ent);
      attr->free_fn (addr);
    }
    ar_set (attr->array, ent, value);
  }
}


void
ht_get_attribute_for_entry (ht_attr attr, ht_entry ent, void *value)
{
  if ( ent == ht_null ) {
    memcpy (value, attr->init, ar_elt_size (attr->array));
  }
  else {
    ar_ref (attr->array, ent, value);
  }
}


void
ht_set_attribute (ht_attr attr, void *key, void *value)
{
  hashtab ht = attr->owner;
  ht_entry ent = ht_insert (ht, key);

  ht_set_attribute_for_entry (attr, ent, value);
}


void
ht_get_attribute (ht_attr attr, void *key, void *value)
{
  hashtab ht = attr->owner;
  ht_entry ent = ht_lookup (ht, key);

  ht_get_attribute_for_entry (attr, ent, value);
}


void
ht_remove_attribute (ht_attr attr, void *key)
{
  ht_set_attribute (attr, key, attr->init);
}


void
ht_dump (hashtab ht)
{
  printf ("DUMP OF HASH TABLE 0x%08x\n\n", (unsigned int) ht);

  printf ("entry table:\n\n");
  
  ar_for_all_indexed (ht->entries, struct hashtab_entry, ent, i) {
    printf ("%4d: key = %08x, hkey = %08x, next = ",
	    i, (unsigned int) ent.key, ent.hkey);

    if ( ent.next == ht_null )
      printf ("----, ");
    else
      printf ("%4d, ", ent.next);

    printf ("free = %d", ent.free);

    if ( ht->hash_fn == ht_hash_string && ent.free == 0 ) {
      printf (",  \"%s\"\n", (char *) ent.key);
    }
    else {
      printf ("\n");
    }
  } ar_end_for;

  printf ("\n");
  printf ("bucket table:\n\n");

  ar_for_all_indexed (ht->buckets, ht_entry, e, i) {
    printf ("%4d: ", i);

    if ( e == ht_null ) {
      printf ("----\n");
    }
    else {
      int first = 1;
      while ( e != ht_null ) {
	if ( !first )
	  printf (", ");
	else
	  first = 0;
	
	printf ("%d", e);

	e = GET_ENTRY (ht, e).next;
      }
      printf ("\n");
    }
  } ar_end_for;

  printf ("\n");
}

      
#if TEST

main ()
{
  char buf[256];
  ht_entry e;
  int x = 0;
  hashtab ht = ht_alloc (4, ht_hash_string, ht_compare_string, ht_string_copy);

  while (1) {
    scanf ("%s", buf);

    switch (buf[0]) {
    case 'i':
      scanf ("%s", buf);
      e = ht_insert (ht, buf);
      printf ("ht_insert (ht, \"%s\") = %d\n", buf, e);
      break;
    case 'l':
      scanf ("%s", buf);
      e = ht_lookup (ht, buf);
      printf ("ht_lookup (ht, \"%s\") = %d\n", buf, e);
      break;
    case 'd':
      scanf ("%s", buf);
      e = ht_delete (ht, buf);
      printf ("ht_delete (ht, \"%s\") = %d\n", buf, e);
      break;
    case 's':
      e = ht_size (ht);
      printf ("ht_size (ht) = %d\n", e);
      break;
    case 't': {
      int i, j;

      printf ("Inserting...");
      fflush (stdout);

      for ( i = 0; i < 1000000; i++ ) {
	ht_entry e;

	if ( i > 0 && i % 100000 == 0 ) {
	  printf ("%d...", i);
	  fflush (stdout);
	}
	  
	sprintf (buf, "sym_%d_%d", i, x);
	e = ht_insert (ht, buf);

	if ( e == ht_null ) {
	  printf ("insertion error\n");
	  exit (1);
	}
      }

      printf ("done\n");

      x++;

      printf ("Extracting...");
      fflush (stdout);

      for ( j = 0; j < x; j++ ) {
	for ( i = 0; i < 1000000; i++ ) {
	  ht_entry e;

	  if ( i > 0 && i % 100000 == 0 ) {
	    printf ("%d...", i);
	    fflush (stdout);
	  }

	  if ( i == 524288 )
	    e = e;
	  
	  sprintf (buf, "sym_%d_%d", i, j);
	  e = ht_lookup (ht, buf);

	  if ( e == ht_null ) {
	    printf ("extraction error\n");
	    exit (1);
	  }
	}
      }

      printf ("done\n");
      break;
    }
    case 'q':
      mem_exit ();
      return 0;
    }
  }
}
#endif

