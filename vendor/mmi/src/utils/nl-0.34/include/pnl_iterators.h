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

#define pnl_dll_for_all_internal(dll, type, var) \
    { type (var); \
      pnl_dll_head __dll = (dll); \
      pnl_dll __next; \
      for ( (var) = (type) pnl_dll_gen_first (__dll); \
            ((var) != NULL) && \
            ((__next = pnl_dll_gen_next (__dll, (pnl_dll) (var))) || 1); \
	    (var) = (type) __next)

#define pnl_dll_for_all(dll, type, var) \
    if ( dll == NULL ) ; else \
    {nl_begin_for pnl_dll_for_all_internal (dll, type, var)
   
#define pnl_net_for_all_routes(net, var) \
    pnl_dll_for_all (pnl_net_routes (net), pnl_route, var)
   
#define pnl_inet_for_all_routes(inet, var) \
    pnl_dll_for_all (pnl_inet_routes (inet), pnl_route, var)
   
#define pnl_route_for_all_branches(route, var) \
    pnl_dll_for_all (pnl_route_branches (route), pnl_branch, var)
   
#define pnl_branch_for_all_segments(branch, var) \
    pnl_dll_for_all (pnl_branch_segments (branch), pnl_segment, var)

#define pnl_end_for }nl_end_for}


#define pnl_design_for_all_nets(pdesign, var) \
    { pnl_design __pdesign = (pdesign); \
      nl_design __design = pnl_design_nl_rep (__pdesign); \
      nl_net_attr __net_attr = pnl_design_net_attr (__pdesign); \
      nl_design_for_all_nets (__design, __net) { \
        pnl_net var; \
        nl_net_attr_get (__net_attr, __net, &var); \
        if ( 0 ) ; else


#define pnl_design_for_all_cells(pdesign, var) \
    { pnl_design __pdesign = (pdesign); \
      nl_design __design = pnl_design_nl_rep (__pdesign); \
      nl_cell_attr __cell_attr = pnl_design_cell_attr (__pdesign); \
      nl_design_for_all_cells (__design, __cell) { \
        pnl_cell var; \
        nl_cell_attr_get (__cell_attr, __cell, &var); \
        if ( 0 ) ; else


#define pnl_design_for_all_ports(pdesign, var) \
    { pnl_design __pdesign = (pdesign); \
      nl_design __design = pnl_design_nl_rep (__pdesign); \
      nl_port_attr __port_attr = pnl_design_port_attr (__pdesign); \
      nl_design_for_all_ports (__design, __port) { \
        pnl_port var; \
        nl_port_attr_get (__port_attr, __port, &var); \
        if ( 0 ) ; else


#define pnl_design_for_all_x_tracks(pdesign, var) \
    pnl_dll_for_all (pnl_design_x_tracks (pdesign), pnl_tracks, var)


#define pnl_design_for_all_y_tracks(pdesign, var) \
    pnl_dll_for_all (pnl_design_y_tracks (pdesign), pnl_tracks, var)
