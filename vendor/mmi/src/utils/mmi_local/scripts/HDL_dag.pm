package HDL_dag;

# Perl package to read a parsed token list (a .hdl file) and create a
# in memory data structures for a net-list and a cell array.

# John Johnson

# Mon Mar 29 10:56:31 1999

# Last edit: <010528.1705>
use strict;

# Use the Perl standard Exporter module. (see: Christaiansen and
# Torkington, "Perl Cookbook", O'Reilly, 1998, page 401.)

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGES $VERSION);
use Exporter;

$VERSION = 0.0;
@ISA = qw(Exporter);

# For testing, use HoRes timers.
# use Time::HiRes qw(gettimeofday);
# Don't use integer during HiRes test.

use integer;

# Every net is identified by one or more numbers, called 'net_id's,
# that are indexes into the @HDLN_netlist* arrays.  Every cell is also
# identified by an unique number, called a 'cell_id', that is an index
# into the @HDLN_cell_name array.

# A net list is built into the @HDLN_netlist* arrays.  Each
# @HDLN_netlist_cells element is a vector of cell_id connected to this
# element.  Each @HDLN_netlist_ports element of a vector of port
# numbers of the corresponding cell_ids.  $HDLN_netlist_cnt 'vec' data
# (32 bits per entry) is the number of entries in these vectors.
# HDLN_netlist_port_bit is the bit number within the pin that is used.

# There may be more than one net_id number to identify each net. All
# the id numbers for the same net are in a circular list.  This
# supports multiple names for a net, as well as connecting two nets
# together.  This circular linked list for each net is stored as
# $HDLN_netlist_clst as 'vec' data (32 bits per entry).  If there is
# only one element for the netlist, then this link points at itself.

# JDJ Fri Mar 10 11:44:27 2000: There currently is a bug in building the
# circular list when there is redundant assigns in the Verilog (ex:
# assign a = b; assign a = b;).  What happens is the relinking when
# an assign loop is found can break the circular list.

use vars '$HDLN_netlist_clst';   push(@EXPORT, '$HDLN_netlist_clst');
$HDLN_netlist_clst = '';

use vars '@HDLN_netlist_cells';  push(@EXPORT, '@HDLN_netlist_cells');
use vars '@HDLN_netlist_ports';  push(@EXPORT, '@HDLN_netlist_ports');
use vars '@HDLN_netlist_port_bit';  push(@EXPORT, '@HDLN_netlist_ports');
use vars '$HDLN_netlist_cnt';    push(@EXPORT, '$HDLN_netlist_cnt');

$HDLN_netlist_cnt = '';

# Keep track of how each declared signal is driven or used, needed to
# select the name when unassign are done.  Here, 'cell' means any
# called module, not just stuff from the cell library. If the signal
# is an input to the module, or an inout, then this is the driver
# type.  Type 'none' occurs when the net is not driven, or is driven
# by an assign. Unassign picks the largest found type value as the
# name for the "map to" signal during unassign subitution.

# Unassign also needs to know when a net is connect to a port of 
# the current module. Used the same ID constants as the driver types.

use vars '@HDLN_netlist_driver_type';    
use vars '@HDLN_netlist_port_type';
use vars '@HDLN_netlist_port_num';

use vars '$HDLN_driver_type_none';        $HDLN_driver_type_none         = 1;
use vars '$HDLN_driver_type_mod_output';  $HDLN_driver_type_mod_output   = 2;
use vars '$HDLN_driver_type_cell_input';  $HDLN_driver_type_cell_input   = 3;
use vars '$HDLN_driver_type_cell_inout';  $HDLN_driver_type_cell_inout   = 4;
use vars '$HDLN_driver_type_mod_inout';   $HDLN_driver_type_mod_inout    = 5;
use vars '$HDLN_driver_type_mod_input';   $HDLN_driver_type_mod_input    = 6;
use vars '$HDLN_driver_type_cell_output'; $HDLN_driver_type_cell_output  = 7;


# Port information about the driver type spepecified for the port is
# set into the HDLN_netlist_driver_type entry. The pid is the
# (-path_id) or (cell_id) of the connected port (i.e., the sign bit
# flags this is a negative module path_id, as opposed to a cell_id.

use vars '@HDLN_netlist_connected_pid';
use vars '@HDLN_netlist_connected_port';

# For some runs we need to know what nets a cell is connected to,
# instead of what cells a net is connected to.  For these runs we
# build the arrays below instead of the the netlist_cells and
# netlist_ports arrays above.  Which set is built is controlled by the
# HDLN_flatten flag.

use vars '@HDLN_connected_nets';   push(@EXPORT, '@HDLN_connected_nets');
use vars '@HDLN_connected_ports';  push(@EXPORT, '@HDLN_connected_ports');
use vars '$HDLN_connected_cnt';    push(@EXPORT, '$HDLN_connected_cnt');
$HDLN_connected_cnt = '';

use vars '$HDLN_flatten'; $HDLN_flatten = 0;

# Sometimes info from HDLN_netlist is cached.  Whenever you modify
# HDLN_netlist, you must also increment its time stamp
# $HDLN_netlist_ts.

use vars '$HDLN_netlist_ts'; $HDLN_netlist_ts = 0;

# Multiple Verilog signal names may point to a net.  If nets are
# connected with assign statement then there may be more that one
# name.  Modules calls also connect nets.

# Every net is assigned at least one name.  This the name assigned
# first has the lowest net_id number. The name is encoded as a record
# of numbers, and stored as a space separated string at each array
# element.  The numbers are indexes into other arrays.  This encoding
# is used to save memory.

# There are several special path_ids that mean the net is connected
# to a constant,  a primary input (or inout), or a primary output.

# Format is a  vec() of 4 32 bit entries.  Use a seperate
# string table for the names as indexing into the stored HLD data can
# be inefficent. (flatten chours.nl.v has a 2.8 mbyte statement!).

#format: <$path_id, $string_tbl_idx $bit_num, $do_range>

use vars '@HDLN_net_name'; 

use vars '$NET_NAME_PATH_ID'; $NET_NAME_PATH_ID       = 0;
use vars '$NET_NAME_STRING_IDX'; $NET_NAME_STRING_IDX = 1;
use vars '$NET_NAME_BIT_NUM'; $NET_NAME_BIT_NUM       = 2;
use vars '$NET_NAME_DO_RANGE'; $NET_NAME_DO_RANGE     = 3;

# The $NET_NAME_STRING_IDX is an index into the HDLN_string_table
# array.  To find out if a name is already in the array the
# %HDLN_string_hash is used.

use vars '@HDLN_string_table'; 
use vars '%HDLN_string_hash';

########################################################

# An elements of the @HDLN_cell_name array contains a record that
# names the module and cell instances.  To conserve memory these
# records are indexes into the original token data and other arrays.
# The format is:

#  < path_id lnum >

# This a space separated string of two numbers, where path_id is an
#  index into the HDLN_path_name array of module instance names and
# <lnum> is an index into the HDLN_hdl_toks arrays for the parsed
# Verilog.

use vars '@HDLN_cell_name'; 

use vars '$HDLN_CELL_NAME_PATH_ID'; $HDLN_CELL_NAME_PATH_ID = 0;
use vars '$HDLN_CELL_NAME_LNUM';    $HDLN_CELL_NAME_LNUM = 1;

# Don't use index zero, push something that is undefiend.
push(@HDLN_cell_name, "-1  -1");

# @HDLN_cell_is_seq is true if the cell is a sequential element,
# and false if it is combinational. It is indexed by a $cell_id.

use vars '@HDLN_cell_is_seq';

# @HDLN_cell_drives_nets is 'vec' data for net_ids that a cell
# drives.  @HDLN_cell_drives_nets is indexed by a $cell_id.
# @HDLN_cell_driving_pins is 'vec' data for the driving port number
# for each cell_id in the list (if there is only one driving port then
# all of these are the same).  $HDLN_cell_drives_cnt is 'vec' data for
# the number of cells each cell_id drives.

use vars '@HDLN_cell_drives_nets';
use vars '@HDLN_cell_driving_pins';
use vars '$HDLN_cell_drives_cnt'; $HDLN_cell_drives_cnt = '';

# @HDLN_cell_mod_id holds the mod_id that corresponds to the instance
# of each $cell_id.  This is the same information as HDLN_path_mod_id,
# but this is index by a cell_id instead of a path_id.  (If I was
# writing this again I would use only the path_mod_id array.)

use vars '@HDLN_cell_mod_id';

# @HDLN_cell_dag holds a space separated list of cell_id's that are
# driven by each cell (built by pass_three).

use vars '@HDLN_cell_dag';

#####################################################

# The HDLN_hdl_toks holds the entire input file.

use vars '@HDLN_hdl_toks'; 

# $HDLN_hdl_elements is the number of elements in @HDLN_hdl_toks.
# Don't use $#HDLN_hdl_toks as we may pre-allocate the array, thus
# $#HDLN_hdl_toks may not be the last valid index.

use vars '$HDLN_hdl_elements'; 

# The module call tree is traversed to create all of the instance path
# names.  This creates the module instances, and gives each
# instantiated module a unique ID.  The @HDLN_path_name holds the name
# for each instance of a module.  Indexes into this array are called
# path_id's.  Each path name stored in this array is a string
# constructed by concatenating of all the hierarchy module instance
# names together, separated by slashes.

use vars '@HDLN_path_name'; 
push(@EXPORT, '@HDLN_path_name');
@HDLN_path_name = ();

# Given a path_id, we sometimes need to map back to the module that was
# used to defined the hierarchical path. The @HDLN_path_mod_id holds
# an mod_id, which is the index into the @HDLN_mod_lnum[], and can be
# used to find the defining module.

use vars '@HDLN_path_mod_id'; 
push(@EXPORT, '@HDLN_path_mod_id');
@HDLN_path_mod_id = ();

# During unassiging, a table is built for each module of the
# nets that are connected to another net. The HDL_mod_connects
# is a array of references to these hashes.

use vars '@HDLN_mod_connects';

# While unassiging we need a table saying which path_ids need to be
# uniquified.  I'm making this a hash because it seems easier to code.
# I don't know if a hash or an array would be smaller.

use vars '%HDLN_uniquify_path_id';

# Unassign builds a table for each path_id that specifies which
# signals within a path's module needs to be connected the one signal
# name selected for the net. This is saved in the HDLN_unassign hash.

use vars '%HDLN_unassign';

# The driven net of the unassign group is specail
# (it can't be connected to multiple ouputs).  Keep track
# of the driver in each path_id.

use vars '%HDLN_unassign_driven';

# Given a path name, we need to be able to find it's path ID.  This is
# done with the %HDLN_path_id hash.  It stores path_ids, which are indexes
# into @HDLN_path_name.

use vars '%HDLN_path_id'; 
push(@EXPORT, '%HDLN_path_id');

# Given a wire name inside an instance of a module, we need to find
# its net_id.  For each instance of a module there is a hash that maps
# all the net names to the net_ids.  References to these hashes are
# stored in the @HDLN_wire_table_ref array. There is one element in
# the this array for each path_id, and it points to a built hash.

use vars '@HDLN_wire_table_ref'; 
push(@EXPORT, '@HDLN_wire_table_ref');

# During unassign, we do a 4'th pass that re-emits the module, uniquify
# them if needed.  HDLN_mod_used_by is an array of lists.  For each
# module there is a list of path_ids that use the module.

use vars '@HDLN_mod_used_by';

#######################################################################

# %HDLN_modules is a table identifying all the modules and cells
# defined in this design.  It is filled during the first pass scan of
# the hdl file.  The value of the store in each element is a mod_id,
# which is and index to the module information arrays.

use vars '%HDLN_modules'; 

# @HDLN_mod_name is an array that maps form a $mod_id into a name string.

use vars '@HDLN_mod_name'; 

# @HDLN_mod_def describes the module was definition type.  It is
# indexed by a $mod_id.

use vars '@HDLN_mod_def';
use vars '$HDLN_MOD_CELL'; $HDLN_MOD_CELL = 1;
use vars '$HDLN_MOD_MODULE'; $HDLN_MOD_MODULE = 2;
use vars '$HDLN_MOD_UNDEF'; $HDLN_MOD_UNDEF = 3;
use vars '$HDLN_MOD_UNDEF_REPORTED'; $HDLN_MOD_UNDEF_REPORTED = 4;

# @HDLN_mod_use_count is incremented whenever a module is statically
# called (including the cell calls).  This array is built during the
# both the first pass.  The first pass is needed to find the root
# module.  It is indexed by a $mod_id. N.B.: This not not a flatten
# netlist use count, only a static call use count.

use vars '@HDLN_mod_use_count';

# @HDLN_mod_lnum is the starting element in the HDL array of a 
# module  that is defined.

use vars '@HDLN_mod_lnum';

# @HDLN_mod_portorder_ref is a pointer to a hash of the port names.  The
# array is indexed by a mod_id, the hash is over the the port names.

# The data in the hash is port number in the order as they are defined
# by the module statement, and is a index in to the port_map array for
# each module.

use vars '@HDLN_mod_portorder_ref';

# @HDLN_mod_port_dirs is a 2 dimensional array that defines the
# I/O direction of each port for each module.  The other arrays
# flag if the port is a bus, it's leftmost bit, and the width.

use vars '@HDLN_mod_port_dirs';
use vars '@HDLN_mod_port_range';
use vars '@HDLN_mod_port_left_bit';
use vars '@HDLN_mod_port_size';

# Theses are the valid entries for each
# $HDLN_mod_port_dirs[$mod_id][$port_num]
# The DELETED is set during a unassign run.

use vars '$HDLN_PORT_DIR_INPUT';    
use vars '$HDLN_PORT_DIR_INOUT';    
use vars '$HDLN_PORT_DIR_OUTPUT'; 
$HDLN_PORT_DIR_INPUT =  $HDLN_driver_type_cell_input;
$HDLN_PORT_DIR_INOUT =  $HDLN_driver_type_cell_inout;
$HDLN_PORT_DIR_OUTPUT = $HDLN_driver_type_cell_output;

# @HDLN_mod_port_names is an array of arrays for the port names of
# each module, in port number order.

use vars '@HDLN_mod_port_names';

# @HDLN_mod_tristate array is true when a cell has any tristate
# outputs, and false if it does not.  It is indexed by a mod_id;

use vars '@HDLN_mod_tristate';

# @HDLN_mod_is_seq array is true when a cell is a flip-flop or other
# sequential element.  DAG searching stops at sequential cells.

use vars '@HDLN_mod_is_seq';

# %HDLN_seq_cells keeps track of the sequential cells found,
# for reporting.

push(@EXPORT, '%HDLN_seq_cells');
use vars '%HDLN_seq_cells';

# @HDLN_mod_is_scan array is true when a cell is a flip-flop or other
# sequential element that has scan.

use vars '@HDLN_mod_is_scan';

# The names of the tristate modules are in a global. For now they are
# build by the caller...

push(@EXPORT, '%HDLN_tristate_cells');
use vars '%HDLN_tristate_cells';  %HDLN_tristate_cells = ();

# The substring for names of the sequential modules are in a
# global. For now they are build by the caller...

push(@EXPORT, '@HDLN_seq_name_substr');
use vars '@HDLN_seq_name_substr';  @HDLN_seq_name_substr = ();

# The substring for names of the sequential modules that also have
# scan are in a global. For now they are build by the caller...

push(@EXPORT, '@HDLN_scan_name_substr');
use vars '@HDLN_scan_name_substr';  @HDLN_scan_name_substr = ();

# If undefined modules are found during net-listing then
# their names are kept in this hash.

use vars '%HDLN_undef_modules';
use vars '$HDLN_undefined_modules';

#################################################################

# Root modules are modules are the one that are defined but not
# called.  There should be at least one.

use vars '$HDLN_root_module_count'; $HDLN_root_module_count = 0;

# The last root module is where the net list is started.
# $HDLN_root_module holds the module name of the last root module.

use vars '$HDLN_root_module'; 
push(@EXPORT, '$HDLN_root_module');

use vars '$HDLN_root_mod_id';   
push(@EXPORT, '$HDLN_root_mod_id');

use vars '$root_path_id';

###################################################################

#  JDJ 990410: I'M NOT SURE THIS STILL WORKS...

# %HDLN_cell_types is the names of all the called cells.  $HDLN_cell is the
# number of unique cells. These are computed during by pass one.

use vars '%HDLN_cell_types'; 
use vars '$HDLN_cells'; $HDLN_cells = 0;

#######################################################################

# $HDLN_lnum is the current line number plus in in the hdl array.  

use vars '$HDLN_lnum'; $HDLN_lnum = 0;
push(@EXPORT, '$HDLN_lnum');

# @HDLN_fields are the HDLN_fields of the current line, $filed0 is the first
# field of the current line.  These are set by get_fields).  $HDLN_idx is
# the current index in the split fields, used in error reporting.

use vars '@HDLN_fields'; 
use vars '$HDLN_field0'; 
use vars '$HDLN_idx'; 

push(@EXPORT, '@HDLN_fields'); 
push(@EXPORT, '$HDLN_field0'); 
push(@EXPORT, '$HDLN_idx'); 

##########################################

# The names in a wire table hash may be bus names and refer to many
# bits.

# The format of one of these entries is:

# <range flag> <left bit> <size> <net_id> ....

# Where '<net_id> ...' is a list of net IDs, starting with the
# left-most bit and working to right.  How to increment this left bit
# number depends on if it is little endian (right>left) or big endian
# (left>right) bit order is used for the bus.  Define some constants
# that help keep this record straight.

use vars '$HDLN_NET_ID_RANGE_LITTLE';$HDLN_NET_ID_RANGE_LITTLE = 1;
use vars '$HDLN_NET_ID_RANGE_BIG';   $HDLN_NET_ID_RANGE_BIG = -1;
use vars '$HDLN_NET_ID_RANGE_NONE';  $HDLN_NET_ID_RANGE_NONE = 0;

use vars '$HDLN_NET_ID_RANGE_FLAG';  $HDLN_NET_ID_RANGE_FLAG = 0;
use vars '$HDLN_NET_ID_LEFT_BIT';    $HDLN_NET_ID_LEFT_BIT = 1;
use vars '$HDLN_NET_ID_BITS';        $HDLN_NET_ID_BITS = 2;
use vars '$HDLN_NET_ID_NETS';        $HDLN_NET_ID_NETS = 3;

push(@EXPORT,
 '$HDLN_NET_ID_RANGE_LITTLE',
 '$HDLN_NET_ID_RANGE_BIG',
 '$HDLN_NET_ID_RANGE_NONE',

 '$HDLN_NET_ID_RANGE_FLAG',
 '$HDLN_NET_ID_LEFT_BIT',
 '$HDLN_NET_ID_BITS',
 '$HDLN_NET_ID_NETS');

##########################################

# Constants also have net_id and they need a path_id.  Define this
# special path_id.

push(@HDLN_path_name, 'Supply0=');
push(@HDLN_path_mod_id, -1);  #Illegal
use vars '$PATH_ID_SUPPLY0';        $PATH_ID_SUPPLY0 = $#HDLN_path_name;

push(@HDLN_path_name, 'Supply1=');
push(@HDLN_path_mod_id, -2);  #Illegal
use vars '$PATH_ID_SUPPLY1';        $PATH_ID_SUPPLY1 = $#HDLN_path_name;

# path_id's less than or equal PATH_ID_CONST are constants.

push(@HDLN_path_name, 'Constant=');
push(@HDLN_path_mod_id, -3);  #Illegal
use vars '$PATH_ID_CONST';        $PATH_ID_CONST = $#HDLN_path_name;

# Input and outputs have special path_ids.

push(@HDLN_path_name, 'Root_Module_Input.');
push(@HDLN_path_mod_id, -4);  # Illegal.
use vars '$PATH_ID_INPUT';        $PATH_ID_INPUT = $#HDLN_path_name;

# Path ID <= $PATH_ID_INPUT are driven.

push(@HDLN_path_name, 'Root_Module_Output.');
push(@HDLN_path_mod_id, -5);  # Illegal.
use vars '$PATH_ID_OUTPUT';        $PATH_ID_OUTPUT = $#HDLN_path_name;


##########################################

# Here are some indexes into hdl lines.

# For cell instances lines, the cell name is store here:

use vars '$HDLN_INSTANCES_ID';        $HDLN_INSTANCES_ID = 4;
push(@EXPORT, '$HDLN_INSTANCES_ID');

# For cell instances lines, the instantiation name is store here:

use vars '$HDLN_INSTANCE_NAME';       $HDLN_INSTANCE_NAME = 9;
push(@EXPORT, '$HDLN_INSTANCE_NAME');

# For cell instances line, the number of parameters plus 1 is store here.

use vars '$HDLN_INSTANCE_PARAMS';       $HDLN_INSTANCE_PARAMS = 6;

# For module lines, the module name is at field 4

use vars '$HDLN_MODULE_NAME';       $HDLN_MODULE_NAME = 4;

#############################################################

# Many times the drivers of a given net are needed.  To make this
# efficient, the @HDLN_net_driver array may specify the driver for the
# net at index net_id.  Every net_id in the circular list has the same
# entry in this array.

use vars '@HDLN_net_driver';

# Same for the pointer to the best net name to use for a given net_id.

use vars '@HDLN_net_first_name';

# Since HDLN_net_driver is a form of a cache, it needs to be
# invalidated.  Keep track of time stamps.

use vars '$HDLN_net_driver_ts'; $HDLN_net_driver_ts = -1;

# Name of the open file

use vars '$HDL_file_name';
use vars '$HDL_file';

# Flags to say report progress in output file and STDERR

use vars '$HDLN_report'; push(@EXPORT, '$HDLN_report');
use vars '$HDLN_comment';  push(@EXPORT, '$HDLN_comment');  # No longer used...
use vars '$HDLN_unconnected_output_warn';  push(@EXPORT, '$HDLN_unconnected_output_warn');
use vars '$HDLN_unconnected_const_warn';  push(@EXPORT, '$HDLN_unconnected_const_warn');
use vars '$HDLN_unconnected_net_warn';  push(@EXPORT, '$HDLN_unconnected_net_warn');
use vars '$HDLN_implicit_wire_warn';  push(@EXPORT, '$HDLN_implicit_wire_warn');

use vars '$HDLN_implicit_wires';  push(@EXPORT, '$HDLN_implicit_wires');

use vars '$DAG_edges';
use vars '$HDLN_unconnected_output_cnt';

use vars '%HDLN_cone_report_truncate'; push(@EXPORT, '%HDLN_cone_report_truncate');
use vars '$HDLN_cone_delete_level'; push(@EXPORT, '$HDLN_cone_delete_level');
$HDLN_cone_delete_level = 2000000000;

# Originally the unique module named were created based on the path
# names, but these got too long for Apollo.

use vars '$long_names';
$long_names = 0;

############################################################

# This library has several different entry points that all call the
# main net-list subroutine with different parameters.  defined that
# function set;

use vars '$HDLN_task_type'; 
use vars '$TASK_REPORT_CONES'; $TASK_REPORT_CONES = 1;
use vars '$TASK_UNASSIGN'; $TASK_UNASSIGN = 2;
use vars '$TASK_NETLIST'; $TASK_NETLIST = 3;
use vars '$TASK_FLATTEN'; $TASK_FLATTEN = 4;

# This is a global used by the print routines
# that says to echo warning to both stderr and stdout.

use vars '$HDLN_Warn_Echo'; 

# Some runs want messages to go to stdout (net_check, etc.)  and some
# want them to go to stderr (unassign, which uses stdout in HDL
# format).

use vars '$HDLN_Msg_to_Stdout'; 

# This global is is used to pass a parameter to the 'do_netlist
# routine'.

use vars '$HDLN_do_netlist_report_net_name';

# The net_reports_ref is a array of cone type and
# and net names. These indexes define which is the type
# and which is the net name.

use vars '$HDLN_NET_REPORT_TYPE';
use vars '$HDLN_NET_REPORT_NAME';
push(@EXPORT, '$HDLN_NET_REPORT_TYPE');
push(@EXPORT, '$HDLN_NET_REPORT_NAME');
$HDLN_NET_REPORT_TYPE = 0;
$HDLN_NET_REPORT_NAME = 1;


#############################################################

push(@EXPORT, 'HDL_report_cones');
sub HDL_report_cones{
    my($cell_libs_ref, $verilog_files_ref, $report_seq, $dag_checks, $net_reports_ref) = @_;

    # Messages to stdout
    $HDLN_Msg_to_Stdout = 1;

    netlist($cell_libs_ref, $verilog_files_ref, $report_seq,
    $dag_checks, $net_reports_ref, $TASK_REPORT_CONES);
}

#############################################################

push(@EXPORT, 'HDL_unassign');
sub HDL_unassign{
    my($cell_libs_ref, $verilog_files_ref)=@_;

    my(@net_reports) = ();

    # Messages to stderr
    $HDLN_Msg_to_Stdout = 0;

    netlist($cell_libs_ref, $verilog_files_ref, 0, 0, \@net_reports,
    $TASK_UNASSIGN);
}

#############################################################

push(@EXPORT, 'HDL_netlist');
sub HDL_netlist{
    my($cell_libs_ref, $verilog_files_ref, $report_net_name)=@_;

    my(@net_reports) = ();

    # Copy the name reporting flag to a global because I don't
    # want to modify the netlist() calling parameters.

    $HDLN_do_netlist_report_net_name = $report_net_name;

    # Messages to errout.
    $HDLN_Msg_to_Stdout = 0;

    netlist($cell_libs_ref, $verilog_files_ref, 0, 0, \@net_reports,
    $TASK_NETLIST);
}

#############################################################

push(@EXPORT, 'HDL_flatten');
sub HDL_flatten{
    my($cell_libs_ref, $verilog_files_ref)=@_;

    my(@net_reports) = ();

    # Set the global flag the effects which netlist is generated.

    $HDLN_flatten = 1;

    # Messages to stderr
    $HDLN_Msg_to_Stdout = 0;

    netlist($cell_libs_ref, $verilog_files_ref, 0, 0, \@net_reports,
    $TASK_FLATTEN);
}

#############################################################

sub netlist{
    my($cell_libs_ref, $verilog_files_ref, $report_seq, $dag_checks,
    $net_reports_ref, $task) = @_;

    my($n);
    my($t);
    my($net_report_ref);
    my($rs);
    my($net);
    my($path_name);
    my($p1, $p2);
    my($msg);

    # Save run type in a global.
    $HDLN_task_type = $task;

    # See if STDOUT and STDERR are the same.
    # Print something to STDERR and check is STDOUT position changes.
    $p1 = tell(STDOUT);

    $msg = sprintf("Start time: %s\n\n", scalar localtime);
    warn("$0: $msg");
    $p2 = tell(STDOUT);
    $HDLN_Warn_Echo = ($p1 == $p2) && $HDLN_Msg_to_Stdout;
    if($HDLN_Warn_Echo){
	print("$msg");
    }

    my($start_time) = time();

    # Read in the net-list

    HDL_dag($cell_libs_ref, $verilog_files_ref);

    if($report_seq) {
	HDLN_print("Use count:    Tristate drivers:");
	foreach $t (sort keys(%HDLN_tristate_cells)){
	    $n =  $HDLN_tristate_cells{$t};
	    if($n) {

		$msg = sprintf(" %9d     $t", $n);
		HDLN_print($msg);
	    };
	}
	HDLN_print("Sequential (clocked) cells:");
	foreach $t (sort keys(%HDLN_seq_cells)){
	    $n =  $HDLN_seq_cells{$t};
	    if($n) {
		$msg = sprintf("  %9d     $t", $n);
		HDLN_print($msg);
	    }
	}
	HDLN_print(""); # Blank line
    }
    
    if($dag_checks) {

	do_scc_check();
    
	do_drivers_check();
    }

    if($task == $TASK_UNASSIGN){
	do_unassign();
	emit_unassign();
    }elsif($task == $TASK_NETLIST){
	do_netlist();
    }elsif($task == $TASK_FLATTEN){
	do_flatten();
    }

    foreach $net_report_ref (@{$net_reports_ref}){

	HDL_report_cone($net_report_ref);
    }

    $msg = sprintf("Stop time: %s\n", scalar localtime);
    HDLN_warn($msg);

    my($user, $system, $cuser, $csystem) = times();
    my($cpu) = $user + $system + $cuser + $csystem;
    my($etime) = time() - $start_time;
    $msg = sprintf("Elapsed time (min:sec): %d:%02d, CPU time: %d sec.\n", int($etime/60), $etime%60, $cpu); 
    HDLN_warn($msg);
}

#############################################################

push(@EXPORT, 'HDL_dag');
sub HDL_dag{
    my($cell_lib_ref, $input_file_ref) = @_;

    my($n);
    my($last_cell_lnum);
    my($mod_name);

    $HDLN_lnum = 0;
    $HDLN_unconnected_output_cnt = 0;
    $HDLN_implicit_wires = 0;

    # Pass 1, read in the modules.

    foreach $HDL_file_name (@$cell_lib_ref){
	if($HDL_file_name !~ /\.hdl$/){
	    $HDL_file_name = "verilog_parser $HDL_file_name |";
	}
	unless (open(HDL_FILE, $HDL_file_name)) {
	    die("$0: Can't open cell library file $HDL_file_name\n");
	};

	$HDL_file = *HDL_FILE;

	# Read the file, saying this is a cell library
	read_hdl_file($HDLN_MOD_CELL);
    };

    $last_cell_lnum = $HDLN_lnum;

    if($#$input_file_ref < 0){
	# no input files specified, use STDIN
	$HDL_file = *STDIN;
	$HDL_file_name = "STDIN";

	# Read the file, saying these are modules in the design
	read_hdl_file($HDLN_MOD_MODULE);

    }else{

	foreach $HDL_file_name (@$input_file_ref){
	    #warn("HDL_file_name=$HDL_file_name\n");
	    if($HDL_file_name !~ /\.hdl$/){
		$HDL_file_name = "verilog_parser $HDL_file_name |";
		#warn("new HDL_file_name=$HDL_file_name\n");
	    }
	    unless (open(HDL_FILE, $HDL_file_name)) {
		die("$0: Can't open input file $HDL_file_name\n");
	    };
	    $HDL_file = *HDL_FILE;

	    # Read the file, saying these are modules in the design

	    read_hdl_file($HDLN_MOD_MODULE);
	};
    };

    if($HDLN_lnum == $last_cell_lnum){
	HDLN_warn("No input modules.");
	die("Aborting\n");
    }

    find_root();

# Pass 2, build the netlist

    $HDLN_undefined_modules = 0;
    pass_two();

    if($HDLN_undefined_modules) {
	HDLN_warn("Undefined modules:");
	foreach $mod_name (sort keys %HDLN_undef_modules){
	    HDLN_warn("\t$mod_name");
	}
	die("Aborting\n");
    }

    $n = $#HDLN_cell_name;  # cell_id zero is not used.
    HDLN_warn("");
    HDLN_warn("Instantiated $n cells.");
    if($HDLN_unconnected_output_cnt){
	if($HDLN_unconnected_output_warn){
	    HDLN_warn("Found $HDLN_unconnected_output_cnt cells without output connections.");
	}else{
	    HDLN_warn("Found $HDLN_unconnected_output_cnt cells without output connections (+o to report).");
	}
    }

    # pass 3, build the dag, if needed.

    if(!$HDLN_flatten){
	pass_three();
	HDLN_warn("Built $DAG_edges DAG edges.");
    }
}

#########################################################

# find_root: read the file, build the module tables.

sub find_root{

    # Find out if any of the modules are called twice.

    my($mod_id);
    
    if(defined($HDLN_root_module)){
	# The root module was set by a run string option.
	if(!defined($mod_id=$HDLN_modules{$HDLN_root_module})){
	    fatal("Specified root module '$HDLN_root_module' is not defined.");
	}
	if($HDLN_mod_def[$mod_id] == $HDLN_MOD_CELL){
	    fatal("Can't flatten '$HDLN_root_module' because it's a library cell.");
	}elsif($HDLN_mod_def[$mod_id] != $HDLN_MOD_MODULE){
	    fatal("Specified root module '$HDLN_root_module' is called but not defined.");
	}

	$HDLN_root_mod_id = $mod_id;
	$HDLN_root_module_count = 1;

    }else{


	if($HDLN_report){
	    # Info only, don't echo to output file.
	    warn("$0: Finding root module...\n");
	};

	for($mod_id=0; $mod_id<=$#HDLN_mod_def; $mod_id++){

	    if(($HDLN_mod_def[$mod_id] == $HDLN_MOD_MODULE) &&
	       ($HDLN_mod_use_count[$mod_id] == 0)) {

		# A root module is not called.

		$HDLN_root_module_count++;

		# Remember the last one as to where to start the
		# netlist.

		$HDLN_root_module = $HDLN_mod_name[$mod_id];
		$HDLN_root_mod_id = $mod_id;
	    
		HDLN_warn("Root module is '$HDLN_root_module'.");
	    };
	}
    }
}

################################################

# Setup some globals to old the fields of the current statement.

# During net listing this get_names function may call this routine
# many times with the same line number.  The line (statement) can be
# very long (2.8Megbytes in the case of flattened chorus.nl.v. 
#

use vars '$cached_lnum'; $cached_lnum = -1;

sub get_fields{

    if($HDLN_lnum != $cached_lnum){
	@HDLN_fields  = split(' ', $HDLN_hdl_toks[$HDLN_lnum]);
	$cached_lnum = $HDLN_lnum;

	$HDLN_field0 = $HDLN_fields[0];
	$HDLN_lnum++;
	$HDLN_idx=0;
    }
}

####################################################

# Define a new module or cell

sub module
{
    my($mod_def) = @_;

    my($mod_id);

    # The id name follows after the module keyword.

    if($HDLN_fields[2] ne 'id'){
	fatal("Expected 'id' after module, but found $HDLN_fields[2].\n");
    };

    $mod_id = define_module($HDLN_fields[$HDLN_MODULE_NAME],
		  $mod_def, $HDLN_lnum-1);
};

####################################################

# Define a new module or cell

sub define_module
{
    my($name, $mod_def, $lnum) = @_;

    my($mod_id);
    my($is_seq);
    my($is_scan);
    my($substr);

    if(defined($mod_id=$HDLN_modules{$name})){
	if($HDLN_mod_def[$mod_id] != $HDLN_MOD_UNDEF){
	    HDLN_warn("WARNING -- redefining module '$name'.");
	};
    } else {
	$mod_id = $#HDLN_mod_name+1;

	$HDLN_modules{$name} = $mod_id;
	$HDLN_mod_name[$mod_id] = $name;
	$HDLN_mod_use_count[$mod_id] = 0;
    };

    # If is a flip-flop we want to keep track of of it.
    # Loop over the array of substring name for flip-flops.

    $is_scan = 0;
    $is_seq = 0;
    foreach $substr (@HDLN_seq_name_substr){
	$is_seq |= (index($name, $substr) >= 0);
    };

    # If this is a library cell then define it as sequential and set
    # its use count to zero.

    if($is_seq && ($mod_def == $HDLN_MOD_CELL)) {
	$HDLN_seq_cells{$name} = 0;

	# Flag the cells that have scan chain pins.

	foreach $substr (@HDLN_scan_name_substr){
	    $is_scan |= (index($name, $substr) >= 0);
	};
    };

    $HDLN_mod_is_seq[$mod_id] = $is_seq;
    $HDLN_mod_is_scan[$mod_id] = $is_scan;
    $HDLN_mod_def[$mod_id] = $mod_def;
    $HDLN_mod_lnum[$mod_id] = $lnum;
    $HDLN_mod_portorder_ref[$mod_id] = ();
    $HDLN_mod_tristate[$mod_id] = defined($HDLN_tristate_cells{$name});

    return $mod_id;
};

###########################################

# make_portorder -- Build the port order hash for the module specified
# by $called_mod_id

sub make_portorder{
    my($mod_id) = @_;

    my($formal_port_cnt);
    my($port_num);

    my(%portorder) = ();
    my(@port_names) = ();

    $HDLN_idx = 1;

    $formal_port_cnt = $HDLN_fields[$HDLN_idx];
    $port_num = 0;
	
    $HDLN_idx++;

    for($port_num=0; $port_num<$formal_port_cnt; $port_num++){
	    
	if($HDLN_fields[$HDLN_idx] ne 'id'){
	    fatal("make_portorder: For port number $port_num, expected 'id' but found '$HDLN_fields[$HDLN_idx]'");
	};
	    
	$HDLN_idx+=2;

	$portorder{$HDLN_fields[$HDLN_idx]} = $port_num;
	push(@port_names, $HDLN_fields[$HDLN_idx]);

	$HDLN_idx++;

    }; # for $port_num

    
    $HDLN_mod_portorder_ref[$mod_id] = \%portorder;
    $HDLN_mod_port_names[$mod_id] = [@port_names];
}

###########################################

# define_ios -- Add to the direction of the I/O ports.

# This is called during the first pass and saves the width of the
# busses and the direction.  HDL statement is setup in the globals.

sub define_ios{
    my($mod_id, $io_type) = @_;

    my($cnt, $cnt_lim);

    my($tok);
    my($port_name);
    my($port_num);
    my($do_range);
    my($left);
    my($right);
    my($size);

    my($portorder_ref) = $HDLN_mod_portorder_ref[$mod_id];

    $HDLN_idx = 1;  # Bump to the count.
    $cnt_lim = $HDLN_fields[$HDLN_idx];

    # Save the scalar/vector info.

    # Setup for no range specified.
    $do_range = $HDLN_NET_ID_RANGE_NONE; 
    $left = 0;
    $size = 1;

    for($cnt=1; $cnt<=$cnt_lim; $cnt++){
	
	$HDLN_idx++; 
	$tok = $HDLN_fields[$HDLN_idx];
	
	# print("define_ios: cnt=$cnt; tok=$tok\n");
	
	if($tok eq 'range') {
	    
	    $HDLN_idx++; 
	    if($HDLN_fields[$HDLN_idx] != 2) {
		fatal("Expected 'range 2', but found 'range $HDLN_fields[$HDLN_idx]'.");
	    }
	    
	    $HDLN_idx++; 
	    if($HDLN_fields[$HDLN_idx] ne 'num') {
		fatal("Expected range 2, 'num', but found '$HDLN_fields[$HDLN_idx]'.");
	    }
	    
	    $HDLN_idx += 2;  # Skip '0' level count.

	    $left = $HDLN_fields[$HDLN_idx];

	    # Skip the original number string and bump to the second
	    # num field.

	    $HDLN_idx += 2;
	    
	    if($HDLN_fields[$HDLN_idx] ne 'num') {
		fatal("Expected range 2, num, 'num', but found '$HDLN_fields[$HDLN_idx]'.");
	    }
	    
	    $HDLN_idx += 2;  # Skip '0' level count.

	    $right = $HDLN_fields[$HDLN_idx];

	    $HDLN_idx++; # now it points at the second number.

	    # Setup using do_range as a loop control.
	    if($left >= $right){
		$size = $left-$right+1;
		$do_range = $HDLN_NET_ID_RANGE_BIG;
	    } else {
		$size = $right-$left+1;
		$do_range = $HDLN_NET_ID_RANGE_LITTLE;
	    }

	} elsif ($tok eq 'id') {
	    
	    # This is a net to add.
	    
	    $HDLN_idx += 2; # Skip to name token.

	    $port_name = $HDLN_fields[$HDLN_idx];
	    
	    # print("define_ios: net=$port_name left=$left, right=$right\n");
	    
	    if(! defined($port_num=$portorder_ref->{$port_name})){
		HDLN_warn("In module $HDLN_mod_name[$mod_id], $HDLN_fields[0] '$port_name' not found in port list.");
	    } else {
		$HDLN_mod_port_dirs[$mod_id][$port_num] = $io_type;
		$HDLN_mod_port_range[$mod_id][$port_num] = $do_range;
		$HDLN_mod_port_left_bit[$mod_id][$port_num] = $left;
		$HDLN_mod_port_size[$mod_id][$port_num] = $size;
	    }
	    
	} else {
	    
	    fatal("define_ios: Expected 'range' or 'id', but found '$HDLN_fields[$HDLN_idx]'");
	    
	};
    } # for $cnt
}

####################################################

# Count the number of times each module is instantiated.

sub instances{

    my($mod_id);

    if($HDLN_fields[1] != 2){
	fatal("Expected 'instances 2', but found 'instances $HDLN_fields[1]'!
This version only supports one instance per module call.");
    };

    if($HDLN_fields[2] ne 'id'){
	fatal("Expected 'instances 2, id', but found 'instances 2, $HDLN_fields[2]'.")
    };

    if(!defined(($mod_id=$HDLN_modules{$HDLN_fields[$HDLN_INSTANCES_ID]}))){
	$mod_id = define_module($HDLN_fields[$HDLN_INSTANCES_ID],
				$HDLN_MOD_UNDEF, -1);
    }

    $HDLN_mod_use_count[$mod_id]++;
}

####################################################

# Read the input file.  Join lines together so that less memory is
# used, and it's faster to parse.  The result is one element for
# each level-1 token type.

sub read_hdl_file{
    my($mod_def) = @_;

# %expected is the hash of top level tokens this program is prepared to handle.

    my(%expected) = qw(
        module 1
        portorder 2
	instances 3
        input  4
        output 4
	inout  4
        wire 6
	assign 7
	supply0 8
        supply1 9
	trireg 10
        register 11
	always 12
        gate 13);

    my($type);
    my($mod_id);

    my(%io_type) = ('input',  $HDLN_PORT_DIR_INPUT,
		    'output', $HDLN_PORT_DIR_OUTPUT,
		    'inout',  $HDLN_PORT_DIR_INOUT);

    my($line_cnt) = 0;
    my($char_cnt) = 0;
    my($line);
    my($eat_lim);
    my($eat_cnt);
    my($l);
    my($err_HDLN_lnum);
    
    if($HDL_file_name eq 'STDIN'){
	HDLN_warn("Reading from STDIN.");
    }else{
	HDLN_warn("Reading file '$HDL_file_name'.");
    }

    while(defined($line=<$HDL_file>)){
	$line_cnt++;

	@HDLN_fields = split(/\s/, $line);
	$HDLN_field0 = $HDLN_fields[0];
         
        # print("read_hdl_toks: HDLN_field0=$HDLN_field0\n");

	if(defined($type=$expected{$HDLN_field0})){
	    if($type == 1){ # 'module'
		# Extend the line to include the module ID.
		$line .= <$HDL_file>;
		$line_cnt++;

	    } else {
		# Pack this level into one line.
		$eat_lim = $HDLN_fields[1];
		for($eat_cnt=0; $eat_cnt<$eat_lim; $eat_cnt++){
		    $l = <$HDL_file>;
		    $line_cnt++;

		    @HDLN_fields = split(/\s/, $l); 
		    $eat_lim += $HDLN_fields[1];

		    $line .= $l;
		}
	    };
	    $HDLN_hdl_toks[$HDLN_lnum++] = $line;
	    $char_cnt += length($line);

	    if($type == 1){ # module
		@HDLN_fields = split(/\s/, $line);
		$mod_id = module($mod_def);
	    }elsif($type == 2) { # portorder
		@HDLN_fields = split(/\s/, $line);
		make_portorder($mod_id);
	    }elsif($type == 3) { # instances
		@HDLN_fields = split(/\s/, $line);
		instances();
	    }elsif($type == 4) { # input, output, inout
		@HDLN_fields = split(/\s/, $line);
		define_ios($mod_id, $io_type{$HDLN_field0});
	    };

	} else {
	    $err_HDLN_lnum = $line_cnt-1;
	    die("$0: unexpected token type at line $err_HDLN_lnum:\n\t$line\n");
	};
    };

    $HDLN_hdl_elements = $HDLN_lnum;
    return ($line_cnt, $char_cnt);
}

####################################################

# pass_two: Start at the root and build the net list.

sub pass_two{

    use vars '%P2_IS_NET';
    use vars '$P2_NET_TYPE_INPUT';local($P2_NET_TYPE_INPUT) = 1;
    use vars '$P2_NET_TYPE_OUTPUT';local($P2_NET_TYPE_OUTPUT) = 2;
    use vars '$P2_NET_TYPE_SUPPLY0';local($P2_NET_TYPE_SUPPLY0) = 3;
    use vars '$P2_NET_TYPE_SUPPLY1';local($P2_NET_TYPE_SUPPLY1) = 4;

    local(%P2_IS_NET) =  (
			  'input' => $P2_NET_TYPE_INPUT,
			  'inout' => $P2_NET_TYPE_INPUT, # same as input
			  'output' => $P2_NET_TYPE_OUTPUT,
			  'supply0' => $P2_NET_TYPE_SUPPLY0,
			  'supply1' => $P2_NET_TYPE_SUPPLY1,
			  'wire' => 5);
			  
# The current hierarchical path is maintained in $P2_path.

    use vars '$P2_path'; local($P2_path) = '';


    netlist_module($HDLN_root_mod_id, '');
}

####################################################

# net_list_module: Recursive subroutine that builds the netlist for a
# module, calls itself for any called modules.

sub netlist_module{
    my($mod_id,  $instance_name, $port_map_ref) = @_;

# $mod_id is the index into hdl_toks for the start of the module.

# $instance_name is the module instance name given to this module,
# used to build the hierarchal path name.  For the root module,
# $instance name is blank.

# $port_map_ref is a reference to an array that holds the net_id's for
# the passed in parameters, in parameter order.

# $portorder_ref is a reference to a hash that maps each input/output
# name into its index into the port_map array.  This information comes
# from the HDL portorder token for this module, and is needed before
# this subroutine is called.

    my($portorder_ref);

    my($path_save);
    my($lnum_save) = $HDLN_lnum;

    my(%wire_table);
    my(%cell_table);

    my($called_mod);
    my($called_mod_id);

    my(@called_port_map);  
    my($called_instance_name);
    
    my($path_id);
    my($path_name);
    my($net_path_id);
    my($net_type);

    # warn("netlist_module: mod_id=$mod_id name=$HDLN_mod_name[$mod_id] instance=$instance_name\n");

    # Reset the scanner to the start of this module.

    $HDLN_lnum = $HDLN_mod_lnum[$mod_id];

    get_fields();

    if($HDLN_field0 ne 'module'){
	fatal("netlist_module: Expected 'module', but found '$HDLN_field0'.");
    };

    $path_save = $P2_path;

    # Don't start the root with a slash.
    if($mod_id == $HDLN_root_mod_id){
	$P2_path = '';
	$path_name = $HDLN_root_module;
	# JDJ Tue Nov 14 15:46:14 2000: use real portorder for root module too.
        # $portorder_ref = ();
	$portorder_ref = $HDLN_mod_portorder_ref[$mod_id];
	$root_path_id = @HDLN_path_name;  # Use '@' before the push.
    }else{
	$P2_path = "$P2_path$instance_name/";
	$path_name = $P2_path;
	$portorder_ref = $HDLN_mod_portorder_ref[$mod_id];
    };
    
    # warn("netlist_module: Set path to      $P2_path\n");

    # Instantiate this module by adding it to the HDLN_path_name array.

    push(@HDLN_path_name, $P2_path);

    # Removing assigns requires mapping form a path back to the module
    # it came from.  Keep track of mod_id for this path.

    push(@HDLN_path_mod_id, $mod_id);

    $path_id = $#HDLN_path_name;

    # Save away the list of path_id's that use this module, for
    # re-emitting during unassign.

    push(@{$HDLN_mod_used_by[$mod_id]}, $path_id);
    
    $HDLN_path_id{$path_name} = $path_id;

    # warn("netlist_module: set HDLN_path_id\{$path_name\} = $HDLN_path_id{$path_name}\n");

    while($HDLN_lnum<$HDLN_hdl_elements) {
	
	get_fields();
	
	# warn("netlist_module: dispatch on '$HDLN_field0'.\n");

	if($HDLN_field0 eq 'module'){

	    # Finished with this module

	    last;

	} elsif ($HDLN_field0 eq 'instances'){

	    $called_mod = $HDLN_fields[$HDLN_INSTANCES_ID];

	    if(!defined($called_mod_id=$HDLN_modules{$called_mod})){
		if(!defined($HDLN_undef_modules{$called_mod})){
		    HDLN_warn("Module '$called_mod' is undefined, used in module $HDLN_mod_name[$mod_id]");
		}
		$HDLN_undef_modules{$called_mod} = 1;
		$HDLN_undefined_modules++;

	    }else{
	    
		if($HDLN_mod_def[$called_mod_id] == $HDLN_MOD_MODULE){
		    # This is a module in this design, go instantiate it.
		    # warn(" called_mod_id: $called_mod_id\n");

		    $called_instance_name =  $HDLN_fields[$HDLN_INSTANCE_NAME];

		    map_params($path_id, $called_mod_id, \%wire_table,
			    \@called_port_map);

		    netlist_module($called_mod_id, 
			       $called_instance_name, 
			       \@called_port_map);

		} else {
		    # Else it's a cell
		
		    make_cell($called_mod_id, \%cell_table, $path_id, \%wire_table);
		}
	    }

	} elsif(defined($net_type=$P2_IS_NET{$HDLN_field0})) {
	    
	    # Make this declaration into a net if needed.
	    # If it's a supply net, flag is as a constant
	    # instead of being part of this instance.

	    if($net_type == $P2_NET_TYPE_SUPPLY0){
		$net_path_id = $PATH_ID_SUPPLY0;
	    }elsif($net_type == $P2_NET_TYPE_SUPPLY1){
		$net_path_id = $PATH_ID_SUPPLY1;

	#JDJ ... primary not special any more.
	#    }elsif($mod_id==$HDLN_root_mod_id){
	#	if($net_type==$P2_NET_TYPE_INPUT){
	#	    $net_path_id = $PATH_ID_INPUT;
	#	}elsif($net_type==$P2_NET_TYPE_OUTPUT){
	#	    $net_path_id = $PATH_ID_OUTPUT;
	#	}else{
	#	    $net_path_id = $path_id;
	#	}

	    }else{
		$net_path_id = $path_id;
	    };

	    make_net(\%wire_table, $net_path_id, $portorder_ref, $port_map_ref);

	} elsif ($HDLN_field0 eq 'assign'){

	    make_assign($path_id, \%wire_table);

	} elsif ($HDLN_field0 eq 'portorder'){
	    # These are skipped here, handled by a module call.
	} else {
	    # Report unexpected token.
	    fatal("netlist_module: unexpected level-1 token: '$HDLN_field0'");
	};
    } # while

    $HDLN_wire_table_ref[$path_id] = \%wire_table;

    # $HDLN_cell_table_ref[$path_id] = \%cell_table;

    $P2_path = $path_save;
    $HDLN_lnum = $lnum_save;

    # warn("netlist_module: Restored path to $P2_path\n");
}

####################################################

# make_assign -- Take a net assignment and
# and connect it into the net-list.

# Note: Verilog assigns are not really net connections as the Verilog
# assigns have direction, i.e., the receiver must be on the left hand
# side of the assign.  Here we are building net-list and don't known
# anything about drivers.

# This net-list program is only able to handle connecting one Verilog
# signal to another signal, it in not able to deal with any behavioral
# expression in an assign statement.

sub make_assign{
    my($path_id, $wire_table_ref) = @_;

    my(@lhs_nets);
    my(@rhs_nets);

    my($net_idx);
    my($net_lim);

    my($lhs_net);
    my($rhs_net);

    my($lhs_width);
    my($rhs_width);

    if($HDLN_fields[$HDLN_idx+1] != 1){
	fatal("make_assign: $P2_path:
   Expected hdl to start with 'assign 1', but found '$HDLN_fields[$HDLN_idx] $HDLN_fields[$HDLN_idx+1]'");
    };

    $HDLN_idx+=2;  # Bump to token count past first assign keyword.

    if(($HDLN_fields[$HDLN_idx] ne 'assign') || ($HDLN_fields[$HDLN_idx+1] != 3)){
	fatal("make_assign: $P2_path:
  Expected second hdl assign token to be 'assign 3', but found '$HDLN_fields[$HDLN_idx] $HDLN_fields[$HDLN_idx+1]'");
    };

    $HDLN_idx+=2;  # Bump to token count past second assign keyword.

    get_nets($path_id, $wire_table_ref, \@lhs_nets);

    # print("make_assign: lhs_nets=@lhs_nets\n");

    if($HDLN_fields[$HDLN_idx] ne 'nop'){
	fatal("make_assign: Expected second hdl assign token 'nop', but found '$HDLN_fields[$HDLN_idx]'");
    };

    $HDLN_idx+=2;  # Bump over nop's 0.

    if(!(($HDLN_fields[$HDLN_idx] eq 'id') || 
       ($HDLN_fields[$HDLN_idx] eq 'num') ||
       ($HDLN_fields[$HDLN_idx] eq 'bit') ||
       ($HDLN_fields[$HDLN_idx] eq 'multiconcat') ||
       ($HDLN_fields[$HDLN_idx] eq 'concat'))){
	fatal("make_assign:  $P2_path:
Assign right hand side must be 'id', 'bit', or 'concat', 'multiconcat',
but found '$HDLN_fields[$HDLN_idx]'");
    };

    get_nets($path_id, $wire_table_ref, \@rhs_nets);

    # warn("make_assign: rhs_nets=@rhs_nets\n");

    $net_lim = $#lhs_nets;
    if($#lhs_nets != $#rhs_nets){
	$lhs_width = $#lhs_nets + 1;
	$rhs_width = $#rhs_nets + 1;
	fatal("make_assign:  $P2_path:
    Assigns left hand side width ($lhs_width bits) not equal to 
    right hand size width ($rhs_width bits).\n"); 

	# Pick the smallest.

	if($#lhs_nets > $#rhs_nets){
            $#lhs_nets = $#rhs_nets;
	}else{
            $#rhs_nets = $#lhs_nets;
	}
    }

    for($net_idx=0; $net_idx<=$net_lim; $net_idx++){

	$lhs_net = $lhs_nets[$net_idx];
	$rhs_net = $rhs_nets[$net_idx];
	connect_nets($lhs_net, $rhs_net);

    } # for $net_idx
}

####################################################

# get_nets -- Build an array of net_ids for the signal description
# at the current HDLN_idx.  Handles 'id', 'bit', 'concat' and 'multiconcat'.

sub get_nets{
    my($path_id, $wire_table_ref, $nets_array_ref) = @_;

    my($has_bit);
    my($has_range);
    my($concat);
    my($concat_lim);
    my($tok);
    my($net_rec);

    my($wire);
    my($idx);
    my($idx_lim);
    my(@net_info);

    my(@multi_nets);
    my($multi);
    my($multi_cnt);

    # print("\nget_nets: HDLN_fields=@HDLN_fields\n");

    if($HDLN_fields[$HDLN_idx] eq 'multiconcat'){
	$HDLN_idx++;  # Bump to multiconcat token count.
	if($HDLN_fields[$HDLN_idx] != 2){
	    fatal("get_nets: Expected 'multiconcat 2', but found 'multiconcat $HDLN_fields[$HDLN_idx]'");
	}

	$HDLN_idx++;  # Bump to multi repeat count

	if($HDLN_fields[$HDLN_idx] ne 'num'){
	    fatal("get_nets: Expected 'multiconcat 2 num', but found 'multiconcat 2 $HDLN_fields[$HDLN_idx]'");
	}

	$HDLN_idx+=2;

	$multi_cnt = $HDLN_fields[$HDLN_idx];

	if($multi_cnt <= 0){
	    fatal("get_nets: multi-concat count must be > 0, but found $multi_cnt.'");
	}

	$HDLN_idx+=2;  # Bump to concat.

	if($HDLN_fields[$HDLN_idx] ne 'concat'){
	    fatal("get_nets: Expected 'multiconcat 2 concat', but found 'multiconcat 2 concat $HDLN_fields[$HDLN_idx]'");
	}

	#recursive call.
	get_nets($path_id, $wire_table_ref, \@multi_nets);

	@$nets_array_ref = (); # Empty the array

	# Push n copies of the concat onto the array.
	for($multi=0; $multi<$multi_cnt; $multi++){
	     push(@{$nets_array_ref}, @multi_nets);
	 };
	return;
    };  # if multiconcat

    if($HDLN_fields[$HDLN_idx] eq 'concat'){

	$HDLN_idx++;  # Bump to concat count.
	$concat_lim = $HDLN_fields[$HDLN_idx] - 1;
	
	$HDLN_idx++;  # Bump to the signal id.

	@{$nets_array_ref} = (); # Empty the array

	# print("get_nets: start concat loop: concat_lim=$concat_lim\n");

	for($concat=0; $concat<=$concat_lim; $concat++){
	    #recursive call.
	    get_nets($path_id, $wire_table_ref, \@multi_nets);
	    push(@{$nets_array_ref}, @multi_nets);
	};
	return;
    };

    # Check to see if there is a bit or range numbers for this wire.
    # If so, get it and bump the HDLN_idx.
	
    if($HDLN_fields[$HDLN_idx] ne 'bit') {
	$has_bit = 0;  # No bit number after this ID
    }else{
	# skip to count
	$HDLN_idx++;
	if($HDLN_fields[$HDLN_idx] != 2){
	    fatal("get_nets: For $P2_path:
   Expected 'bit 2' but found 'bit $HDLN_fields[$HDLN_idx]");
	};
	$has_bit = 1;  # remember this one has a bit number.
	$HDLN_idx++; # Skip to id for wire name.
    }
    
    if($HDLN_fields[$HDLN_idx] ne 'range') {
	$has_range = 0;  # No bit number after this ID
    }else{
	# skip to count
	$HDLN_idx++;
	if($HDLN_fields[$HDLN_idx] != 3){
	    fatal("get_nets: For $P2_path:
    Expected 'range 3' but found 'range $HDLN_fields[$HDLN_idx]");
	};
	$has_range = 1;  # remember this one has a bit number.
	$HDLN_idx++; # Skip to id for wire name.
    }
    
    $tok = $HDLN_fields[$HDLN_idx];
    
    # print("get_nets: concat loop: concat=$concat tok=$tok has_bit=$has_bit has_range=$has_range HDLN_idx=$HDLN_idx\n");
    
    if($tok eq 'num') {
	
	# This pin is connected to a number, not an wire.
	# Make a new net if needed.
	
	if($has_bit){
	    fatal("get_nets: For $P2_path:
   Bit specification not allowed on constants $HDLN_fields[$HDLN_idx]");
	}
	if($has_range){
	    fatal("get_nets: For $P2_path:
   Range specification not allowed on constants $HDLN_fields[$HDLN_idx]");
	}
	
	$HDLN_idx+=3; # Skip to number's name.
	$wire = $HDLN_fields[$HDLN_idx];
	
	# Don't put this in the wire table, but create a 
	# net for it.
	$net_rec = new_const_net();
	
    } elsif($tok eq 'id') {
	
	$HDLN_idx+=2; # Skip to wire name.
	$wire = $HDLN_fields[$HDLN_idx];
	
	# warn("get_nets: looking up wire=$wire\n");
	
	if(! defined($net_rec=$wire_table_ref->{$wire})){
	    if($HDLN_implicit_wire_warn){
		HDLN_print("Declaring implicit wire '$wire'.");
	    }
	    $HDLN_implicit_wires++;
	    # Net name is in $HDLN_fields[$HDLN_idx].
	    new_net($HDLN_NET_ID_RANGE_NONE, 0, 1, $path_id, $wire_table_ref);
	    $net_rec=$wire_table_ref->{$wire};
	};
	
    } else {
	fatal("get_nets: For $P2_path:
   Expected to 'id' or 'num' for signal name, but found '$tok'.\n");
    };
    
    @net_info = split(/ /, $net_rec);
    
    # print("get_nets: For $wire, net_info=@net_info\n");

    if($has_bit || $has_range) {
	$idx = get_range_idx(\@net_info);
	if($has_range) {
	    $idx_lim = get_range_idx(\@net_info);
	} else {
	    $idx_lim = $idx;
	};
    } else { 
	# No bit number for this signal, so use all of the signal.
	$idx = $HDLN_NET_ID_NETS;  
	$idx_lim = $#net_info;
    };
    
    check_range($wire, \@net_info, $idx, $idx_lim);
    
    # Copy the nets into the return array.

    @{$nets_array_ref} = @net_info[$idx..$idx_lim];
    
    # print("get_nets: after assign: idx=$idx idx_lim=$idx_lim net_array='@{$nets_array_ref}'.\n");

    $HDLN_idx++;  # Bump to next
}

####################################################

# Take the IDs on the current line and make them into nets.

sub make_net{
    my($wire_table_ref, $path_id, $portorder_ref, $port_map_ref) = @_;
    
    my($net_type);
    my($cnt, $cnt_lim);

    my($do_range);
    my($left, $right);
    my($size);

    my($tok);
    my($net);

    my($calling_sz);
    my($port_num);
    my($port_rec);
    my(@port_info);
    my($is_io);
    my($idx);
    my(@net_info);
    my($n);
    my($dt);
    my($net_id);

    $net_type = $HDLN_fields[$HDLN_idx];

    $HDLN_idx++;  # Bump to the count.
    $cnt_lim = $HDLN_fields[$HDLN_idx];

    # Setup for no range specified.
    $do_range = $HDLN_NET_ID_RANGE_NONE; 
    $left=0;
    $size=1;

    for($cnt=1; $cnt<=$cnt_lim; $cnt++){

	$HDLN_idx++; 
	$tok = $HDLN_fields[$HDLN_idx];

	# print("make_net: cnt=$cnt; tok=$tok\n");

	if($tok eq 'range') {
	    
	    $HDLN_idx++; 
	    if($HDLN_fields[$HDLN_idx] != 2) {
		fatal("Expected 'range 2', but found 'range $HDLN_fields[$HDLN_idx]'.");
	    };

	    $HDLN_idx++; 
	    if($HDLN_fields[$HDLN_idx] ne 'num') {
		fatal("Expected range 2, 'num', but found '$HDLN_fields[$HDLN_idx]'.");
	    };

	    $HDLN_idx += 2;  # Skip '0' level count.
	    $left = $HDLN_fields[$HDLN_idx];

	    # Skip the original number's string and bump to the second
	    # num field.

	    $HDLN_idx += 2;

	    if($HDLN_fields[$HDLN_idx] ne 'num') {
		fatal("Expected range 2, num, 'num', but found '$HDLN_fields[$HDLN_idx]'.");
	    };

	    $HDLN_idx += 2;  # Skip '0' level count.
	    $right = $HDLN_fields[$HDLN_idx];

	    $HDLN_idx++; # now it points at the second number.

	    # Set the loop control
	    if($left >= $right){
		$size = $left-$right+1;
		$do_range = $HDLN_NET_ID_RANGE_BIG;
	    } else {
		$size = $right-$left+1;
		$do_range = $HDLN_NET_ID_RANGE_LITTLE;
	    };

	} elsif ($tok eq 'id') {
	    
	    # This is the net to add.
	    
	    $HDLN_idx += 2; # Skip to name token.

	    # Enter the name into the table. 
	    
	    $net = $HDLN_fields[$HDLN_idx];

	    # warn("make_net: net=$net net_type=$net_type \n");

	    if(! defined($wire_table_ref->{$net})){

		# Enter the name into the table.
		
		$is_io = 0; # Assume this is not an I/O port.

		if(defined($port_num=$portorder_ref->{$net})){

		    # warn("make_net: $net is a port, port_num=$port_num\n");

		    # If there is not a parameter passed into this
		    # port then port_map_ref will be undefined and
		    # we'll create a new net for it.

		    if(defined($port_rec=$port_map_ref->[$port_num])){
			$is_io = 1;
		    } else {
			if((($net_type eq 'input') || ($net_type eq 'inout'))
			   && ($path_id != $root_path_id)){
			    HDLN_warn("For instance:");
			    HDLN_warn("\t$HDLN_path_name[$path_id]");
			    HDLN_warn("\tNothing connected to $net_type port '$net'");
			}
		    }
		}

		# Define it.
		# Net name is in $HDLN_fields[$HDLN_idx].

		new_net($do_range, $left, $size,
			$path_id, $wire_table_ref);

		# If this is a input/output statement then set the
		# HDLN_netlist_driver_type entries.  The net may or
		# may not be an actural parameter, these are
		# determined when the net is declared as an i/o.

		if($net_type eq 'input'){
		    $dt = $HDLN_driver_type_mod_input;
		}elsif($net_type eq 'inout'){
		    $dt = $HDLN_driver_type_mod_inout;
		}elsif($net_type eq 'output'){
		    $dt = $HDLN_driver_type_mod_output;
		}else{
		    $dt = $HDLN_driver_type_none;
		}
		 
		# Type port nets even if they are not connected.

		if($dt != $HDLN_driver_type_none){
		    @net_info = split(/ /, $wire_table_ref->{$net});
         	    for($n=$HDLN_NET_ID_NETS; $n<=$#net_info; $n++){
        
			# warn("make_net: n=$n net_info\[$n\]=$net_info[$n] net_type=$net_type $net\n");
			$net_id = $net_info[$n];
			$HDLN_netlist_port_type[$net_id] = $dt;
			$HDLN_netlist_port_num[$net_id] = $port_num;

			# This driver type info may be overwritten
			# when this net is connected to a cell.
			$HDLN_netlist_driver_type[$net_id] = $dt;
			$HDLN_netlist_connected_pid[$net_id] = -$path_id;
			$HDLN_netlist_connected_port[$net_id] = $port_num;
			# warn("make_net: $net -- net_id=$net_id dt=$dt, pid=$HDLN_netlist_connected_pid[$net_id], port_num=$port_num\n");

		    }    
		}

		if($is_io){

		    # This is a port and already has a net assigned to
		    # it.  Check its width and connect it to the
		    # already assigned net_id's.

		    @port_info = split(/ /, $port_rec);
		    $calling_sz = scalar(@port_info);
		    if($calling_sz > $size){
			HDLN_warn("Port '$net' is receiving too many bits:");
			HDLN_warn("\tDefined width = $size");
			HDLN_warn("\tCalling width = $calling_sz");
			HDLN_warn("\tInstance: $HDLN_path_name[$path_id]");

			# Pick rightmost bits.
			$idx = $calling_sz - $size;
		    } else {
			$idx = 0;
		    }
		    
		    if($calling_sz < $size){
			HDLN_warn("Port '$net' didn't receive enough bits:");
			HDLN_warn("\tCalling width = $calling_sz");
			HDLN_warn("\tDefined width = $size");
			HDLN_warn("\tInstance: $HDLN_path_name[$path_id]");
		    }

		    # For ports, connect these newly created nets 
		    # to the existing nets.

		    @net_info = split(/ /, $wire_table_ref->{$net});

		    for($n=$HDLN_NET_ID_NETS; $n<=$#net_info; $n++){
			connect_nets($net_info[$n], $port_info[$idx]);
			$idx++;
		    }
		}

		# warn("make_net: For net: $net_type $net, wire_rec=$wire_table_ref->{$net}\n");

	    }; # if !defined
	    
	    # Clear range  for next time.
	    $do_range = $HDLN_NET_ID_RANGE_NONE; 
	    $left=0;
	    $size=1;

	} else {

	    fatal("make_net: Expected 'range' or 'id', but found '$HDLN_fields[$HDLN_idx]'");

	};
    } # for $cnt
}

###############################################################

# new_net -- create a new net and enter it into the tables.

# net's name is in $HDLN_fields[$HDLN_idx];

sub new_net{
    my($do_range, $left, $size, $path_id, $wire_table_ref) = @_;

    my($sz);
    my($bit);
    my($wire_rec);

    my($net) = $HDLN_fields[$HDLN_idx];
    my($lnum) =  $HDLN_lnum - 1;
    my($net_id);

    # One entry per bit.

    $wire_rec = '';

    for($sz=0, $bit=$left; $sz<$size; $sz++, $bit+=$do_range){
	
	push(@HDLN_net_name, 
	     make_net_name_rec($path_id, $HDLN_fields[$HDLN_idx],
			       $bit, $do_range));

	# Also start a net-list for this net with it being unconnected
	# and pointing itself, with zero connections.

	$net_id = $#HDLN_net_name;
	vec($HDLN_netlist_clst, $net_id, 32) = $net_id;
	$HDLN_netlist_ts++;

	if(!$HDLN_flatten){
	    $HDLN_netlist_cells[$net_id] = '';
	    $HDLN_netlist_ports[$net_id] = '';
	    $HDLN_netlist_port_bit[$net_id] = '';
	    vec($HDLN_netlist_cnt, $net_id, 32) = 0;

	    # Default to unknown.
	    $HDLN_netlist_driver_type[$net_id] = $HDLN_driver_type_none;
	    $HDLN_netlist_port_type[$net_id] = $HDLN_driver_type_none;
	}
	
	# Append this net_id to the list associated with
	# this name.

	$wire_rec = "$wire_rec $#HDLN_net_name";

	# print("new_net: wire_rec = '$wire_rec' sz=$sz size=$size bit=$bit do_range=$do_range\n");
    }
    
    # Save this wire record in the hash for this
    # module instance.
    
    $wire_table_ref->{$net} = "$do_range $left $size$wire_rec";

    # warn("new_net: wire_table_ref->\{$net\}=$wire_table_ref->{$net}'.\n");
}

####################################################

# Make the record string that is used to build a net name.

# Format is <path_id> <string_idx> <bit_num> <do_raange>
# This format is used to save memory.

sub make_net_name_rec{
    my($path_id, $name, $bit_num, $do_range) = @_;

    my($str_idx);
    my($name_rec);

    # If if we already have stored this name string.

    if(!defined($str_idx=$HDLN_string_hash{$name})){

	# New string for this name.
	push(@HDLN_string_table, $name);
	$str_idx = $#HDLN_string_table;
	$HDLN_string_hash{$name} = $str_idx;
    }

    $name_rec = "\000" x 16;  # 16 bytes per record.
    vec($name_rec, $NET_NAME_DO_RANGE, 32) = $do_range;
    vec($name_rec, $NET_NAME_BIT_NUM, 32) = $bit_num;
    vec($name_rec, $NET_NAME_STRING_IDX, 32) = $str_idx;
    vec($name_rec, $NET_NAME_PATH_ID, 32) = $path_id;

    return $name_rec;
}

####################################################

# Take the 'num' at the current hdl position and make a net_id
# and a net_rec for it.

# Return the wire_table_rec for the the new net.

sub new_const_net{

    my($num);
    my($i);
    my($width);
    my($wire_rec);
    my($bit);
    my($left);
    my($lnum);
    my($net_id);
    my($do_range);

    if($HDLN_fields[$HDLN_idx-3] ne 'num') {
	$HDLN_idx -= 3;
	fatal("new_const_net: Expected 'num', but found '$HDLN_fields[$HDLN_idx]'.");
    };

    $num = $HDLN_fields[$HDLN_idx];
    if(($i=index($num, "'")) >= 0){
	# Width specified, use it.
	$width = substr($num, 0, $i) + 0;
    } else {
	# constants default to 32 bits.
	$width = 32;
    };

    $left = $width-1;

    # print("new_const_net: num=$num, left=$left, width=$width\n");

    $wire_rec = '';
    $lnum = $HDLN_lnum - 1;

    if($width > 1){
	$do_range = $HDLN_NET_ID_RANGE_BIG;
    }else{
	$do_range = $HDLN_NET_ID_RANGE_NONE;
    }

    for($bit=$left;  $bit>=0;  $bit--){

	# Define a new net for each bit.

	push(@HDLN_net_name, 
	     make_net_name_rec($PATH_ID_CONST, $HDLN_fields[$HDLN_idx],
			       $bit, $do_range));

	# Also start a net list for this net
	# with it being unconnected and pointing
	# at itself.
	
	$net_id = $#HDLN_net_name;
	vec($HDLN_netlist_clst, $net_id, 32) = $net_id;
	$HDLN_netlist_ts++;

	if(!$HDLN_flatten){
	    $HDLN_netlist_cells[$net_id] = '';
	    $HDLN_netlist_ports[$net_id] = '';
	    $HDLN_netlist_port_bit[$net_id] = '';
	    vec($HDLN_netlist_cnt, $net_id, 32) = 0;

	    # Default drive type to unknown.  Should not be used,
	    # except to find input verses output connections.

	    $HDLN_netlist_driver_type[$net_id] = $HDLN_driver_type_none;
	    $HDLN_netlist_port_type[$net_id] = $HDLN_driver_type_none;
	}

			
	# Append this net_id to the list associated with
	# this name.  Leading space is needed.
	$wire_rec = "$wire_rec $#HDLN_net_name";
    };

    return "$HDLN_NET_ID_RANGE_BIG $left $width$wire_rec";
}

###############################################

# map_params -- create a port_map array that identifies which of the
# caller's nets are to be used for each of the callee's ports.

# port_map: an array of wire_rec records, in port order.

sub map_params{
    my($path_id, $called_mod_id, $wire_table_ref, $called_port_map_ref) = @_;

    # $called_mod_id is the called module's lnum in the hdl array

    # $wire_table_ref id a reference to the calling module's wire table.

    # $called_order_ref is a reference to hash that is filled with the
    # called module's port name to port number mapping.

    # $called_order_ref is a reference to hash that is to be filled with the
    # called module's port name to port number mapping.

    my($portorder_rec);
    my($port_num);
    my($actual_port_cnt);
    my($dot_id);
    my(@nets_array);
    my($bit);
    my($tok_num);
    
    my($nets_idx);
    my($port_dir);
    my($net_id);
    my($net);
    my($cur_dt);
    my($instance_idx);

    my($called_mod_name) = $HDLN_mod_name[$called_mod_id];
    my($called_portorder_ref) = $HDLN_mod_portorder_ref[$called_mod_id];

    my($id_cnt);

    # print("map_params: Calling instance: @HDLN_fields\n");

    $HDLN_idx = 4; # Set it to the called module's name.

    if($HDLN_fields[$HDLN_idx] ne $called_mod_name){
	fatal("map_params: INTERNAL ERROR 200402 -- expected '$called_mod_name' but found '$HDLN_fields[$HDLN_idx]'");
    };

    $HDLN_idx += 2; # Bump it to the port count.

    # The called instance name doesn't count in the port count.

    $actual_port_cnt = $HDLN_fields[$HDLN_idx] - 1;

    $HDLN_idx++; # Bump it to 'id' for the instance name.

    if($HDLN_fields[$HDLN_idx] ne 'id'){
	fatal("map_params: expected 'id' for instance name but found '$HDLN_fields[$HDLN_idx]'");
    };
    
    $HDLN_idx+=2; # Bump it to name.

    $instance_idx = $HDLN_idx;

    $HDLN_idx++; # Bump it to 'id' for first port.

    @$called_port_map_ref = (); # Un-define the array.

    for($tok_num=0; $tok_num<$actual_port_cnt; $tok_num++){

 	# Build the the port connection list
	
	if($HDLN_fields[$HDLN_idx] ne 'dot') {

	    # Call by position, port number is current loop index.
	    
	    $port_num = $tok_num;
	    $id_cnt = 1;

	} else {

	    # Call by name, get the name and look it up.

	    $id_cnt = $HDLN_fields[$HDLN_idx+1];
	    if($id_cnt != 2){
		warn("map_params: Found 'dot $id_cnt'\n");
	    }

	    $HDLN_idx+=2;  # Bump to start called port name.
	    if($HDLN_fields[$HDLN_idx] ne 'id') {
		fatal("map_params: Expected to find 'id' after dot, but found '$HDLN_fields[$HDLN_idx]'.\n");
	    }
	    
	    $id_cnt--;  # Consumed one of the tokens 

	    $HDLN_idx+=2; # Skip to name
	    $dot_id =  $HDLN_fields[$HDLN_idx];
	    if(! defined($port_num=$called_portorder_ref->{$dot_id})){
		fatal("map_params: Port .$dot_id() not found in called module's port list.\n");
	    };

	    $HDLN_idx++;  # Bump to calling port name id.
	}

	# print("map_params: mapping ports. tok_num=$tok_num, port_num=$port_num, actual_port_cnt=$actual_port_cnt\n");
	    
	if($id_cnt){  # If it was just 'dot 1' then don't do lookup for the ID.

	    get_nets($path_id, $wire_table_ref, \@nets_array);
	    $called_port_map_ref->[$port_num] = join(' ', @nets_array);
	
	    # print("map_params: dot_id=$dot_id called_port_map_ref->\[$port_num\] = $called_port_map_ref->[$port_num]\n");

	    # Loop over the connected signals and set the connection info
	    # for unassigns.

	    $port_dir = $HDLN_mod_port_dirs[$called_mod_id][$port_num];

	    for($nets_idx=0; $nets_idx<=$#nets_array; $nets_idx++){

		$net_id = $nets_array[$nets_idx];
		$cur_dt=$HDLN_netlist_driver_type[$net_id];

		# Update this signal type if this is higher priority
		# (port_dir and driver_type have the same values).

		if($port_dir > $cur_dt){
		    $HDLN_netlist_driver_type[$net_id] = $port_dir;
		    $HDLN_netlist_connected_pid[$net_id] = 
			-(@HDLN_path_name);  # Use '@' before the push.
		    # negative flags a path_id in this pid array.
		    $HDLN_netlist_connected_port[$net_id] = $port_num;
		    # warn("map_params: net_id=$net_id type=$port_dir pid=$HDLN_netlist_connected_pid[$net_id], port=$port_num\n");
		}

		# Check to see if there is more than one driver in this
		# module.

		if($port_dir == $HDLN_PORT_DIR_OUTPUT){

		    # This is driven by a cell output port. Report this
		    # net if it is already driven by the module input
		    # ports, or another output port.

		    if(($cur_dt == $HDLN_driver_type_cell_output)||
		       ($cur_dt == $HDLN_driver_type_mod_input)){
			
			# Need to set the wire table before calling get_name;

			$HDLN_wire_table_ref[$path_id] = $wire_table_ref;
			
			$net = net_name($net_id);
			HDLN_warn("");
			HDLN_warn("In module '$HDLN_mod_name[$HDLN_path_mod_id[$path_id]]' net:");
			HDLN_warn("\t$net");
			HDLN_warn("is connected to multiple drive ports by call:");
			HDLN_warn("\t$HDLN_mod_name[$called_mod_id] $HDLN_fields[$instance_idx](.$dot_id())\n");
		    }
		}
	    }
	}# If($id_cnt);
	
    } # for $tok

# Many times output ports are unconnected, so output ports produced
# too many warnings.

#    while(($dot_id, $port_num) = each(%$called_portorder_ref)){ 
#	if(!defined($called_port_map_ref->[$port_num])){
#	    warn("$0:Module '$called_mod_name' port '$dot_id' is unconnected for
#\t instance call '$HDLN_fields[$HDLN_INSTANCE_NAME]'.\n");
#	};
#    };

}

####################################################

# get_range_idx -- a bit or bit range has been declared on a variable,
# git then number and map it to the index into the  net_info array

sub get_range_idx{
    my($net_info_ref) = @_;

    my($bit);
    my($idx);

    $HDLN_idx++; # bump to bit number
    if($HDLN_fields[$HDLN_idx] ne 'num'){
	fatal("get_range_idx: expected 'num' for bit number but found '$HDLN_fields[$HDLN_idx]");
    };
    $HDLN_idx+=2; # bump to decimal number
    $bit = $HDLN_fields[$HDLN_idx];
		
    $HDLN_idx++; # bump to number string
    if("$bit" ne $HDLN_fields[$HDLN_idx]){
	fatal("get_range_idx: only simple bit numbers allowed.");
    };

    $idx = $net_info_ref->[$HDLN_NET_ID_LEFT_BIT] +
	$bit*$net_info_ref->[$HDLN_NET_ID_RANGE_FLAG] + $HDLN_NET_ID_NETS;

    return $idx;
}

##########################

# check_range - check to see if the specified range,
# which has been mapped into net_info indexes is within the legal bit range.

sub check_range{
    my($sig, $net_info_ref, $idx, $idx_lim) = @_;    

    my($left, $right);
    my($size);

    if(($idx<$HDLN_NET_ID_NETS) || ($idx_lim>$#$net_info_ref)){

	$size = $#$net_info_ref;
	# print("check_range: idx=$idx, idx_lim=$idx_lim, size=$size\n");
	# print("check_range: net_info = @{$net_info_ref}\n");

	$left = $net_info_ref->[$HDLN_NET_ID_LEFT_BIT];
	$right = $left+
	    ($net_info_ref->[$HDLN_NET_ID_BITS]-1)*$net_info_ref->[$HDLN_NET_ID_RANGE_FLAG];
	
	fatal("check_range: bit range on $sig is not in the range of \[$left:$right\]");
    };
}

####################################################

# Take the cell on the current line and insert it into the cell_ids.
# Add the connections to the net list.

sub make_cell{
    my($mod_id, $cell_table_ref, $path_id, $wire_table_ref) = @_;

    my($mod_def);
    my($portorder_ref);
    my($cell_rec);
    my($tok_cnt, $tok_lim);
    my($net_id);
    my($pin_name);
    my(@pin_net_ids);
    my($cell_id);
    my($port_num, $port_dir);
    my($nets_cnt);
    my($nets);
    my($nets_pins);
    my($cnt);
    my($do_range);
    my($left);
    my($right);
    my($size);
    my($net_cnt);

    my($lnum) = $HDLN_lnum - 1;
    
    # print("make_cell: @HDLN_fields\n");

    if($HDLN_fields[$HDLN_idx] ne 'instances') {
	fatal("make_cell: Expected to find 'instances', but found '$HDLN_fields[$HDLN_idx]'.\n");
    };

    if($HDLN_fields[$HDLN_INSTANCES_ID] ne $HDLN_mod_name[$mod_id]) {
	fatal("make_cell: INTERNAL ERROR 104216: $HDLN_fields[$HDLN_INSTANCES_ID] ne $HDLN_mod_name[$mod_id]\n");
    };

    $HDLN_idx += 6;  # Bump to the index to the instance token count.

    $tok_lim = $HDLN_fields[$HDLN_idx];
    $tok_cnt = 0;

    $HDLN_idx++;  # Bump to the index to the instance name token;

    if($HDLN_fields[$HDLN_idx] ne 'id') {
	fatal("make_cell: Expected to find instance name 'id', but found '$HDLN_fields[$HDLN_idx]'");
    }

    $HDLN_idx+=2;  # Bump to the index to the instance name;
    
    # Make this into a new cell by pushing it onto the name array.
    
    $cell_rec = "$path_id $lnum";
    push(@HDLN_cell_name, $cell_rec);
    $cell_id = $#HDLN_cell_name;
    $HDLN_cell_mod_id[$cell_id] = $mod_id;

    $cell_table_ref->{$HDLN_fields[$HDLN_idx]} = $cell_id;

    # warn("make_cell: cell $HDLN_fields[$HDLN_idx] is cell_id  $cell_table_ref->{$HDLN_fields[$HDLN_idx]}, path=$HDLN_path_name[$path_id]\n");

    # This probably is not worth it, but copy the seq flag from the
    # module's definition to this cell's instance for efficiency.

    $HDLN_cell_is_seq[$cell_id] = $HDLN_mod_is_seq[$mod_id];
    if($HDLN_mod_is_seq[$mod_id] && ($HDLN_mod_def[$mod_id] == $HDLN_MOD_CELL)){
	$HDLN_seq_cells{$HDLN_mod_name[$mod_id]}++;
    }

    # Count the number of each tristate.
    if($HDLN_mod_tristate[$mod_id]){
	if(!defined($HDLN_tristate_cells{$HDLN_fields[$HDLN_INSTANCES_ID]})){
	    fatal("make_cell: INTERNAL ERROR 213954: '$HDLN_fields[$HDLN_INSTANCES_ID]' not in tristate hash.");
	};
	$HDLN_tristate_cells{$HDLN_fields[$HDLN_INSTANCES_ID]}++;
    }

    $tok_cnt++; # Skip to first connection token.

    $HDLN_idx++;  # Bump to start of pin token.  

    # The ports definition for this cell.

    $mod_def = $HDLN_mod_def[$mod_id];
    if($mod_def == $HDLN_MOD_UNDEF){
	HDLN_warn("Cell '$HDLN_fields[$HDLN_INSTANCES_ID]' is undefined.");
        $HDLN_mod_def[$mod_id] = $HDLN_MOD_UNDEF_REPORTED;
	$mod_def = $HDLN_MOD_UNDEF_REPORTED;
    }

    $portorder_ref = $HDLN_mod_portorder_ref[$mod_id];

    # Default to driving nothing, leading character stripped below.
    $nets = '';
    $nets_pins = '';
    $nets_cnt = 0;

    # Add this cell's ports into the net-lists.

    for(; $tok_cnt<$tok_lim; $tok_cnt++){
	    
	# Get the next pin name and the net_ids it is connected to.

	@pin_net_ids = ();  # In case there is no connection.
	$pin_name = get_nxt_pin($path_id, $wire_table_ref, \@pin_net_ids);
	
	if(!defined($port_num=$portorder_ref->{$pin_name})){

	    if($mod_def != $HDLN_MOD_UNDEF_REPORTED){
	       fatal("Cell '$HDLN_fields[$HDLN_INSTANCES_ID]' does not have a port '$pin_name'
\t for instance call '$HDLN_fields[$HDLN_INSTANCE_NAME]'");
	    }
          
	    # Define the port info so that we don't
	    # get undefined usages later.

	    $port_num = 0;
	    $port_dir = $HDLN_PORT_DIR_INPUT; # not equal to output
	    $HDLN_mod_port_dirs[$mod_id][$port_num] = $port_dir;

	} else {

	    $port_dir = $HDLN_mod_port_dirs[$mod_id][$port_num];

	    if(!defined($port_dir)){
		fatal("Undefined port direction in module $HDLN_mod_name[$mod_id]), port $HDLN_mod_port_names[$mod_id][$port_num])\n");
	    }

	    if($port_dir == $HDLN_PORT_DIR_INOUT){
		# JDJ Wed May 16 23:19:58 2001
		# Seems to be working OK with inout ports
		# At the top level.  Stop reporting this message.

		# HDLN_warn("inout ports not yet supported:");
		# HDLN_warn("\t cell '$HDLN_fields[$HDLN_INSTANCES_ID]' port '$pin_name'");
		# HDLN_warn("\t instance call '$HDLN_fields[$HDLN_INSTANCE_NAME]'.");
	    }
	    
	}

	$do_range = $HDLN_mod_port_range[$mod_id][$port_num];
	$left = $HDLN_mod_port_left_bit[$mod_id][$port_num];
	$size =	$HDLN_mod_port_size[$mod_id][$port_num];

	$net_cnt = scalar(@pin_net_ids);

	#if(!defined($left)){
	#    print("make_cell: left is NOT DEFINED!\n");
	#    print("make_cell: port_num=$port_num net_cnt=$net_cnt size=$size\n");
	#}

	# Don't warn about zero sized connection miss matches.
	# Assume if its .port() the programmer knows what he is doing.

	if($net_cnt && ($net_cnt != $size)){

	    HDLN_warn(
	     "module '$HDLN_mod_name[$mod_id]', port '$HDLN_mod_port_names[$mod_id][$port_num]', is defined to be $size bits,\n".
	     "\t but is called using $net_cnt for instance:\n".
	     "\t $HDLN_path_name[$path_id]$HDLN_fields[$HDLN_INSTANCE_NAME]\n");
	}

	foreach $net_id (@pin_net_ids) {

	    # If this is a flattening run then keep track of all the
	    # nets this cell is connected to.  We only need to know
	    # the nets that are connect to a cell.  Or if this is a
	    # output port, always add it to the list of nets this cells
	    # drives.

	    if($HDLN_flatten || ($port_dir == $HDLN_PORT_DIR_OUTPUT)){
		vec($nets, $nets_cnt, 32) = $net_id;
		vec($nets_pins, $nets_cnt, 32) = $port_num;
		$nets_cnt++;
	    }

	    if(!$HDLN_flatten){

		# This run needs to know what cells are connect to a net.
		# Add this cell_id to the list for this net.

		$cnt = vec($HDLN_netlist_cnt, $net_id, 32);
		vec($HDLN_netlist_cnt, $net_id, 32) = $cnt + 1;

		vec($HDLN_netlist_cells[$net_id], $cnt, 32) = $cell_id; 
		vec($HDLN_netlist_ports[$net_id], $cnt, 32) = $port_num; 
		vec($HDLN_netlist_port_bit[$net_id], $cnt, 32) = $left;

		# The do_range is also says which way to increment
		# the port bit number.
		$left += $do_range;

		# Bump the time stamp.
		$HDLN_netlist_ts++;

		 # warn("make_cell: pin_name=$pin_name, net_id=$net_id port_dir=$port_dir\n");
		 # warn("make_cell: HDLN_netlist_driver_type\[$net_id\]=$HDLN_netlist_driver_type[$net_id]\n");

		if($port_dir > $HDLN_netlist_driver_type[$net_id]){
		    # Update the connection info for unassign
		    $HDLN_netlist_driver_type[$net_id] = $port_dir;
		    # Positive pid is a cell_id.
		    $HDLN_netlist_connected_pid[$net_id] = $cell_id;
		    $HDLN_netlist_connected_port[$net_id] = $port_num;
		    # warn("make_cell: net -- net_id=$net_id port_dir=$port_dir, pid=$HDLN_netlist_connected_pid[$net_id], port_num=$port_num\n");
		}
	    }
	}
    }

    if($HDLN_flatten){
	vec($HDLN_connected_cnt, $cell_id, 32) = $nets_cnt;
	$HDLN_connected_nets[$cell_id] = $nets;
	$HDLN_connected_ports[$cell_id] = $nets_pins;
    }else{
	if($nets_cnt == 0){
	    # This cell doesn't drive anything, report it if it's
	    # defined.
	    if($mod_def != $HDLN_MOD_UNDEF){
		if($HDLN_unconnected_output_warn){
		    HDLN_print("Found cell without any output connections:");
		    HDLN_print("    cell=$HDLN_fields[$HDLN_INSTANCES_ID] instance=$HDLN_path_name[$path_id]$HDLN_fields[$HDLN_INSTANCE_NAME]");
		};
		$HDLN_unconnected_output_cnt++;
	    }
	}
	vec($HDLN_cell_drives_cnt, $cell_id, 32) = $nets_cnt;
	$HDLN_cell_drives_nets[$cell_id] = $nets;
	$HDLN_cell_driving_pins[$cell_id] = $nets_pins;
    }
}

####################################################

# get_nxt_pin -- Parse the next pin name on a cell instance hdl line
# and return its name and the net_id(s) it is connect to.

sub get_nxt_pin{
    my($path_id, $wire_table_ref, $pin_ids_ref) = @_;

    my($tok);
    my($pin_name);
    my($has_bit);
    my($bit);
    my($net_id);
    my($idx);
    my($wire);
    my($net_rec);
    my($id_cnt);

    $tok =  $HDLN_fields[$HDLN_idx];
    if($tok ne 'dot') {
	fatal("get_nxt_pin: Expected to find 'dot', but found '$tok'");
    };

    $id_cnt = $HDLN_fields[$HDLN_idx+1];

    if(($id_cnt!=1)&&($id_cnt!=2)){
    	fatal("get_nxt_pin: Found 'dot $id_cnt', expected 'dot 1' or 'dot 2'\n");
    }

    $id_cnt--;  # Consumed one of the tokens 

    $HDLN_idx+=2; # Skip over the first ID.
    $tok =  $HDLN_fields[$HDLN_idx];
    if($tok ne 'id') {
	fatal("get_nxt_pin: Expected to find 'id' after dot, but found '$tok'");
    };

    $HDLN_idx+=2; # Skip to the pin name.
    $pin_name = $HDLN_fields[$HDLN_idx]; # Save this to put in the record.
    $HDLN_idx++; # Skip to second ID for the wire.

    if($id_cnt){   # If it was just 'dot 1' then don't do lookup for the ID.
	get_nets($path_id, $wire_table_ref, $pin_ids_ref);
    }
    return $pin_name;
} 

####################################################

# get_first_net_name -- given a net_id, return the net name that is
# highest up in the hierarchy.  This is the one with the lowest net_id
# number.

push(@EXPORT, 'get_first_net_name');
sub get_first_net_name{
    my($net_id) = @_;
    my($lowest);
    my($path, $net);
    
    # Setup the @HDLN_net_first_name entries.
    get_drivers($net_id);
    
    $lowest = $HDLN_net_first_name[$net_id];
    
    ($net, $path) = get_net_name($lowest);
    
    return ($net, $path);
}

####################################################
#
# net_name --  safe version of get_net_name.
# Doesn't modifiy fields position.

sub net_name{
    my($net_id) = @_;

    my($lnum_save);
    my($idx_save);
    my($name, $p);

    $lnum_save = $HDLN_lnum-1;
    $idx_save = $HDLN_idx;
    ($name, $p)= get_net_name($net_id);
    $lnum_save = $HDLN_lnum = $lnum_save;
    get_fields();
    $HDLN_idx  = $idx_save;

    return $name;
}

####################################################

# get_net_name -- build the string name for a net_id. Returns the net
# name and the path_id used to build the name.

sub get_net_name{
    my($net_id) = @_;
    
    my($name_rec);
    my($p, $b, $do_r);
    my($name);

    my($net);

    $name_rec = $HDLN_net_name[$net_id];

    $p = vec($name_rec, $NET_NAME_PATH_ID, 32);
    $name = $HDLN_string_table[vec($name_rec, $NET_NAME_STRING_IDX, 32)];

    if($p <= $PATH_ID_CONST) {

	$b = vec($name_rec, $NET_NAME_BIT_NUM, 32);
	$net = get_const_bit($name, $b);

    }else{

	$net = "$HDLN_path_name[$p]$name";
    
	# If this net is declared as a bus then report the bit number.
	$do_r = vec($name_rec, $NET_NAME_DO_RANGE, 32);
	if($do_r != $HDLN_NET_ID_RANGE_NONE){
	    $b = vec($name_rec, $NET_NAME_BIT_NUM, 32);
	    $net .= "\[$b\]";
        }
    }

    return ($net, $p);
}

####################################################

# get_const_bit  -- give a Verilog constant and a bit number
# extract the value of the bit.

sub get_const_bit{
    my($const, $bit) = @_;

    my($idx);
    my($base);
    my($width);
    my($digits);
    my($dig);
    my($val);

    if(($idx=index($const, "'")) >= 0){
	# Width is specified, use it.
	$width = substr($const, 0, $idx);
	$base = substr($const, $idx+1, 1);
	$digits =  substr($const, $idx+2);
    }else{
	$base = 'd';
	$width = 32;
	$digits = $const;
    }

    $digits =~ s/_//g;

    if($bit > $width){
	$val = 0;
    } else {
	$base = lc($base);
	if($base eq 'b'){
	    if($bit >= length($digits)){
		# Not a digit in the string
		$val = 0;
	    }else{
		# minus to substr indexes from the left.
		$dig = substr($digits, -($bit+1), 1);
		$val = $dig;
	    }
	}elsif($base eq 'o'){
	    $idx = int($bit/3);
	    if($idx >= length($digits)){
		$val = 0;
	    }else{
		$dig = substr($digits, -($idx+1), 1);
		$val = ($dig >> ($bit % 3)) & 1;
	    }
	}elsif(($base eq 'd')||($base eq 'h')){
	    if($base eq 'd'){
		# Convert decimal to hex
		$digits = sprintf("%x", $digits);
	    }
	    $idx = int($bit/4);
	    if($idx >= length($digits)){
		$val = 0;
	    }else{
		$dig = substr($digits, -($idx+1), 1);
		$val = (hex($dig) >> ($bit % 4)) & 1;
	    }
	}else{
	    fatal("Unknown base '$base' in constant $const");
	}
    }	   
    return("1'b$val");
}
####################################################

# unassign_rec -- build the string for an unassign record name for a
# net_id.  The rec format for a bus is "name bit". i.e., space
# separated name and bit number, for a non-bit it is just the net
# name.

sub unassign_rec{
    my($net_id) = @_;
    
    my($net, $bus, $rec);  # return values.

    my($p, $f, $b, $do_r);
    my($name_rec);

    $name_rec = $HDLN_net_name[$net_id];
    $p = vec($name_rec, $NET_NAME_PATH_ID, 32);
    $net = $HDLN_string_table[vec($name_rec, $NET_NAME_STRING_IDX, 32)];

    if($p <= $PATH_ID_CONST){

	# Always report the bit number if the net is a constant, and
	# say it is a bus, because push_hdl expects a constant to have
	# a bit number.

	$bus = 1;
	$b = vec($name_rec, $NET_NAME_BIT_NUM, 32);
	$rec = "$net $b";

    }else{

	# If this net is declared as a bus then set the bit number.

	if($do_r != $HDLN_NET_ID_RANGE_NONE){
	    $bus = 1;
	    $b = vec($name_rec, $NET_NAME_BIT_NUM, 32);
	    $rec = "$net $b";
	}else{
	    # Not a bus
	    $bus = 0;
	    $rec = $net;
	}
    }

    # print("unassign_rec: return '$net, $bus, $rec'\n");

    return ($net, $bus, $rec);
}

####################################################

# Given a net_id, and a path_id, find the how the signal is driven
# inside of the given path_id.  It is the name of signal that is an
# input, or is driven by a cell.  Return the first driver found.
# Start at the passed in net so that the first driver found is the
# "map to" net during unassigns.

# JDJ Mon Nov 13 11:20:37 2000
# Not currently used.

sub get_driven_net{
    my($net_id_in, $path_id_in)= @_;

    my($path_id);
    my($net);
    my($type);
    my($rtn_net);

    $net = $net_id_in;
    $rtn_net =  $net_id_in; # Default to the input net.

    while(1) {


	$path_id = vec($HDLN_net_name[$net], $NET_NAME_PATH_ID, 32);

	if($path_id == $path_id_in){
	    $type = $HDLN_netlist_driver_type[$net];

	    if(($type == $HDLN_driver_type_cell_output) ||
	       ($type == $HDLN_driver_type_mod_input)){
		# Found a driver, use it.
		# warn("get_driven_net: found driver, return net=$net\n");

		return $net;
	    }

	    if(($type == $HDLN_driver_type_cell_inout) ||
	       ($type == $HDLN_driver_type_mod_inout)){
		# This is better than an input, remember it.
		$rtn_net = $net;
	    }
	}
	$net = vec($HDLN_netlist_clst, $net, 32);
	if($net == $net_id_in){
	    last;
	}
    } #while(1)

    # No drivers, the last ioout seen, or eturn the one passed in.

    return $rtn_net;
}

####################################################

# connect_nets -- connect two nets together.

sub connect_nets{
    my($lhs_net, $rhs_net) = @_;

    my($old_lhs, $old_rhs);

    # Swap the pointers.  This will link these two
    # circular lists into one.

    $old_lhs = vec($HDLN_netlist_clst, $lhs_net, 32);
    $old_rhs = vec($HDLN_netlist_clst, $rhs_net, 32);
    vec($HDLN_netlist_clst, $lhs_net, 32) = $old_rhs;
    vec($HDLN_netlist_clst, $rhs_net, 32) = $old_lhs;

    # Bump the time stamp.
    $HDLN_netlist_ts++;
}

##########################################################

# get_drivers -- given a net_id, find the driver of the net.

# For efficiency, the result is cached.  For every entry in this
# net_id's circular list the find the drivers and store them in
# HDLN_net_driver array.

# The returned driver info is space separated list of
# <cell_id,pin_name> pairs.  There may be more than one driver, or
# there may be none.

# Also find the lowest net_id in the group, this is used by
# get_first_name.  If the net has a driver, then
# $HDLN_net_first_name[$net_id] is the net_id of the first driver.
# Else it is the lower net_id of the circular list, which is usually a
# constant or a primary input.  Selecting the driver is needed for
# unassign, so that the input/output direction of the substituted
# names are correct.

push(@EXPORT, 'get_drivers');
sub get_drivers{
    my($net_id)= @_;

    my($n);
    my($i);
    my($i_lim);
    my($net, $pin);
    my($dvr_rec);
    my(@dvr_info, $dvr_idx);
    my($cell_name);
    my($lowest);
    my($cell_id, $cell_lim);
    my($d);
    my($dvr_cnt);
    my($const);
    my($special);
    my($p);

    my($drives_nets);
    my($driving_pins);
    my($cnt);
    my($dvr_cell_id);
    my($pin_name);
    my($connections);

    my($rpt_name, $rpt_p, $rpt_mod);

    # Invalidate caching if it changed since last update.

    if($HDLN_net_driver_ts < $HDLN_netlist_ts){
	# It's changed, empty cached data.
	@HDLN_net_driver = ();
	@HDLN_net_first_name = ();
	$HDLN_net_driver_ts = $HDLN_netlist_ts;

	# First Loop over all the cells, and mark the net_ids that are
	# driven by the cells.  A second pass over the nets will
	# follow the net's circular list to collect all the drivers
	# for each net.

	$dvr_cnt = 0;
	$cell_lim = $#HDLN_cell_name;

	# warn("get_drivers: flushed cache with $cell_lim cells.\n");

	for($cell_id=1; $cell_id<=$cell_lim; $cell_id++){
	    $drives_nets = $HDLN_cell_drives_nets[$cell_id];
	    $driving_pins = $HDLN_cell_driving_pins[$cell_id];
	    $cnt = vec($HDLN_cell_drives_cnt, $cell_id, 32);
	    $dvr_cnt += $cnt;
	    for($d=0; $d<$cnt; $d++){
		$net = vec($drives_nets, $d, 32);
		$pin = vec($driving_pins, $d, 32);

		# Set the array saying this segment is driven.

		if(defined($HDLN_net_driver[$net])){
		    $HDLN_net_driver[$net] .= " $cell_id $pin";
		} else {
		    $HDLN_net_driver[$net] = "$cell_id $pin";
		}

		# This segment is driven, report if
		# it's an input to the module

		if($HDLN_netlist_driver_type[$net] == 
		   $HDLN_driver_type_mod_input){
		    ($rpt_name, $rpt_p) = get_net_name($net);
		    $rpt_mod = $HDLN_mod_name[$HDLN_path_mod_id[$rpt_p]];
		    HDLN_warn("\n$0: In module $rpt_mod,\n\t input $rpt_name is driven.");
		}
	    }
	}

	# HDLN_warn("Setup $dvr_cnt pins as drivers.");
    }

    if(defined($HDLN_net_first_name[$net_id])){

	# Name is already defined, so the drivers have already been collected.

	$dvr_rec = $HDLN_net_driver[$net_id];

    } else {

	# Not currently defined.  Need to build it.

	# warn("get_drivers: Defining drivers for net_id=$net_id\n");

	$n = $net_id;
	$lowest = $#HDLN_net_name+1;

	if($net_id >= $lowest){
	    fatal("INTERNAL ERROR 310635: get_drivers -- net_id ($net_id) too big.");
	};

	$dvr_rec = '';
	$const = 0;
	$special = -1;

	$connections = 0;

	while(1){

	    # warn("get_drivers: net_id=$net_id n=$n\n");

	    $connections++;

	    # Keep track of the lowest net number for the name.
	    if($n < $lowest){
		$lowest = $n;
	    }
		
	    if(defined($HDLN_net_driver[$n])){

		# A cell is driving this segment of the net.

		# Keep track of the lowest driven net number for the
		# name.

		# my($net_x, $p_x) = get_net_name($n);
		# warn("get_drivers: driven net_id $n net_x=$net_x p_x=$p_x\n");

		# Accumulate driven net names into the driver list.

		if($dvr_rec){
		    # Append another driver.
		    $dvr_rec .= " $HDLN_net_driver[$n]";
		} else {
		    $dvr_rec = "$HDLN_net_driver[$n]";
		}
	    }

	    # Check if this net_id is a constant

	    $p = vec($HDLN_net_name[$n], $NET_NAME_PATH_ID, 32);
	    if($p <= $PATH_ID_CONST) {
		$const++;
	     	$special = $n;
	    };
	    
	    # Follow the circular list for this net.
	    $n = vec($HDLN_netlist_clst, $n, 32);
	    if($n == $net_id){
		last;
	    }
	}


	# If any of the connections are to constants or primary inputs
	# then report that connection.

	if($special >= 0){
	    $lowest = $special;
	    # warn("\nget_drivers: special lowest=$lowest\n");
	}

	# Loop through the list again, setting the HDLN_net_driver
	# elements.

	$n = $net_id;
	while(1){
	    $HDLN_net_driver[$n] = $dvr_rec;
	    $HDLN_net_first_name[$n] = $lowest;

	    $n = vec($HDLN_netlist_clst, $n, 32);
	    if($n == $net_id){
		last;
	    }
	}
	
	# Now that the list is built we can report multiple constant
	# connections to the net.  Calling report_net will make a
	# recursive call to this routine.

	if($const>1) {
	    HDLN_warn("Multiple constants connected one net, see output file.");
	    HDLN_print("NETLIST ERROR: $const constants are connected to net:");
	    report_net($lowest);
	};

	if(($const>0) && ($dvr_rec ne '')){
	    HDLN_warn("NETLIST ERROR: Constant net is driven.");
	    HDLN_print("NETLIST ERROR: $const constants and cell output drivers are connected to net:");
	    HDLN_print("\tcell output drivers:");
	    @dvr_info = split(/ /, $dvr_rec);
	    for($dvr_idx=0; $dvr_idx<=$#dvr_info;$dvr_idx+=2){
		$dvr_cell_id = $dvr_info[$dvr_idx];
		$cell_name = make_cell_name($dvr_cell_id);
		$pin_name = $HDLN_mod_port_names[$HDLN_cell_mod_id[$dvr_cell_id]][$dvr_info[$dvr_idx+1]];
		HDLN_print("\t\t$cell_name pin=$pin_name");
	    };
	    HDLN_print("\tnet names:");
	    report_net($lowest);
	    
	    HDLN_print("");
	}
    }
    
    return $dvr_rec;
}

##########################################################

# pass_three -- build the DAG, or at least a Directed Graph.

# For each cell, take the list of nets it drives and build it to a
# list of cells.

# Loop over the cell array.  For each cell, loop over all the
# connections to the nets it it drives.  Keep track of what cells it
# is connect to using the %drives hash.  At the end turn the hash into
# a space separated list of cell_ids.

# Finding strongly connect components (SCC's) in the cell drivers
# graph.

# For each SCC, there is a space separated list of cell_ids.

use vars '@scc_lists';

# Number of SCCs found.
use vars '$scc_cnt';
$scc_cnt = 0;    # number of strongly connected components.

sub pass_three{

    my($cell_id);
    my($cell_lim);
    my($net, $net_lim);
    my($pin);

    my($idx, $lim);
    my($drv_pin);
    my($connect_cell, $connect_port);
    my($connect_mod, $connect_dir);
    my(%drives);
    my($drv_idx, $drv_cnt);
    my($drives_nets);
    my($driving_pins);

    $DAG_edges = 0;
    $cell_lim = $#HDLN_cell_name;
    for($cell_id=1; $cell_id<=$cell_lim; $cell_id++){

	# clear the set of cells this cell drives.
	%drives = ();
	$drives_nets = $HDLN_cell_drives_nets[$cell_id];
	$driving_pins = $HDLN_cell_driving_pins[$cell_id];
	$drv_cnt = vec($HDLN_cell_drives_cnt, $cell_id, 32);
	for($drv_idx=0; $drv_idx<$drv_cnt; $drv_idx++){
	    $net = vec($drives_nets, $drv_idx, 32);
	    $net_lim = $net;
	    while(1) {
		$lim = vec($HDLN_netlist_cnt, $net, 32);
		for($idx=0; $idx<$lim;  $idx++){
		    $connect_cell = vec($HDLN_netlist_cells[$net], $idx, 32);
		    $connect_port = vec($HDLN_netlist_ports[$net], $idx, 32);
		    $connect_mod  = $HDLN_cell_mod_id[$connect_cell];
                    $connect_dir = $HDLN_mod_port_dirs[$connect_mod][$connect_port];
		    if($connect_cell != $cell_id){

			if($connect_dir != $HDLN_PORT_DIR_OUTPUT){
			    # remember this cell.
			    $drives{$connect_cell} = 1;
			    $DAG_edges++;
			}

		    }else{			

			# This connection is to the cell itself,
			# make sure it's connected to only the output.

			$drv_pin = vec($driving_pins, $drv_idx, 32);
			if($drv_pin != $connect_port){
			    # This cell drives itself (I hope it's a
			    # flip-flip!).
			    $drives{$connect_cell} = 1;
			    $DAG_edges++;

			    # The SCC check doesn't find self-loops, so
			    # build it here
			    if($HDLN_cell_is_seq[$cell_id] == 0) {
				# This is not a flip-flop, so its a async loop,
				# make a list of one.
				$scc_lists[$scc_cnt++] = "$cell_id";
			    }
			};
		    };
		};

		# Follow the list.
		$net = vec($HDLN_netlist_clst, $net, 32);
		if($net == $net_lim){
		    last;
		};
	    };
	};
	$HDLN_cell_dag[$cell_id] = join(" ", keys(%drives));
    };  # for($cell_id)
}

##########################################################

# HDL_report_cone -- given a net name, report the cone of logic driven
# by the wire.

# Reporting the cone of logic loops over inputs connected to the wire
# and does a depth first search on the cells connected to the input.
# The search stops when a flip-flop is reached.

# @CONE_val is the array used to mark which nodes have already been
# visited.

use vars '@CONE_val';

# $CONE_level is a global used to report one '~' of each level of
# driver.

use vars '$CONE_level';

# $CONE_prefix flags if the cell is the end of the clone, which is
# defined to be when the cell is sequential or when it is in the
# $HDLN_cone_report_truncate hash.

use vars '$CONE_prefix';

# The CONE_trunc flag says comment out this and deeper levels

use vars '$CONE_trunc';

# The $CONE_drive_net is the net_id of the driver for reported logic
# cone.  It is effected by the '-l level' option.

use vars '$CONE_drive_net';

# Function to call for each component.
# use vars '$CONE_function';

# Default for CONE_function.
# sub null_function{}

# Sometimes (when extracting buffer trees) we want the and non-buffer
# and non-inverter cell to become a leaf cell.  This flag controls
# this.

use vars '$CONE_logic_is_leaf';

# JDJ Sun Jul  9 09:46:29 2000:
# Input value of $instance_path is ignored!
# push(@EXPORT, 'HDL_report_cone');

sub HDL_report_cone{
    # my($instance_path, $wire_name_ref, $cone_funct_ref, $logic_is_leaf) = @_;
    my($net_report_ref) = @_;

    my($instance_path);
    my($wire_name);
    my($path_id);
    my($net_name);
    my($wire_table_ref);

    my(@wire_info);
    my($wire_rec);
    my($wire);
    my($bit);
    my($incr);

    my($net, $net_lim);
    my($idx, $lim);
    my($connect_cell);

    my($connect_port);
    my($connect_mod);
    my($connect_dir);
    my($driving_cell);
    my($driving_port);
    my($driving_mod);
    my($cell_name);
    my($pin_name);
    my($rs);
    my($msg);

    my($nets_vec) = '';
	
    # Set the type of netlist flag.
    # Expected values are 'net', 'clk' and 'buf'.
    $CONE_logic_is_leaf = 
	($$net_report_ref[$HDLN_NET_REPORT_TYPE] ne 'net');

    $wire_name = $$net_report_ref[$HDLN_NET_REPORT_NAME];

    $rs = rindex($wire_name, '/');
    #warn("netlist: rs=$rs, wire_name=$wire_name\n");

    if(($rs<0) || ($wire_name =~ /^\\/)){ 
	# No slash in name, or the name starts with a slash, use
	# root module.
	$instance_path = $HDLN_root_module;
    }else{
	$instance_path = substr($wire_name, 0, $rs+1);
	$wire_name = substr($wire_name, $rs+1);
    }

    #warn("netlist: instance_path=$instance_path wire_name=$wire_name\n");

    if(!defined($path_id=$HDLN_path_id{$instance_path})){
	HDLN_warn("Instance path '$instance_path' not found");
	return 0;
    };
    
    $wire_table_ref = $HDLN_wire_table_ref[$path_id];

    if(!defined($wire_rec=$wire_table_ref->{$wire_name})){
	HDLN_warn("Wire '$wire_name' not found in instance '$instance_path'");
	return 0;
    };

    # Loop over this net's connections.  For each non-output, do a
    # depth first search and the DAG.

    @wire_info = split(/ /, $wire_rec); 
    $bit = $wire_info[$HDLN_NET_ID_LEFT_BIT];
    $incr = $wire_info[$HDLN_NET_ID_RANGE_FLAG];

    # Loop over the bits of this wire.

    for($wire=$HDLN_NET_ID_NETS; $wire<=$#wire_info; $wire++){

	HDLN_print("");  # Blank line
	$msg = "***CONE $$net_report_ref[0] $wire_name";
	if($incr != 0){
	   $msg .= "\[$bit\]";
	};
	$msg .= " instance $instance_path";
	HDLN_print($msg);

	# Clear the array used to flag which cells have already been
	# reported.

	@CONE_val = ();
	$CONE_trunc = 0;
	$CONE_prefix = '   ';
	$CONE_level = '~';
	$net_lim = $wire_info[$wire];
	$net = $net_lim;

	$CONE_drive_net = -1;

	# Loop over the circular list for the net.

	while(1){

	    # Loop over the cells connected to this section of the
	    # net.

	    $lim = vec($HDLN_netlist_cnt, $net, 32);
	    for($idx=0; $idx<$lim;  $idx++){

		# Need to visit this cell if it's not driving this net.

		$connect_cell = vec($HDLN_netlist_cells[$net], $idx, 32);
		$connect_port = vec($HDLN_netlist_ports[$net], $idx, 32);
		$connect_mod  = $HDLN_cell_mod_id[$connect_cell];
		$connect_dir = $HDLN_mod_port_dirs[$connect_mod][$connect_port];
		if($connect_dir != $HDLN_PORT_DIR_OUTPUT){
		    if(! defined($CONE_val[$connect_cell])){
			vec($nets_vec, 0, 32) = $net;
			cone_visit($connect_cell, $nets_vec, 1);
		    }
		}else{
		    $driving_cell = $connect_cell;
		    $driving_port = $connect_port;
		    $driving_mod = $connect_mod;
		}
	    }

	    # Follow the net circular list.

	    $net = vec($HDLN_netlist_clst, $net, 32);
	    if($net == $net_lim){
		last;
	    }
	}

	if($CONE_drive_net < 0){
	    # -l level not specified, use the input net.
	    $CONE_drive_net = $net;
	}

	($net_name, $path_id) = get_first_net_name($CONE_drive_net);
	$msg = "driving_net: $net_name";

	if($path_id != $root_path_id){
	    $cell_name =  make_cell_name($driving_cell);
	    $pin_name = $HDLN_mod_port_names[$driving_mod][$driving_port];
	    $msg .= " $cell_name pin: $pin_name";
	}
	HDLN_print($msg);

	$bit += $incr;
    }
}

#############################################################

# cone_visit -- recursive subroutine used to find the cone of logic
# from cell.  Does a depth first search on the statement DAG.

# See Sedgewick, "Algorithms in C"

sub cone_visit {
    my($k, $nets_vec, $nets_vec_cnt) = @_;

    my($drives_cnt);
    my($edgelst);
    my($v, @verts, $i);
    my($cell_name);
    # my($is_trunc);
    my($pin_name);
    my($level);
    my($leaf);
    my($net_idx, $net, $net_name, $p);
    my($msg);

    my($level_save) =  $CONE_level;;
    my($prefix_save) = $CONE_prefix;;
    my($trunc_save) = $CONE_trunc;;

    $CONE_val[$k] = 1; 

    # There are two different visit functions rolled into one here.
    # The $CONE_logic_is_leaf flag says whether to emit buffer tree
    # replacement information, which is a list of cells to be removed
    # and a list of connections to be made (maybe more than one per
    # cell).  IF $CONE_logic_is_leaf is false we emit a DAG style
    # netlist, a long with net names

    if(!$CONE_logic_is_leaf){
	for($net_idx=0; $net_idx<$nets_vec_cnt; $net_idx++){
	    $net = vec($nets_vec, $net_idx, 32);
	    # Setup the @HDLN_net_first_name entries.
	    get_drivers($net);
	    $net = $HDLN_net_first_name[$net];
	    ($net_name, $p) = get_net_name($net);
	    HDLN_print("Net: $net_name");
	}
    }

    $pin_name = pin_connections($k, $nets_vec, $nets_vec_cnt);

    # If this the start of the delete depth then set the delete flag.

    $level = length($CONE_level);

    $cell_name = make_cell_name($k);
    
    $leaf = 0;
    if($HDLN_cell_is_seq[$k]){
	# print("cone_visit: is_trunc=$is_trunc HDLN_cell_is_seq\[$k\]=$HDLN_cell_is_seq[$k]\n");
	if($HDLN_mod_is_scan[$HDLN_cell_mod_id[$k]]){
	    $CONE_prefix = 'SFF ';
	}else{
	    $CONE_prefix = 'SEQ ';
	}
	$leaf = 1;

    }elsif(!defined($HDLN_mod_port_dirs[$HDLN_cell_mod_id[$k]][2])){

	# This cell has only two ports, so it must be a buffer.
	# when inserting buffer tree we want to delete all existing
	# buffers, so flag it to be deleted.

	$CONE_prefix = '2P  ';

    }else{
	
	# This cell is not sequential, and it does not have
	# exactly two ports, so it must be some other logic ties the the
	# tree. 

	$leaf = $CONE_logic_is_leaf;
	$CONE_prefix = 'GATE';
    }

    $msg = "$CONE_prefix $CONE_level pin: $pin_name $cell_name";

    # $CONE_trunc |= $is_trunc;
    # if($HDLN_cell_is_seq[$k]) {

    if($leaf){

	# This is the end of the DAG, don't report fanout.

	HDLN_print("$msg");
	@verts = ();

    } else {

	#  Search deeper.

	$edgelst = $HDLN_cell_dag[$k];
	@verts = split(/ /, $edgelst);

	# Report the fanout for this driver.
	$msg .= sprintf(" fanout=%d", scalar @verts);
	HDLN_print($msg);
    }

    # Call the passed in cone function
    # for the cases when we are doing more than just printing.
    # &$CONE_function($level, $k);

    $CONE_level .= '~';

    for($i=0; $i<@verts; $i++) {
	$v = $verts[$i];
	if($CONE_logic_is_leaf || (! $CONE_val[$v])) {
	    # Reporting all connections to leaf cells or 
	    # First time this node has been seen.
	    &cone_visit($v, $HDLN_cell_drives_nets[$k],
			vec($HDLN_cell_drives_cnt, $k, 32));
	}
    }

    $CONE_trunc = $trunc_save;
    $CONE_level = $level_save;
    $CONE_prefix = $prefix_save;

}; # cone_visit

#####################################

# Find strongly connect components (SCC's) in the cell drivers graph.
# See Sedgewick, "Algorithms in C", page 482.

push(@EXPORT, 'do_scc_check');
sub do_scc_check{

    # All locals are variables passed to &scc_visit.
    use vars '$scc_id'; local($scc_id);

    # The node marked array, index by a cell_id
    use vars '@scc_val'; local(@scc_val);  

    # Stack of visited node for SCC algorithm
    use vars '@scc_stack'; local(@scc_stack);  

    # stack pointer:
    use vars '$scc_p'; local($scc_p); 

    # Used  while building Cell_ids in each SCC.
    use vars '@scc_list'; local(@scc_list); 

    use vars '$scc_tristate_loops'; local($scc_tristate_loops);
    use vars '$scc_async_loops'; local($scc_async_loops);

    my($k);

    $scc_id = 0;
    $scc_p = 0;

    @scc_val = ();   # Clear the array.
    $#scc_val = $#HDLN_cell_name;  # pre-allocate the mark array.

    # JDJ Sun Nov 19 16:40:46 2000:
    # This started at 1 before I changed it first cell number to 1.
    # Should it be 2?

    for($k=1; $k <= $#HDLN_cell_name; $k++){
	if (! defined($scc_val[$k])) {
	    &scc_visit($k);
	};
    };
    
    print_scc_lists();

    if($scc_tristate_loops){
	HDLN_warn("Found $scc_tristate_loops possible async loops if all tri-states are enabled.");
    };

    HDLN_warn("Found $scc_async_loops async loops.");

    if($scc_async_loops != 0){
	HDLN_print("=================================\n");
    }

    return($scc_cnt);
};

#####################################

# scc_visit -- recursive subroutine used in finding the strongly
# connected components of the statement graph, when it is not a DAG.
# See Sedgewick, page 482.

sub scc_visit {
    my($k) = @_;

    my($edgelst);
    my($v, @verts);
    my($m, $min);
    my($snum);
    my($scc_edge_cnt);

    $scc_val[$k] = ++$scc_id;
    $min = $scc_id;
    $scc_stack[$scc_p++] = $k;

    if($HDLN_cell_is_seq[$k] == 0) {
	# This is not a flip-flop, follow  what it drives.
	@verts = split(/ /, $HDLN_cell_dag[$k]);
	foreach $v (@verts) {
	    # print("scc_visit: foreach k=$k v=$v min=$min scc_id=$scc_id scc_p=$scc_p\n"); 
	    $m = (! $scc_val[$v]) ? &scc_visit($v) : $scc_val[$v];
        
	    # print("scc_visit: set m: v=$v m=$m min=$min k=$k scc_id=$scc_id scc_p=$scc_p\n"); 
	    if($m < $min) {
		$min = $m;
	    };
	};
    };

    if ($min == $scc_val[$k]){
        $scc_edge_cnt = 0;
        $#scc_list = 0;  # Clear out the array.
	while (!defined($scc_stack[$scc_p]) || ($scc_stack[$scc_p] != $k)) {
                $snum = $scc_stack[--$scc_p]; 
	        $scc_list[$scc_edge_cnt++] = $snum;
		$scc_val[$scc_stack[$scc_p]] = $#HDLN_cell_name+1;
       	};

	if($scc_edge_cnt > 1){
	    $scc_lists[$scc_cnt++] = join(' ', @scc_list);
	};
   };
   return($min);

}; # scc_visit

###########

# print_scc_lists -- print out the lists of nodes containing
# strongly connected components.

sub print_scc_lists { 

    my($x, $path_id);
    my($rec, @list);
    my(@drives, $i, $nxt);
    my(%list_pos);
    my($reported);
    my($flag);
    my($cell_name);
    my($tristate);

    $scc_tristate_loops = 0;
    $scc_async_loops = 0;

    foreach $rec (@scc_lists){

	# print("print_scc_lists: rec=$rec\n");

	@list = sort {$a <=> $b} split(/ /, $rec);

	$tristate = 0;

	%list_pos = ();
	for($i=0; $i<=$#list; $i++){
	    $list_pos{$list[$i]} = $i;

	    # If this loop contains a tri-state drive,
	    # then don't complain about it.

	    if($HDLN_mod_tristate[$HDLN_cell_mod_id[$list[$i]]]){
		$tristate = 1;
	    };
	};
	    
	if($tristate){
	    $scc_tristate_loops++;
	} else {

	    # Report the async loop

	    $scc_async_loops++;

	    $reported = 0;
	
	    HDLN_print("==========");
	    HDLN_print("NETLIST WARNING: Async loop found (strongly connected directed graph topology found):");
	    
	    # Need to loop until all the cells in the list are reported,
	    # not just the first async loop.
	    $i = 0;
	    while($reported <= $#list){
		
		while(($x=$list[$i]) >= 0){

		    $list[$i] = -1;  # Flag this one as printed.
		    $reported++;
		    
		    
		    $cell_name = make_cell_name($x);
		    HDLN_print("");
		    HDLN_print("Driver: $cell_name");
		    
		    # print("\t  cell_id=$x, drives cell_ids: ($HDLN_cell_dag[$x])\n");
		    
		    @drives = split(/ /,$HDLN_cell_dag[$x]);
		    $i = -1;
		    foreach $nxt (@drives) {
			# print("print_scc_list: drives='@drives' nxt=$nxt list_pos='%list_pos'\n");
			
			if(defined($list_pos{$nxt})){
			    # Found the which cell in the SCC that this one drives.
			    $i=$list_pos{$nxt};
			    $flag = "**>";
			} else {
			    $flag = "-->";
			};
			
			$cell_name = make_cell_name($nxt);
			HDLN_print("\t$flag $cell_name");
		    }
		    if($i < 0){
			fatal("print_scc_lists: INTERNAL ERROR 121613: SCC cell $x does not drive another cell in SCC");
		    };
		};
		
		if($reported <= $#list){
		    HDLN_print("*** The above list is an async loop.  Another loop sharing some of the same cells is:");
		    # Find next unreported element.
		    for($i=0; $i<=$#list; $i++){
			if($list[$i] >= 0){
			    # Use this $i.
			    last;
			};
		    };
		    
		    if($i > $#list){
			fatal("print_scc_lists: INTERNAL ERROR 140313: More SCC drivers to report but no progress made");
		    };
		};
	    };
	    HDLN_print("=====\n");
	}  # if{$tristate) .. else report/
    }
}

##########################################################

# make_cell_name -- given a cell_id, create a name string for it.

# $HDL_fields is also setup so that $HDLN_fields[$HDLN_INSTANCES_ID]
# holds the cell name.

sub make_cell_name{
    my($cell_id) = @_;

    my($path_id);

    ($path_id, $HDLN_lnum) = split(/ /, $HDLN_cell_name[$cell_id]);
    get_fields();

    return "cell: $HDLN_fields[$HDLN_INSTANCES_ID] instance: $HDLN_path_name[$path_id]$HDLN_fields[$HDLN_INSTANCE_NAME]";
}

##########################################################

push(@EXPORT, 'HDLN_cell_instance_name');
sub HDLN_cell_instance_name{
    my($cell_id) = @_;

    my($path_id);

    ($path_id, $HDLN_lnum) = split(/ /, $HDLN_cell_name[$cell_id]);
    get_fields();
    
    return("$HDLN_path_name[$path_id]$HDLN_fields[$HDLN_INSTANCE_NAME]");
}

##########################################################

push(@EXPORT, 'HDLN_cell_type_name');
sub HDLN_cell_type_name{
    my($cell_id) = @_;

    my($path_id);

    ($path_id, $HDLN_lnum) = split(/ /, $HDLN_cell_name[$cell_id]);
    get_fields();
    
    return($HDLN_fields[$HDLN_INSTANCES_ID]);
}

##########################################################

# do_drivers_check -- Check to see if any net has other than one driver.

push(@EXPORT, 'do_drivers_check');
sub do_drivers_check{
    
    my($net);
    my($lowest);
    my($dvr_rec, @dvr_info, $dvr_idx);
    my($drivers);
    my($cell_id, $cell_name);
    my($net_cnt);
    my($path_id);
    my($pin_cnt);
    my($no_drv) = 0;
    my($multi_drv) = 0;
    my($no_conn) = 0;
    my($input_no_conn) = 0;
    my($const_no_conn) = 0;
    my($all_tri);
    my($tristate_net_cnt) = 0;
    my($msg);

    my(@no_drivers) = ();
    my(@unconn_consts) = ();
    my(@unconn_inputs) = ();
    my(@unconn_nets) = ();

    # Empty cached data, uses the HDLN_net_first_name array as flag
    # for the already checked nets.

    @HDLN_net_driver = ();
    @HDLN_net_first_name = ();
    $HDLN_net_driver_ts = $HDLN_netlist_ts-1; # Force a rebuild.

    $net_cnt = 0;
    for($net=0; $net<=$#HDLN_net_name; $net++){

	if(!defined($HDLN_net_first_name[$net])){

	    $net_cnt++;
	    # First net_id in this circular list, check it.

	    $dvr_rec = get_drivers($net);

	    @dvr_info = split(/ /, $dvr_rec);
	    $drivers = ($#dvr_info + 1) >> 1;

	    if($drivers == 0){
		# ($net_name, $path_id) = get_first_net_name($net);
    
		$lowest = $HDLN_net_first_name[$net];

		$path_id = vec($HDLN_net_name[$lowest], $NET_NAME_PATH_ID, 32);

		#my($net_namex, $path_idx);
		#($net_namex, $path_idx) = get_first_net_name($net);
		# warn("do_drivers_check: net_namex=$net_namex, path_idx=$path_idx lowest=$lowest\n");

		# Check for nets driven by constants, primary inputs,
		# and unconnected nets.

		$pin_cnt = net_connections($net);

		if($pin_cnt == 0){
		    if($path_id==$PATH_ID_CONST){
			if($HDLN_unconnected_const_warn){
			    push(@unconn_consts, $net);
			}
			$const_no_conn++;
		#    }elsif($path_id==$PATH_ID_INPUT){
		#	push(@unconn_inputs, $net);
		#	$input_no_conn++;
		    }else{
			if($HDLN_unconnected_net_warn){
			    push(@unconn_nets, $net);
			}
			$no_conn++;
		    }
		}
		if(($pin_cnt>0) && ($path_id>$PATH_ID_CONST) &&
		   ($path_id!=$root_path_id) ) {
		    # warn("do_drivers_check: no drivers-- lowest=$lowest pint_cnt=$pin_cnt path_id=$path_id\n");
		    push(@no_drivers, $net);
		    $no_drv++;
		};

	    }elsif($drivers > 1){

		# Multiple drivers, make sure they are all tristates.
		# First loop over all the drivers.

		$all_tri = 1;  # Assume all are tristate.
		for($dvr_idx=0; $dvr_idx<=$#dvr_info;$dvr_idx+=2){
		    if(! $HDLN_mod_tristate[$HDLN_cell_mod_id[$dvr_info[$dvr_idx]]]){
			$all_tri = 0;
		    };
		};

		if($all_tri) {
		    $tristate_net_cnt++;
		}else{
		    HDLN_print("Net has $drivers drivers. Net name:");
		    report_net($net);
		    $multi_drv++;
		    HDLN_print("  Drivers:");
		    for($dvr_idx=0; $dvr_idx<=$#dvr_info;$dvr_idx+=2){
			$cell_name = make_cell_name($dvr_info[$dvr_idx]);
			# print("\t$cell_name pin=$dvr_info[$dvr_idx+1]\n");
			HDLN_print("\t$cell_name pin: $HDLN_mod_port_names[$HDLN_cell_mod_id[$dvr_info[$dvr_idx]]][$dvr_info[$dvr_idx+1]]");
		    };
		    HDLN_print("");
		}
	    } else {
		# number of drivers == 1,
	    } # Drivers == 1
	}
    }

    # Now loop over the nets that were buffered up and reported each
    # problem in a group.

    foreach $net (@unconn_consts) {
	HDLN_print("Unconnected constant:");
	report_net($net);
    }	
    foreach $net (@unconn_inputs) {
	HDLN_print("Unconnected primary input:");
	report_net($net);
    }	
    foreach $net (@unconn_nets) {
	HDLN_print("Net has no connections:");
	report_net($net);
    }	

    foreach $net (@no_drivers) {
	HDLN_print("Net has no drivers:");
	report_net($net);
    }	

    HDLN_warn("Checked drivers for $net_cnt nets.");

    if($HDLN_implicit_wires){
	$msg = "Declared $HDLN_implicit_wires implicit wires";
	if(! $HDLN_implicit_wire_warn){
	    $msg .= " (use +i to report.)";
	}else{
	    $msg .= '.';
	}
	HDLN_warn($msg);
    }

    if($tristate_net_cnt){
	HDLN_warn("Found $tristate_net_cnt nets driven by multiple tri-state drivers.");
    }

    if($const_no_conn){
	$msg = "Found $const_no_conn unconnected constants";
	if(! $HDLN_unconnected_const_warn){
	    $msg .= " (use +c to report.)";
	}else{
	    $msg .= '.';
	}
	HDLN_warn($msg);
    }

    if($no_conn){
	$msg = "Found $no_conn nets with no connections";
	if(! $HDLN_unconnected_net_warn){
	    $msg .= " (use +u to report.)";
	}else{
	    $msg .= '.';
	}
	HDLN_warn($msg);
    }

    HDLN_warn("");

    if($input_no_conn){
	HDLN_warn("Found $input_no_conn primary inputs with no connections.");
    }

    if($multi_drv){
	HDLN_warn("Found $multi_drv nets with multiple drivers.");
    };
    if($no_drv){
	HDLN_warn("Found $no_drv nets with no drivers.");
    }

    return $net_cnt;
}

##########################################################

# do_unassign

sub do_unassign{

    my($outer_net);
    my($net);
    my($last_net);
    my($dvr_rec);
    my($path_id);
    my($p);
    my($mod_id);
    my($name);
    my(%connection_cnt);
    my($cnt);
    my($connected);
    my($wire_rec, @wire_info);
    my($mapto_rec);
    my($driven_rec);
    my(%paths);
    my($is_const);
    my($path_ids_with_connections);
    my($net_list_ref);
    my($uniq_needed);
    my($list_ref);
    my($c_name, $c_bus, $const_rec);
    my($base_name, $bus, $rec);
    my($lowest);
    my($xnet, $xpath);

    # Empty cached data, uses the HDLN_net_first_name array as flag
    # for the already checked nets.

    @HDLN_net_driver = ();
    @HDLN_net_first_name = ();
    $HDLN_net_driver_ts = $HDLN_netlist_ts-1; # Force a rebuild.

    for($outer_net=0; $outer_net<=$#HDLN_net_name; $outer_net++){

	if(!defined($HDLN_net_first_name[$outer_net])){

	    # First net_id in this circular list, check it.

	    # Set the first_name:
	    $dvr_rec = get_drivers($outer_net);

	    %paths = ();
	    $path_ids_with_connections = 0;
	    $uniq_needed = 0;

	    $lowest = $HDLN_net_first_name[$outer_net];
	    
	    # warn("do_unassign: outer_net=$outer_net, lowest=$lowest\n"); 

	    $p = vec($HDLN_net_name[$lowest], $NET_NAME_PATH_ID, 32);
	    if($p <= $PATH_ID_CONST){
		$is_const = 1;
		($c_name, $c_bus, $const_rec) = unassign_rec($lowest);
	    }else{
		$is_const = 0; 
	    }

	    # Look for two signals in the same path, or a constant.

	    $net = $outer_net;
	    $last_net = $net;
	    while(1) {

		$path_id = vec($HDLN_net_name[$net], $NET_NAME_PATH_ID, 32);
		if($path_id <= $PATH_ID_CONST){

		    # This is the constant, don't enter
		    # it into the unassign table.
		    if($is_const == 0){
			fatal("INTERNAL: do_unassign -- unexpected PATH_ID_CONST");
		    }

		}elsif($is_const){

		    # This constant always needs to be mapped.

		    ($base_name, $bus, $rec) = unassign_rec($net);
		    # warn("do_unassign: mapping constant: path_id=$path_id rec=$rec\n");
		    $HDLN_unassign{$path_id}->{$rec} = $const_rec;
		    if($bus){
			$HDLN_unassign{$path_id}->{$base_name} = ':u';
		    }

		    # If this is a port then this path_id needs to
		    # be uniquified.

		    $mod_id = $HDLN_path_mod_id[$path_id];
		    if(defined($HDLN_mod_portorder_ref[$mod_id]->{$base_name})){
			# This constant is a port of this module, so
			# we need to uniquify modules in this path.
			# warn("do_unassign: port is constant: path_id=$path_id rec=$rec\n");
			$uniq_needed = 1;
		    }

		}else{  # else not a constant, save in the hash of paths.

		    # Save  away the list of nets for each used path.
                    push(@{$paths{$path_id}}, $net);
		}

		$net = vec($HDLN_netlist_clst, $net, 32);
		if($net == $last_net){
		    last;
		}
	    } #while(1)

	    # Loop over each used path_id to see if an unassign is
	    # needed in each module.  This search is needed because we
	    # have to pick an output port over an input port when
	    # substituting the signals.

	    while (($path_id, $net_list_ref) = each(%paths)) {
		if(scalar(@{$net_list_ref}) > 1){

		    # This path_id has 2 or more net names for the
		    # same net, an unassign is needed.

		    # Keep track of how many unique path_id have
		    # connections, to determine if we must uniquify
		    # the modules used in this path.

		    $path_ids_with_connections++;

		    # Get the signal name to use in this module
		    # (path), it is the name of the driver, or is an
		    # input.

		    ($mapto_rec, $driven_rec) =
			select_unassign_net($path_id, $net_list_ref);

		    # Build a table for this path_id that says to
		    # connect this signal name to the first signal
		    # name.

		    foreach $net (@{$net_list_ref}){

			($base_name, $bus, $rec) = unassign_rec($net);

			$HDLN_unassign{$path_id}->{$rec} = $mapto_rec;
			$HDLN_unassign_driven{$path_id}->{$rec} = $driven_rec;
			
			# warn("do_unassign: HDLN_unassign\{$path_id\}->\{$rec\} = $rec0;\n");

			# If this is a bit of a bus then also flag the
			# bus name as needing an unassign.

			if($bus){
			    $HDLN_unassign{$path_id}->{$base_name} = ':u';
			}
		    }
		}
	    } # while(each())

	    # If there is more than one path_id that needs to have
	    # nets connected then there are probably two or more ports
	    # connected to the net.  In this case we uniquify all of
	    # the modules that this net passes through.  Also if a
	    # constant is connected to a port then uniquify these
	    # paths.

	    if(($path_ids_with_connections > 1) 
	       || $uniq_needed){

		# Set flags saying these path_ids must be uniquified.

		$net = $outer_net;
		while(1) {

		    $path_id = vec($HDLN_net_name[$net], $NET_NAME_PATH_ID, 32);
		    if($path_id > $PATH_ID_CONST){
			$HDLN_uniquify_path_id{$path_id} = 1;
		    }
		    
		    # Follow the list.
		    $net = vec($HDLN_netlist_clst, $net, 32);
		    if($net == $outer_net){
			last;
		    }
		}
	    }
	}
    }
}

##########################################################

# on_dvr_path -- Return 1 if the passed in path_id is
# on the path to the passed in net_id.

sub on_dvr_path{
    my($path_id, $net_id)=@_;

    my($path);
    my($dvr_rec);
    my(@dvr_info);
    my($drivers);
    my($cell_rec);
    my(@cell_info);
    my($cell_path);
    my($port_num);
    my($trunc_path);
    my($xname, $xpath); # for debug


    ($xname, $xpath) = get_net_name($net_id);
    #warn("on_dvr_path: path_id=$path_id, net_id=$net_id ($xname)\n");

    if($path_id <= $PATH_ID_CONST){
	fatal("INTERNAL: on_dvr_path: path_id is a constant");
    }

    $path = $HDLN_path_name[$path_id];

    # warn("on_dvr_path: path=$path $xname, $xpath\n");
    

    $dvr_rec = get_drivers($net_id);

    @dvr_info = split(/ /, $dvr_rec);
    $drivers = ($#dvr_info + 1) >> 1;
    if($drivers == 0){
	return 0;
    }

    # warn("on_dvr_path: drv_info=@dvr_info\n");

    # Alway pic the first driver if there are more than 1.  Multiple
    # drivers are reported elsewhere.

    $cell_rec = $HDLN_cell_name[$dvr_info[0]];
    @cell_info = split(/ /, $cell_rec);
    $cell_path = $HDLN_path_name[$cell_info[0]];

    # warn("on_dvr_path: cell_info=@cell_info, cell_path=$cell_path\n");

    $trunc_path = substr($cell_path, 0, length($path)); 
			
    # warn("on_dvr_path: compare '$path' to '$trunc_path' for $xname\n");

    if($path eq $trunc_path){
	# warn("on_dvr_path: return 1, xname=$xname, path=$HDLN_path_name[$path_id]\n");
	return 1;
    }else{
	# warn("on_dvr_path: 0 return, xname=$xname, path=$HDLN_path_name[$path_id]\n");
	return 0;
    }
}

##########################################################

# get_unassign_port -- For the passed in module port
# type, find the lowest port number and bit number
# for the nets in the $net_list_ref.

sub get_unassign_port{
    my($check_port_type, $net_list_ref) = @_;

    my($mapto_rec);
    my($mapto_bus);

    my($net_id);
    my($port_num);
    my($type);
    my($p_type);
    my($base_name, $bus, $rec);
    my($junk, $bit_num);
    my($max_type);
    my($min_port_num);
    my($min_bit_num);

    # Default to none;
    $mapto_rec = '';

    $max_type = $HDLN_driver_type_none-1;

    foreach $net_id (@{$net_list_ref}){
	$type = $HDLN_netlist_port_type[$net_id];
	
	# Treat input and inout as the same.

	if(($type == $check_port_type) ||
	   (($type == $HDLN_driver_type_mod_inout) &&
	    ($check_port_type == $HDLN_driver_type_mod_input))){

	    # This is the type of port we are looking for,
	    # priorize the port number.

	    $p_type = $type * 2; # Make room for a bus bit.
	    ($base_name, $bus, $rec) = unassign_rec($net_id);
	    if($bus){
		# Busses are more important than non-busses.
		$p_type += 1;
		($junk, $bit_num) = split(' ', $rec);
	    }

	    $port_num = $HDLN_netlist_port_num[$net_id];

	    if($p_type >= $max_type){
		if($p_type > $max_type){
		    # First time this type is seen, initialize the port
		    # number to used within this type.
		    $max_type = $p_type;
		    $min_port_num = 2000000000;
		}
		# Pick the smallest port number.
		if($port_num < $min_port_num){
		    # Found a new candidate, save it.
		    $min_port_num = $port_num;
		    $mapto_rec = $rec;
		    $mapto_bus = $bus;  
		    if($bus){
			$min_bit_num = $bit_num;
		    }
		}elsif($port_num == $min_port_num){
		    # Same port, check for differ bit.
		    if(!$mapto_bus){
			fatal("INTERNAL: get_unassign_port: expected mapto port to be a bus.");
		    }
		    if($bit_num < $min_bit_num){
			$min_bit_num = $bit_num;
			$mapto_rec = $rec;
		    }
		}
	    }
	}
    }

    return($mapto_rec);
}

##########################################################

# get_unassign_dvr -- For the passed in module type, find the driving
# cell and port for the nets in the $net_list_ref.

# Find the lower port and bit number of the cell
# on the path to the driver.

sub get_unassign_dvr{
    my($path_id, $net_list_ref) = @_;

    my($dvr_rec);
    my($dvr_bus);

    my($net_id);
    my($port_num);
    my($type);
    my($pid);
    my($p_type);
    my($base_name, $bus, $rec);
    my($junk, $bit_num);
    my($max_type);
    my($min_port_num);
    my($min_bit_num);
    my($xname, $xpath); # for debug

    # Default to none;
    $dvr_rec = '';

    $max_type = $HDLN_driver_type_none-1;

    foreach $net_id (@{$net_list_ref}){
	$type = $HDLN_netlist_driver_type[$net_id];

	($xname, $xpath) = get_net_name($net_id);

	# warn("get_unassign_dvr: top of loop, type=$type xname=$xname, path=$HDLN_path_name[$path_id]\n");

	if($type != $HDLN_driver_type_cell_output){
	    # Only checking ouputs.
	    next;
	}

	$pid = $HDLN_netlist_connected_pid[$net_id];
	if($pid > 0){
	    # This is a cell output, it must be a driver.
	}elsif(on_dvr_path(-$pid, $net_id)){
	    # The called module is on the driving path,
	    # test this port.
	}else{
	    # This net does not qualify as a possible driving
	    # pin, skip it.
	    next;
	}

	($xname, $xpath) = get_net_name($net_id);
	# warn("get_unassign_dvr: on-dvr-path xname=$xname, path=$HDLN_path_name[$path_id]\n");

	# Priorize the port number.

	$p_type = $type * 2; # Make room for a bus bit.
	($base_name, $bus, $rec) = unassign_rec($net_id);

	# warn("get_unassign_dvr: bus=$bus rec=$rec\n");
	
	if($bus){
	    # Busses are more important than non-busses.
	    $p_type += 1;
	    ($junk, $bit_num) = split(' ', $rec);
	}

	$port_num = $HDLN_netlist_connected_port[$net_id];

	if($p_type >= $max_type){
	    if($p_type > $max_type){
		# First time this type is seen, initialize the port
		# number to used within this type.
		$max_type = $p_type;
		$min_port_num = 2000000000;
	    }
	    # Pick the smallest port number.
	    if($port_num < $min_port_num){
		# Found a new candidate, save it.
		$min_port_num = $port_num;
		$dvr_rec = $rec;
		$dvr_bus = $bus;  
		if($bus){
		    $min_bit_num = $bit_num;
		}
		# warn("get_unassign_dvr: set dvr_rec=$dvr_rec, bus=$bus\n");
	    }elsif($port_num == $min_port_num){
		# Same port, check for differ bit.
		if(!$dvr_bus){
		    fatal("INTERNAL: get_unassign_port: expected dvr port to be a bus.");
		}
		if($bit_num < $min_bit_num){
		    $min_bit_num = $bit_num;
		    $dvr_rec = $rec;
		    # warn("get_unassign_dvr: update bit in dvr_rec=$dvr_rec, bus=$bus\n");
		}
	    }
	}
    }

    # warn("get_unassign_dvr: after first loop dvr_rec=$dvr_rec\n");

    if($dvr_rec eq ''){
	# Didn't find a ouput, see if there is an input 
	# to this module.

	$dvr_rec = get_unassign_port($HDLN_driver_type_mod_input,
				       $net_list_ref);
    }
    return($dvr_rec);
}

##########################################################

# select_unassign_net -- Select the net to use as the "map-to" net of
# an unassign within a module.

# The highest priority driver type is selected.

sub select_unassign_net{
    my($path_id, $net_list_ref) = @_;
    
    my($mapto_rec, $dvr_rec);

    my($net_id);
    my($mod_id);
    my($base_name, $bus);

    # warn("select_unassign_net: entered @{$net_list_ref}\n");

    # Find the driving net.

    $dvr_rec = get_unassign_dvr($path_id, $net_list_ref);

    if($dvr_rec eq ''){
	# No driver found, warn and fault to the first net.
	$net_id = $$net_list_ref[0];

	$mod_id = $HDLN_path_mod_id[$path_id];
	HDLN_warn("");
	HDLN_warn("During unassign, found no drivers for:");
	HDLN_warn("module: $HDLN_mod_name[$mod_id]");
	HDLN_warn("\tnet names:");
	report_net($net_id);

	($base_name, $bus, $dvr_rec) = unassign_rec($net_id);
    }

    # Find the mapto net.

    $net_id = $$net_list_ref[0];
    if(on_dvr_path($path_id, $net_id)){
	$mapto_rec = get_unassign_port($HDLN_driver_type_mod_output,
				       $net_list_ref);

    }else{
	$mapto_rec = get_unassign_port($HDLN_driver_type_mod_input,
				       $net_list_ref);
    }

    # This net is not connected to a module port,
    # use the drive net name for the mapto net.

    if($mapto_rec eq ''){
	$mapto_rec = $dvr_rec;
    }

    return($mapto_rec, $dvr_rec);
}

##########################################################

# do_flatten -- dump a flatten cell list with connection.
# Always writes to stdout.

sub do_flatten{

    my($cell_id);
    my($cell_rec);
    my($path_id);
    my($path_name);
    my($net_name);
    my($pin_name);
    my($port_id);
    my($port_cnt);
    my($nets);
    my($ports);
    my($net_id);
    my($pin_id);
    my($path);
    my($cell_lim);
    my(@ports);
    my($wire_table_ref);
    my($portorder_ref);
    my($port_num);
    my($port_name);
    my($dir);
    my($left);
    my($right);
    my($wire_rec);
    my(@wire_info);
    my($in_concat);
    my($next_pin_id);
    my($wire_name);

# $port_rec=$port_map_ref->[$port_num]  $HDLN_root_mod_id

    print("module $HDLN_root_module");

    @ports = ();

    $wire_table_ref = $HDLN_wire_table_ref[$root_path_id];

    if(defined($portorder_ref=$HDLN_mod_portorder_ref[$HDLN_root_mod_id])){
	# Get then port name in port order.
	foreach $port_name (keys %$portorder_ref){
	    $ports[$portorder_ref->{$port_name}] = $port_name;
	}
	# output the port names
	print(" (\n");

	for($port_num = 0; $port_num<=$#ports; $port_num++){
	    $port_name = $ports[$port_num];
	    print("\t$port_name");
	    if($port_num != $#ports){
		print(",\n");
	    }
	}
	print(")");
    }
    print(";\n\n");
    
    # Output the inputs and outputs.

    for($port_num=0; $port_num<=$#ports; $port_num++){
	$port_name = $ports[$port_num];
	$dir = $HDLN_mod_port_dirs[$HDLN_root_mod_id][$port_num];
	print("\t");
	if($dir ==  $HDLN_PORT_DIR_INPUT){
	    print("input");
	}elsif($dir ==  $HDLN_PORT_DIR_OUTPUT){
	    print("output");
	}elsif($dir ==  $HDLN_PORT_DIR_INOUT){
	    print("inout");
	}else{
	    fatal("do_flatten: bad i/o direction ($dir) for $port_name");
	}

	$wire_rec = $wire_table_ref->{$port_name};
	@wire_info = split(/ /, $wire_rec);
	
	if($wire_info[$HDLN_NET_ID_RANGE_FLAG] == $HDLN_NET_ID_RANGE_NONE){
	    print("\t");
	}else{
	    $left = $wire_info[$HDLN_NET_ID_LEFT_BIT];
	    $right = $left + 
		$wire_info[$HDLN_NET_ID_RANGE_FLAG]*($wire_info[$HDLN_NET_ID_BITS]-1);
	    print("\t\[$left:$right\]");
	}
	print("\t$port_name;\n");
    }

    # Emit the busses at top level.

    foreach $wire_name (sort keys %{$wire_table_ref}){
	#print("wire_name=$wire_name\n");
	$wire_rec = $wire_table_ref->{$wire_name};
	@wire_info = split(/ /, $wire_rec);
	if($wire_info[$HDLN_NET_ID_RANGE_FLAG] != $HDLN_NET_ID_RANGE_NONE){
	    $left = $wire_info[$HDLN_NET_ID_LEFT_BIT];
	    $right = $left + 
		$wire_info[$HDLN_NET_ID_RANGE_FLAG]*($wire_info[$HDLN_NET_ID_BITS]-1);
	    print(" \twire\t[$left:$right\]\t$wire_name;\n");
	}
    }
    print("\n");

    $cell_lim = $#HDLN_cell_name;

    for($cell_id=1; $cell_id<=$cell_lim; $cell_id++){
	$cell_rec = $HDLN_cell_name[$cell_id];
	($path_id,  $HDLN_lnum) = split(/ /, $cell_rec);
	get_fields();

	if($path_id > $root_path_id){
	    $path_name = "\\$HDLN_path_name[$path_id]$HDLN_fields[$HDLN_INSTANCE_NAME] ";
	}else{
	    $path_name = "$HDLN_fields[$HDLN_INSTANCE_NAME]";
	}

	print("$HDLN_fields[$HDLN_MODULE_NAME] $path_name");

	$port_cnt = vec($HDLN_connected_cnt, $cell_id, 32);
	$nets = $HDLN_connected_nets[$cell_id];
	$ports = $HDLN_connected_ports[$cell_id];
	$in_concat = 0;

	for($port_id=0; $port_id<$port_cnt; $port_id++){
	    if($port_id == 0){
		print(" (\n");
	    }

	    $net_id = vec($nets, $port_id, 32);

	    $pin_id = vec($ports, $port_id, 32);
	    ($net_name, $path) = get_first_net_name($net_id);

	    if($port_id != ($port_cnt-1)){
		$next_pin_id = vec($ports, $port_id+1, 32);
	    }else{
		$next_pin_id = -1;
	    }
	    
	    if($path == $PATH_ID_CONST){
		# Delete the special name.
		# Use /o to compile only once.
		$net_name =~ s/^$HDLN_path_name[$PATH_ID_CONST]//o;
	    }elsif($path == $PATH_ID_SUPPLY0){
		$net_name = "1'b0";
	    }elsif($path == $PATH_ID_SUPPLY1){
		$net_name = "1'b1";
	# JDJ 001116: not special any more.
	#    }elsif($path == $root_path_id){
	#	# Delete the special name.
	#	# Use /o to compile only once.
	#	$net_name =~ s/^$HDLN_path_name[$PATH_ID_INPUT]//o;
	#	$net_name =~ s/^$HDLN_path_name[$PATH_ID_OUTPUT]//o;
	    }

	    $pin_name = $HDLN_mod_port_names[$HDLN_cell_mod_id[$cell_id]][$pin_id];

	    if(!$in_concat){
		print("\t.$pin_name(");
	    }

	    if($pin_id == $next_pin_id){
		if(!$in_concat){
		    # First net of the bus, start the concat.
		    print("{\n");
		    $in_concat = 1;
		}
	    }


	    if($in_concat){
		print("\t\t");
	    }

	    if($path > $root_path_id){
		print("\\");
	    }
	    print("$net_name ");
	    
	    if($in_concat){
		if($pin_id != $next_pin_id){
		    # End of concat, close it up
		    print("}");
		    $in_concat = 0;
		}
	    }
	    if(!$in_concat){
		print(")");
	    }

	    if($port_id != ($port_cnt-1)){
		print(",\n");
	    }else{
		print(")");
	    }
	}
	print(";\n");
    }

    print("endmodule\n");
}

##########################################################

# do_netlist -- dump a netlist.  "Net-name: list of cells".  Cells in
# alphabetical order.  If it's a constant net, then only one cell per
# line.

# Always writes to stdout


sub do_netlist{

    my($outer_net);
    my($net);
    my($net_nxt);
    my($dvr_rec);
    my($lowest);
    my($name, $path);
    my($cell_ids);
    my($cell_cnt);
    my($c);
    my($cell);
    my($pin);
    my($cell_name);
    my(@cells);
    my($cell_mod_id);
    my($pin_name);

    my($len);
    my($max_len);
    my($max_name);

    my($path_id);
    my($port_type);

    my(@out_list);  # Big array to be sorted
    my($nam);
    my($cnt);
    my($line);

    # Empty cached data, uses the HDLN_net_first_name array as flag
    # for the already checked nets.

    @HDLN_net_driver = ();
    @HDLN_net_first_name = ();
    $HDLN_net_driver_ts = $HDLN_netlist_ts-1; # Force a rebuild.

    # warn("do_netlist: nets=$#HDLN_net_name\n");

    $max_len = 0; # Keep track of longest list.

    for($outer_net=0; $outer_net<=$#HDLN_net_name; $outer_net++){

	if(!defined($HDLN_net_first_name[$outer_net])){

	    # Setup lowest, mark $HDLN_net_first_name.

	    $dvr_rec = get_drivers($outer_net);

	    @cells = ();
	    $net = $outer_net;

	    while(1) {

		# Look for primary I/Os,
		# may be more that one connected to this net.

		$path_id = vec($HDLN_net_name[$net], $NET_NAME_PATH_ID, 32);
		if($path_id == $root_path_id){
		    if($HDLN_netlist_port_type[$net] != $HDLN_driver_type_none){
			($pin_name, $path) = get_net_name($net);
			push(@cells, $pin_name);

		    }
		}

		# Look at the connected cells.

		$cell_cnt = vec($HDLN_netlist_cnt, $net, 32);

		for($c=0; $c<$cell_cnt; $c++){

		    $cell = vec($HDLN_netlist_cells[$net], $c, 32);
		    $cell_name = HDLN_cell_instance_name($cell);
		    $pin_name = get_pin_name($net, $c);

		    push(@cells, "$cell_name.$pin_name");
		} 

		$net = vec($HDLN_netlist_clst, $net, 32);
		if($net == $outer_net){
		    last;
		}
	    }

	    $lowest = $HDLN_net_first_name[$outer_net];
	    ($name, $path) = get_net_name($lowest);


	    $len = scalar(@cells);

	    # Don't report unconnected nets.

	    if($len){
		if($path <= $PATH_ID_CONST){
		    # Print out constants one line per cell,
		    # always including the value of the constant.
		    foreach $cell (@cells){
			push(@out_list, "$name: $cell");
		    }
		}else{
		    
		    @cells = sort(@cells);

		    if($HDLN_do_netlist_report_net_name){
			$nam = "$name: ";
		    }else{

			$nam = '';
		    }
		    push(@out_list, "$nam@cells");
		}
		    
		# Keep track of largest only for named nets, 
		# not constants.
		
		if($len > $max_len){
		    $max_len = $len;
		    $max_name = $name;
		}
	    }
	}
    }
    
    $cnt = scalar(@out_list);
    warn("Sorting $cnt nets ...\n");

    @out_list = sort(@out_list);

    $cnt = scalar(@out_list);
    warn("Writing $cnt output lines ...\n");

    foreach $line (@out_list){
	print("$line\n");
    }

    HDLN_warn("Largest: $max_len connections for $max_name");
}

##########################################################

# net_connections -- Count the number of pins connected to a net.

sub net_connections{
    my($net) = @_;
    my($net_lim, $cnt);

    $cnt = 0;
    $net_lim = $net;
    while(1) {
	
	$cnt += vec($HDLN_netlist_cnt, $net, 32);

	# Follow the list.
	$net = vec($HDLN_netlist_clst, $net, 32);
	if($net == $net_lim){
	    last;
	};
    };
    return $cnt;
}

##########################################################

# pin_connections -- report all the pins names on a given cell that
# are connected to a 'vec' of net_ids.

sub pin_connections{
    my($cell, $nets_vec, $vec_cnt) = @_;

    my(@pins_array) = ();
    my($nets_idx);
    my($net, $net_lim);
    my($idx, $lim);
    my($connect_cell);
    my($pin);
    my($cell_mod_id);
    my($pin_name);
    my($do_range);
    my($bit);

    for($nets_idx=0; $nets_idx<$vec_cnt; $nets_idx++){
	$net=vec($nets_vec, $nets_idx, 32);
	$net_lim = $net;
	while(1){

	    $lim = vec($HDLN_netlist_cnt, $net, 32);
	    for($idx=0; $idx<$lim;  $idx++){
		$connect_cell = vec($HDLN_netlist_cells[$net], $idx, 32);
		if($connect_cell == $cell){
		    $pin_name = get_pin_name($net, $idx);
		    push(@pins_array, $pin_name);
		}
	    }

	    # Follow the net circular list.
	    $net = vec($HDLN_netlist_clst, $net, 32);
	    if($net == $net_lim){
		last;
	    }
	}
    }
    return join(' ', @pins_array);
}

#########################################################
#
# get_pin_name -- Given a net_id and an index into
# the connected cells for the net_id, return the
# pin name (and bit number if it has one).

sub get_pin_name{
    my($net, $idx)=@_;

    my($cell);
    my($pin);
    my($cell_mod_id);
    my($do_range);
    my($bit);

    my($pin_name);

    $cell = vec($HDLN_netlist_cells[$net], $idx, 32);
    $pin = vec($HDLN_netlist_ports[$net], $idx, 32);
    $cell_mod_id = $HDLN_cell_mod_id[$cell];
    $pin_name = $HDLN_mod_port_names[$cell_mod_id][$pin];
    $do_range = $HDLN_mod_port_range[$cell_mod_id][$pin];
    if($do_range != 0){
	$bit = vec($HDLN_netlist_port_bit[$net], $idx, 32);
	$pin_name .=  "\[$bit\]";
    }

    return $pin_name;
}

##########################################################

# report_net --  report all the names for a net.

sub report_net{
    my($net) = @_;

    my($net_nxt, $net_lim);
    my($first, $parens);
    my($net_name, $p);

    # Setup the @HDLN_net_first_name entries.
    get_drivers($net);

    $net = $HDLN_net_first_name[$net];
    
    $first = 1;
    $parens = 0;
    $net_lim = $net;
    while(1) {
	
	($net_name, $p) = get_net_name($net);
	$net_nxt = vec($HDLN_netlist_clst, $net, 32);
	
	if($parens){
	    # another name, and this net has more than one name
	    # put a space in front.
	    $net_name = "  $net_name";

	    # If last name then add a closing paren
	    if($net_nxt==$net_lim){
		$net_name = "$net_name )";
	    };
	}
	
	if($first && ($net_nxt!=$net_lim)){
	    # This net has more than one name, put in parens.
	    $net_name = "( $net_name";
	    $first = 0;
	    $parens=1;
	}
	
	HDLN_print("\t$net_name");

	$net = $net_nxt;  # Follow the list.
	if($net == $net_lim){
	    last;
	};
    };
    HDLN_print("");
}

##########################################################

# emit_unassign -- loop over the modules.  For each one that
# must be uniquified, emit the required number of copies, changing
# the modules it calls.  Replace all the connected nets with just one
# name version.  Remove any assign statements.

sub emit_unassign{

    my($mods);
    my($mod_id);
    my($used_by_ref);
    my($emit_unmodified);
    my($path_id);
    my($non_unique_path_id);

    $mods = scalar(@HDLN_mod_def);

    for($mod_id=0; $mod_id<$mods; $mod_id++){
	if($HDLN_mod_def[$mod_id] == $HDLN_MOD_MODULE){
	    # This is an input module as opposed to a cell library,
	    # so emit it.

	    $used_by_ref = $HDLN_mod_used_by[$mod_id];

	    if(!defined($used_by_ref)){
		HDLN_warn("Deleting unused module module $HDLN_mod_name[$mod_id]");
		next;
	    }

	    # Loop over the instances of this module, emitting the ones
	    # that need to be uniquified.

	    $non_unique_path_id = -1; # Preset to an illegal value.
	    foreach $path_id (@$used_by_ref){
		if(defined($HDLN_uniquify_path_id{$path_id})){
		    # print("emit_unassign: Uniquify $HDLN_mod_name[$mod_id] for $HDLN_path_name[$path_id]\n");
		    reemit($mod_id, $path_id, 1);
		}else{
		    # print("emit_unassign: non-uniquify $HDLN_mod_name[$mod_id] for path_id=$path_id $HDLN_path_name[$path_id]\n");
		    $non_unique_path_id = $path_id;
		}
	    }
	    if($non_unique_path_id != -1){
		# This module is used more times than it is
		# uniquified, so emit the original version.

		# print("emit_unassign: Emit unmodified mod $HDLN_mod_name[$mod_id]\n");
		reemit($mod_id, $non_unique_path_id, 0);
	    }
	}
    }
}

##########################################################

# reemit -- Reemit a given module, changing all the instance calls to
# be prefixed by the given path name and specified instance name, if
# uniquify is set.

sub reemit{
    my($mod_id, $path_id, $uniquify) = @_;

    my($lnum_save);
    my($assigns);
    my($path_name);
    my($instance_prefix);
    my(@hdl);
    my($called_mod);
    my($called_mod_id);
    my($called_instance_name);
    my($called_path);
    my($called_path_id);

    # print("reemit: mod_id=$mod_id ($HDLN_mod_name[$mod_id]), path_id=$path_id ($HDLN_path_name[$path_id]) uniquify=$uniquify\n");

    $path_name =  $HDLN_path_name[$path_id];
    $instance_prefix = "$HDLN_root_module/$path_name";

    # Get rid of trailing slash.
    if(chop($instance_prefix) ne '/'){
	# put whatever it was back.
	$instance_prefix = "$HDLN_root_module/$path_name";
    }

    $instance_prefix =~ s!/!__!g;  # Convert slashes to double underscores.

    $HDLN_lnum = $HDLN_mod_lnum[$mod_id];

    #print("reemit: HDLN_lnum=$HDLN_lnum HDLN_hdl_elements=$HDLN_hdl_elements '\n");

    get_fields();
    @hdl = @HDLN_fields;
    if($uniquify){

	# This module is uniquified, substitute it's new name, unless
	# it the root module.

	if($path_id != $root_path_id){
	    if($long_names){
		$hdl[$HDLN_MODULE_NAME] = $instance_prefix;
	    }else{
		$hdl[$HDLN_MODULE_NAME] = "$hdl[$HDLN_MODULE_NAME]\$\$$path_id\$\$";
		if(length($hdl[$HDLN_MODULE_NAME]) > 127){
		    HDLN_warn("Uniquified module name is > 127 characters:");
		    HDLN_warn("\t$hdl[$HDLN_MODULE_NAME]");
		    HDLN_warn("");
		}
	    }
	}
    }

    # Count how many assign statements there are to be deleted.

    $lnum_save = $HDLN_lnum;
    $assigns = 0;
    while($HDLN_lnum<$HDLN_hdl_elements) {
	get_fields();
	if($HDLN_field0 eq 'module'){
	    # Finished with this module
	    last;
	} elsif ($HDLN_field0 eq 'assign'){
	    $assigns++;
	};
    } # while

    $HDLN_lnum = $lnum_save;

    # Reduce the number of statement in this module by the number of
    # assign statement found.

    $hdl[1] -= $assigns;

    # print("reemit: module: @hdl\n");
    emit_hdl(\@hdl);

    while($HDLN_lnum<$HDLN_hdl_elements) {
	
	get_fields();

	# print("reemit: dispatch on '@HDLN_fields'\n");

	if($HDLN_field0 eq 'module'){
	    # Finished with this module
	    last;

	} elsif ($HDLN_field0 eq 'instances'){

	    @hdl = @HDLN_fields;

	    $called_mod = $HDLN_fields[$HDLN_INSTANCES_ID];

	    $called_mod_id = $HDLN_modules{$called_mod};

	    if($HDLN_mod_def[$called_mod_id] == $HDLN_MOD_MODULE){

		# This is a module in this design

		# This module is being uniquified, see if
		# this instance should be replaced.

		$called_instance_name =  $HDLN_fields[$HDLN_INSTANCE_NAME];

		$called_path = "$path_name$called_instance_name/";
		    
		$called_path_id = $HDLN_path_id{$called_path};

		#print("reemit: HDLN_path_id\{$called_path\}=$called_path_id\n");

		if(!defined($called_path_id)){
		    fatal("reemit: Didn't find HDLN_path_id\{$called_path\}\n");
		};

		if(defined($HDLN_uniquify_path_id{$called_path_id})){
		    # Uniquify this module call
		    if($long_names){
			$called_mod = $instance_prefix.'__'.$called_instance_name;
		    }else{
			$called_mod = "$called_mod\$\$$called_path_id\$\$";
		    }
		    $hdl[$HDLN_INSTANCES_ID] = $called_mod;
		}

		#print("reemit: instance: @hdl\n");

	    } else {

		# Else it's a cell
		#print("reemit: cell: @HDLN_fields\n");

		@hdl = @HDLN_fields;
		
	    };

	    uniquify_hdl(\@hdl, $path_id, $called_mod_id);

	} elsif ($HDLN_field0 eq 'assign'){

	    # print("reemit: remove assign: @HDLN_fields\n");

	} else {
	    # print("reemit: @HDLN_fields\n");
	    emit_hdl(\@HDLN_fields);
	};
    } # while
}

##########################################################

# uniquify_hdl - 

sub uniquify_hdl{
    my($hdl_ref, $path_id, $called_mod_id) = @_;
    
    my($tok_idx);
    my($tok_lim);
    my($id);
    my($bit);
    my($rec);
    my($new_rec);
    my($bit1, $bit2);
    my($dx);
    my($bit_lim);
    my($bits);
    my($map_cnt);
    my($port_num);
    my($port_dir);
    my(@new_hdl);
    my($wire_rec);
    my(@wire_info);
    my($driven);
    my($concat_cnt);
    my($id_cnt);

    # print("uniquify_hdl: hdl = @{$hdl_ref}\n");

    $tok_lim = scalar(@{$hdl_ref});

    $port_num = 0;

    # $tok_idx=10 skips to first parameter.

    @new_hdl = @{$hdl_ref}[0..9];

    for($tok_idx = 10; $tok_idx<$tok_lim;){
	if($hdl_ref->[$tok_idx] ne 'dot'){
	    fatal("uniquify_hdl: expected 'dot', found $hdl_ref->[$tok_idx]\n");
	}

	$id_cnt = $hdl_ref->[$tok_idx+1];
	if(($id_cnt!=1)&&($id_cnt!=2)){
	    fatal("uniquify_hdl: expected 'dot 1' or 'dot 2', found $id_cnt\n");
	}

	$port_num = $HDLN_mod_portorder_ref[$called_mod_id]->{$hdl_ref->[$tok_idx+4]};
	if(!defined($port_num)){
	    fatal("INTERNAL: uniquify_hdl port number for '$hdl_ref->[$tok_idx+4]' is undefined");
	}

	$port_dir = $HDLN_mod_port_dirs[$called_mod_id][$port_num];

	push(@new_hdl, @{$hdl_ref}[$tok_idx..$tok_idx+4]);
	$tok_idx += 5; # Skip to called ID, 

	# Outputs are special.
	$driven = ($port_dir == $HDLN_PORT_DIR_OUTPUT);


	# Usually this loop executes only once.  Only in the 
	# case of a in-parameter concat will it loop.
	# May loop zero times if there is no parameter (dot 1, $id_cnt==1)
	
	for($concat_cnt=$id_cnt-1; $concat_cnt>0; $concat_cnt--){

	    if($hdl_ref->[$tok_idx] eq 'concat'){
		
		# A in-parameter concat, pass it.
		# This loop will continue and map the id's inside this
		# concat.
		
		# Loop for the specified number of IDs.
		$concat_cnt += $hdl_ref->[$tok_idx+1];

		push(@new_hdl, @{$hdl_ref}[$tok_idx..$tok_idx+1]);
		$tok_idx += 2;
		
	    }elsif($hdl_ref->[$tok_idx] eq 'bit'){
		$id = $hdl_ref->[$tok_idx+4];
		$bit = $hdl_ref->[$tok_idx+7];
		$rec = "$id $bit";
		push_unassign_rec(\@new_hdl, $rec, $path_id,
				  $port_dir, $driven);
		$tok_idx += 9; 

	    }elsif($hdl_ref->[$tok_idx] eq 'range'){
		$id = $hdl_ref->[$tok_idx+4];
		$bit1 = $hdl_ref->[$tok_idx+7];
		$bit2 = $hdl_ref->[$tok_idx+11];
		
		# print("uniquify_hdl: tok_idx=$tok_idx, checking range: '$id $bit1 $bit2'\n");

		if($bit1 <= $bit2){
		    $dx = 1;
		}else{
		    $dx = -1;
		}

		$bit_lim = $bit2 + $dx;  # Loop at least once.
		$map_cnt = 0;
		for($bit=$bit1; $bit!=$bit_lim; $bit+=$dx){
		    $rec = "$id $bit";
		    if(defined($new_rec=$HDLN_unassign{$path_id}->{$rec})){
			$map_cnt++;
		    }
		}
		
		if($map_cnt == 0){
		    push(@new_hdl, @{$hdl_ref}[$tok_idx..$tok_idx+12]);
		}else{

		    # This bus is re-mapped, concat together
		    # the bits.
		    
		    $bits = abs($bit1-$bit2) + 1;
		
		    push(@new_hdl, 'concat', $bits);

		    for($bit=$bit1; $bit!=$bit_lim; $bit+=$dx){
			$rec = "$id $bit";
			push_unassign_rec(\@new_hdl, $rec,
					  $path_id, $port_dir, $driven);
		    }
		}
		$tok_idx += 13; 
		
	    }elsif($hdl_ref->[$tok_idx] eq 'id'){
		
		$id = $hdl_ref->[$tok_idx+2];
		# print("uniquify_hdl: tok_idx=$tok_idx, checking signal: '$rec'\n");
		
		if(defined($new_rec=$HDLN_unassign{$path_id}->{$id})){
		    
		    #print("uniquify_hdl: map: $id -> $new_rec; port_num=$port_num port_dir=$port_dir\n");
		    if($new_rec ne ':u'){
			push_unassign_rec(\@new_hdl, $id, $path_id,
				      $port_dir, $driven);
		    }else{

			# This is a bus and at least one of it's bit is mapped.
			# Treat it as a range.

			$wire_rec = $HDLN_wire_table_ref[$path_id]->{$id};
			@wire_info = split(/ /, $wire_rec);
			$dx = $wire_info[$HDLN_NET_ID_RANGE_FLAG];
			if($dx == $HDLN_NET_ID_RANGE_NONE){
			    fatal("INTERNAL: uniquify_hdl: bus map for non-bus '$id'");
			}
			$bit1 = $wire_info[$HDLN_NET_ID_LEFT_BIT];
			$bits = $wire_info[$HDLN_NET_ID_BITS];
		    
			push(@new_hdl, 'concat', $bits);

			$bit_lim = $bit1 + $bits*$dx;
			for($bit=$bit1; $bit!=$bit_lim; $bit+=$dx){
			    $rec = "$id $bit";
			    push_unassign_rec(\@new_hdl, $rec, $path_id,
					      $port_dir, $driven);
			}
		    }
		}else{
		    push(@new_hdl, @{$hdl_ref}[$tok_idx..$tok_idx+2]);
		}
		$tok_idx += 3;
	    }elsif($hdl_ref->[$tok_idx] eq 'num'){
		# Inline constant, just pass it.
		push(@new_hdl, @{$hdl_ref}[$tok_idx..$tok_idx+3]);
		$tok_idx += 4;
	    }else{
		fatal("uniquify_hdl: unexpected token: tok_idx=$tok_idx ($hdl_ref->[$tok_idx])\n");
	    }
	} #For(concat_cnt...)
    }

    emit_hdl(\@new_hdl);
}

##########################################################

# push_unassign_rec -- Push a new ID into the hdl buffer, subituting
# the mapto ID if this passed in ID should be mapped for doing an
# unassign.

sub push_unassign_rec{
    my($hdl_ref, $rec, $path_id, $port_dir, $driven) = @_;

    my($new_rec);
    my($dvr_rec);

    if(!defined($new_rec=$HDLN_unassign{$path_id}->{$rec})){
	# No mapping, no change needed.
	push_hdl($hdl_ref, $rec, $port_dir, $rec);
    }else{
	if(!$driven || 
	   ($driven &&
	    defined($dvr_rec=$HDLN_unassign_driven{$path_id}->{$rec}) &&
	    ($rec eq $dvr_rec))){
	    # Not an ouput port, or is an ouput but and
	    # it is the selected output port for the mappping.
	    # Do the subitution.
	    push_hdl($hdl_ref, $new_rec, $port_dir, $rec);
	}else{
	    # This output is not the driven net.
	    # Change the name to a new name, by adding 'DELERED'.
	    $rec  =~ s/([^ ]*) *([\d]*)/$1_$2\$DELETED\$/;
	    push_hdl($hdl_ref, $rec, $port_dir, $rec);
	}
    }
}

##########################################################

sub push_hdl{
    my($hdl_ref, $rec, $port_dir, $old_rec)=@_;

    my(@info);
    my(@old_info);
    my($val);
    my($bits);
    my($string);

    @info = split(/ /, $rec);
    if(scalar(@info) == 1){
	# Just an id
	push(@$hdl_ref, 'id', '0', $info[0]);
    }elsif(scalar(@info) == 2){
	# A bit of a bus
	if($info[0] =~ /^[0-9]/){
	    # This is a number
	    if($info[0] =~ /^([0-9]+)'b([01]+)$/){ # for emacs: '){
                $bits = $1;
		$string = $2;
		if($info[1] >= $bits){
		    HDLN_warn("Can't select bit $info[1] from constant $info[0].'");
		}

                $bits = length($string);
                if($info[1] >= $bits){
		    $val = 0;
		}else{
		    $val = substr($string, $bits-1-$info[1], 1);
		}
		#warn("push_hdl: bit=$info[1], info\[0\]=$info[0], bits=$bits, string=$string, val=$val\n");

	    }else{
		HDLN_warn("Currently only bit constants are supported, not $info[0]");
		$val = 0;
	    }
	    if($port_dir != $HDLN_PORT_DIR_OUTPUT){
		push(@$hdl_ref, 'num', '0', $val, "1'b$val");
	    }else{

		# This is a an output port that is driven by a constant.
		# We replace this signal where ever it's used.
		# Keep the original bus so that we don't drive
		# constants.  It will become and "unconnected constant".

		@old_info = split(/ /, $old_rec);
		if(scalar(@old_info) > 1){
		    push(@$hdl_ref, 'bit', '2', 'id', '0', $old_info[0],
			 'num', '0', $old_info[1], $old_info[1]);
		}else{
		    push(@$hdl_ref, 'id', '0', $old_info[0]);
		}
	    }
	}else{
	    # Not a constant, but has a bit.
	    push(@$hdl_ref, 'bit', '2', 'id', '0', $info[0],
		 'num', '0', $info[1], $info[1]);
	}
    }else{
	fatal("INTERNAL: push_hdl -- expected 1 or 2 fields in rec.");
    }
}
##########################################################

# emit_hdl - emit an line of hdl.
# Always writes to stdout.

use vars '%hdl_token_fields';
$hdl_token_fields{'module'} = 2;
$hdl_token_fields{'portorder'} = 2;
$hdl_token_fields{'input'} = 2;
$hdl_token_fields{'output'} = 2;
$hdl_token_fields{'inout'} = 2;
$hdl_token_fields{'wire'} = 2;
$hdl_token_fields{'reg'} = 2;
$hdl_token_fields{'bit'} = 2;
$hdl_token_fields{'range'} = 2;
$hdl_token_fields{'assign'} = 2;
$hdl_token_fields{'concat'} = 2;
$hdl_token_fields{'instances'} = 2;
$hdl_token_fields{'instance'} = 2;
$hdl_token_fields{'dot'} = 2;
$hdl_token_fields{'nop'} = 2;

$hdl_token_fields{'id'} = 3;
$hdl_token_fields{'num'} = 4;

sub emit_hdl{
    my($hdl_ref) = @_;
    
    my($cnt);
    my($tok);

    $cnt = 0;
    foreach $tok (@{$hdl_ref}){
	if($cnt == 0){
	    if(!defined($cnt=$hdl_token_fields{$tok})){
		fatal("emit_hdl: Unexpected token '$tok'\n");
	    }
	}else{
	    print(" ");
	}
	print($tok);
	$cnt--;
	if($cnt == 0){
	    print("\n");
	}
    }
}

##########################################################

# Report a fatal error and die

push(@EXPORT, 'fatal');
sub fatal{
    my($msg) = @_;

    my($err_msg);
    my(@lines);
    my($i);
    my($x);
    my(@flds);
    my($num) = $HDLN_lnum - 1;

    HDLN_warn("FATAL ERROR:");
    HDLN_warn("\t$msg");
    if($HDLN_Msg_to_Stdout){
	HDLN_warn("(more info in output file)");
    }

    @lines = split(/\n/,  $HDLN_hdl_toks[$num]);
    $x = 0;
    for($i=0; $i<=$#lines; $i++){
	$err_msg = sprintf("idx %3d: %s", $x, $lines[$i]);
	HDLN_print($err_msg);
	@flds = split(/\s/, $lines[$i]);  
	$x += $#flds+1;
    }

    HDLN_print("");

    die("Aborting\n");
}

#################################

# HDLN_warn -- print a message to STDERR and maybe STDOUT.

push(@EXPORT, 'HDLN_warn');
sub HDLN_warn{
    my($msg) = @_;
    
    warn("$0: $msg\n");

    if($HDLN_Warn_Echo){
	print("$msg\n");
    }
}

#################################

# HDLN_print -- print a message to STDOUT, or STDERR if STDOUT is in a specail format.

push(@EXPORT, 'HDLN_print');
sub HDLN_print{
    my($msg) = @_;
    
    if($HDLN_Msg_to_Stdout){
	print("$msg\n");
    }else{
	warn("$msg\n");
    }
}

#################################

1;  # Return true for Module Interface.

