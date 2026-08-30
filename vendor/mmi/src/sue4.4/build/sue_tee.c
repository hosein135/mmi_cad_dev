// ************************************************************************
// 
// Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
// Portions Copyright (c) 1994 Sun Microsystems, Inc. All rights reserved.
// 
// Permission is hereby granted, without written agreement and without
// license or royalty fees, to use, copy, modify, and distribute this
// software and its documentation for any purpose, provided that the
// above copyright notice and the following three paragraphs appear in
// all copies of this software.
// 
// IN NO EVENT SHALL JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS, INC. BE
// LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
// CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
// DOCUMENTATION, EVEN IF JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS,
// INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// JUNIPER NETWORKS, INC. AND SUN MICROSYSTEMS, INC. SPECIFICALLY
// DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
// NON-INFRINGEMENT.
// 
// THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
// NETWORKS, INC. AND SUN MICROSYSTEMS, INC. HAVE NO OBLIGATION TO
// PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
// 
// ************************************************************************

// This program is supposed to contain the functionality of tee(1), except
// for the options.  So "suetee foo" will copy stdin to stdout, plus write
// it to file foo.  "sue | tee foo" won't go away until you exit an interactive
// program (like emacs or netscape) if you enter them while in sue.  So
// suetee watches for the exit message (bye[], below) from sue and forces
// an exit.

#include <stdio.h>

// the exit message
char bye[] = "xiting Micro Magic SUE.  Have a nice day.";
// the prompt
char prompt[] = "sue> ";

main(int argc, char **argv)
{
	char *prog = *argv;
	int c;
	char *p = bye;
	char *q = prompt;
	FILE *logfile;

	argc--; argv++;

	// only accepts one form of command line, "suetee file"
	if (argc != 1) {
		fprintf(stderr, "usage: %s file\n", prog);
		exit(1);
	}


	// open the file for writing
	logfile = fopen(*argv, "w");
	if (!logfile) {
		// error if you can't
		fprintf(stderr, "can't write %s\n", *argv);
	}

	// read a character at a time from stdin,
	// copying it to stdout and the log file
	while (1) {

		// get next character
		int c = fgetc(stdin);
		// exit if EOF
		if (c == EOF) exit(0);

		// copy it to stdout
		fputc(c, stdout);
		// copy it to logfile
		if (logfile) fputc(c, logfile);

		// this happy code watches for the sue prompt
		if (c == '\n') { 
			// reset our "state machine" whenever we see a newline
			q = prompt;
		} else {
			if (c ==  *q) {
				// if the input character matches the next one in the
				// happy prompt message, increment the pointer into the
				// prompt message
				q++;
			} else {
				// otherwies start over again
				q = prompt;
			}
		} 
		if (!*q) {
			// if we make it all the way to the end of the happy prompt
			// message, then we have a prompt, so flush stdout.
			fflush(stdout);
			q = prompt;
		}

		// this happy code watches for the sue exit message
		if (c == 'x') {
			// reset our "state machine" whenever we see an "x",
			// as in "E[x]iting Micro Magic SUE ...
			p = bye+1;
		} else {
			if (c == *p) {
				// if the input character matches the next one in the
				// happy exit message, increment the pointer into the
				// exit message
				p++;
			} else {
				// otherwise start over again
				p = bye;
			}
		}
		if (!*p) {
			// if we make it all the way to the end of the happy exit
			// message, then sue just exited, so suetee better exit too,
			// so emacs or netscape can't hang it up.
			fputc('\n', stdout);
			exit(0);
		}
	}
}


