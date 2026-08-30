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

#define nl_dll_for_all_internal(dll, type, var) \
    { type (var); \
      nl_dll __next; \
      for ( (var) = (type) nl_dll_gen_first ((nl_dll_head) dll); \
            ((var) != NULL) && \
            ((__next = nl_dll_gen_next ((nl_dll) (var))) || 1); \
            (var) = (type) __next)
   
#define nl_dll_for_all(dll, type, var) \
    { nl_dll_for_all_internal (dll, type, var)
   
#define nl_design_for_all_nets(design, var) \
    { nl_dll_for_all_internal (nl_design_nets (design), nl_net, var)

#define nl_design_for_all_net_buses(design, var) \
    { nl_dll_for_all_internal (nl_design_net_buses (design), nl_bus, var)

#define nl_design_for_all_cells(design, var) \
    { nl_dll_for_all_internal (nl_design_cells (design), nl_cell, var)

#define nl_design_for_all_cell_buses(design, var) \
    { nl_dll_for_all_internal (nl_design_cell_buses (design), nl_bus, var)

#define nl_design_for_all_ports(design, var) \
    { nl_dll_for_all_internal (nl_design_ports (design), nl_port, var)

#define nl_design_for_all_port_buses(design, var) \
    { nl_dll_for_all_internal (nl_design_port_buses (design), nl_bus, var)

#define nl_design_for_all_references(design, var) \
    { nl_dll_for_all_internal (nl_design_references (design), nl_reference, var)

#define nl_design_for_all_types(design, var) \
    { nl_dll_for_all_internal (nl_design_types (design), nl_type, var)

#define nl_design_for_all_attributes(design, var) \
    { nl_dll_for_all_internal (nl_design_attrs (design), nl_attr, var)

#define nl_design_for_all_subprograms(design, var) \
    { nl_dll_for_all_internal (nl_design_subprograms (design), nl_subprogram, var)

#define nl_design_for_all_idesigns(design, var) \
    { nl_dll_for_all_internal (nl_design_idesigns (design), nl_idesign, var)

#define nl_bus_for_all_net_members(bus, var) \
    { ASSERT (nl_bus_member_kind (bus) == nl_kind_net); \
    ar_for_all (nl_bus_members (bus), nl_net, var)

#define nl_bus_for_all_net_members_reverse(bus, var) \
    { ASSERT (nl_bus_member_kind (bus) == nl_kind_net); \
    ar_for_all_reverse (nl_bus_members (bus), nl_net, var)

#define nl_bus_for_all_cell_members(bus, var) \
    { ASSERT (nl_bus_member_kind (bus) == nl_kind_cell); \
    ar_for_all (nl_bus_members (bus), nl_cell, var)

#define nl_bus_for_all_refpin_members(bus, var) \
    { ASSERT (nl_bus_member_kind (bus) == nl_kind_refpin); \
    ar_for_all (nl_bus_members (bus), nl_refpin, var)

#define nl_bus_for_all_refpin_members_reverse(bus, var) \
    { ASSERT (nl_bus_member_kind (bus) == nl_kind_refpin); \
    ar_for_all_reverse (nl_bus_members (bus), nl_refpin, var)

#define nl_bus_for_all_port_members(bus, var) \
    { ASSERT (nl_bus_member_kind (bus) == nl_kind_port); \
    ar_for_all (nl_bus_members (bus), nl_port, var)

#define nl_bus_for_all_members(bus, var) \
    { ar_for_all (nl_bus_members (bus), nl_object, var)

#define nl_bus_for_all_members_reverse(bus, var) \
    { ar_for_all_reverse (nl_bus_members (bus), nl_object, var)

#define nl_type_for_all_indexes(type, var) \
    {{ int __left = nl_type_left (type); \
       int __right = nl_type_right (type); \
       int __incr = (__left >= __right) ? 1 : -1; \
       int __width = (__left >= __right) \
                     ? __left - __right + 1 \
                     : __right - __left + 1; \
       int __i; \
       int var = __right; \
       for ( __i = 0; __i < __width; __i++, var += __incr )
 
#define nl_cell_for_all_inputs(cell, var) \
    { ar __inputs = nl_cell_inputs (cell); \
      if ( __inputs == NULL ); else \
        ar_for_all (__inputs, nl_pin, var)

#define nl_cell_for_all_outputs(cell, var) \
    { ar __outputs = nl_cell_outputs (cell); \
      if ( __outputs == NULL ); else \
        ar_for_all (__outputs, nl_pin, var)

#define nl_cell_for_all_inouts(cell, var) \
    { ar __inouts = nl_cell_inouts (cell); \
      if ( __inouts == NULL ); else \
        ar_for_all (__inouts, nl_pin, var)

#if 0
#define nl_cell_for_all_pins(cell, var) \
    {{ nl_cell __cell = (cell); \
       ar __pins[3]; \
       int __i; \
       int __j; \
       int __size; \
       nl_pin (var); \
       __pins[0] = nl_cell_inputs (__cell); \
       __pins[1] = nl_cell_outputs (__cell); \
       __pins[2] = nl_cell_inouts (__cell); \
       __i = 0; \
       while ( (__size = ar_size (__pins[__i])) == 0 && __i < 3 ) \
	 __i++; \
       for ( __j = 0; \
	     __i < 3 && (((var) = AR_REF (__pins[__i], nl_pin, __j)) || 1); \
             __j++, \
             __j = __j < __size ? __j : 0, \
             __i = (__j == 0) ? __i + 1 : __i, \
             __size = (__j == 0) ? ar_size (__pins[__i]) : __size )
#endif

#define nl_cell_for_all_pins(cell, var) \
    { ar __pins[3]; \
      nl_cell __cell = (cell); \
      int __i; \
      __pins[0] = nl_cell_inputs (__cell); \
      __pins[1] = nl_cell_outputs (__cell); \
      __pins[2] = nl_cell_inouts (__cell); \
      for ( __i = 0; __i < 3; __i++ ) \
        if ( __pins[__i] == NULL ); else \
          ar_for_all (__pins[__i], nl_pin, var)

#define nl_reference_for_all_inputs(reference, var) \
    { ar_for_all (nl_reference_inputs (reference), nl_refpin, var)

#define nl_reference_for_all_outputs(reference, var) \
    { ar_for_all (nl_reference_outputs (reference), nl_refpin, var)

#define nl_reference_for_all_inouts(reference, var) \
    { ar_for_all (nl_reference_inouts (reference), nl_refpin, var)

#define nl_reference_for_all_refpins(reference, var) \
    { nl_dll_for_all_internal (nl_reference_refpins (reference), nl_refpin,var)

#define nl_reference_for_all_buses(reference, var) \
    { nl_dll_for_all_internal (nl_reference_buses (reference), nl_bus, var)

#define nl_reference_for_all_instances(reference, var) \
    { ar_for_all (nl_reference_instances (reference), nl_cell, var)

#define nl_net_for_all_fanins(net, var) \
    { nl_dll_for_all_internal (nl_net_fanins (net), nl_pin, var)

#define nl_net_for_all_fanouts(net, var) \
    { nl_dll_for_all_internal (nl_net_fanouts (net), nl_pin, var)

#define nl_net_for_all_fanios(net, var) \
    { nl_dll_for_all_internal (nl_net_fanios (net), nl_pin, var)

#define nl_net_for_all_pins(net, var) \
    { nl_dll_head __pins[3]; \
      nl_net __net = (net); \
      int __i; \
      __pins[0] = nl_net_fanins (__net); \
      __pins[1] = nl_net_fanouts (__net); \
      __pins[2] = nl_net_fanios (__net); \
      for ( __i = 0; __i < 3; __i++ ) \
        nl_dll_for_all_internal (__pins[__i], nl_pin, var)

#if 0
#define nl_net_for_all_pins(net, var) \
    {{ nl_dll_head __pins[3]; \
       nl_net __net = (net); \
       int __i; \
       nl_dll __next; \
       nl_pin (var); \
       __pins[0] = nl_net_fanins (__net); \
       __pins[1] = nl_net_fanouts (__net); \
       __pins[2] = nl_net_fanios (__net); \
       __next = nl_dll_gen_first (__pins[0]); \
       for ( __i = 0; \
             (__i < 3) && ((var) = (nl_pin) __next) && \
               ((__next = nl_dll_gen_next (__next)) || 1); \
             __i += (__next == NULL), \
             __next = (__next == NULL) \
                      ? nl_dll_gen_first (__pins[__i]) \
                      : __next )
#endif

#define nl_context_for_all_designs(context, var) \
    { nl_dll_for_all_internal (nl_context_designs (context), nl_design, var)

#define nl_context_for_all_libraries(context, var) \
    { nl_dll_for_all_internal (nl_context_libraries (context), nl_library, var)

#define nl_idesign_for_all_icells(idesign, var) \
    nl_dll_for_all_internal (nl_design_cells (nl_idesign_design (idesign)), \
                             nl_cell, __cell) { \
      nl_icell (var) = nl_idesign_get_icell (idesign, __cell);

#define nl_idesign_for_all_inets(idesign, var) \
    nl_dll_for_all_internal (nl_design_nets (nl_idesign_design (idesign)), \
                             nl_net, __net) { \
      nl_inet (var) = nl_idesign_get_inet (idesign, __net);

#define nl_idesign_for_all_iports(idesign, var) \
    nl_dll_for_all_internal (nl_design_ports (nl_idesign_design (idesign)), \
                             nl_port, __port) { \
      nl_iport (var) = nl_idesign_get_iport (idesign, __port);

#define nl_icell_for_all_inputs(icell, var) \
    { nl_idesign __idesign = nl_icell_idesign (icell); \
      nl_cell __cell = nl_icell_cell (icell); \
      nl_ipin var; \
      ar __inputs = nl_cell_inputs (__cell); \
      if ( __inputs == NULL ); else \
        ar_for_all (__inputs, nl_pin, __pin) \
          if ( (var = nl_idesign_get_ipin (__idesign, __pin)) && 0 ); else

#define nl_icell_for_all_outputs(icell, var) \
    { nl_idesign __idesign = nl_icell_idesign (icell); \
      nl_cell __cell = nl_icell_cell (icell); \
      nl_ipin var; \
      ar __outputs = nl_cell_outputs (__cell); \
      if ( __outputs == NULL ); else \
        ar_for_all (__outputs, nl_pin, __pin) \
          if ( (var = nl_idesign_get_ipin (__idesign, __pin)) && 0 ); else

#define nl_icell_for_all_inouts(icell, var) \
    { nl_idesign __idesign = nl_icell_idesign (icell); \
      nl_cell __cell = nl_icell_cell (icell); \
      nl_ipin var; \
      ar __inouts = nl_cell_inouts (__cell); \
      if ( __inouts == NULL ); else \
        ar_for_all (__inouts, nl_pin, __pin) \
          if ( (var = nl_idesign_get_ipin (__idesign, __pin)) && 0 ); else

#if 0

#define nl_icell_for_all_ipins(icell, var) \
    { nl_idesign __idesign = nl_icell_idesign (icell); \
      nl_cell __cell = nl_icell_cell (icell); \
      int __i; \
      ar __pins[3]; \
      __pins[0] = nl_cell_inputs (__cell); \
      __pins[1] = nl_cell_outputs (__cell); \
      __pins[2] = nl_cell_inouts (__cell); \
      for ( __i = 0; __i < 3; __i++ ) \
        ar_for_all (__pins[__i], nl_pin, __pinr) \
          if ( (var = nl_idesign_get_ipin (__idesign, __pin)) && 0 ); else


#define nl_inet_for_all_ipins(inet, var) \
    { nl_idesign __idesign = nl_inet_idesign (inet); \
      nl_net __net = nl_inet_net (inet); \
      nl_dll_head __pins[3]; \
      nl_net __net = (inet); \
      int __i; \
      __pins[0] = nl_net_fanins (__net); \
      __pins[1] = nl_net_fanouts (__net); \
      __pins[2] = nl_net_fanios (__net); \
      for ( __i = 0; __i < 3; __i++ ) \
        nl_dll_for_all_internal (__pins[__i], nl_pin, __pin) \
          if ( (var = nl_idesign_get_ipin (__idesign, __pin)) && 0 ); else

#endif


#define nl_inet_for_all_fanins(inet, var) \
    { nl_idesign __idesign = nl_inet_idesign (inet); \
      nl_net __net = nl_inet_net (inet); \
      nl_ipin var; \
      nl_dll_for_all_internal (nl_net_fanins (__net), nl_pin, __pin) \
        if ( (var = nl_idesign_get_ipin (__idesign, __pin)) && 0 ); else

#define nl_inet_for_all_fanouts(inet, var) \
    { nl_idesign __idesign = nl_inet_idesign (inet); \
      nl_net __net = nl_inet_net (inet); \
      nl_ipin var; \
      nl_dll_for_all_internal (nl_net_fanouts (__net), nl_pin, __pin) \
        if ( (var = nl_idesign_get_ipin (__idesign, __pin)) && 0 ); else

#define nl_inet_for_all_fanios(inet, var) \
    { nl_idesign __idesign = nl_inet_idesign (inet); \
      nl_net __net = nl_inet_net (inet); \
      nl_ipin var; \
      nl_dll_for_all_internal (nl_net_fanios (__net), nl_pin, __pin) \
        if ( (var = nl_idesign_get_ipin (__idesign, __pin)) && 0 ); else

#define nl_icell_for_all_ipins(icell, var) \
    { int __i; \
      ar __pins[3]; \
      nl_cell __cell = nl_icell_cell (icell); \
      nl_idesign __idesign = nl_icell_idesign (icell); \
      nl_ipin var; \
      __pins[0] = nl_cell_inputs (__cell); \
      __pins[1] = nl_cell_outputs (__cell); \
      __pins[2] = nl_cell_inouts (__cell); \
      for ( __i = 0; __i < 3; __i++ ) \
        if ( __pins[__i] == NULL ); else \
          ar_for_all (__pins[__i], nl_pin, __pin) \
            if ( (var = nl_idesign_get_ipin (__idesign, __pin)) && 0); else

#define nl_cell_for_all_icells(cell, var) \
    { nl_design __design = nl_cell_design (cell); \
      nl_dll_head __idesigns = nl_design_idesigns (__design); \
      nl_icell var; \
      nl_dll_for_all_internal (__idesigns, nl_idesign, __idesign) \
        if ( (var = nl_idesign_get_icell (__idesign, cell)) && 0 ); else

#define nl_net_for_all_inets(net, var) \
    { nl_design __design = nl_net_design (net); \
      nl_dll_head __idesigns = nl_design_idesigns (__design); \
      nl_inet var; \
      nl_dll_for_all_internal (__idesigns, nl_idesign, __idesign) \
        if ( (var = nl_idesign_get_inet (__idesign, net)) && 0 ); else

#define nl_subprogram_for_all_formals(subr, var) \
    { nl_dll_for_all_internal (nl_subprogram_formals (subr), nl_symbol, var)

#define nl_subprogram_for_all_locals(subr, var) \
    { nl_dll_for_all_internal (nl_subprogram_locals (subr), nl_symbol, var)

#define nl_library_for_all_libcells(library, var) \
    { nl_dll_for_all_internal (nl_library_libcells (library), nl_libcell, var)

#define nl_libcell_for_all_libpins(libcell, var) \
    { nl_dll_for_all_internal (nl_libcell_libpins (libcell), nl_libpin, var)


#define nl_begin_for {{
#define nl_end_for   }}
