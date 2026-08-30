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

#ifndef MEM_H
#  define MEM_H
#  include <sys/types.h>

#define MEM_TRACING

typedef struct mem_group_s *mem_group;

extern mem_group mem_group_create (char *, int);
extern void      mem_group_free_contents (mem_group);
extern void      mem_group_free (mem_group);
extern mem_group mem_group_set (mem_group);
extern mem_group mem_group_of_pointer (void *);
extern size_t    mem_size_of_allocation (void *);

extern void  mem_free (void *);
extern void  mem_free_traced (void *);
extern void *mem_malloc_from_group (size_t, mem_group);
extern void *mem_malloc_from_group_traced (size_t, mem_group,
					   const char *, int);
extern void *mem_calloc_from_group (size_t, size_t, mem_group);
extern void *mem_calloc_from_group_traced (size_t, size_t, mem_group,
					   const char *, int);
extern void *mem_malloc (size_t);
extern void *mem_malloc_traced (size_t, const char *, int);
extern void *mem_calloc (size_t, size_t);
extern void *mem_calloc_traced (size_t, size_t, const char *, int);
extern void *mem_realloc (void *, size_t);
extern void *mem_realloc_traced (void *, size_t, const char *, int);
extern char *mem_strdup_from_group (char *, mem_group);
extern char *mem_strdup_from_group_traced (char *, mem_group,
					   const char *, int);
extern char *mem_strdup (char *);
extern char *mem_strdup_traced (char *, const char *, int);
extern void  mem_show_active (void);
extern void  mem_show_usage (void);
extern unsigned long mem_usage_free (void);


#ifdef MEM_TRACING
#  define MALLOC(x)	mem_malloc_traced ((x), __FILE__, __LINE__)
#  define CALLOC(x, y)	mem_calloc_traced ((x), (y), __FILE__, __LINE__)
#  define REALLOC(x, y)	mem_realloc_traced ((x), (y), __FILE__, __LINE__)
#  define FREE(x)	mem_free_traced (x)
#  define STRDUP(x)	mem_strdup_traced ((x), __FILE__, __LINE__)
#  define GMALLOC(x, g)	mem_malloc_from_group_traced ((x), (g), __FILE__, __LINE__)
#  define GCALLOC(x, g)	mem_calloc_from_group_traced ((x), (g), __FILE__, __LINE__)
#  define GSTRDUP(x, g)	mem_strdup_from_group_traced ((x), (g), __FILE__, __LINE__)
#else
#  define MALLOC(x)		mem_malloc (x)
#  define CALLOC(x, y)		mem_calloc ((x), (y))
#  define REALLOC(x, y)		mem_realloc ((x), (y))
#  define FREE(x)		mem_free (x)
#  define STRDUP(x)		mem_strdup (x)
#  define GMALLOC(x, g)		mem_malloc_from_group ((x), (g))
#  define GCALLOC(x, y, g)	mem_calloc_from_group ((x), (y), (g))
#  define GSTRDUP(x, g)		mem_strdup_from_group ((x), (g))
#endif


#define STRDUPA(x)      strcpy (alloca (1 + strlen (x)), x)


#endif
