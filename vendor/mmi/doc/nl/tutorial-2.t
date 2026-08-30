NL_SHELL TUTORIAL


Part II. Hierarchy

The nl database is hierarchical.  There are a number of commands
associated with querying and manipulating the hierarchy.  This part of
the tutorial covers these commands.

First, read in the Verilog file from Part I of this tutorial.

  % read_verilog tutorial.v
  Current design is now "add4".
  full_adder add4
 
The read_verilog command reads in all designs (modules) in the
specified Verilog file.  However, even if the file contains a complete
hierarchical design, the read_verilog command does not recover the
hierarchy.  To do that, and to use any hierarchical features of
nl_shell, you first have to link the designs in the hierarchy
together.  Do this with the link command:

  % link
  Could not resolve reference 'MMI_XOR2B'
  Could not resolve reference 'MMI_XOR2A'
  Could not resolve reference 'MMI_NAND2A'
  Could not resolve reference 'MMI_NAND3B'

The link command simply visits all references in the design and tries
to find a design in memory with the same name as the reference.  If it
finds such a design, it links it to the reference as a subdesign, and
recursively links the subdesign.  The messages shown above indicate
that nl_shell was not able to find designs named MMI_XOR2B, etc. in
memory.  These designs are instantiated in full_adder, which is a
subdesign of add4.  We can ignore these messages for now.  Even though
the link command could not resolve these references, it did resolve
all other references (namely, by linking the full_adder reference in
add4 to the full_adder design).

Not that linking begins with the current design and traverses downward
through the hierarchy.  It is assumed that the current design is the
top-level design of the hierarchy.  nl_shell does not try to figure
out which design should be the top level.

The link can fail for a reference if either a design with the same
name as the reference cannot be found, or if the ports on the design
that was found do not match the pins on the corresponding reference.
In either case, a warning message is printed and that part of the
hierarchy remains unlinked.  It does not prevent the rest of the
hierarchy from being linked.

If you want to see the result of the link command, use the
report_hierarchy command.

  % report_hierarchy
  Hierarchy report for add4:

  add4
      full_adder: fa1 fa2 fa3 fa4
          MMI_XOR2B (unlinked)
          MMI_XOR2A (unlinked)
          MMI_NAND2A (unlinked)
          MMI_NAND3B (unlinked)

This report shows that the top-level module, add4, contains a
reference called full_adder with four instances: fa1, fa2, fa3, and
fa4.  The full adder reference is linked to a subdesign that contains
references MMI_XOR2B, MMI_XOR2A, MMI_NAND2A, and MMI_NAND3B.
Furthermore, the MMI references are unlinked.


