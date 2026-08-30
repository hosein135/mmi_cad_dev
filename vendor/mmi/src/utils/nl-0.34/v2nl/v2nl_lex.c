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


int v2nl_translate_off = 0;
int v2nl_dc_script = 0;
int v2nl_line_comment;


static ar v2nl_state_stack = NULL;
static ar v2nl_file_stack = NULL;
static hashtab v2nl_macro_table = NULL;
static ht_attr v2nl_macro_attr = NULL;
static ht_attr v2nl_macro_hard = NULL;
static hashtab v2nl_escaped_id_table = NULL;
static ht_attr v2nl_escaped_id_attr = NULL;


struct ifdef_mode {
  int if_line;
  int if_mode;
  int else_mode;
};

static ar v2nl_ifdef_stack = NULL;


void
v2nl_lex_cleanup (void)
{
  if ( v2nl_state_stack ) {
    ar_free (v2nl_state_stack);
  }

  if ( v2nl_ifdef_stack ) {
    ar_free (v2nl_ifdef_stack);
  }

  v2nl_lex_end_escaped_translation ();

  v2nl_state_stack = NULL;
  v2nl_ifdef_stack = NULL;

  v2nl_translate_off = 0;
  zzmode (START);
}


static
char *
v2nl_skip_whitespace (char *str)
{
  char *s = str;

  while ( *s == ' ' || *s == '\t' )
    s++;

  return s;
}

    
static
char *
v2nl_get_token (char *str, int *len_p)
{
  char *s = str;
  char *tok;
  int length = 0;

  s = v2nl_skip_whitespace (s);

  tok = s;

  while ( *s != ' ' && *s != '\t' && *s != '\0' ) {
    s++;
    length++;
  }

  *len_p = length;
  return tok;
}

    
int
v2nl_is_pragma_begin (char *text)
{
  /* Skip over the comment characters ("/ *" or "//"). */
  char *s = text + 2;

  s = v2nl_skip_whitespace (s);

  if ( strcasecmp (s, "synopsys") == 0 ) {
    return 1;
  }
  else if ( strcasecmp (s, "$s") == 0 ) {
    return 1;
  }
  else if ( strcasecmp (s, "juniper") == 0 ) {
    return 1;
  }
  else if ( strcasecmp (s, "$j") == 0 ) {
    return 1;
  }

  return 0;
}


static
void
v2nl_push_lexer_state (void)
{
  struct zzdlg_state state;

  zzsave_dlg_state (&state);

  if ( v2nl_state_stack == NULL ) {
    mem_group prev_group = mem_group_set (v2nl_mem_group);

    v2nl_state_stack = AR_NEW (1, struct zzdlg_state);
    v2nl_file_stack = AR_NEW (1, char *);

    mem_group_set (prev_group);
  }

  ar_add (v2nl_state_stack, &state);
  ar_add (v2nl_file_stack, &v2nl_current_file);
}


static
void
v2nl_pop_lexer_state (void)
{
  struct zzdlg_state state;
  int size;

  zzsave_dlg_state (&state);

  if ( state.stream != NULL ) {
    fclose (state.stream);
  }

  ASSERT (v2nl_state_stack != NULL);

  size = ar_size (v2nl_state_stack);
  ASSERT (size > 0);
  ar_ref (v2nl_state_stack, size-1, &state);
  ar_remove_indexed_element (v2nl_state_stack, size-1);

  ASSERT (size == ar_size (v2nl_file_stack));
  ar_ref (v2nl_file_stack, size-1, &v2nl_current_file);
  ar_remove_indexed_element (v2nl_file_stack, size-1);

  zzrestore_dlg_state (&state);
}


static
void
v2nl_free_macro_def (void *ptr)
{
  char *dfn = *(char **)ptr;

  if ( dfn != NULL ) {
    FREE (dfn);
  }
}


static
void
v2nl_init_macro_table (void)
{
  mem_group prev_group = mem_group_set (v2nl_mem_group);

  v2nl_macro_table = ht_alloc (16, ht_hash_string, ht_compare_string,
				ht_copy_string, ht_free_string);

  v2nl_macro_attr = ht_new_attribute (v2nl_macro_table, sizeof (char *),
				       NULL, v2nl_free_macro_def);

  v2nl_macro_hard = ht_new_attribute (v2nl_macro_table, sizeof (int),
				      NULL, NULL);

  mem_group_set (prev_group);
}


void
v2nl_free_macro_table (void)
{
  if ( v2nl_macro_table ) {
    ht_free (v2nl_macro_table);
  }

  v2nl_macro_table = NULL;
  v2nl_macro_attr = NULL;
  v2nl_macro_hard = NULL;
}


void
v2nl_define_macro (char *name, char *text, int hard)
{
  if ( v2nl_macro_table == NULL ) {
    v2nl_init_macro_table ();
  }

  {
    ht_entry hte = ht_lookup (v2nl_macro_table, name);
    char *dfn = STRDUP (text);

    if ( hte == ht_null ) {
      hte = ht_insert (v2nl_macro_table, name);
    }
    else {
      int flag;

      ht_get_attribute_for_entry (v2nl_macro_hard, hte, &flag);

      if ( flag )
	return;
    }

    ht_set_attribute_for_entry (v2nl_macro_attr, hte, &dfn);
    ht_set_attribute_for_entry (v2nl_macro_hard, hte, &hard);
  }
}


void
v2nl_undef_macro (char *name)
{
  ht_delete (v2nl_macro_table, name);
}


static
void
v2nl_expand_macro (char *name)
{
  if ( v2nl_macro_table == NULL ) {
  undefined:
    v2nl_warning ("attempt to expand undefined macro %s", name);
  }
  else {
    ht_entry hte = ht_lookup (v2nl_macro_table, name);

    if ( hte == ht_null ) {
      goto undefined;
    }
    else {
      char *dfn;

      ht_get_attribute_for_entry (v2nl_macro_attr, hte, &dfn);

      v2nl_push_lexer_state ();
      zzrdstr (dfn);
    }
  }
}


static
void
v2nl_include_file (char *file)
{
  FILE *ifp = fopen (file, "r");

  if ( ifp == NULL ) {
    v2nl_error ("could not open %s for reading.", file);
  }
  else {
    v2nl_push_lexer_state ();
    v2nl_current_file = STRDUP (file);
    zzrdstream (ifp);
  }
}


void
v2nl_wrap (void)
{
  if ( v2nl_state_stack != NULL &&
       ar_size (v2nl_state_stack) > 0 ) {
    zzchar_t *lextext = v2nl_zzlextext;

    zzskip ();
    v2nl_pop_lexer_state ();

    v2nl_zzlextext = lextext;
  }
}


void
v2nl_do_macro_definition (char *text)
{
  /* Skip over the "`define". */
  char *s = text + 7;
  int name_len = 0;
  char *t;
  char *name;
  char *rest;

  t = v2nl_get_token (s, &name_len);

  name = alloca (name_len + 1);
  strncpy (name, t, name_len);
  name[name_len] = 0;

  rest = v2nl_skip_whitespace (t + name_len);

  v2nl_define_macro (name, rest, 0);
}


void
v2nl_do_macro_undef (char *text)
{
  /* Skip over the "`undef". */
  char *s = text + 6;
  int name_len = 0;
  char *name;

  name = v2nl_get_token (s, &name_len);

  v2nl_undef_macro (name);
}


void
v2nl_do_macro_expansion (char *text)
{
  /* Skip over the "`" */
  char *s = text + 1;

  v2nl_expand_macro (s);
}


void
v2nl_do_include_file (char *text)
{
  /* Skip over the "`include" */
  char *s = text + 8;
  char *t;
  int name_len = 0;
  char *name;

  t = v2nl_get_token (s, &name_len);

  name = alloca (name_len + 1);
  strncpy (name, t+1, name_len-1);
  name[name_len-2] = 0;

  v2nl_include_file (name);
}


static
void
v2nl_push_ifdef_mode (int line, int if_mode, int else_mode)
{
  if ( v2nl_ifdef_stack == NULL ) {
    v2nl_ifdef_stack = AR_NEW (1, struct ifdef_mode);
  }

  {
    struct ifdef_mode mode;

    mode.if_line = line;
    mode.if_mode = if_mode;
    mode.else_mode = else_mode;

    ar_add (v2nl_ifdef_stack, &mode);
  }
}


static
void
v2nl_pop_ifdef_mode (void)
{
  int size = ar_size (v2nl_ifdef_stack);

  ar_remove_indexed_element (v2nl_ifdef_stack, size-1);
}


static
int
v2nl_get_ifdef_mode (void)
{
  if ( v2nl_ifdef_stack == NULL ) {
    return START;
  }
  else {
    int size = ar_size (v2nl_ifdef_stack);

    if ( size == 0 ) {
      return START;
    }
    else {
      struct ifdef_mode mode;

      ar_ref (v2nl_ifdef_stack, size-1, &mode);

      return mode.if_mode;
    }
  }
}


static
int
v2nl_get_else_mode (void)
{
  int size = ar_size (v2nl_ifdef_stack);
  struct ifdef_mode mode;

  ar_ref (v2nl_ifdef_stack, size-1, &mode);

  return mode.else_mode;
}


static
void
v2nl_set_ifdef_mode (int new_if_mode)
{
  int size = ar_size (v2nl_ifdef_stack);
  struct ifdef_mode mode;

  ar_ref (v2nl_ifdef_stack, size-1, &mode);

  mode.if_mode = new_if_mode;

  ar_set (v2nl_ifdef_stack, size-1, &mode);
}


static
void
v2nl_ifdef (char *name)
{
  int mode = v2nl_get_ifdef_mode ();

  if ( v2nl_macro_table == NULL ) {
  not_defined:
    zzmode (IFDEF_IGNORE);
    v2nl_push_ifdef_mode (zzline, IFDEF_IGNORE, mode);
  }
  else {
    ht_entry hte = ht_lookup (v2nl_macro_table, name);

    if ( hte == ht_null ) {
      goto not_defined;
    }
    else {
      v2nl_push_ifdef_mode (zzline, START, IFDEF_IGNORE);
    }
  }
}


static
void
v2nl_else (void)
{
  int mode = v2nl_get_else_mode ();

  zzmode (mode);

  v2nl_set_ifdef_mode (mode);
}


static
void
v2nl_endif (void)
{
  int mode;

  v2nl_pop_ifdef_mode ();

  mode = v2nl_get_ifdef_mode ();
  
  zzmode (mode);
}


void
v2nl_do_ifdef (char *text)
{
  /* Skip over the "`ifdef" */
  char *s = text + 6;
  char *t;
  int name_len = 0;
  char *name;

  t = v2nl_get_token (s, &name_len);

  name = alloca (name_len + 1);
  strncpy (name, t, name_len);
  name[name_len] = 0;

  v2nl_ifdef (name);
}


void
v2nl_do_else (char *text)
{
  v2nl_else ();
}


void
v2nl_do_endif (char *text)
{
  v2nl_endif ();
}


void
v2nl_maybe_end_comment (char *text)
{
  if ( text[0] == '\n' || text[0] == EOF ) {
    if ( v2nl_line_comment ) {
      if ( v2nl_translate_off )
	zzmode (TRANSLATE_OFF);
      else
	zzmode (START);
    }
  }
  else if ( text[0] == '*' ) {
    if ( ! v2nl_line_comment ) {
      if ( v2nl_translate_off )
	zzmode (TRANSLATE_OFF);
      else
	zzmode (START);
    }
  }
  else {
    ASSERT (0);
  }
}


void
v2nl_ports_only_gettok (void)
{
  int v2nl_ports_only_in_subprogram = 0;

  while (1) {
    int token;
    char *text;

    v2nl_zzgettok ();

    token = NLA;
    text = NLATEXT;

    if ( token == MODULE ) {
      v2nl_ports_only_skip = 0;
    }
    else if ( token == ENDMODULE || token == zzEOF_TOKEN ) {
      v2nl_ports_only_skip = 1;
      return;
    }
    else if ( token == FUNCTION || token == TASK ) {
      v2nl_ports_only_in_subprogram = 1;
      v2nl_ports_only_skip = 1;
    }
    else if ( token == ENDFUNCTION || token == ENDTASK ) {
      v2nl_ports_only_in_subprogram = 0;
      v2nl_ports_only_skip = 1;
    }
    else if ( token == INPUT ||
	      token == OUTPUT ||
	      token == INOUT ) {
      v2nl_ports_only_skip = v2nl_ports_only_in_subprogram;
    }

    if ( v2nl_ports_only_skip == 0 ) {
      if ( text[0] == ';' && text[1] == 0 ) {
	v2nl_ports_only_skip = 1;
      }

      return;
    }
  }
}


void
v2nl_process_escaped_id (void)
{
  char *text = zztext + 1;
  ht_entry ent = ht_null;

  if ( v2nl_escaped_id_table )
    ent = ht_lookup (v2nl_escaped_id_table, text);

  if ( ent != ht_null ) {
    char *new_text;

    ht_get_attribute_for_entry (v2nl_escaped_id_attr, ent, &new_text);

    zzreplstr (new_text);
  }
  else {
    zzreplstr (text);
  }
}


static
void
v2nl_free_fn (void *ptr_p)
{
  void *ptr = *(void **)ptr_p;

  if ( ptr != 0 )
    FREE (ptr);
}


void
v2nl_lex_add_escaped_translation (char *from, char *to)
{
  if ( v2nl_escaped_id_table == NULL ) {
    v2nl_escaped_id_table
      = ht_alloc_from_group (sizeof (char *), ht_hash_string,
			     ht_compare_string, NULL,
			     ht_free_string, v2nl_mem_group);
    v2nl_escaped_id_attr = ht_new_attribute (v2nl_escaped_id_table,
					     sizeof (char *), NULL,
					     v2nl_free_fn);
  }

  {
    char *from_copy = GSTRDUP (from, v2nl_mem_group);
    ht_entry ent = ht_insert (v2nl_escaped_id_table, from_copy);
    void *to_copy = GSTRDUP (to, v2nl_mem_group);
    ht_set_attribute_for_entry (v2nl_escaped_id_attr, ent, &to_copy);
  }
}


void
v2nl_lex_end_escaped_translation (void)
{
  if ( v2nl_escaped_id_table ) {
    ht_free (v2nl_escaped_id_table);
  }

  v2nl_escaped_id_table = NULL;
  v2nl_escaped_id_attr = NULL;
}
