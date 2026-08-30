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

/* typedef enum ssa_value_kind ssa_value_kind; */
/* typedef struct ssa_value * ssa_value; */
typedef void * ssa_value;
typedef struct ssa_binding * ssa_binding;
typedef struct ssa_global * ssa_global;
typedef struct ssa_context * ssa_context;

typedef ssa_binding (*ssa_var_get_fun) (void *, void *);
typedef void        (*ssa_var_set_fun) (void *, ssa_binding, void *);


extern ssa_global	ssa_global_create (ssa_var_get_fun, ssa_var_set_fun,
					   void *);
extern void		ssa_global_free (ssa_global);

extern ssa_binding	ssa_binding_create (ssa_context, void *, ssa_value,
					    ssa_value, ssa_binding);
extern void *		ssa_binding_var (ssa_binding);
extern ssa_value	ssa_binding_current_value (ssa_binding);
extern ssa_value	ssa_binding_future_value (ssa_binding);
extern void		ssa_binding_free (ssa_binding);

extern ssa_binding	ssa_lookup (ssa_context, void *);
extern void		ssa_bind (ssa_context, void *, ssa_binding);
extern void		ssa_unbind (ssa_context, void *);

extern ssa_context	ssa_context_create (ssa_context, ssa_context,
					    ssa_global);
extern ar		ssa_context_bindings (ssa_context);
extern ssa_context	ssa_context_first_child (ssa_context);
extern ssa_context	ssa_context_next (ssa_context);
extern void		ssa_context_free (ssa_context);
extern ssa_context	ssa_context_branch (ssa_context);
extern ssa_context	ssa_context_up (ssa_context);
extern void		ssa_context_clear_children (ssa_context);

extern void		ssa_define (ssa_context, void *, ssa_value);
extern void		ssa_define_future (ssa_context, void *, ssa_value);
extern ssa_value	ssa_read (ssa_context, void *);
extern ssa_value	ssa_read_future (ssa_context, void *);
extern ssa_value	ssa_read_final (ssa_context, void *);


#define ssa_context_for_all_children(context, var) \
  { ssa_context var; \
    ssa_context __context = (context); \
    for ( var = ssa_context_first_child (__context); \
          var != NULL; \
          var = ssa_context_next (var) )
          
#define ssa_end_for }
