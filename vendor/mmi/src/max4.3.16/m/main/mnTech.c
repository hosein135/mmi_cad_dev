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



/*
 * mnTech.c --
 *
 * Read in a technology file.
 *
 *     ********************************************************************* 
 *     * Copyright (C) 1985, 1990 Regents of the University of California. * 
 *     * Permission to use, copy, modify, and distribute this              * 
 *     * software and its documentation for any purpose and without        * 
 *     * fee is hereby granted, provided that the above copyright          * 
 *     * notice appear in all copies.  The University of California        * 
 *     * makes no representations about the suitability of this            * 
 *     * software for any purpose.  It is provided "as is" without         * 
 *     * express or implied warranty.  Export of this software outside     * 
 *     * of the United States of America may require an export license.    * 
 *     *********************************************************************
 */


#include <stdio.h>
#include <ctype.h>
#include <stdarg.h>
#include "magic.h"
#include "main.h"
#include "mainInt.h"
#include "memory.h"
#include "main.h"
#include "database.h"
#include "layout.h"
#include "cif.h"
#include "drc.h"
#include "extract.h"
#include "layout.h"
#include "geometry.h"
#include "utils.h"
#include "message.h"

/* tech file version (appended to tech filenames) */
#define VERSION 27

static int techLineNumber;
static char *techFileName = NULL;

#define	iseol(c)	((c) == EOF || (c) == '\n')

/*
 * Each client of the technology module must make itself known by
 * a call to mnTechAddClient().  These calls provide both the names
 * of the sections of the technology file, as well as the procedures
 * to be invoked with lines in these sections.
 *
 * The following table is used to record clients of the technology
 * module.
 */

typedef struct tC
{
  bool		(*tc_proc)();	/* Procedure to be called for each
				 * line in section.
				 */
  void		(*tc_init)();	/* Procedure to be called before any
				 * lines in a section are processed.
				 */
  void		(*tc_final)();	/* Procedure to be called after all
				 * lines in section have been processed.
				 */
  struct tC	*tc_next;	/* Next client in section */
} techClient;

typedef int SectionID;		/* Mask set by TechAddClient */

typedef struct
{
  char		*ts_name;	/* Name of section */
  techClient	*ts_clients;	/* Pointer to list of clients */
  bool		 ts_read;	/* Flag: TRUE if section was read */
  bool		 ts_optional;	/* Flag: TRUE if section is optional */
  SectionID	 ts_thisSect;	/* SectionID of this section */
  SectionID	 ts_prevSects;	/* Mask of sections that must be
				 * read in before this one.  The
				 * mask is constructed from the
				 * section identifiers set by
				 * TechAddClient().
				 */
} techSection;

#define	MAXSECTIONS	(8 * sizeof (int))	/* Not easily changeable */
#define	MAXARGS		30
#define MAXLINESIZE	1024

#define	SectionToMaskBit(s)		(1 << (s))
#define SectionMaskHasSection(m, s)	(m & SectionToMaskBit(s))

static int techSectionNum;		/* ID of next new section */
static SectionID techSectionMask;	/* Mask of sections already read */

static techSection techSectionTable[MAXSECTIONS];
static techSection *techSectionFree;	/* Pointer to next free section */
static techSection *techCurrentSection;	/* Pointer to current section */

static techSection *techFindSection(char *sectionName);


/*
 * ----------------------------------------------------------------------------
 *
 * mnTechAddClient --
 *
 * Add a client to the technology module.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Identifies "sectionName" as a valid name for a section of a .tech
 *	file, and specifies that init() is the procedure to be called when
 *	a new technology is loaded, proc() as the procedure to be called
 *	for each line in the given section, and final() as the procedure to
 *      be called after the last line in the given section.
 *
 *	The init() procedure takes no arguments.
 *	The proc() procedure should be of the following form:
 *		bool
 *		proc(sectionName, argc, argv)
 *			char *sectionName;
 *			int argc;
 *			char *argv[];
 *		{
 *		}
 *	The final() procedure takes no arguments.
 *
 *	The argument prevSections should be a mask of the SectionID's
 *	of all sections that must be read in before this one.
 *
 *	If the argument 'pSectionID' is non-NULL, it should point to
 *	an int that will be set to the sectionID of this section.
 *
 *	It is legal for several procedures to be associated with a given
 *	sectionName; this is accomplished through successive calls to
 *	mnTechAddClient with the same sectionName.  The procedures will
 *	be invoked in the order in which they were handed to mnTechAddClient().
 *
 *	If the procedure given is NULL for init(), proc(), or final(), no
 *	procedure is invoked.
 *
 * ----------------------------------------------------------------------------
 */

static void
mnTechAddClient(char *sectionName, 
	      void (*init) (/* ??? */), 
	      bool (*proc) (/* ??? */), 
	      void (*final) (/* ??? */), 
	      SectionID prevSections, 
	      SectionID *pSectionID, 
	      int opt)                       /* TRUE if optional setion */
{
    techSection *tsp;
    techClient *tcp, *tcl;

    tsp = techFindSection(sectionName);
    if (tsp == (techSection *) NULL)
    {
	tsp = techSectionFree++;
	ASSERT(tsp < &techSectionTable[MAXSECTIONS], "mnTechAddClient");
	tsp->ts_name = StrDup((char **) NULL, sectionName);
	tsp->ts_clients = (techClient *) NULL;
	tsp->ts_thisSect = SectionToMaskBit(techSectionNum);
	tsp->ts_prevSects = (SectionID) 0;
	tsp->ts_optional = opt;
	techSectionNum++;
    }

    tsp->ts_prevSects |= prevSections;
    if (pSectionID)
	*pSectionID = tsp->ts_thisSect;

    MALLOC_TAG(techClient *,
	       tcp,
	       sizeof(techClient),
	       "techClient");

    ASSERT(tcp != (techClient *) NULL, "mnTechAddClient");
    tcp->tc_init = init;
    tcp->tc_proc = proc;
    tcp->tc_final = final;
    tcp->tc_next = (techClient *) NULL;

    if (tsp->ts_clients == (techClient *) NULL)
	tsp->ts_clients = tcp;
    else
    {
	for (tcl = tsp->ts_clients; tcl->tc_next; tcl = tcl->tc_next)
	    /* Nothing */;
	tcl->tc_next = tcp;
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * techGetTokens --
 *
 * Read a line from the technology file and split it up into tokens.
 * Blank lines are ignored.  Lines ending in backslash are joined
 * to their successor lines.
 * We assume that all macro definition and comment elimination has
 * been done by the C preprocessor.
 *
 * Results:
 *	Returns the number of tokens into which the line was split, or
 *	-1 on end of file.  Never returns 0.
 *
 * Side effects:
 *	Copies the line just read into 'line'.  The trailing newline
 *	is turned into a '\0'.  The line is broken into tokens which
 *	are then placed into argv.
 *
 * ----------------------------------------------------------------------------
 */

int techGetTokens(char *line, 
               			/* Character array into which line is read */
		  int size, 
             			/* Size of character array */
		  register FILE *file, 
                        	/* Open technology file */
		  char **argv)
                 		/* Vector of tokens built by techGetTokens() */
{
    register char *get, *put;
    bool inquote;
    int argc = 0;

    /* Read one line into the buffer, joining lines when they end
     * in backslashes.
     */

start:
     get = line;
     while (size > 0)
     {
	techLineNumber += 1;
	if (fgets(get, size, file) == NULL) return (-1);
	for (put = get; *put != '\n'; put++) size -= 1;
	if ((put != get) && (*(put-1) == '\\'))
	{
	    get = put-1;
	    continue;
	}
	*put= '\0';
	break;
    }
    if (size == 0) MnTechError("long line truncated\n");

    get = put = line;

    if (*line == '#') goto start;	/* Ignore comments */

    while (*get != '\0')
    {
	/* Skip leading blanks */

	while (isspace(*get)) get++;

	/* Beginning of the token is here. */

	argv[argc] = put = get;
	if (*get == '"')
	{
	    get++;
	    inquote = TRUE;
	} else inquote = FALSE;

	/*
	 * Grab up characters to the end of the token.  Any character
	 * preceded by a backslash is taken literally.
	 */
	
	while (*get != '\0')
	{
	    if (inquote)
	    {
		if (*get == '"') break;
	    }
	    else if (isspace(*get)) break;

	    if (*get == '\\')	/* Process quoted characters literally */
	    {
		get += 1;
		if (*get == '\0') break;
	    }

	    /* Copy into token receiving area */
	    *put++ = *get++;
	}

	/*
	 * If we got no characters in the token, we must have been at
	 * the end of the line.
	 */
	if (get == argv[argc])
	    break;
	
	/* Terminate the token and advance over the terminating character. */

	if (*get != '\0') get++;	/* Careful!  could be at end of line! */
	*put++ = '\0';
	argc++;
    }

    if (argc == 0)
	goto start;

    return (argc);
}


/*
 * ----------------------------------------------------------------------------
 * mnTechRead --
 *
 * Initialize technology description information from a file.
 *
 * Results:
 *	TRUE if technology is successfully initialized (all required
 *	sections present and error free); FALSE otherwise.  Unrecognized
 *	sections cause an error message to be printed, but do not otherwise
 *	affect the result returned by TechLoad().
 *
 * Side effects:
 *	Calls technology initialization routines of other modules
 *	to initialize technology-specific information.
 *
 * ----------------------------------------------------------------------------
 */

static bool
mnTechRead(FILE *tf)
{
    register techSection *tsp;
    register techClient *tcp;
    char suffix[20], line[MAXLINESIZE];
    char *argv[MAXARGS];
    SectionID mask, badMask;
    int argc, s;
    bool retval, skip;

    techLineNumber = 0;
    badMask = (SectionID) 0;

    /*
     * Mark all sections as being unread.
     */
    techSectionMask = 0;
    for (tsp = techSectionTable; tsp < techSectionFree; tsp++)
    {
	tsp->ts_read = FALSE;
    }

    /*
     * Sections in a technology file begin with a single line containing
     * the keyword identifying the section, and end with a single line
     * containing the keyword "end".
     */

    retval = TRUE;
    skip = FALSE;
    while ((argc = techGetTokens(line, sizeof line, tf, argv)) >= 0)
    {
	if (!skip && techCurrentSection == NULL)
	{
	    if (argc != 1)
	    {
		MnTechError("Bad section header line\n");
		goto skipsection;
	    }

	    tsp = techFindSection(argv[0]);
	    if (tsp == (techSection *) NULL)
	    {
		MnTechError("Unrecognized section name: %s\n", argv[0]);
		goto skipsection;
	    }
	    if (mask = (tsp->ts_prevSects & ~techSectionMask))
	    {
		register techSection *sp;

		MnTechError("Section %s appears too early.\n", argv[0]);
		MsgErrorF("\tMissing prerequisite sections:\n");
		for (sp = techSectionTable; sp < techSectionFree; sp++)
		    if (mask & sp->ts_thisSect)
			MsgErrorF("\t\t%s\n", sp->ts_name);
		goto skipsection;
	    }
	    techCurrentSection = tsp;

	    /* Invoke initialization routines for all clients that
	     * provided them.
	     */

	    for (tcp = techCurrentSection->ts_clients;
		    tcp != NULL;
		    tcp = tcp->tc_next)
	    {
		if (tcp->tc_init)
		    (void) (*tcp->tc_init)();
	    }
	    continue;
	}

	/* At the end of the section, invoke the finalization routine
	 * of the client's, if there is one.
	 */

	if (argc == 1 && strcmp(argv[0], "end") == 0)
	{
	    if (!skip)
	    {
		techSectionMask |= techCurrentSection->ts_thisSect;
		techCurrentSection->ts_read = TRUE;
		for (tcp = techCurrentSection->ts_clients;
			tcp != NULL;
			tcp = tcp->tc_next)
		{
		    if (tcp->tc_final)
			(*tcp->tc_final)();
		}
	    }
	    techCurrentSection = (techSection *) NULL;
	    skip = FALSE;
	    continue;
	}

	if (!skip)
	    for (tcp = techCurrentSection->ts_clients;
			tcp != NULL;
			tcp = tcp->tc_next)
		if (tcp->tc_proc)
		{
		    if (!(*tcp->tc_proc)(techCurrentSection->ts_name,argc,argv))
		    {
			retval = FALSE;
			badMask |= techCurrentSection->ts_thisSect;
		    }
		}
	continue;

skipsection:
	MsgErrorF("[Skipping to \"end\"]\n");
	skip = TRUE;
    }

    if (badMask)
    {
	MsgErrorF("The following sections of %s contained errors:\n", techFileName);
	for (s = 0; s < techSectionNum; s++)
	    if (SectionMaskHasSection(badMask, s))
		MsgErrorF("    %s\n", techSectionTable[s].ts_name);
    }

    for (tsp = techSectionTable; tsp < techSectionFree; tsp++)
	if (!tsp->ts_read && !tsp->ts_optional)
	{
	    MsgErrorF("Section \"%s\" was missing from %s.\n",
		tsp->ts_name, techFileName);
	    retval = FALSE;
	}

    return (retval);
}

/*
 * ----------------------------------------------------------------------------
 *
 * MnTechError --
 *
 * 	This procedure is called to print out error messages during
 *	Tech file reading.  (Gives filename, section, and line number)
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	An error message is printed.
 *
 * ----------------------------------------------------------------------------
 */
void
MnTechError(char *fmt, ...)
{
    va_list args;
    va_start(args,fmt);

    MsgErrorF("Error in technology file %s, line %d, section %s:\n\t",
	    techFileName, 
	    techLineNumber,
	    (techCurrentSection)?techCurrentSection->ts_name:"(none)");
    MsgErrorV(fmt, args);

    va_end(args);
}






/*
 * ----------------------------------------------------------------------------
 *
 * contactObsolete --
 *
 * called on non empty contact section.
 *
 * Complain and ignore:  Magic style contacts no longer supported.
 *
 * ----------------------------------------------------------------------------
 */
static bool
contactObsolete(char *sectionName, int argc, char **argv)
{
  MnTechError("Magic style contacts no longer supported.\n");
  return FALSE;
}



/*
 * ----------------------------------------------------------------------------
 *
 * stylesObsolete --
 *
 * called on non empty contact section.
 *
 * Complain and ignore:  Magic style contacts no longer supported.
 *
 * ----------------------------------------------------------------------------
 */
static bool
stylesObsolete(char *sectionName, int argc, char **argv)
{
  MnTechError("Styles no longer defined in .tech file.\n");
  return FALSE;
}

/*
 * ----------------------------------------------------------------------------
 *
 * techFindSection --
 *
 * Return a pointer to the entry in techSectionTable for the section
 * of the given name.
 *
 * Results:
 *	A pointer to the new entry, or NULL if none could be found.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

techSection *
techFindSection(char *sectionName)
{
    register techSection *tsp;

    for (tsp = techSectionTable; tsp < techSectionFree; tsp++)
	if (strcmp(tsp->ts_name, sectionName) == 0)
	    return (tsp);

    return ((techSection *) NULL);
}


/*
 * ----------------------------------------------------------------------------
 *
 * TechLoad --
 *
 * Read in a tech file.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *      Tech file opened and read.
 *      "Client" procedures called to process various lines in tech file.
 *
 * ----------------------------------------------------------------------------
 */

void
mnTechLoad(char *tech, char *var)  /* For technology: <tech>[_<var>] */
{
    SectionID sec_tech, sec_planes, sec_types, sec_styles;
    SectionID sec_connect, sec_contact, sec_compose;
    SectionID sec_cifinput, sec_cifoutput;
    SectionID sec_drc, sec_extract, sec_wiring, sec_router;
    SectionID sec_plow, sec_plot, sec_mzrouter;

    void (*nullProc)() = 0;
    bool (*nullProcBool)() = 0;

    /* initialize tech database */
    techCurrentSection = (techSection *) NULL;
    techSectionFree = techSectionTable;
    techSectionNum = 0;

    /* register tech "clients" (call backs during tech file read in) */
    mnTechAddClient("tech", 
		    DBTechInit, 
		    DBTechSetTech, 
		    nullProc,
		    (SectionID) 0, 
		    &sec_tech, 
		    FALSE);

    mnTechAddClient("version", 
		    nullProc, 
		    DBTechSetVersion, 
		    nullProc,
		    (SectionID) 0, 
		    (int *) 0, 
		    TRUE);           /* optional */

    mnTechAddClient("planes",	
		    nullProc, 
		    DBTechAddPlane, 
		    nullProc,
		    (SectionID) 0, 
		    &sec_planes, 
		    FALSE);

    mnTechAddClient("types", 
		    nullProc, 
		    DBTechAddType, 
		    DBTechFinalType,
		    sec_planes,      /* dependencies */
		    &sec_types, 
		    FALSE);

    mnTechAddClient("compose", 
		    DBTechInitCompose,
		    DBTechAddCompose, 
		    DBTechFinalCompose,
		    sec_types|sec_planes,
		    &sec_compose, 
		    FALSE);

    mnTechAddClient("connect", 
		    DBTechInitConnect,
		    DBTechAddConnect, 
		    DBTechFinalConnect,
		    sec_types|sec_planes,
		    &sec_connect, 
		    FALSE);

    mnTechAddClient("cifoutput", 
		    CIFTechInit, 
		    CIFTechLine, 
		    CIFTechFinal,
		    (SectionID) 0, 
		    &sec_cifoutput, 
		    FALSE);

    mnTechAddClient("cifinput", 
		    CIFReadTechInit, 
		    CIFReadTechLine,
		    CIFReadTechFinal, 
		    (SectionID) 0, 
		    &sec_cifinput, 
		    FALSE);

    mnTechAddClient("drc", 
		    DRCTechInit, 
		    DRCTechAddRule, 
		    DRCTechFinal,
		    sec_types|sec_planes, 
		    &sec_drc, 
		    FALSE);

    mnTechAddClient("extract", 
		    nullProc, 
		    ExtTechLine, 
		    ExtTechFinal,
		    sec_types|sec_connect, 
		    &sec_extract, 
		    FALSE);

    /* The following sections are obsolete.
     * They are registered for syntactic backward compatibility only.
     */

    mnTechAddClient("styles", 
		    nullProc, 
		    stylesObsolete,
		    nullProc,
		    (SectionID) 0,
		    &sec_styles, 
		    TRUE);           
  
    mnTechAddClient("contact", 
		    nullProc,
		    contactObsolete,       
		    nullProc,
		    (SectionID) 0, 
		    &sec_contact, 
		    TRUE);           

    mnTechAddClient("mzrouter", 
		    nullProc,
		    nullProcBool,
		    nullProc,
		    sec_types|sec_planes, 
		    &sec_mzrouter, 
		    TRUE);

    mnTechAddClient("wiring", 
		    nullProc, 
		    nullProcBool, 
		    nullProc,
		    sec_types, 
		    &sec_wiring, 
		    TRUE);

    mnTechAddClient("router", 
		    nullProc,
		    nullProcBool,
		    nullProc,
		    sec_types, 
		    &sec_router, 
		    TRUE);

    mnTechAddClient("plowing", 
		    nullProc,
		    nullProcBool,
		    nullProc,
		    sec_types|sec_connect|sec_contact, 
		    &sec_plow, 
		    TRUE);

    mnTechAddClient("plot", 
		    nullProc,
		    nullProcBool,
		    nullProc,
		    sec_types, &sec_plot, 
		    TRUE);

    /* find tech file and read it in */
    {
      FILE *fp = NULL;
      char name1[1000];
      char name2[1000];
      char *realname;

      /* First try var specific */
      if(var)
      {
	sprintf(name1,"tech/%s/%s-%s.tech27", tech, tech, var);	
	fp = PaOpen(name1, "r", NULL, MnPathSysLib, &realname);
      }

      /* if no var specific tech file found, try "generic" */
      if(!fp) 
      {
	sprintf(name2,"tech/%s/%s.tech27", tech, tech);	
	fp = PaOpen(name2, "r", NULL, MnPathSysLib, &realname);
      }

      /* if no tech file found, complain and take abnormal exit */
      if (!fp) 
      {
	if(var)
	{
	  MsgErrorF("Could not find tech file %s nor %s in any"
		    " of these directories:\n"
		    "\t%s\n",
		    name1, name2, MnPathSysLib);
	}
	else
	{
	  MsgErrorF("Could not find tech file %s in any"
		    " of these directories:\n"
		    "\t%s\n",
		    name2, MnPathSysLib);
	}
	exit(1);
      }

      /* save realname for use in any error messages */
      StrDup(&techFileName, realname);

      /* Announce and read it in */
      MsgInfoF("Reading %s\n", realname);      

      if (!mnTechRead(fp))
      {
	fprintf(stderr, "Could not load technology %s", tech);
	if(var) fprintf(stderr,"_%s",var);
	fprintf(stderr, "\n");
	exit(0);
      }

      /* close it */
      fclose(fp);
    }

    /* print tech name, version */
    MsgInfoF("Technology: %s (version %s)\n", 
	     DBTechName, 
	     DBTechVersion?DBTechVersion:"?");
}

