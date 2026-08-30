NL_SHELL TUTORIAL


Part I. Basics

The first part of this tutorial will introduce you to the basics of
nl_shell.  You will read in a Verilog file, which builds the nl
database, and make several queries on the database.  It may help to
stare at the Verilog file and the output of the nl commands until you
see the relationship between the two (which shouldn't take very long).

First, read in the tutorial design.

  % read_verilog tutorial.v
  Current design is now "add4".
  full_adder add4
 
The read_verilog command has read in designs named "full_adder" and
"add4".  Also, since add4 was the last module in the Verilog file, it
has set the current design to be add4.  The name of current design is
specified by the TCL current_design variable.  So, you can verify the
current design by checking the value of this variable.

  % puts $current_design
  add4

To see the names of the designs that are currently in memory, use the
"list_designs" command.

  % list_designs
  full-adder add4

Now we can look at some of the things that are in design add4, such as
its cells, ports, and nets:

  % list_cells
  fa1 fa2 fa3 fa4
  % list_ports
  {x[0]} {x[1]} {x[2]} {x[3]} {y[0]} {y[1]} {y[2]} {y[3]} cin {z[0]} {z[1]}
  {z[2]} {z[3]} cout
  % list_nets
  {x[0]} {x[1]} {x[2]} {x[3]} {y[0]} {y[1]} {y[2]} {y[3]} cin {z[0]} {z[1]}
  {z[2]} {z[3]} cout {carry[2]} {carry[1]} {carry[0]}

The list_ports command has optional switches -inputs, -outputs, and
-inouts, that allow you to list just the input, output, or inout
ports.  For example,

  % list_ports -inputs
  {x[0]} {x[1]} {x[2]} {x[3]} {y[0]} {y[1]} {y[2]} {y[3]} cin
  % list_ports -outputs
  {z[0]} {z[1]} {z[2]} {z[3]} cout

The design also contains "references", which are placeholders for
subdesigns.  There will be one reference in the design for each unique
instantiated subdesign.  In the add4 design, the only subdesign we've
instantiated is "full_adder", which we have instantiated four times.

  % list_references
  full_adder

Apart from references, another type of object that may not be obvious
is the pin.  Cells and ports are connected to nets through pins.  To
get a list of all the pins on a cell, use get_cell_pins.

  % get_cell_pins fa1
  fa1/a fa1/b fa1/cin fa1/cout fa1/sum

Notice that pins are displayed in the form <cell-name>/<port-name>.

One of the interesting things you can do with a pin is find out what
net it is connected to.  To do this, use the get_pin_net command.

  % get_pin_net fa1/a
  x[0]

You can also find out the list of pins that are connected to a net.
Like this:

  % get_net_pins {carry[0]}
  fa1/cout fa2/cin

Notice that when you enter a name that contains brackets ('[' or ']')
you have to enclose it in braces ("{}") to keep TCL from getting
confused.

You might also want to find out what cell a pin belongs to.  To do
this, use the get_pin_owner command:

  % get_pin_owner fa1/cout
  fa1

You can also get the reference of a cell, and the list of cells for a
reference.  Like this:

  % get_cell_reference fa1
  full_adder
  % get_reference_cells full_adder
  fa1 fa2 fa3 fa4

There are several "find" commands (e.g. "find_nets", "find_cells")
that allow you to search for objects by name.  These commands take as
argument a pattern, and return all objects (cells, nets, etc.) whose
name matches the patter.  By default, the find commands use the TCL
string_match function to match the pattern against the name.  Using
the optionaol switches -exact and -regexp you can tell the find
commands to find the object whose name matches the pattern either
exactly or as a regular expression.  For example, to find all the nets
whose name begins with 'x', do this:

  % find_nets x*
  {x[0]} {x[1]} {x[2]} {x[3]}

You can also find all nets that end in "[0]".  But, since square
bracket ('[' and ']') are special characters both for TCL and for
string_match, you have to type in the pattern in a slighly obscure
way.  Like this:

  % find_nets {*\[0\]}
  {x[0]} {y[0]} {z[0]} {carry[0]}

So, the pattern has to be enclosed in braces ("{}") to keep TCL from
interpreting the square brackets.  Also, the square brackets need to
be preceeded by backslashes ('\') to keep string_match from treating
them as special characters.

Other find commands are:
  - find_designs
  - find_nets
  - find_ports
  - find_cells
  - find_references
  - find_pins

The find_pins command needs a little explanation since pin names are
combinations of cell names and port names.  If you wanted to find all
pins that refer to ports called "a", you would use this command:

  % find_pins */a
  fa1/a fa2/a fa3/a fa4/a

And to find all the pins on cell fa1, you could do this:

  % find_pins fa1/*
  fa1/a fa1/b fa1/cin fa1/cout fa1/sum

But, if you wanted to get a list of all the pins in the design, you
couldn't do this:

  % find_pins *

That's because the slash character ('/') in the pattern is special.
When you do "find_pins */a", that means "find all the cells that match
'*', then find all pins of those cells that match 'a'".  So, if you
want to find all the pins in the design, you have to do it this way:

  % find_pins */*
  fa1/a fa1/b fa1/cin fa1/cout fa1/sum fa2/a fa2/b fa2/cin fa2/cout fa2/sum
  fa3/a fa3/b fa3/cin fa3/cout fa3/sum fa4/a fa4/b fa4/cin fa4/cout fa4/sum

Finally, you can find a list of all nl commands with the command
list_commands, which prints out an alphabetical listing of all the nl
commands (not including any of the TCL built-in commands).  To find
out what any command does, you can use the -help option, which is
accepted by all nl commands.  For example:

  % find_pins -help
  Return the list of pins whose name matches the specified pattern.
  By default the pattern is matched according to the rules of string_match.

    Usage: find_pins [-exact] [-regexp] <string> [<design>]

    option              description

    -exact              the pin name should exactly match the pattern
    -regexp             the pin name should match the pattern

    argument            description

    <string>            pattern to match
    <design>            design in which to find the pins

