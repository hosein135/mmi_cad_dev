// This program is supposed to contain the functionality of tee(1), except
// for the options.  So "suetee foo" will copy stdin to stdout, plus write
// it to file foo.  "sue | tee foo" won't go away until you exit an interactive
// program (like emacs or netscape) if you enter them while in sue.  So
// suetee watches for the exit message (bye[], below) from sue and forces
// an exit.

#include <stdio.h>

// the exit message
// it must start with an x and have no other x's in it
// or else you have to hack the code below.
// case insensitive
char bye[] = "xiting micro magic sue.  have a nice day.";
// the prompt
// the * becomes [a-z0-9#]*
// case insensitive
char prompt[] = "sue*> ";

int alnunum(char c)
{
	if (c == '#') return 1;
	if (c >= 'a' && c <= 'z') return 1;
	if (c >= '0' && c <= '9') return 1;
	return 0;
}

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

		// our happy prompt and exit strings are case insensitive
		if (c >= 'A' && c <= 'Z') c = c + 'a' - 'A';

		// this happy code watches for the sue prompt
		if (c == '\n') { 
			// reset our "state machine" whenever we see a newline
			q = prompt;
		} else {
			if (*q == '*') {
				if (c == *(q+1)) {
					// if the input character matches the next char
					// in the happy prompt message after the *, then
					// skip the star and the next char.
					q += 2;
				} else if (alnunum(c)) {
					// ignore all the chars that match the char class
				} else {
					// start over if a char is neither in the char class
					// nor does it match the next prompt char after the *
					q = prompt;
				}
			} else if (c ==  *q) {
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
			// as in "e[x]iting micro magic sue ...
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


