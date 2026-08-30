## ************************************************************************
## 
## Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
## 
## Permission is hereby granted, without written agreement and without
## license or royalty fees, to use, copy, modify, and distribute this
## software and its documentation for any purpose, provided that the
## above copyright notice and the following three paragraphs appear in
## all copies of this software.
## 
## IN NO EVENT SHALL JUNIPER NETWORKS, INC. BE LIABLE TO ANY PARTY FOR
## DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
## ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
## JUNIPER NETWORKS, INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
## DAMAGE.
## 
## JUNIPER NETWORKS, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES,
## INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
## NON-INFRINGEMENT.
## 
## THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
## NETWORKS, INC. HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
## UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
## 
## ************************************************************************

# Default generator name in "MC Build" menu.
set MC(default_generator) xtop

set MACRO(x2_3) {x3 x2}

set MACRO(x7_8) {x8 x7}
set MACRO(x5_10) {x10 {x5 x6 x7_8}}
set MACRO(x9_11) {x11 x9}

set MACRO(x12_13) {x13 x12}
#set MACRO(xtop) {CELL {x1 x2_3 x4 x5_10 {SPACE -8.03} x9_11 x12_13 x14}}
set MACRO(xtop) {CELL {x1 x2_3 x4 x5_10 {SPACE [expr [mc_width x8] - [mc_width x7]]} x9_11 x12_13 x14}}


puts "x megacell loaded"
