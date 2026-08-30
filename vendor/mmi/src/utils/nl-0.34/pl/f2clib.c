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

#include "f2c.h"


integer
s_cmp (char *str1, char *str2, ftnlen size1, ftnlen size2)
{
  int i;
  int min = size1 < size2 ? size1 : size2;

  for ( i = 0; i < min; i++ ) {
    if ( str1[i] > str2[i] )
      return 1;
    if ( str1[i] < str2[i] )
      return -1;
  }

  for ( i = min; i < size1; i++ ) {
    if ( str1[i] > 0 ) {
      return 1;
    }
  }

  for ( i = min; i < size2; i++ ) {
    if ( str2[i] > 0 ) {
      return -1;
    }
  }

  return 0;
}


integer
s_copy (char *str1, char *str2, ftnlen size1, ftnlen size2)
{
  int i;
  int min = size1 < size2 ? size1 : size2;

  for ( i = 0; i < min; i++ ) {
    str1[i] = str2[i];
  }

  for ( i = min; i < size1; i++ ) {
    str1[i] = 0;
  }

  return 0;
}


integer
f_open (olist *o)
{
  return 0;
}


integer
s_wsfe (cilist *c)
{
  return 0;
}


integer
s_wsle (cilist *c)
{
  return 0;
}


integer
do_fio (integer *c, char *s, ftnlen size)
{
  return 0;
}


integer
do_lio (integer *c, char *s, ftnlen size)
{
  return 0;
}


integer
e_wsfe (void)
{
  return 0;
}


integer
e_wsle (void)
{
  return 0;
}


doublereal
etime_ (real *a)
{
  a[0] = 0;
  a[1] = 0;

  return 0.0;
}
