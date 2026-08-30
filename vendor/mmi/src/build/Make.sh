#!/bin/ksh

#
#       Generator Program for MMI Tools Releases
#
alias -x gcp=gcp
alias -x gtar=gtar
set -x				;# print commands before executing them.

MAX_RELEASE=max4.2.11
NST_RELEASE=nst2.4
SUE_RELEASE=sue4.4
MMIDOC_RELEASE=mmidoc1.4
GDSPLOT_RELEASE=gdsplot4.16
FLEX_RELEASE=flexlm
EDIF2SUE_RELEASE=edif2sue1.2.12
SPEEDY_RELEASE=speedy3.4
NL_RELEASE=nl-0.34

MMI_BUILD_DIR=`pwd`

MMI_RELEASE_DIR=/volume/mmi/rel
UTILS=/volume/mmi/utils/bin.sparc-solaris2
DATE=`date +%y%m%d`
RELEASE_NAME=mmi_${DATE}
RELEASE_DIR=${MMI_RELEASE_DIR}/${RELEASE_NAME}

# This is the list of operating systems supported.
BINLIST="bin.sparc-solaris2 bin.i486-linux bin.hppa"
#BINLIST="bin.sparc-solaris2 bin.i486-linux"

# set -e causes the shell to exit if any command fails.
# The ERR trap executes the error function in this case.
# The Init alias contains commands to be executed
# inside each function.
alias -x Init='trap error ERR; set -xe'
trap error ERR

function error {
    echo ERROR: Release did not complete
    mv ${RELEASE_DIR} ${RELEASE_DIR}.failed
    exit 2\"
}

# This function can make nst, nl, speedy, etc. directories.
# Takes three arguments: name of thing, the release dir variable name,
# and a list of executables.  We specify the executable names,
# rather than just copying everything, as a double check for errors.
function make_thing {
    thing=$1
    # This is double indirectin: Set thing_release_dir 
    # to the value of the variable specified by the second argument $2.
    eval thing_release_dir=\$$2
    thing_exe_list=$3

    Init
    gcp -a ${thing_release_dir} ${RELEASE_DIR}
    if [ "$thing" != "$thing_release_dir" ];then
	(cd ${RELEASE_DIR};ln -s ${thing_release_dir} $thing)
    fi

    for file in $thing_exe_list;do
      for BIN_DIR in $BINLIST;do
	if [ -d ${RELEASE_DIR}/$thing/${BIN_DIR} ];then
	    ( cd ${RELEASE_DIR}/${BIN_DIR}
	      ln -s ../$thing/${BIN_DIR}/$file .
	    )
	else
	    echo "WARNING: No directory: ${RELEASE_DIR}/$thing/${BIN_DIR}"
	fi
      done
    done
}


function make_sue {
    Init
    gcp -a ${SUE_RELEASE} ${RELEASE_DIR}
    (cd ${RELEASE_DIR}; ln -s ${SUE_RELEASE} sue)
    for BIN_DIR in $BINLIST;do
      ( cd ${RELEASE_DIR}/${BIN_DIR}
	ln -s ../sue/sue .
      )
    done
#    sue_exe_list=""
#    for file in $sue_exe_list;do
#      for BIN_DIR in $BINLIST;do
#	( cd ${RELEASE_DIR}/${BIN_DIR}
#	  ln -s ../sue/${BIN_DIR}/$file .
#	)
#      done
#    done

    # verilog to sue stuff
    gcp -a verilog_to_sue ${RELEASE_DIR}

    # yav2s is the new version, but it uses nl, which we dont ship to customers.
    # verilog_to_sue is the old version, that is in the release
    # because it was documented for customers.
    for BIN_DIR in $BINLIST;do
    	( cd ${RELEASE_DIR}/${BIN_DIR}
	  ln -s ../verilog_to_sue/yav2s .
    	  ln -s ../verilog_to_sue/${BIN_DIR}/verilog_parser .
    	  ln -s ../verilog_to_sue/scripts/verilog_preprocessor .
    	  ln -s ../verilog_to_sue/scripts/verilog_to_sue .
    	)
    done
}

function make_max {
    Init

    gcp -a ${MAX_RELEASE} ${RELEASE_DIR}
    (cd ${RELEASE_DIR}; ln -s ${MAX_RELEASE} max)
    for BIN_DIR in $BINLIST;do
	( cd ${RELEASE_DIR}/${BIN_DIR}
	  ln -s ../max/${BIN_DIR}/* .
	  ln -s ../max/tech/tech_target/make_tech .
	  ln -s ../max/tech/tech_target/gds_input .
	  ln -s ../max/tech/tech_target/drac_convert .
	)
    done
}


# Create the release dir.  Run this first.
function make_RelDir {
    Init

    ( set +e  ;# Ignore errors from rm
      rm -f  ${MMI_RELEASE_DIR}/${RELEASE_NAME}.tar.gz
      rm -f  ${MMI_RELEASE_DIR}/${RELEASE_NAME}.tar
      rm -rf ${MMI_RELEASE_DIR}/${RELEASE_NAME}
    )
    mkdir ${RELEASE_DIR}
    mkdir ${RELEASE_DIR}/scripts
    for BIN_DIR in $BINLIST;do
      mkdir ${RELEASE_DIR}/${BIN_DIR}
    done
}

function make_doc {
    Init

    # text files
    cp -p release_doc/README ${RELEASE_DIR}/README
    cp -p release_doc/RELEASE_NOTES ${RELEASE_DIR}
#    cp -p release_doc/MMI_LICENSE_AGREEMENT ${RELEASE_DIR}
#    cp -p release_doc/MMI_COPYRIGHT_NOTICE ${RELEASE_DIR}
    cp -p release_doc/COPYRIGHT_NOTICE ${RELEASE_DIR}
    cp -p release_doc/bug_report.html ${RELEASE_DIR}

    # sample mmi_local
    gcp -a mmi_local.sample ${RELEASE_DIR}

    # mmi logo
    cp -p mmi_logo.gif ${RELEASE_DIR}

    # doc directory.  Tutorials are included here.
    mkdir ${RELEASE_DIR}/doc
    ( cd ${RELEASE_DIR}/doc/
      ln -s ../max/doc max
      ln -s ../max/doc mcc
      ln -s ../sue/doc sue
      ln -s ../sue/doc dpc
      ln -s ../nst/doc nst
      ln -s ../speedy/doc speedy
      ln -s ../nl/doc nl
    )

    # The edif2sue doc is not in a separate doc sub-directory,
    # so we do it this way.
    mkdir ${RELEASE_DIR}/doc/edif2sue
    (cd ${RELEASE_DIR}/doc/edif2sue; ln -s ../../edif2sue/user_doc .)
}

function make_dpc_tutorial {
    Init

    # go to src directory and do a build and an install to build directory
    ( cd ../src/${SUE_RELEASE}/doc/dpc_build_tutorial
      ./build
      ./install
    )
}

function make_flex {
    Init
    # Flex
    gcp -a ${FLEX_RELEASE} ${RELEASE_DIR}
    for BIN_DIR in $BINLIST;do
      ( cd ${RELEASE_DIR}/${BIN_DIR}
	ln -s ../flexlm/${BIN_DIR}/* .
      )
    done
}

function make_misc {
    Init

    # gdsplot
# NO GDSPLOT
#    gcp -a ${GDSPLOT_RELEASE} ${RELEASE_DIR}
#    (cd ${RELEASE_DIR}; ln -s ${GDSPLOT_RELEASE} gdsplot)

#    cp -p scripts/gdsplot.pat ${RELEASE_DIR}/scripts
#    cp -p scripts/gdsplot.cfg ${RELEASE_DIR}/scripts

    # add src
    gcp -a /volume/mmi/src/pd/src ${RELEASE_DIR}/src

    # vcd_verilog (for SUE)
    cp -p scripts/vcd_verilog ${RELEASE_DIR}/scripts

    # mmidoc: Copy all files except RCS
    filelist=`find ${MMIDOC_RELEASE}/* | sed /RCS/d`
    tar cf - $filelist | (cd ${RELEASE_DIR}; tar xf -)
    (cd ${RELEASE_DIR}; ln -s ${MMIDOC_RELEASE} mmidoc)
    for BIN_DIR in $BINLIST;do
      ( cd ${RELEASE_DIR}/${BIN_DIR}
	ln -s ../mmidoc/mmidoc .
	ln -s ../mmidoc/mmi_tutorial .
      )
    done

    # misc executables directory
    (cd misc; gcp -a $BINLIST ${RELEASE_DIR})

    # tcl libraries
    gcp -a lib ${RELEASE_DIR}

    # Link all script files into each release.
    for BIN_DIR in $BINLIST
    do
      ( cd ${RELEASE_DIR}/${BIN_DIR}
        ln -s ../scripts/* .
	)
    done
}


function run_lmstrip {
    Init
    set +e
    # Run lmstrip on things to make licensing more secure.
    for BIN_DIR in $BINLIST
    do
      ( cd ${RELEASE_DIR}/${BIN_DIR}
	$UTILS/lmstrip max
	$UTILS/lmstrip nst
	$UTILS/lmstrip edif2sue
        cd ../sue/${BIN_DIR}
	$UTILS/lmstrip sue.exe
	)
    done
}

# Now do it

Init
make_RelDir
make_max
make_dpc_tutorial
make_sue
make_thing nst NST_RELEASE nst
make_thing speedy SPEEDY_RELEASE speedy_package.so
make_thing nl NL_RELEASE nl_shell
make_thing edif2sue EDIF2SUE_RELEASE edif2sue
make_misc
#make_flex
make_doc
#run_lmstrip


# All done copying files.
# Set permissions on files.

  ${UTILS}/build_fix_permissions ${MMI_RELEASE_DIR}/${RELEASE_NAME}

  ( cd ${RELEASE_DIR}/sue/schematics; chmod oug+w . devices \
	  spice mspice verilog dpc devices/tclIndex spice/tclIndex \
	  mspice/tclIndex verilog/tclIndex dpc/tclIndex
    )


    # Make the .tar.gz file for external release

  ( cd ${MMI_RELEASE_DIR}
    rm -f new
    ln -s ${RELEASE_NAME} new
    gtar -z -c -f ${RELEASE_NAME}.tar.gz ${RELEASE_NAME}
    )
