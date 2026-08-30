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
#include "error.h"
#include "mem.h"
#include "ar.h"
#include "hashtab.h"
#include "nl.h"


void
ast2g_error (const char *format, ...)
{
  va_list ap;
  int len = strlen (format);
  char *new_format = alloca (32 + len);

  sprintf (new_format, "error: %s", format);

  va_start (ap, format);
  error_va_list ((const char *) new_format, ap);
}


void
ast2g_ast_error (nl_ast node, const char *format, ...)
{
  va_list ap;
  int len = strlen (format);
  char *new_format = alloca (32 + len);
  char *file = nl_ast_file (node);
  int line = nl_ast_line (node);

  sprintf (new_format, "error: %s line %d: %s", file, line, format);

  va_start (ap, format);
  error_va_list ((const char *) new_format, ap);
}


void
ast2g_warning (const char *format, ...)
{
  va_list ap;
  int len = strlen (format);
  char *new_format = alloca (32 + len);

  sprintf (new_format, "warning: %s\n", format);

  va_start (ap, format);
  vfprintf (stderr, (const char *) new_format, ap);
}


void
ast2g_ast_warning (nl_ast node, const char *format, ...)
{
  va_list ap;
  int len = strlen (format);
  char *new_format = alloca (32 + len);
  char *file = nl_ast_file (node);
  int line = nl_ast_line (node);

  sprintf (new_format, "warning: %s line %d: %s\n", file, line, format);

  va_start (ap, format);
  vfprintf (stderr, (const char *) new_format, ap);
}
