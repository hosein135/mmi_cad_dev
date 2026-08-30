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

#undef NUMBER
#undef ID
#undef VERILOG_NUMBER
#undef REF
#undef BIT
#undef SLICE
#undef CONCAT
#undef REPEAT_CONCAT
#undef BIN_RADIX
#undef HEX_RADIX
#undef DEC_RADIX
#undef OCT_RADIX

#define NUMBER nl_token_number
#define ID nl_token_id
#define VERILOG_NUMBER nl_token_vnum
#define REF nl_token_ref
#define BIT nl_token_bit
#define SLICE nl_token_slice
#define CONCAT nl_token_concat
#define REPEAT_CONCAT nl_token_repeat_concat
#define BIN_RADIX nl_token_bin
#define HEX_RADIX nl_token_hex
#define DEC_RADIX nl_token_dec
#define OCT_RADIX nl_token_oct
