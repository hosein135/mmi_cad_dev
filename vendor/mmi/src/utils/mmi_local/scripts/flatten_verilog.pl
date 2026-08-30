: # Start Perl. sh will execute the these 2 lines but Perl won't.
eval 'exec perl -w -S $0 ${1+"$@"}'
if 0;

# Perl script to flatten a Verilog netlist.

# John Johnson

# Fri Mar 10 09:31:16 2000

# Last edit: <010707.1134>

use strict;
use integer;

# Bring in Micro Magic's Verilog netlist builder
use lib "$ENV{MMI_LOCAL}/scripts/";

# For development, use the local one, or the one in my home directory
# over the one in the NET_CHECK directory.

use lib "$ENV{HOME}/net_check";

use HDL_dag;

#############################################################
# Start of main
#############################################################

use vars '$MMI_TECH';
use vars '$MMI_TECH_ROOT';

my(@cell_libs) = ();
my(@verilog_files) = ();

# Make the name look better.  Get rid of the path.
my($rs) = rindex($0, '/');
if($rs>=0){ 
    $0 = substr($0, $rs+1);
};

# Setup some globals that control the HDL_dag package.

$HDLN_comment = '//';
$HDLN_report = 1;
$HDLN_unconnected_output_warn = 0;
$HDLN_unconnected_net_warn = 0;
$HDLN_implicit_wire_warn = 0;

print("$HDLN_comment Command: @ARGV\n");

# Default to MMI's standard library.

use vars '$DEFAULT_ROOT'; $DEFAULT_ROOT = '/volume/mmi_proj/proj/tech/';
use vars '$DEFAULT_TECH'; $DEFAULT_TECH = 'mmi15';

if(!defined($MMI_TECH_ROOT=$ENV{MMI_TECH_ROOT})){
    $MMI_TECH_ROOT = $DEFAULT_ROOT;
}
if(!defined($MMI_TECH=$ENV{MMI_TECH})){
    $MMI_TECH = $DEFAULT_TECH;
}


while(@ARGV){
    if($ARGV[0] =~ /^-c/){

        # -c says this is a cell library

        shift @ARGV;
        push(@cell_libs, $ARGV[0]);
        shift @ARGV;

    }elsif($ARGV[0] =~ /^-root/){

        # -root specifies the root module

        shift @ARGV;
	$HDLN_root_module = $ARGV[0];
        shift @ARGV;

    }elsif($ARGV[0] =~ /^[+\-]/){
        die "Flatten a Verilog net-list.

usage: $0 [-c <cell_lib>] [-root <module name>] <verilog or .hdl> 

options:
-c      cell_lib   => Specify Cell library.
-root   name       => Specify the root module to start flattening.

If \$MMI_TECH_ROOT is not defined it defaults to:
    $DEFAULT_ROOT

If \$MMI_TECH is defined the the library defaults to:
    $DEFAULT_TECH

Version <010707.1134>
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

HDL_flatten(\@cell_libs, \@verilog_files);

0;
# end of main



