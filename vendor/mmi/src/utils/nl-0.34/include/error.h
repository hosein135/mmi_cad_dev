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

#include <setjmp.h>


extern char error_message[];
void *error_set_tag (void *);
void  error_throw (int) NORETURN;
void  error (const char *, ...) NORETURN;
void  error_tagged (int, const char *, ...) NORETURN;
void  error_va_list (const char *, void *) NORETURN;
void  error_va_list_tagged (int, const char *, void *) NORETURN;
void  error_append_message (const char *, ...);


#define error_catch \
  do { \
    jmp_buf __env; \
    int __jmp_result; \
    int __continue = 0; \
    void *__prev = error_set_tag (__env); \
    if ( (__jmp_result = setjmp (__env)) == 0 )


#define error_unwind_protect \
  do { \
    jmp_buf __env; \
    int __jmp_result; \
    int __continue; \
    void *__prev = error_set_tag (__env); \
    if ( (__jmp_result = __continue = setjmp (__env)) == 0 )


#define error_on_tag(t) \
    else if (__jmp_result == (t) && (error_set_tag (NULL) || 1))


#define error_on_error \
    else if (1 && (error_set_tag (NULL) || 1))


#define error_current_tag __jmp_result


#define error_on_exit


#define error_dont_continue()  (__continue = 0)


#define error_end \
    error_set_tag (__prev); \
    if (__continue) { \
      error_throw (__continue); \
    } \
  } while (0)
