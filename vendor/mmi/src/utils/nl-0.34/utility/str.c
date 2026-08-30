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
#include "error.h"
#include "str.h"


char *
str_append (char *str1, ...)
{
  int len1 = strlen (str1);
  int total_length = len1 + 1;
  va_list ap;

  va_start (ap, str1);

  do {
    char *arg = va_arg (ap, char *);
    int arg_len;

    if ( arg == NULL )
      break;

    arg_len = strlen (arg);
    total_length += arg_len;
  } while (1);

  va_end (ap);

  {
    char *result = MALLOC (total_length);
    int pos = len1;

    strcpy (result, str1);

    va_start (ap, str1);

    do {
      char *arg = va_arg (ap, char *);
      int arg_len;

      if ( arg == NULL )
	break;

      arg_len = strlen (arg);
      strcpy (result + pos, arg);
      pos += arg_len;
    } while (1);

    va_end (ap);

    return result;
  }
}


int
str_match (char *substring, char *str, char escape_char)
{
  int i;
  int sublen = strlen (substring);
  int len = strlen (str);

  for ( i = 0; i < len - sublen + 1; i++ ) {
    if ( str[i] == escape_char && str[i+1] != 0 ) {
      i += 2;
    }
    else if ( strncmp (substring, str + i, sublen) == 0 ) {
      return i;
    }
  }

  return -1;
}


void
str_unescape (char *str, char esc_char, char *escaped)
{
  char *s = str;
  char *t = str;
  char c;
  int len = strlen (escaped);

  ASSERT (esc_char != 0);

  do {
    c = s[0];

    if ( c == esc_char ) {
      if ( strncmp (s+1, escaped, len) != 0 ) {
	*t = esc_char;
	t++;
      }
    }
    else {
      *t = c;
      t++;
    }

    s++;
  } while ( c != 0 );
}


struct str_buf {
  char *buffer;
  int pos;
  int alloc;
};


str_buf
str_concat_begin (void)
{
  str_buf result = MALLOC (sizeof (*result));

  result->buffer = MALLOC (64);
  result->pos = 0;
  result->alloc = 64;

  return result;
}


static
unsigned int
power_2_roundup (unsigned int n)
{
  unsigned int x = n;
  unsigned int result = 1;

  while ( x > 0 ) {
    result <<= 1;
    x >>= 1;
  };

  return result;
}


void
str_concat (str_buf buf, ...)
{
  va_list ap;

  va_start (ap, buf);

  do {
    char *str = va_arg (ap, char *);
    int len;

    if ( str == NULL )
      break;

    len = strlen (str);

    if ( buf->pos + len + 1 >= buf->alloc ) {
      int need = power_2_roundup (buf->pos + len + 1);
      buf->buffer = REALLOC (buf->buffer, need);
    }

    strcpy (buf->buffer + buf->pos, str);

    buf->pos += len;
  } while (1);
}


char *
str_concat_end (str_buf buf)
{
  char *result = buf->buffer;

  FREE (buf);

  return result;
}


char *
str_toupper (char *str)
{
  char *s = str;

  while ( *s ) {
    *s = toupper (*s);
    s++;
  }

  return str;
}


char *
str_tolower (char *str)
{
  char *s = str;

  while ( *s ) {
    *s = tolower (*s);
    s++;
  }

  return str;
}


int
str_parse_number (char *str, int precision)
{
  int len = strlen (str);
  char *start = alloca (len + precision + 1);
  char *t = start;
  char *s = str;
  int count = 0;
  int decimal = 0;
  int result;
  int i;

  while ( *s != 0 ) {
    if ( decimal ) {
      count++;
    }

    if ( count > precision ) {
      if ( *s != '0' ) {
	error ("too many decimal places in number (max is %d): %s", precision, str);
      }
    }
    else if ( *s == '.' ) {
      if ( decimal ) {
	error ("duplicated decimal point in number: %s", str);
      }
      s++;
      decimal = 1;
    }
    else {
      *t = *s;
      s++;
      t++;
    }
  }

  for ( i = count; i < precision; i++ ) {
    *t = '0';
    t++;
  }

  *t = 0;

  result = atoi (start);

  return result;
}
