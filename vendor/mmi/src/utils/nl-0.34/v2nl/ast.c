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

#undef zzlink
#undef zzastnew
#undef zzpre_ast
#undef zzfree_ast
#undef zztmake
#undef zzdup_ast
#undef zztfree

#define zzlink nl_ast_link
#define zzastnew() nl_ast_create (nl_token_null)
#define zzpre_ast nl_ast_prewalk
#define zzfree_ast nl_ast_free_tree
#define zztmake nl_ast_make
#define zzdup_ast nl_ast_dup
#define zztfree nl_ast_free


/* add a child node to the current sibling list */
void
zzsubchild (AST **_root, AST **_sibling, AST **_tail)
{
  AST *n;

  zzNON_GUESS_MODE {
    n = zzastnew ();

#ifdef DEMAND_LOOK
    zzcr_ast (n, &(zzaCur), LA(0), LATEXT(0));
#else
    zzcr_ast (n, &(zzaCur), LA(1), LATEXT(1));
#endif

    zzastPush (n);

    if ( *_tail != NULL ) {
      nl_ast_set_sibling (*_tail, n);
    }
    else {
      *_sibling = n;
      if ( *_root != NULL ) {
	nl_ast_set_child (*_root, *_sibling);
      }
    }
    *_tail = n;
    if ( *_root == NULL ) {
      *_root = *_sibling;
    }
  }
}


/* make a new AST node.  Make the newly-created
 * node the root for the current sibling list.  If a root node already
 * exists, make the newly-created node the root of the current root.
 */
void
zzsubroot (AST **_root, AST **_sibling, AST **_tail)
{
  AST *n;

  zzNON_GUESS_MODE {

    n = zzastnew ();

#ifdef DEMAND_LOOK
    zzcr_ast (n, &(zzaCur), LA(0), LATEXT(0));
#else
    zzcr_ast (n, &(zzaCur), LA(1), LATEXT(1));
#endif

    zzastPush (n);

    if ( *_root != NULL ) {
      if ( nl_ast_child (*_root) == *_sibling ) {
	*_sibling = *_tail = *_root;
      }
    }

    *_root = n;
    nl_ast_set_child (*_root, *_sibling);
  }
}

