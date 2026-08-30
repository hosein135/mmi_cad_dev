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

#include "stdpccts.h"
typedef AST SORAST;
#include "sorcerer.h"


void
def2pnl2_cr_ast (AST *tree, Attrib *attr, int tok, char *txt)
{
  tree->token = tok;
  tree->text = NULL;
  tree->num = -1;

  switch ( tok ) {
  case DEF_IDENT:
  case DEF_QUOTED:
  case DEF_N:
  case DEF_S:
  case DEF_FS:
  case DEF_FN:
    tree->text = strdup (txt);
    break;
  case DEF_NUMBER:
    tree->num = atoi (txt);
    break;
  }
}


AST *
def2pnl2_mk_ast (AST *t, int tok, char *txt)
{
  def2pnl2_cr_ast (t, NULL, tok, txt);

  return t;
}


static
void
dump_string (char *str)
{
  char *s = str;

  putchar ('\"');

  while ( *s ) {
    if ( *s == '\"' || *s == '\\' ) {
      putchar ('\\');
    }
    putchar (*s);
    s++;
  }

  putchar ('\"');
}


static
void
dump_token (char *str)
{
  printf (str);
}


static
void
dump (AST *tree, int indent)
{
  while ( tree != NULL ) {
    int i;

    if ( tree->down ) {
      printf ("\n");
      for ( i = 0; i < indent; i++ )
	putchar (' ');
      printf ("(");
    }

    if ( tree->token == DEF_IDENT ) {
      dump_string (tree->text);
    }
    else if ( tree->token == DEF_QUOTED ) {
      dump_string (tree->text);
    }
    else {
      dump_token (tree->text);
    }

    if ( tree->down ) {
      printf (" ");
      dump (tree->down, indent + 2);
      printf(")");
    }

    tree = tree->right;

    if ( tree != NULL )
      printf (" ");
  }
}


static
void
dump_top (AST *tree)
{
  printf ("(DEF");
  dump (tree, 2);
  printf (")\n");
}
  

static
void
def_zzerr (const char *str)
{
  fprintf (stderr, "Error: line %d: %s\n", zzline, str);
  exit (1);
}


main ()
{
  AST *root = NULL;

  zzerr = def_zzerr;

  ANTLR (def_file (&root), stdin);

  {
    STreeParser parser;

    STreeParserInit (&parser);

    def2pnl_def_file (&parser, &root);
  }
}
