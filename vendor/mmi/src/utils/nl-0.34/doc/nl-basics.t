NL DATA STRUCTURE BASICS


When you read in a Verilog file, a set of designs is created.  A
design is analogous to a Verilog module.

Designs contain the following types of objects:

  cell - an instance, whether its an instance of a library cell or
    another design (module)
  net - a wire
  reference - a placeholder for a design.  In Verilog, you may see the
    instantiation of a design before you see the design itself; that's
    why we need references.
  port - a Verilog port

Consider the following Verilog module.


module m (a, b, x, y, z);
  input a, b;
  output x, y;
  inout z;

  wire s, t;

  m1 u1 (.p(a), .q(x), .r(s));
  m1 u2 (.p(a), .q(y), .r(t));
  m2 u3 (.u(s), .v(t), .w(z));

endmodule


The nl_design for this module would look something like this:

     design: m
       ports: a, b, x, y, z
       cells: u1, u2, u3
       nets:  a, b, x, y, z, s, t;
       references: m1, m2

Note that a, b, x, y, and z are both ports and nets.  In Verilog,
ports and nets can have the same name.  In nl, they also have the same
name, but they are distince objects.

Cells and ports contain pins, and pins are connected to nets.  So,
port "a" in the example above is represented like this in nl:

                                  +-----+   +------+
                           +------| pin |---| cell |
                           |      |     |   | "u1" |
                           |      +-----+   +------+
  +------+   +-----+    +-----+
  | port |---| pin |----| net |
  | "a"  |   |     |    | "a" |
  +------+   +-----+    +-----+
                           |
                           |      +-----+   +------+
                           +------| pin |---| cell |
                                  |     |   | "u2" |
                                  +-----+   +------+

Notice that I didn't put any names on the pins.  To save memory, the
names of pins are not stored on the pins of the cell, they are stored
on the pins of the reference, which are called "refpins."  So, the
cells and their references in the example above are represented this
way:


  +------------+             +-----------+          +-----------+
  |    cell    |-------------| reference |----------|   cell    |
  |    "u1"    |             |   "m1"    |          |   "u2"    |
  +------------+             +-----------+          +-----------+
    |   |   |                  |   |   |              |   |   |
    |   |   |                  |   |   |              |   |   |
    |   |  +-----+     +--------+  |   |         +-----+  |   |
    |   |  | pin |---->| refpin |<-+---+---------| pin |  |   |
    |   |  |     |     |  "p"   |  |   |         |     |  |   |
    |   |  +-----+     +--------+  |   |         +-----+  |   |
    |   |                          |   |                  |   |
    |  +-----+             +--------+  |             +-----+  |
    |  | pin |------------>| refpin |<-+-------------| pin |  |
    |  |     |             |  "q"   |  |             |     |  |
    |  +-----+             +--------+  |             +-----+  |
    |                                  |                      |
   +-----+                     +--------+                +-----+
   | pin |-------------------->| refpin |<---------------| pin |
   |     |                     |  "r"   |                |     |
   +-----+                     +--------+                +-----+


The lines in this diagram represent bidirectional links, unless they
end in "<" or ">".  So, the link from pins to refpins is
unidirectional--there is no direct link from a refpin to a pin.

From the diagram above, it's easy to see that if you want to get the
name of a pin, you first get its refpin, then get the name of the
refpin.

When a Verilog file is read in, you just get an unrelated set of
designs.  There are no links between the designs that represent the
hierarchical relationship between them.  To put the design into a
hierarchical structure, you have to "link" the design.  When the
design is linked, references are matched to designs by name, and links
are added to the references showing which design it represents.  The
"m1" reference in the above example might end up looking like this:


  +-----------+                  +-----------+
  | reference |----------------->|  design   |
  |    "m1"   |                  |   "m1"    |
  +-----------+                  +-----------+
    |   |   |                      |   |   |
    |   |   |                      |   |   |
    |   |  +--------+        +------+  |   |
    |   |  | refpin |------->| port |  |   |
    |   |  |  "p"   |        | "p"  |  |   |
    |   |  +--------+        +------+  |   |
    |   |                              |   |
    |  +--------+                +------+  |
    |  | refpin |--------------->| port |  |
    |  |  "q"   |                | "q"  |  |
    |  +--------+                +------+  |
    |                                      |
   +--------+                        +------+
   | refpin |----------------------->| port |
   |  "r"   |                        | "r"  |
   +--------+                        +------+

