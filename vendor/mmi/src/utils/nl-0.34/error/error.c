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


char error_message[1024];
static void *error_current_tag;


void *
error_set_tag (void *buf)
{
  void *result = error_current_tag;

  error_current_tag = buf;

  return result;
}


void
error_throw (int val)
{
  if ( error_current_tag == NULL ) {
    fprintf (stderr, "UNCAUGHT EXCEPTION (%d): %s\n", val, error_message);
    fprintf (stderr, "Aborting.\n");
    abort ();
  }
  else {
    longjmp (error_current_tag, val);
  }
}


void
error (const char *format, ...)
{
  va_list ap;

  va_start (ap, format);
  error_va_list_tagged (1, format, ap);
}


void
error_va_list (const char *format, void *ap_arg)
{
  va_list ap = (va_list) ap_arg;
  error_va_list_tagged (1, format, ap);
}


void
error_tagged (int tag, const char *format, ...)
{
  va_list ap;

  va_start (ap, format);
  error_va_list_tagged (tag, format, ap);
}


void
error_va_list_tagged (int tag, const char *format, void *ap_arg)
{
  va_list ap = (va_list) ap_arg;

  vsprintf (error_message, format, ap);
  va_end (ap);

  error_throw (tag);
}


void
error_append_message (const char *format, ...)
{
  char *msg = error_message;

  while ( *msg != '\0' ) {
    msg++;
  }

  {
    va_list ap;

    va_start (ap, format);
    vsprintf (msg, format, ap);
    va_end (ap);
  }
}
