/*
 * patchlevel.h --
 *
 *     	Current patch level, for keeping track of updates.
 *
 * rcsid="$Header"
 */

#define _PATCHLEVEL 

#define PATCHLEVEL 2

/* The following procedure returns a string describing the patches installed. */
/* When making patches, please also patch patchlevel.c! */

extern char *PatchNames();

