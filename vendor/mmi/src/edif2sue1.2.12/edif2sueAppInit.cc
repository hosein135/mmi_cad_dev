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

#include <stdlib.h>	// for malloc
#include <sys/stat.h>	// for statbuf (objviously)

#include <util.h>

rc_t read_config_file(char *);
BOOLEAN parse_only;

int error_count;
int warning_count;

///////////////////////////////////////////////////////////



int
main(int argc, char *argv[]) {

	BOOLEAN	user_specified_config_file = false;

	SUE::SHOW_RIPPERS = false;
	SUE::LITERAL_NETNAMES = false;
	SUE::cellname_prefix = "eq_";
	SUE::output_dir_path = "sue/";
	SUE::CONTINUE_ON_TRANSLATE_ERRORS = false;
	SUE::SUPPRESS_PROGRESS_MESSAGES = false;
	SUE::MAKE_NETLISTS = false;
	SUE::SKIP_BAD_PORTS = false;
	SUE::IGNORE_PROPERTY_LIST = NULL;
	SUE::USE_GLOBALS = NULL;
	SUE::CADENCE_PROPERTY_VALUES = false;
	SUE::ADD_VERILOG_PROPERTY_BY_LIBRARY = NULL;
	SUE::ROUND_TO_GRID_LINES = false;
	SUE::CONVERT_CADENCE_NETNAMES = false;
	SUE::ADD_TITLE_BAR = false;
	SUE::SUPPRESS_INSTANCE_NAME_PREFIX = NULL;
	SUE::UNIQUIFY_DUPLICATE_NAMES = false;
	SUE::SCALE_COORDS = false;
	SUE::scale_coords_factor = 1;
	SUE::ignore_cellnames_list = NULL;
	SUE::TANNER_RENAME_BUG = false;
	SUE::ORCAD_CELLNAME_BUG = false;
	
	SUE::PROPERTY_STR_YINCR = 30;

	parse_only = false;

	if (argc < 2) {
		printf("version %s compiled %s\n", E2S_VERSION, __DATE__);
		printf("edif2sue {-config_file <path>} <edif file name>\n");
		printf("    default config file is $MMI_TOOLS/edif2sue/e2s_rc\n");
		printf("    multiple config files can be specified\n");
		printf("    \n");
		printf("    config file entries (1 per line) as follows\n");
		printf("    \n");
		printf("    config_file <path>\n");
		printf("    cellprefix <cell prefix string> | no_cellprefix\n");
		printf("    outdir <output directory path>\n");
		printf("    suppress_progress_messages\n");
		printf("    continue_on_translate_errors\n");
		printf("    no_mmi_globals\n");
		printf("    show_rippers\n");
		printf("    literal_netnames\n");
		printf("    parse_only\n");
	//	printf("    make_netlists\n");
		printf("    skip_bad_ports\n");
		printf("    no_skip_bad_ports\n");
		printf("    ignore_property <string>\n");
		printf("    use_global <cell_name> <global_name>\n");
		printf("    cadence_property_conversion\n");
		printf("    no_cadence_property_conversion\n");
		printf("    add_verilog_property_by_library <library-name>\n");
		printf("    round_to_grid_lines\n");
		printf("    convert_cadence_netnames\n");
		printf("    add_title_bar\n");
		printf("    suppress_instance_name_prefix <name prefix string>\n");
		printf("    ingore_cell_definition <cell name>\n");
		printf("    scale_coordinates <integer scale factor>\n");
		printf("    uniquify_duplicate_names\n");
		
		printf("    \n");
		return	0;
	}

	int arg = 1;
	while (argc > arg && argv[arg][0] == '-') {
		char *option = argv[arg++];


		if (strcmp(option, "-config_file") == 0) {
			if (argc > arg) {
				printf("...reading config file %s\n", argv[arg]);
				rc_t rc = read_config_file(argv[arg++]);
				if (rc != RC_NOMINAL) {
					printf("read config file failed\n");
					exit(-1);
				}
				user_specified_config_file = true;
			} else {
				printf("specify config file name, please\n");
				exit(0);
			}
		}

		else if (strcmp(option, "-v") == 0) {
			printf("version %s compiled %s\n", E2S_VERSION, __DATE__);
			exit(0);
		}

		else {
			printf("unknown option %s\n", option);
			exit(0);
		}
	}

	if (arg == argc) {
		printf("need name of edf file after options, please\n");
		exit(0);
	}


#define MAX_CONFIG_FILENAME_SIZE 0x1000
	char config_fn[MAX_CONFIG_FILENAME_SIZE];
	struct stat statbuf;
	if (user_specified_config_file == false) {
		sprintf(config_fn, "%s/edif2sue/e2s_rc", getenv("MMI_TOOLS"));
		if (strlen(config_fn) >= MAX_CONFIG_FILENAME_SIZE) {
			printf("overflowed config filename buffer\n");
			exit(-1);
		}

		int ri = stat(config_fn, &statbuf);
		if (ri == 0) {
			printf("...reading config file %s\n", config_fn);
			rc_t rc = read_config_file(config_fn);
			if (rc != RC_NOMINAL) {
				printf("read default config file %s failed\n", config_fn);
				exit(-1);
			}
		} 
	}

	char *edf_filename = argv[arg++];
	if (arg != argc) {
		printf("extra arguement after edf file name??? %s\n", argv[arg]);
		exit(0);
	}

	int *start = (int *)malloc(sizeof(int));

	EDIF_FILE *edif_file = new EDIF_FILE(edf_filename);
	rc_t rc = edif_file->open();
	if (rc != RC_NOMINAL) {
		printf("exiting due to edif file open failed\n");
		exit (-1);
	}


	printf("begin parsing...\n");

	error_count = 0;
	warning_count = 0;
	rc = edif_file->parse();
	edif_file->close();

	if (error_count != 0) {
		printf("\n ...%d errors and %d warnings encountered, "
		    "terminating\n", error_count, warning_count);
		exit(-1);
	}

	if (warning_count != 0) {
		printf("\nDANGER %d warnings encountered", warning_count);
		printf("continuing, but results are unpredicatable\n");
	}

	if (parse_only == true) {
		edif_file->get_top_expr()->print(0);
		exit(0);
	}
	
	printf("begin translating...\n");

	SUE *sue = new SUE();
	rc = sue->translate(edif_file->get_top_expr());
	if (rc != RC_NOMINAL) {
		exit(-1);
	}

	// the generated nmos & pmos icons don't display size,
	// so make some magic ones that do.
	//	sue->write_magic_transistor_files();


	int *finish = (int *)malloc(sizeof(int));
	printf("all done! dynamic memory used = %d (%x hex) bytes\n", finish-start, finish-start);

	return 0;
}

#define MAX_INLINE_SIZE	1000

rc_t
read_config_file(char* filename)
{
	FILE *fd = fopen(filename, "r");
	if (fd == NULL) {
		printf("open config file \"%s\" failed, errno %d\n",
		    filename, errno);
		return RC_FAILED;
	}
	int lineno = 1;
	
	char line[MAX_INLINE_SIZE];
	char *s = line;
	char *p = s;

	while (1) {
		s = fgets(line, MAX_INLINE_SIZE, fd);
		if (s == NULL) break;

		// comment? .... '#' in column 1
		if (*s == '#') continue;

		char option[MAX_INLINE_SIZE];
		char arg1[MAX_INLINE_SIZE];
		char arg2[MAX_INLINE_SIZE];
		char arg3[MAX_INLINE_SIZE];

		arg1[0] = '\0';
		arg2[0] = '\0';
		arg3[0] = '\0';

		sscanf(s, "%s%s%s%s\n", option, arg1, arg2, arg3);

		if (strcmp(option, "cellprefix") == 0) {
			SUE::cellname_prefix = strdup(arg1);

		} else if (strcmp(option, "no_cellprefix") == 0) {
			SUE::cellname_prefix = "";

		} else if (strcmp(option, "config_file") == 0) {
			read_config_file(arg1);

		} else if (strcmp(option, "outdir") == 0) {
			SUE::output_dir_path = strdup(arg1);

		} else if (strcmp(option, "suppress_progress_messages") == 0) {
			SUE::SUPPRESS_PROGRESS_MESSAGES = true;
			printf("...suppressing progress messages\n");


		} else if (strcmp(option, "continue_on_translate_errors") == 0) {
			SUE::CONTINUE_ON_TRANSLATE_ERRORS = true;

		} else if (strcmp(option, "no_mmi_globals") == 0) {
			SUE::USE_GLOBALS = false;

		} else if (strcmp(option, "show_rippers") == 0) {
			SUE::SHOW_RIPPERS = true;

		} else if (strcmp(option, "literal_netnames") == 0) {
			SUE::LITERAL_NETNAMES = true;

		} else if (strcmp(option, "parse_only") == 0) {
			parse_only = true;

		} else if (strcmp(option, "make_netlists") == 0) {
			SUE::MAKE_NETLISTS = true;

		} else if (strcmp(option, "skip_bad_ports") == 0) {
			SUE::SKIP_BAD_PORTS = true;

		} else if (strcmp(option, "no_skip_bad_ports") == 0) {
			SUE::SKIP_BAD_PORTS = false;

		} else if (strcmp(option, "round_to_grid_lines") == 0) {
			SUE::ROUND_TO_GRID_LINES = true;

		} else if (strcmp(option, "convert_cadence_netnames") == 0) {
			SUE::CONVERT_CADENCE_NETNAMES = true;

		} else if (strcmp(option, "add_title_bar") == 0) {
			SUE::ADD_TITLE_BAR = true;

		} else if (strcmp(option, "ignore_cell_definition") == 0) {
			SUE::ignore_cellnames_list = new ListOfCHARSTAR(
			    strdup(arg1), SUE::ignore_cellnames_list);

		} else if (strcmp(option, "scale_coordinates") == 0) {
			int arg_scale_factor;
			int rv = sscanf(arg1, "%d", &arg_scale_factor);
			if (rv != 1) {
				printf("can\'t convert scale factor\n");
				exit(-1);
			}
			SUE::scale_coords_factor = arg_scale_factor;
			SUE::SCALE_COORDS = true;
			SUE::PROPERTY_STR_YINCR *= arg_scale_factor;


		} else if (strcmp(option, "uniquify_duplicate_names") == 0) {
			SUE::UNIQUIFY_DUPLICATE_NAMES = true;

		} else if (strcmp(option, "suppress_instance_name_prefix") == 0) {
			SUE::SUPPRESS_INSTANCE_NAME_PREFIX = strdup(arg1);

		} else if (strcmp(option, "ignore_property") == 0) {
			// pretty hacky way to deal with quoted strings here
			if (arg1[0] == '\"') {
				char *p = line;
				char *endp = line + strlen(line);
				while (p < endp  && *p != '\"') p++;
				p++;
				char *r = arg1;
				while (p < endp && *p != '\"') *r++ = *p++;
				*r = '\0';
			}
			SUE::IGNORE_PROPERTY_LIST = new ListOfCHARSTAR(
			    strdup(arg1), SUE::IGNORE_PROPERTY_LIST);

		} else if (strcmp(option, "use_global") == 0) {
			SUE::USE_GLOBALS = new BINDING_CHAIN(
			    strdup(arg1), strdup(arg2), strdup(arg3), SUE::USE_GLOBALS);

		} else if (strcmp(option, "no_cadence_property_conversion") == 0) {
			SUE::CADENCE_PROPERTY_VALUES = false;

		} else if (strcmp(option, "cadence_property_conversion") == 0) {
			SUE::CADENCE_PROPERTY_VALUES = true;

		} else if (strcmp(option, "tanner_rename_bug") == 0) {
			SUE::TANNER_RENAME_BUG = true;

		} else if (strcmp(option, "orcad_cellname_bug") == 0) {
			SUE::ORCAD_CELLNAME_BUG = true;

		} else if (strcmp(option, "add_verilog_property_by_library") == 0) {
			SUE::ADD_VERILOG_PROPERTY_BY_LIBRARY = new ListOfCHARSTAR(
			    strdup(arg1), SUE::ADD_VERILOG_PROPERTY_BY_LIBRARY);
		} 

		else {
			printf("don't recognize option string \"%s\"\n", s);
			exit(-1);
		}	
	}

	// RFE.... should check for stream error indication
	return RC_NOMINAL;
	
}
