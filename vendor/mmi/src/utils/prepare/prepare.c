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


/* Syntax: 
 *
 *       prepare [-s] [-n] input_file1, input_file2, ... > output_file 
 *
 * Output file included in .c file like this:
 *
 *        unsigned char a[] = {
 *          #include output_file
 *        };
 *
 * If -s, output is quoted string format instead of list of ints.
 *
 */

#include <stdio.h>

int OptionS = 0;  /* if set, output string format */

static __inline__ writeChar(unsigned char c)
{
  static int count = 0;

  /* add line break every few chars */
  if(count == 15)
  {
    if(OptionS)
    {
      printf("\\\n");
    }
    else
    {
      printf("\n");
    }

    count = 0;
  }

  {
    if(OptionS)
    {
      printf("\\%03o",c);
    }
    else
    {
      printf("0%o,",c);
    }
  } 

  count++;
}
    
writeBuffer(unsigned char *buf, int size)
{

  while(size)
  {
    writeChar(*(buf++));
    size--;
  }
}

int
main(int argc, 
		/* Number of command-line arguments. */
     char **argv)
		/* Values of command-line arguments. */
{
  char *cmdName;

  /* get command name */
  cmdName = *argv;
  argv++;
  argc--;

  /* process options */
  while(argc && **argv=='-')
  {
    if(strcmp(*argv,"-s")==0) 
    {
      OptionS = 1;
    }  
    else 
    {
      goto usage;
    }

    argv++;
    argc--;
  }

  /* if string format, put out an initial quote */
  if(OptionS) printf("\"");

  /* process one file at a time */
  while(argc) 
  {
    int size;
    FILE *fp;

    char *fileName = *argv;

    /* open file */
    if ((fp = fopen(fileName,"r")) == NULL) 
    {
      fprintf(stderr,"%s:  Error, can't find file %s\n",
	      cmdName, fileName);
      exit(1);
    }

    /* process one buffer at a time */
    while(1)
    {
      unsigned char buf[BUFSIZ];

      /* fill buffer */
      size = fread(buf, sizeof(char), BUFSIZ, fp);
      if (size == EOF) 
      {
        fprintf(stderr,"%s: error, while reading file %s\n",
		cmdName, fileName);
	exit(1);
      }
      if (size == 0) break;

      /* write buffer */
      writeBuffer(buf, size);
    }

    /* add a return character at the end of the file, so unterminated final
     * lines don't cause trouble.
     */
    {
      unsigned char c = '\n';
      writeChar(c);
    }

    /* advance to next arg */
    argv++;
    argc--;
  }

  /* add terminator */
  {
    unsigned char c = '\0';
    if(OptionS)
    {
      printf("\\%03o\"\n", c);
    }
    else
    {
      printf("0%o\n", c);
    }

  }

  /* normal completion */
  return 0;

usage:
  fprintf(stderr,"Usage: %s [-s] input_file1 ... > output_file\n"
	  "\t If -s, output is quoted string format instead of list of ints.\n",
	  cmdName);
  exit(1);
}

