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

typedef struct unparse_fp *unparse_fp;

extern unparse_fp unparse_open (FILE *);
extern void       unparse_flush (unparse_fp);
extern void       unparse_close (unparse_fp);
extern void       unparse_set_indent (unparse_fp, int);
extern void       unparse_set_line_limit (unparse_fp, int);
extern int        unparse_column (unparse_fp);
extern int        unparse_indent (unparse_fp);
extern int        unparse_line_limit (unparse_fp);
extern void       unparse_newline (unparse_fp ufp);
extern void       unparse_space (unparse_fp ufp, int);
extern void       unparse_token (unparse_fp, char *, int);
extern void       unparse_int (unparse_fp, int, int);
extern void       unparse_float (unparse_fp, float, int);
extern void       unparse_double (unparse_fp, double, int);

