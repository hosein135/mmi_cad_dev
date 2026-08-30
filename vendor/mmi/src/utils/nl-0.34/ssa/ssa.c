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
#include "nl.h"
#include "ssa.h"


#if 0
enum ssa_value_kind { ssa_value_null, ssa_value_global, ssa_value_local };


struct ssa_value {
  char *name;
  ssa_value_kind kind;
  union {
    nl_net net;
    nl_ast ast;
  } def;
  ar uses;
};
#endif


struct ssa_binding {
  int level;
  int index;
  void *var;
  ssa_value current_value;
  ssa_value future_value;
  ssa_binding up;
};


struct ssa_global {
  ssa_var_get_fun var_get;
  ssa_var_set_fun var_set;
  void *var_data;
};


struct ssa_context {
  int level;
  ar bindings;
  int num_children;
  ssa_context up;
  ssa_context next;
  ssa_context prev;
  ssa_context first_child;
  ssa_context last_child;
  ssa_global global;
};


struct ssa_var_data {
  hashtab ht;
  ht_attr attr;
};


static
ssa_binding
ssa_string_var_get (void *var, void *ptr)
{
  struct ssa_var_data *data = (struct ssa_var_data *) ptr;
  hashtab ht = data->ht;
  ht_attr attr = data->attr;
  ssa_binding result;
  ht_entry ent = ht_lookup (ht, var);

  if ( ent == ht_null ) {
    ent = ht_insert (ht, var);
  }

  ht_get_attribute_for_entry (attr, ent, &result);

  return result;
}


static
void
ssa_string_var_set (void *var, ssa_binding binding, void *ptr)
{
  struct ssa_var_data *data = (struct ssa_var_data *) ptr;
  hashtab ht = data->ht;
  ht_attr attr = data->attr;
  ht_entry ent = ht_lookup (ht, var);

  if ( ent == ht_null ) {
    ASSERT (0);
  }
  else {
    ht_set_attribute_for_entry (attr, ent, &binding);
  }
}


ssa_global
ssa_global_create (ssa_var_get_fun get_fun, ssa_var_set_fun set_fun,
		   void *var_data)
{
  ssa_global result = MALLOC (sizeof (*result));

  if ( get_fun == NULL ) {
    struct ssa_var_data *data = MALLOC (sizeof (*data));
    
    ASSERT (set_fun == NULL);
    ASSERT (var_data == NULL);
    
    data->ht = ht_alloc (16, ht_hash_string, ht_compare_string,
			   ht_copy_string, ht_free_string);
    data->attr = ht_new_attribute (data->ht, sizeof (ssa_binding), NULL, NULL);

    result->var_data = data;
    result->var_get = ssa_string_var_get;
    result->var_set = ssa_string_var_set;
  }
  else {
    result->var_data = var_data;
    result->var_get = get_fun;
    result->var_set = set_fun;
  }

  return result;
}


void
ssa_global_free (ssa_global global)
{
  if ( global->var_get == ssa_string_var_get ) {
    struct ssa_var_data *data = (struct ssa_var_data *) global;

    ht_free (data->ht);
  }

  FREE (global);
}


ssa_binding
ssa_lookup (ssa_context context, void *var)
{
  ssa_global global = context->global;
  ssa_binding result = global->var_get (var, global->var_data);

  return result;
}


void
ssa_bind (ssa_context context, void *var, ssa_binding binding)
{
  ssa_global global = context->global;

  global->var_set (var, binding, global->var_data);
}


void
ssa_unbind (ssa_context context, void *var)
{
  ssa_global global = context->global;
  ssa_binding binding = global->var_get (var, global->var_data);

  if ( binding == NULL ) {
    return;
  }

  if ( context->level == binding->level ) {
    ssa_binding prev = binding->up;
    ar bindings = context->bindings;
    int index = binding->index;

    global->var_set (var, prev, global->var_data);

    ar_remove_indexed_element (bindings, index);

    if ( binding->index < ar_size (bindings) - 1 ) {
      ssa_binding moved;

      ar_ref (bindings, index, &moved);

      moved->index = index;
    }

    ssa_binding_free (binding);
  }
}

  
#if 0
ssa_value
ssa_value_create (ssa_value_kind kind, char *name, void *ptr)
{
  ssa_value result = MALLOC (sizeof (*result));

  result->kind = kind;

  if ( kind == ssa_value_global ) {
    result->def.net = (nl_net) ptr;
  }
  else {
    result->def.ast = (nl_ast) ptr;
  }

  result->uses = ar_alloc (1, sizeof (nl_ast));

  return result;
}
#endif


ssa_binding
ssa_binding_create (ssa_context context, void *var, ssa_value current_value,
		    ssa_value future_value, ssa_binding up)
{
  ssa_binding result = MALLOC (sizeof (*result));

  result->level = context->level;
  result->index = ar_size (context->bindings);
  ar_add (context->bindings, &result);
  result->var = var;
  result->current_value = current_value;
  result->future_value = future_value;
  result->up = up;

  return result;
}


void *
ssa_binding_var (ssa_binding binding)
{
  return binding->var;
}


ssa_value
ssa_binding_current_value (ssa_binding binding)
{
  return binding->current_value;
}


ssa_value
ssa_binding_future_value (ssa_binding binding)
{
  return binding->future_value;
}


void
ssa_binding_free (ssa_binding binding)
{
  FREE (binding);
}


ssa_context
ssa_context_create (ssa_context up, ssa_context prev, ssa_global global)
{
  ssa_context result = MALLOC (sizeof (*result));

  if ( up == NULL ) {
    result->level = 0;
  }
  else {
    result->level = up->level + 1;
  }

  result->bindings = ar_alloc (0, sizeof (ssa_binding));
  result->num_children = 0;
  result->up = up;
  result->next = NULL;
  result->prev = prev;
  result->first_child = NULL;
  result->last_child = NULL;
  result->global = global;

  if ( prev != NULL ) {
    prev->next = result;
  }

  return result;
}


ssa_context
ssa_context_first_child (ssa_context context)
{
  return context->first_child;
}


ssa_context
ssa_context_next (ssa_context context)
{
  return context->next;
}


ar
ssa_context_bindings (ssa_context context)
{
  return context->bindings;
}


void
ssa_context_free (ssa_context context)
{
  ar_for_all (context->bindings, ssa_binding, binding) {
    ssa_binding_free (binding);
  } ar_end_for;

  ar_free (context->bindings);

  FREE (context);
}


ssa_context
ssa_context_branch (ssa_context context)
{
  ssa_context result = ssa_context_create (context, context->last_child,
					   context->global);

  context->last_child = result;

  context->num_children++;

  if ( context->first_child == NULL ) {
    context->first_child = context->last_child;
  }

  return context->last_child;
}


ssa_context
ssa_context_up (ssa_context context)
{
  ssa_global global = context->global;

  ASSERT (context->first_child == NULL);
  ASSERT (context->last_child == NULL);
  
  ar_for_all (context->bindings, ssa_binding, binding) {
    ssa_binding prev = binding->up;

    global->var_set (binding->var, prev, global->var_data);
  } ar_end_for;

  return context->up;
}


void
ssa_context_clear_children (ssa_context context)
{
  ssa_context child = context->first_child;

  while ( child != NULL ) {
    ssa_context next = child->next;
    ssa_context_free (child);
    child = next;
  }

  context->num_children = 0;
  context->first_child = NULL;
  context->last_child = NULL;
}


void
ssa_define (ssa_context context, void *var, ssa_value value)
{
  ssa_binding binding = ssa_lookup (context, var);

  if ( binding == NULL || binding->level != context->level ) {
    ssa_binding new = ssa_binding_create (context, var, value, NULL, binding);
    ssa_bind (context, var, new);
  }
  else {
    binding->current_value = value;
  }
}


void
ssa_define_future (ssa_context context, void *var, ssa_value value)
{
  ssa_binding binding = ssa_lookup (context, var);

  if ( binding == NULL || binding->level != context->level ) {
    ssa_binding new = ssa_binding_create (context, var, NULL, value, binding);
    ssa_bind (context, var, new);
  }
  else {
    binding->future_value = value;
  }
}


ssa_value
ssa_read (ssa_context context, void *var)
{
  ssa_binding binding = ssa_lookup (context, var);

  if ( binding == NULL )
    return NULL;
  else
    return binding->current_value;
}


ssa_value
ssa_read_future (ssa_context context, void *var)
{
  ssa_binding binding = ssa_lookup (context, var);

  if ( binding == NULL )
    return NULL;
  else
    return binding->future_value;
}


ssa_value
ssa_read_final (ssa_context context, void *var)
{
  ssa_binding binding = ssa_lookup (context, var);

  if ( binding == NULL )
    return NULL;
  else if ( binding->future_value != NULL )
    return binding->future_value;
  else
    return binding->current_value;
}


#ifdef SSA_TEST
int
main ()
{
  ssa_global global = ssa_global_create (NULL, NULL, NULL);
  ssa_context context = ssa_context_create (NULL, NULL, global);
  char buf[256];

  while (1) {
    char arg[256];
    ssa_value value;
    ssa_context new_context;

    fprintf (stderr, "(ssa) ");
    gets (buf);

    switch ( buf[0] ) {

    case 'b':
      new_context = ssa_context_branch (context);
      printf ("ssa_context_branch (%x) = %x\n",
	      (int) context, (int) new_context);
      context = new_context;
      break;

    case 'p':
      new_context = ssa_context_up (context);
      printf ("ssa_context_up (%x) = %x\n", (int) context, (int) new_context);
      context = new_context;
      break;

    case 'c':
      ssa_context_clear_children (context);
      printf ("ssa_context_clear_children (%x)\n", (int) context);
      break;

    case 'l':
      printf ("bindings for context %x: ", (int) context);
      ar_for_all (context->bindings, ssa_binding, binding) {
	printf (" %s=%d", (char *) binding->var, (int) binding->value);
      } ar_end_for;
      printf ("\n");
      break;

    case 'L': {
      int count = 0;
      ssa_context child = context->first_child;

      printf ("context %x has %d children.\n", (int) context,
	      context->num_children);

      while ( child != NULL ) {
	count++;

	printf ("child %d (%x): ", count, (int) child);

	ar_for_all (child->bindings, ssa_binding, binding) {
	  printf (" %s=%d", (char *) binding->var, (int) binding->value);
	} ar_end_for;

	printf ("\n");

	child = child->next;
      }
      break;
    }

    case 'd':
      sscanf (buf+1, "%s%d", arg, (int *)&value);
      ssa_define (context, arg, value);
      printf ("ssa_define (%x, \"%s\", %d)\n", (int) context, arg,
	      (int) value);
      break;

    case 'u':
      sscanf (buf+1, "%s", arg);
      ssa_unbind (context, arg);
      printf ("ssa_unbind (%x, \"%s\")\n", (int) context, arg);
      break;

    case 'r':
      sscanf (buf+1, "%s", arg);
      value = ssa_read (context, arg);
      printf ("ssa_read (%x, \"%s\") = %d\n", (int) context, arg, (int) value);
      break;

    case 'q':
      return 0;

    default:
      fprintf (stderr, "not a command: %c\n", buf[0]);
    }
  }
}
#endif
