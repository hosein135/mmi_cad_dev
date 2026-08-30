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
#include "nl_int.h"


/*internal*/
nl_type
nl_type_create (char *name, nl_object owner, nl_typeclass type_class)
{
  nl_kind owner_kind = nl_object_kind (owner);
  nl_type result;

  if ( owner_kind == nl_kind_design ) {
    result = nl_design_alloc_type ((nl_design) owner, name);
  }
  else if ( owner_kind == nl_kind_library ) {
    result = nl_library_alloc_type ((nl_library) owner, name);
  }
  else {
    ASSERT (0);
  }

  result->owner = owner;
  result->class = type_class;
  result->left = 0;
  result->right = 0;
  result->base_type = NULL;

  return result;
}


/*internal*/
void
nl_type_free (nl_type type)
{
  nl_object owner = type->owner;
  nl_kind owner_kind = nl_object_kind (owner);

  FREE (type->name);
  if ( owner_kind == nl_kind_design ) {
    nl_design_free_object ((nl_design) owner, (nl_object) type);
  }
  else if ( owner_kind == nl_kind_library ) {
    ASSERT (!"freeing types in libraries is not yet implemented");
  }
  else {
    ASSERT (0);
  }
}


static
nl_type
nl_type_get_by_name (nl_object owner, char *name)
{
  nl_kind kind = nl_object_kind (owner);
  nl_type type;

  if ( kind == nl_kind_design ) {
    type = nl_design_get_type_by_name ((nl_design) owner, name);
  }
  else if ( kind == nl_kind_library ) {
    type = nl_library_get_type_by_name ((nl_library) owner, name);
  }
  else {
    ASSERT (0);
  }

  return type;
}


/**
   Return the scalar type in specified owner.  The scalar type is the
   type of a single, unbused wire.
**/
/*exported*/
nl_type
nl_type_get_scalar (nl_object owner)
{
  nl_type type = nl_type_get_by_name (owner, "scalar");

  if ( type == NULL ) {
    type = nl_type_create ("scalar", owner, nl_typeclass_scalar);
  }

  return type;
}


/**
   Return the integer type the specified owner.  The integer type is the
   type of a single, unbused wire.
**/
/*exported*/
nl_type
nl_type_get_integer (nl_object owner)
{
  nl_type type = nl_type_get_by_name (owner, "integer");

  if ( type == NULL ) {
    type = nl_type_create ("integer", owner, nl_typeclass_integer);
    type->left = 31;
    type->right = 0;
  }

  return type;
}


/**
   Return an array type whose member type is 'base', whose left bound
   is 'lb', and whose right bound is 'rb'.  The array type is the type
   of a bus.  The member type can be any type, including another
   array.
**/
/*exported*/
nl_type
nl_type_get_array (nl_type base, int lb, int rb)
{
  nl_object owner = base->owner;
  char *base_name = base->name;
  int base_name_len = strlen (base_name);
  char *name = alloca (base_name_len + 20);
  nl_type result;

  sprintf (name, "%s[%d:%d]", base_name, lb, rb);
  
  result = nl_type_get_by_name (owner, name);

  if ( result == NULL ) {
    result = nl_type_create (name, owner, nl_typeclass_array);

    result->left = lb;
    result->right = rb;
    result->base_type = base;
  }

  return result;
}


/**
   Return the number of leaf-level members of type 'type'.  This would
   correspond tot the number of nets in a bus.  Note that if 'type' is
   an array of arrays, this routine returns the total number of
   members in all the subarrays.
**/
/*exported*/
int
nl_type_width (nl_type type)
{
  nl_typeclass type_class = type->class;

  if ( type_class == nl_typeclass_scalar ) {
    return 1;
  }
  else if ( type_class == nl_typeclass_integer ) {
    return 32;
  }
  else {
    nl_type base = type->base_type;
    int base_width = nl_type_width (base);
    int width = (1 + abs (type->left - type->right)) * base_width;

    return width;
  }
}


/**
   Make a copy of type 'type' in the specified owner.
**/
/*exported*/
nl_type
nl_type_copy (nl_type type, nl_object owner)
{
  nl_typeclass class = nl_type_class (type);

  if ( class == nl_typeclass_scalar ) {
    nl_type result = nl_type_get_scalar (owner);

    return result;
  }
  else if ( class == nl_typeclass_array ) {
    int left = type->left;
    int right = type->right;
    nl_type base = nl_type_copy (type->base_type, owner);
    nl_type result = nl_type_get_array (base, left, right);

    return result;
  }
  else {
    ASSERT (0);
  }
}


/*exported*/
int
nl_type_array_depth (nl_type type)
{
  nl_type t = type;
  int count = 0;

  while ( t->class == nl_typeclass_array ) {
    count++;
    t = t->base_type;
  }

  return count;
}


/*exported*/
void
nl_type_get_index_for_offset (nl_type type, int offset, int *index_array)
{
  int depth = nl_type_array_depth (type);

  if ( depth > 1 ) {
    fprintf (stderr, "Arrays of arrays are not yet supported.\n");
    ASSERT (0);
  }

  if ( type->left < type->right ) {
    index_array[0] = type->right - offset;
  }
  else {
    index_array[0] = type->right + offset;
  }
}


/*exported*/
int
nl_type_get_offset_for_index (nl_type type, int index, int *offset_p)
{
  int depth = nl_type_array_depth (type);

  if ( depth > 1 ) {
    fprintf (stderr, "Arrays of arrays are not yet supported.\n");
    ASSERT (0);
  }

  {
    int left = type->left;
    int right = type->right;
    
    if ( type->left < type->right ) {
      if ( index >= left && index <= right ) {
	*offset_p = type->right - index;
	return 1;
      }
      else {
	return 0;
      }
    }
    else {
      if ( index >= right && index <= left ) {
	*offset_p = index - type->right;
	return 1;
      }
      else {
	return 0;
      }
    }
  }
}
