

nl_cell nl_cell_create (char * name, nl_reference reference)

    Create a new instance (cell) of reference 'reference' named 'name'.
    This routine also creates a number of pins depending on the number of
    pins on the specified reference.  This routine uses the pins to
    populate the inputs, outputs, and inouts of the new cell.


void nl_cell_disconnect (nl_cell cell)

    Disconnect all nets from cell 'cell'.  The cell will still have all
    its pins, but none of them will be connected to nets.


nl_pin nl_cell_get_pin_by_refpin (nl_cell cell, nl_refpin refpin)

    Return the pin on cell 'cell' that corresponds to pin 'refpin' on the
    cell's reference.  It is assumed that 'refpin' belongs to the cell's
    reference.


void nl_cell_rename (nl_cell cell, char * new_name)

    Change the name of cell 'cell' to 'new_name'.


nl_design nl_design_create (char * name, nl_context context)

    Create an empty design named 'name' in context 'context'.


void nl_design_remove_cell (nl_design design, nl_cell cell)

    Remove cell 'cell' from design 'design'.  All the cell's pins will be
    disconnected; all references to the cell are removed from the design;
    and the cell itself is freed.  Any further reference to this cell is
    invalid.


void nl_design_remove_port (nl_design design, nl_port port)

    Remove port 'port' from design 'design'.  The port's pin will be
    disconnected; all references to the port are removed from the design;
    and the port itself is freed.  Any further reference to this port is
    invalid.


void nl_design_remove_net (nl_design design, nl_net net)

    Remove net 'net' from design 'design'.  All the net's pins will be
    disconnected; all references to the net are removed from the design;
    and the net itself is freed.  Any further reference to this net is
    invalid.


void nl_design_remove_reference (nl_design design, nl_reference reference)

    Remove reference 'reference' from design 'design'.


void nl_design_remove_attr (nl_design design, nl_attr attr)

    Remove attribute 'attr' from design 'design'.  The attribute is
    removed from any object to which it is attached; all the storage
    associated with the attribute is freed; and the attribute itself is
    freed.  Any further reference to this attribute is invalid.


nl_cell nl_design_get_cell_by_name (nl_design design, char * name)

    Return the cell named 'name' in design 'design'.  If the design does
    not contain a cell with this name, return NULL.


nl_reference nl_design_get_reference_by_name (nl_design design, char * name)

    Return the reference named 'name' in design 'design'.  If the design
    does not contain a reference with this name, return NULL.


nl_net nl_design_get_net_by_name (nl_design design, char * name)

    Return the net named 'name' in design 'design'.  If the design does
    not contain a net with this name, return NULL.


nl_named_object nl_design_get_net_or_bus_by_name (nl_design design, char * name)

    Return the net or bus or nets named 'name' in design 'design'.  If the
    design does not contain either a net or a bus of nets with this name,
    return NULL.


nl_named_object nl_design_get_object_by_name (nl_design design, char * name)

    Return the cell, bus of cells, net, or bus of nets named 'name' in
    design 'design'.  If the design does not contain a cell, bus of cells,
    net, or bus of nets with this name, return NULL.


nl_object nl_design_get_port_by_name (nl_design design, char * name)

    Return the port named 'name' in design 'design'.  If the design does
    not contain a port with this name, return NULL.


nl_type nl_design_get_type_by_name (nl_design design, char * name)

    Return the type named 'name' in design 'design'.  If the design does
    not contain a type with this name, return NULL.


nl_attr nl_design_get_attr_by_name (nl_design design, char * name)

    Return the attribute named 'name' in design 'design'.  If the design
    does not contain a attribute with this name, return NULL.


void nl_design_add_supply0 (nl_design design, nl_object net_or_bus)

    Declare 'net_or_bus', which must either be a net or a bus of nets, to
    be a "supply0" in design 'design'.  If this design is written out as
    Verilog, the specified net or bus will be declared using "supply0".


void nl_design_add_supply1 (nl_design design, nl_object net_or_bus)

    Declare 'net_or_bus', which must either be a net or a bus of nets, to
    be a "supply1" in design 'design'.  If this design is written out as
    Verilog, the specified net or bus will be declared using "supply1".


int nl_design_num_nets (nl_design design)

    Return the number of nets (including the ones that are in buses) in
    design 'design'.


int nl_design_num_net_buses (nl_design design)

    Return the number of buses of nets in design 'design'.


int nl_design_num_cells (nl_design design)

    Return the number of cells (including the ones that are in buses) in
    design 'design'.


int nl_design_num_cell_buses (nl_design design)

    Return the number of buses of cells in design 'design'.


int nl_design_num_ports (nl_design design)

    Return the number of ports (including the ones that are in buses) in
    design 'design'.


int nl_design_num_port_buses (nl_design design)

    Return the number of buses of ports in design 'design'.


int nl_design_num_references (nl_design design)

    Return the number of references in design 'design'.


int nl_design_num_types (nl_design design)

    Return the number of types in design 'design'.


int nl_design_num_attrs (nl_design design)

    Return the number of attributes in design 'design'.


nl_context nl_context_create (void)

    Create and return an nl context.  All nl designs are contained within
    a context.  So, you have to create an nl context before you can create
    any nl designs.


void nl_context_free (nl_context context)

    Free nl_context 'context'.  All designs associated with this context
    are also freed.


void nl_context_remove_design (nl_context context, nl_design design)

    Remove design 'design' from context 'context'.  All storage associated
    with the specified design (e.g. cells, nets) is also freed.


void nl_context_remove_library (nl_context context, nl_library library)

    Remove library 'library' from context 'context'.  All storage
    associated with the specified library (e.g. cells, nets) is also
    freed.


nl_design nl_context_get_design_by_name (nl_context context, char * name)

    Return the design in context 'context' whose name is 'name'.  If there
    is no design in the context with that name, return NULL.


nl_reference nl_reference_create (char * name, nl_design design, nl_object down_design)

    Create a new reference named 'name' within design 'design'.  The down
    design of the reference will be 'down_design'.  This routine does not
    create any pins on the reference.


void nl_reference_add_bus (nl_reference reference, nl_bus bus)

    Add refpin bus 'bus' to reference 'reference'.


int nl_reference_num_instances (nl_reference reference)

    Return the number of instances (cells) whose reference is 'reference'.


nl_object nl_reference_get_refpin_by_name (nl_reference reference, char * name)

    Return the refpin named 'name' on reference 'reference'.  If there is
    no pin with that name on the reference, return NULL.


int nl_reference_input_width (nl_reference reference)

    Return the number of input pins on reference 'reference'.


int nl_reference_output_width (nl_reference reference)

    Return the number of output pins on reference 'reference'.


int nl_reference_inout_width (nl_reference reference)

    Return the number of inout pins on reference 'reference'.


nl_refpin nl_refpin_create (char * name, nl_object down_port, nl_reference reference)

    Create a new refpin named 'name' on reference 'reference' that
    corresponds to 'down_port' on the down design of the reference.
    'down_port' may be NULL, in which case the refpin will be unlinked and
    its direction will be "unknown."


nl_pin nl_pin_create (nl_refpin refpin, nl_cell_or_port cell_or_port)

    Create a new pin corresponding to 'refpin' on cell or port
    'cell_or_port'.  If 'cell_or_port' is a port, 'refpin' should be NULL.
    It generally should not be necessary to call this routine, since pins
    are created on cells and ports with they are created.


void nl_pin_connect_net (nl_pin pin, nl_net net)

    Connect pin 'pin' to net 'net'.  Depending on its direction, the pin
    will be added to the fanouts, fanins, or fanios of the net.  If the
    direction of the pin is unknown, it will be added to the fanios of the
    net.


void nl_pin_disconnect (nl_pin pin)

    Disconnect pin 'pin' from any net it is currently connected to.


nl_direction nl_pin_direction (nl_pin pin)

    Return the direction of pin 'pin'.


nl_net nl_net_create (char * name, nl_wireclass class, nl_design design)

    Create a new net named 'name' of class 'class' in design 'design'.
    The class is one of nl_wireclass_wire, nl_wireclass_reg, etc. and is
    used to distinguish between different types of Verilog wires.


void nl_net_rename (nl_net net, char * new_name)

    Change the name of net 'net' to 'new_name'.


nl_port nl_port_create (char * name, nl_design design, nl_direction direction)

    Create port named 'name' on design 'design'.  The direction of the
    port will be 'direction'.  This routine also creates a pin on the
    port.


void nl_port_connect_net (nl_port port, nl_net net)

    Connect net 'net' to port 'port'.


void nl_port_rename (nl_port port, char * new_name)

    Change the name of port 'port' to 'new_name'.


nl_type nl_type_get_scalar (nl_object owner)

    Return the scalar type in specified owner.  The scalar type is the
    type of a single, unbused wire.


nl_type nl_type_get_integer (nl_object owner)

    Return the integer type the specified owner.  The integer type is the
    type of a single, unbused wire.


nl_type nl_type_get_array (nl_type base, int lb, int rb)

    Return an array type whose member type is 'base', whose left bound is
    'lb', and whose right bound is 'rb'.  The array type is the type of a
    bus.  The member type can be any type, including another array.


int nl_type_width (nl_type type)

    Return the number of leaf-level members of type 'type'.  This would
    correspond tot the number of nets in a bus.  Note that if 'type' is an
    array of arrays, this routine returns the total number of members in
    all the subarrays.


nl_type nl_type_copy (nl_type type, nl_object owner)

    Make a copy of type 'type' in the specified owner.


void nl_idesign_remove_attr (nl_idesign idesign, nl_attr attr)

    Remove attribute 'attr' from design 'design'.  The attribute is
    removed from any object to which it is attached; all the storage
    associated with the attribute is freed; and the attribute itself is
    freed.  Any further reference to this attribute is invalid.


nl_library nl_library_create (char * name, nl_context context)

    Create an empty design named 'name' in context 'context'.
