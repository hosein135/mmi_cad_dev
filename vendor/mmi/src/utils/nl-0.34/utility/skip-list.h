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

/* $Id: skip-list.h,v 1.1 1998/05/26 06:17:33 jka Exp $ */
#ifndef _skip_list_h
#define _skip_list_h


typedef struct skip_list_s *skip_list;
typedef void *sl_node;


extern skip_list sl_create( void );
extern void      sl_free( skip_list );
extern int       sl_member( skip_list, unsigned int );
extern int       sl_get( skip_list, unsigned int, void ** );
extern int       sl_put( skip_list, unsigned int, void ** );
extern int       sl_add( skip_list, unsigned int, void * );
extern int       sl_remove( skip_list, unsigned int );
extern int       sl_insert( skip_list, unsigned int, void * );
extern int       sl_intern( skip_list, unsigned int, void ** );
extern int       sl_extract( skip_list, unsigned int, void ** );
extern int       sl_exchange( skip_list, unsigned int, void ** );
extern int       sl_toggle( skip_list, unsigned int, void * );
extern void      sl_print( skip_list );
extern void      sl_diagram( skip_list );
extern sl_node   sl_first_node (skip_list);
extern sl_node   sl_next_node (sl_node);
extern int       sl_node_key_data (sl_node, unsigned int *, void **);


#define sl_for_all_entries(sl, key_var, data_type, data_var) \
  { sl_node __node; \
    skip_list __sl = (sl); \
    unsigned int (key_var); \
    data_type (data_var); \
    for ( __node = sl_first_node (__sl); \
          __node != NULL && \
          sl_node_key_data (__node, &(key_var), (void **)&(data_var)); \
          __node = sl_next_node (__node) )

#define sl_end_for }

#endif
