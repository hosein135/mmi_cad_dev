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

#include <util.h>

#define MAXLINESIZE 5000


///////////////////////////////////////////////////////////

class SOMEFILE {
    public:
		SOMEFILE(char *name);

	// the file is treated as a stream (fopen'd)
	rc_t	ropen();
	rc_t	wopen();

	rc_t	close();

	rc_t	prettyup(FILE *outfile);
	rc_t	break_libs(char *outfn_base);
	rc_t	get_cell(char *cellname, FILE *outfile);
	
	int	get_lineno();

//  private:
	char *	name;
	FILE *	fd;		// valid & open <==> fd != 0	
	int	lineno;	// current line number during parse
				// (for error reporting)
	

};


main(int argc, char *argv[])
{
	int arg = 1;

	if (argc <= arg) {
		printf("command?\n");
		printf("    pretty <infile = xxx.edf> <outfile = pretty>\n");
		printf("    break_libs <infile = xxx> <outname_base = lib_>\n");
		printf("    get_cell <cellname> <infile = break/Db> <outname = xxx.edf>\n");
		return	0;
	}

	char *cmd = argv[arg++];
	if (strcmp(cmd, "pretty") == 0) {

		char *infn = "xxx.edf"; 
		if (argc > arg)		infn = argv[arg++];
		char *outfn = "pretty"; 
		if (argc > arg)		outfn = argv[arg++];
		printf("pretty in %s out %s\n", infn, outfn);

		SOMEFILE infile(infn);
		infile.ropen();
		SOMEFILE outfile(outfn);
		outfile.wopen();

		infile.prettyup(outfile.fd);

		infile.close();
		outfile.close();
		return  0;
	}

	if (strcmp(cmd, "break_libs") == 0) {

		char *infn = "xxx"; 
		if (argc > arg)		infn = argv[arg++];
		char *outfn_base = "lib_"; 
		if (argc > arg)		outfn_base = argv[arg++];
		printf("break_libs in %s out %s_libname_n\n", infn, outfn_base);

		SOMEFILE infile(infn);
		infile.ropen();

		infile.break_libs(outfn_base);

		infile.close();
		return  0;
	}

	if (strcmp(cmd, "get_cell") == 0) {

		char *cellname = ""; 
		if (argc > arg)		cellname = argv[arg++];
		else {
			printf("need cellname, at least\n");
			exit(-1);
		}

		char *infn = "break/Db"; 
		if (argc > arg)		infn = argv[arg++];

		char *outfn = "xxx.edf"; 
		if (argc > arg)		outfn = argv[arg++];

		printf("get_cell %s in %s out %s\n", 
		    cellname, infn, outfn);

		SOMEFILE infile(infn);
		infile.ropen();

		SOMEFILE outfile(outfn);
		outfile.wopen();

		infile.get_cell(cellname, outfile.fd);

		infile.close();
		outfile.close();
		return  0;
	}

	printf("what command?\n");

	return 0;

}



///////////////////////////////////////////////////////////


SOMEFILE::SOMEFILE(char *arg_name)
    : name(arg_name), fd(NULL)
{
}


rc_t
SOMEFILE::ropen()
{
	fd = fopen(name, "r");
	if (fd == NULL) {
		printf("open edif file \"%s\" failed, errno %d\n",
		    name, errno);
		return RC_FAILED;
	}
	lineno = 1;
	return RC_NOMINAL;
}

rc_t
SOMEFILE::wopen()
{
	fd = fopen(name, "w");
	if (fd == NULL) {
		printf("open edif file \"%s\" failed, errno %d\n",
		    name, errno);
		return RC_FAILED;
	}
	lineno = 1;
	return RC_NOMINAL;
}

rc_t
SOMEFILE::close()
{
	if (fd == NULL) {
		return RC_INVALID;
	}
	fclose(fd);
	fd = NULL; 
}	

rc_t
SOMEFILE::prettyup(FILE *out)
{
	int c = getc(fd);	// yes, int
	int indentlevel = 0;

	while (c != EOF) {

		switch ((char)c) {

		    case '(':
			putc(c, out);
			indentlevel++;
			break;	

		    case ')':
			putc(c, out);
			indentlevel--;
			if (indentlevel < 0) {
				printf("indentlevel went negative\n");
				exit (-1);
			}
			break;

		    case '\n':
			putc(c, out);
			for (int i = 0; i < indentlevel; i++) {
				putc(' ', out);
				putc(' ', out);
			}
			while (isspace(c))	c = getc(fd);
			ungetc(c, fd);
			break;

		    default:
			putc(c, out);
			break;
		}
		c = getc(fd);
	}					

	if (indentlevel != 0)
		printf("EOF with indent level %d\n", indentlevel);
	
}

rc_t
SOMEFILE::break_libs(char *outfn_base)
{

	char	line[MAXLINESIZE];
	char	tstr[MAXLINESIZE];

	// first the non-lib stuff
	SOMEFILE *outfile = new SOMEFILE(outfn_base);
	outfile->wopen();
	
	while (1) {
		char *p = fgets(line, MAXLINESIZE, fd);
		if (p == NULL) return RC_NOMINAL;

		if (strstr(line, "(library ") != 0) {
			outfile->close();
			delete outfile;
			outfile == NULL;
			break;
		}
	
		fprintf(outfile->fd, line);
	} 
		
	int libno = 1;

	while (1) {

		printf("found lib %d: %s", libno, line);
		sprintf(tstr, "%s%d", outfn_base, libno);
		outfile = new SOMEFILE(tstr);	
		outfile->wopen();
		fprintf(outfile->fd, line);
		
		char *p;
		while(1) {
			p = fgets(line, MAXLINESIZE, fd);
			if ((p == NULL) ||
			    (strstr(line, "(library ") != 0)) {
				outfile->close();
				delete outfile;
				outfile == NULL;
				break;
			}

			fprintf(outfile->fd, line);
		} 
	
		if (p == NULL) return RC_NOMINAL;

		libno++;
	}
}

rc_t
SOMEFILE::get_cell(char *cellname, FILE *outfile)
{

	char	line[MAXLINESIZE];
	char	tstr[MAXLINESIZE];

	sprintf(tstr, "(cell %s ", cellname);
	int linenumber = 0;

	while (1) {
		char *p = fgets(line, MAXLINESIZE, fd);
		if (p == NULL) {
			printf("cell not found....read %d lines\n", linenumber);
			return RC_NOMINAL;
		}
		linenumber++;

		if (strstr(line, tstr) != 0) break;
	} 

	printf("found cell....starts at line %d\n", linenumber);
		
	while (1) {
		fprintf(outfile, line);
		
		char *p = fgets(line, MAXLINESIZE, fd);
		if ((p == NULL)	||
		    (strstr(line, "(cell ") != 0)) return RC_NOMINAL;

	}
}

