: # Start Perl. sh will execute the next 2 lines but Perl won't.
eval 'exec perl -w -S $0 ${1+"$@"}'
if 0;

# Perl script to test HDL_dag

# John Johnson

# Fri Apr  9 16:42:30 1999

# Last edit: <010707.1118>

use strict;
use integer;

# Bring in Micro Magic's Verilog netlist builder
use lib "$ENV{MMI_LOCAL}/scripts/";

# For development, use the local one, or the one in my home directory
# over the one in the NET_CHECK directory.

use lib "$ENV{HOME}/net_check";

use HDL_dag;

# use a global to keep track of the pins the user said to ignore.

use vars '%ARG_ignore_ports';       local(%ARG_ignore_ports);
use vars '%ARG_report_ports';       local(%ARG_report_ports);
use vars '$ARG_report_flag';        local($ARG_report_flag);

use vars '$MMI_TECH';
use vars '$MMI_TECH_ROOT';

#############################################################
# Start of main
#############################################################

my(@cell_libs) = ();
my(@verilog_files) = ();
my(@net_reports) = ();
my($dag_checks) = 1;
my($report_seq) = 0;

# Make the name look better.  Get rid of the path,
my($rs) = rindex($0, '/');
if($rs>=0){ 
    $0 = substr($0, $rs+1);
};

# warn("$0: ENV\{NET_CHECK\}=$ENV{NET_CHECK}\n");

$ARG_report_flag = 0;

# For now, hard code the names of the tristate cells.  This defines
# them in the hash, and the number is how many time they are used.

%HDLN_tristate_cells = qw(
			  MMI_TSBUFC 0
			  MMI_TSBUFE 0
			  );

# Default MMI's standard library.  If there's a $MMI_TECH defined
# then the library is in /proj/tech/$MMI_TECH/library/verilog/$MMI_TECH.v

# Identify the the names of sequential cells.

if(!defined($MMI_TECH_ROOT=$ENV{MMI_TECH_ROOT})){
    $MMI_TECH_ROOT = '/volume/mmi_proj/proj/tech/';
}
if(!defined($MMI_TECH=$ENV{MMI_TECH})){
    $MMI_TECH = 'mmi15';
}

if($MMI_TECH eq "mmi25"){

    # Old way,  add in the Virage RAM cell
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

# Sequential cells with this sub-string in their names will be flagged
# as in the scan chain.

@HDLN_scan_name_substr = qw(MMI_SFF);

# For now, hard code the cell name that should truncate the reporting
# of a clock cone.

%HDLN_cone_report_truncate = qw(
				);

$HDLN_comment = '//';
$HDLN_report = 1;
$HDLN_unconnected_const_warn = 0;
$HDLN_unconnected_output_warn = 0;
$HDLN_unconnected_net_warn = 0;
$HDLN_implicit_wire_warn = 0;

print("$HDLN_comment Command: @ARGV\n");

while(@ARGV){
    if($ARGV[0] =~ /^-clk/){

        shift @ARGV;
	push(@net_reports, ['clk', $ARGV[0]]);
        shift @ARGV;

    }elsif($ARGV[0] =~ /^-buf/){

        # -n gives name of a net to trace.

        shift @ARGV;
	push(@net_reports, ['buf', $ARGV[0]]);
        shift @ARGV;

    }elsif($ARGV[0] =~ /^-c/){

        # -c says this is a cell library

        shift @ARGV;
        push(@cell_libs, $ARGV[0]);
        shift @ARGV;

    }elsif($ARGV[0] =~ /^\+c/){

	$HDLN_unconnected_const_warn = 1;
        shift @ARGV;

    }elsif($ARGV[0] =~ /^-d/){

        # -d says to skip the DAG check the dag

        shift @ARGV;
	$dag_checks = 0;

    }elsif($ARGV[0] =~ /^-l/){

        # -l says start flagging deletes at this level

        shift @ARGV;
	$HDLN_cone_delete_level =  $ARGV[0];
        shift @ARGV;

    }elsif($ARGV[0] =~ /^-n/){

        # -n gives name of a net to trace.

        shift @ARGV;
	push(@net_reports, ['net', $ARGV[0]]);
        shift @ARGV;
	
    }elsif($ARGV[0] =~ /^-root/){

        # -root specifies the root module

        shift @ARGV;
	$HDLN_root_module = $ARGV[0];
        shift @ARGV;

    }elsif($ARGV[0] =~ /^-s/){

        # -s to add a seq. cell sub-string.

        shift @ARGV;
        push(@HDLN_seq_name_substr, $ARGV[0]);
        shift @ARGV;

    }elsif($ARGV[0] =~ /^\+s/){

        # +s says report names of tristate drivers
	# and sequential cells

        shift @ARGV;
	$report_seq = 1;

    }elsif($ARGV[0] =~ /^\+o/){

        # +o  Says report unconnected output cells

        shift @ARGV;
	$HDLN_unconnected_output_warn = 1;

    }elsif($ARGV[0] =~ /^\+i/){

        # +i  Says report implicit wires.

        shift @ARGV;
	$HDLN_implicit_wire_warn = 1;

    }elsif($ARGV[0] =~ /^\+u/){
 
        # +u  Says report unconnected nets.
 
        shift @ARGV;
        $HDLN_unconnected_net_warn = 1;
 
    }elsif($ARGV[0] =~ /^[+\-]/){
        die "Analyze driver-receiver connections for a Verilog net-list.

usage: $0 [-d] [-c cell_lib] [-s substr] [reports] <verilog or hdl file> 

-c cel_lib   => Specify Cell library.
-d           => Don't do DAG checks.
-s substr    => Add 'substr' to the list of sequential cells.

reports:

-buf net => Report buffer tree info for signal 'net'
-clk net => Report clock tree info for signal 'net'
-n net   => Report logic cone starting at 'net'.
+c       => Report unconnected constants.
+i       => Report implicit wires.
+o       => Report cells with no output connections.
+s       => Report (hard coded!) names of sequential cells.
+u       => Report unconnected wires.

If no -c <cell_lib> option is specified then the cell library defaults
to: 
    $MMI_TECH_ROOT/$MMI_TECH/library/verilog/$MMI_TECH.v

The root direction is specified the MMI_TECH_ROOT environment
variable, the technology library is specified by the MMI_TECH
environment variable.

Version <010707.1118>
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

#warn("Calling HDL_report_cones\n");
HDL_report_cones(\@cell_libs, \@verilog_files, $report_seq, $dag_checks, \@net_reports);

# end of main
