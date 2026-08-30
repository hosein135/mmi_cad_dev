: # Start Perl. sh will execute the these 2 lines but Perl won't.
eval 'exec perl -w -S $0 ${1+"$@"}'
if 0;

# Perl script to test HDL_dag

# John Johnson

# Sat Jan  1 21:41:27 2000

# Last edit: <010707.1127>

use strict;
use integer;

# Bring in Micro Magic's Verilog netlist builder

# Bring in Micro Magic's Verilog netlist builder
use lib "$ENV{MMI_LOCAL}/scripts/";

# For development, use the local one, or the one in my home directory
# over in the in the mmi_local directory.

use lib "$ENV{HOME}/net_check/";
use lib ".";

use HDL_dag;

use vars '$MMI_TECH';
use vars '$MMI_TECH_ROOT';

# Use a global to keep track of the pins the user said to ignore.

use vars '%ARG_ignore_ports';       local(%ARG_ignore_ports);
use vars '%ARG_report_ports';       local(%ARG_report_ports);
use vars '$ARG_report_flag';        local($ARG_report_flag);

#############################################################
# Start of main
#############################################################

my(@cell_libs) = ();
my(@verilog_files) = ();
my(@net_reports) = ();
my($dag_checks) = 0;
my($report_seq) = 0;

my($report_net_name);

# Make the name look better.  Get rid of the path.
my($rs) = rindex($0, '/');
if($rs>=0){ 
    $0 = substr($0, $rs+1);
};

$ARG_report_flag = 0;

# For now, hard code the names of the tristate cells.  This defines
# them in the hash, and the number is how many time they are used.

%HDLN_tristate_cells = qw(
			  MMI_TSBUFC 0
			  MMI_TSBUFE 0
			  );

# For now, hard code the substring within the names of sequential
# cells.

@HDLN_seq_name_substr = qw(MMI_FF 
			   MMI_SRAM
			   MMI_LL
			   );

# Sequential cells with this substring in their names
# will be flagged as in the scan chain.

@HDLN_scan_name_substr = qw(MMI_SFF);

# For now, hard code the cell name that should truncate the reporting
# of a clock cone.

%HDLN_cone_report_truncate = qw(
				);

$HDLN_comment = '//';
$HDLN_report = 1;
$HDLN_unconnected_output_warn = 0;
$HDLN_unconnected_net_warn = 0;
$HDLN_implicit_wire_warn = 0;

# Default to reporting net names.
$report_net_name = 1;

HDLN_warn("Command: @ARGV\n");

# Default to MMI's standard library.

use vars '$DEFAULT_ROOT'; $DEFAULT_ROOT = '/volume/mmi_proj/proj/tech/';
use vars '$DEFAULT_TECH'; $DEFAULT_TECH = 'mmi15';

if(!defined($MMI_TECH_ROOT=$ENV{MMI_TECH_ROOT})){
    $MMI_TECH_ROOT = $DEFAULT_ROOT;
}
if(!defined($MMI_TECH=$ENV{MMI_TECH})){
    $MMI_TECH = $DEFAULT_TECH;
}

# Identify the the names of sequential cells.
if($MMI_TECH eq "mmi25"){

    # Old way, hard code the names...  Add in the Virage RAM cell
    # names.

    @HDLN_seq_name_substr = qw(FF 
			   RF 
			   ICV 
			   DCV 
			   ELUT
			   MMI_SRAM
			   MMI_LL
			   );

    push(@cell_libs, "$ENV{MMI_TOOLS}/../mmi_local/scripts/tsmc25.hdl");

}else{

    # The mmi18 library has a MMI_RPTRF cell, so a having a 'RF' would
    # makes it look sequential, but it's really a repeater.

    @HDLN_seq_name_substr = qw(MMI_FF 
			       MMI_SFF
			       MMI_SRAM
			       MMI_LL
			   );
}

while(@ARGV){
    if($ARGV[0] =~ /^-c/){

        # -c says this is a cell library

        shift @ARGV;
        push(@cell_libs, $ARGV[0]);
        shift @ARGV;

    }elsif($ARGV[0] =~ /^-no_names/){

        # -no_name says to not start the line wit the net name.

	$report_net_name = 0;
        shift @ARGV;

    }elsif($ARGV[0] =~ /^-s/){

        # -s to add a seq. cell substring.

        shift @ARGV;
        push(@HDLN_seq_name_substr, $ARGV[0]);
        shift @ARGV;

    }elsif($ARGV[0] =~ /^[+\-]/){
        die "Write netlist to stdout.  One line per net.

usage: $0 [-no_names] [-c cell_lib_file] [-s seq_cell_substr] <verilog file> 

-c lib     => Specify Cell library.  Can be repeated.
-s substr  => Add 'substr' to the list of substrings that identify of sequential cells.
              default is (@HDLN_seq_name_substr).
-no_names  => Omit the net name at the start of each output line.

If \$MMI_TECH_ROOT is not defined it defaults to:
    $DEFAULT_ROOT

If \$MMI_TECH is defined the the library defaults to:
    $DEFAULT_TECH

Version <010707.1127>
";
    } else {
        push(@verilog_files, $ARGV[0]);
        shift @ARGV;
    };
};

# If the user didn't specify any cell library, set the default

if(scalar(@cell_libs) == 0){
    push(@cell_libs, "$MMI_TECH_ROOT/$MMI_TECH/library/verilog/$MMI_TECH.v");
}

HDL_netlist(\@cell_libs, \@verilog_files, $report_net_name);

# end of main




