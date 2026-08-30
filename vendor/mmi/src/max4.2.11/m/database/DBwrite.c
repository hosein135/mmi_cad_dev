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
 * DBwrite.c --
 *
 * Writing of cells in native (max) format.
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

#ifndef lint
static char rcsid[] = "$Header: DBio.c,v 6.0 90/08/28 18:09:53 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/file.h>
#include <sys/stat.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "tile.h"
#include "utils.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "main.h"
#include "message.h"
#include "drc.h"
#include "undo.h"
#include "malloc.h"
#include "signals.h"
#include "cif.h"

extern int errno;
extern char *Path;

/* incremented on writes to keep track of file size */
int DBFileOffset;

#define FPRINTF(f,s)\
{\
     if (fprintf(f,s) == EOF) goto ioerror;\
     DBFileOffset += strlen(s);\
}

/* return 1 on error */
#define FPRINTR(f,s)\
{\
     if (fprintf(f,s) == EOF) return 1;\
     DBFileOffset += strlen(s);\
}

/* return 0 on error */
#define FPRINTR0(f,s)\
{\
     if (fprintf(f,s) == EOF) return 0;\
     DBFileOffset += strlen(s);\
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbWriteRects --
 *
 * Outputs the manhattan data (rects) for the cell.
 *
 * ----------------------------------------------------------------------------
 */

/* write out one rect */
static __inline__ int
dbWriteRect1(TileType type, 
	     Group *group, 
	     Tile *tile, 
	     struct writeArg *arg)
{
    char pstring[BUFSIZ];

    if (type != arg->wa_type) return 0;

    if (!arg->wa_found)
    {
	sprintf(pstring, "layer %s\n", DBTypeLongName(type));
	FPRINTR(arg->wa_file,pstring);
	arg->wa_found = TRUE;
    }

    if(group && group->g_class)
    {
      sprintf(pstring, "%d %d %d %d %s\n",
	      LEFT(tile), BOTTOM(tile), RIGHT(tile), TOP(tile),
	      group->g_name);
    }
    else
    {
      sprintf(pstring, "%d %d %d %d\n",
	      LEFT(tile), BOTTOM(tile), RIGHT(tile), TOP(tile));
    }

    FPRINTR(arg->wa_file,pstring);
    return 0;
}

/* filter func, outputs single tile 
 * (one rect per group)
 */
static int
dbWriteRectFunc(Tile *tile, ClientData cdarg)
{
    struct writeArg *arg = (struct writeArg *) cdarg;
    TileType type = DBgetTileType(tile);

    if (!DBisSetTileFlag(tile,TF_MULTIGROUP))
    {
      /* single group */

      if(dbWriteRect1(type, 
		      (Group *) TiGetGroups(tile), 
		      tile,
		      arg)) return 1;

    }
    else
    {
      /* multiple groups */

      GroupList *gl;
    
      for(gl=(GroupList *) TiGetGroups(tile); gl; gl=gl->gl_next)
      {
	if(dbWriteRect1(gl->gl_type,
		       gl->gl_group,
		       tile,
		       arg)) return 1;
      }
    }

    return 0;
}

static bool dbWriteRects(CellDef *cellDef, FILE *f)
{
    struct writeArg arg;
    int pNum;
    TileType type;
    TileTypeBitMask typeMask;

    arg.wa_file = f;
    for (type = TT_PAINTBASE; type < DBNumUserLayers; type++)
    {
	if ((pNum = DBPlane(type)) < 0)
	    continue;
	arg.wa_found = FALSE;
	arg.wa_type = type;
	TTMaskSetOnlyType(&typeMask, type);
	if (DBPlaneEnumAreaPaint((Tile *) NULL, 
			  cellDef->cd_planes[pNum],
			  &TiPlaneRect, 
			  &typeMask, 
			  dbWriteRectFunc, 
			  (ClientData) &arg))
	    goto ioerror;
    }
    return TRUE;

ioerror: 
    return FALSE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbWriteLabels --
 *
 * Output labels in cell.
 *
 * Results:
 *	Normally returns TRUE; returns FALSE on I/O error.
 *
 * Side effects:
 *	Writes to the disk file.
 *
 * ----------------------------------------------------------------------------
 */

static bool
dbWriteLabels(CellDef *cellDef, FILE *f)
{
    register Label *lab;

    char lstring[256];

    for (lab = cellDef->cd_labels; lab; lab = lab->lab_next)
    {
       sprintf(lstring, "lab %s %d %d %d %d %d %d %s\n",
	       DBTypeLongName(lab->lab_type),
	       lab->lab_rect.r_xbot, lab->lab_rect.r_ybot,
	       lab->lab_rect.r_xtop, lab->lab_rect.r_ytop,
	       lab->lab_pos, lab->lab_kind, lab->lab_text);
        FPRINTF(f,lstring);
    }
    return TRUE;

ioerror:
    return FALSE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbWriteVersions --
 *
 * Write def versions section.
 *
 * Results:
 *	Returns TRUE normally, or FALSE on error or EOF.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */
static bool
dbWriteVersions(CellDef *cellDef, /* def to be written */
		FILE *f)          /* open file to write to */
{
  char headerstring[BUFSIZ];

  sprintf(headerstring, "vMAIN %d %d\n",
	  cellDef->cd_vMAIN.vs_time, cellDef->cd_vMAIN.vs_rev);
  FPRINTR0(f,headerstring);

  sprintf(headerstring, "vDRC %d %d\n",
	  cellDef->cd_vDRC.vs_time, cellDef->cd_vDRC.vs_rev);
  FPRINTR0(f,headerstring);

  sprintf(headerstring, "vBBOX %d %d\n",
	  cellDef->cd_vBBOX.vs_time, cellDef->cd_vBBOX.vs_rev);
  FPRINTR0(f,headerstring);

  return TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbCellWriteFileDef --
 *
 * Called by DBCellWriteFile() to write contents of cell to open file.
 *
 * (called once for each gcell referenced by a cell, then for the cell
 *  itself)
 * Mark the cell as having been written out.  Before calling this
 * procedure, the caller should make sure that timestamps have been
 * updated where appropriate.
 *
 * Results:
 *	TRUE if the cell could be written successfully, FALSE otherwise.
 *
 * Side effects:
 *	Writes to open file. 

 *	In the event of an error while writing out the cell,
 *	the external integer errno is set to the UNIX error
 *	encountered, and the above bits are not cleared in
 *	cellDef->cd_flags.
 *
 * ----------------------------------------------------------------------------
 */

static bool
dbCellWriteFileDef(CellDef *cellDef,  /* def to be written */
		   FILE *f,           /* open file to write to */
		   char *depName,     /* name of dependent cell
				       * (null for main def)
				       */
		   char *showName,    /* show name to save with cell */
		   char *showInst)    /* instance 'id' to show with cell */
{

    if(depName)
    {
      char *p;

      /* dependent def */
      char buf[BUFSIZ];

      /* DEF name */
      sprintf(buf,"\n\nDEF %s ", 
	      depName);
      for(p=buf;*p!='\0';p++); 

      /* DEF name "show_name" */
      p = StrQuote(showName,p);
      *p++ = ' ';

      /* DEF name "show_name" "show_inst" */
      p = StrQuote(showInst,p);

      /* append newline and terminate string */
      *p++='\n';
      *p='\0';

      /* write out DEF line */ 
      FPRINTF(f,buf);
    }
    else
    {
      /* main def */
      FPRINTF(f,"\n\nDEF\n");

      FPRINTF(f,"\nSECTION VERSIONS {\n");
      if(!dbWriteVersions(cellDef,f)) goto ioerror;
      FPRINTF(f,"} SECTION VERSIONS\n");
    }

    if(DBPropsQ(cellDef))
    {
      FPRINTF(f,"\nSECTION PROPERTIES {\n");
      if(!dbPropertiesWrite(cellDef,f)) goto ioerror;
      FPRINTF(f,"} SECTION PROPERTIES\n");
    }

    FPRINTF(f,"\nSECTION RECTS {\n");
    if(!dbWriteRects(cellDef,f)) goto ioerror;
    FPRINTF(f,"} SECTION RECTS\n");

    if(cellDef->cd_polygons)
    {
      FPRINTF(f,"\nSECTION POLYGONS {\n");
      if(!dbPolyWrite(cellDef,f)) goto ioerror;
      FPRINTF(f,"} SECTION POLYGONS\n");
    }

    if(cellDef->cd_wirePaths)
    {
      FPRINTF(f,"\nSECTION WIREPATHS {\n");
      if(!dbWPathWrite(cellDef,f)) goto ioerror;
      FPRINTF(f,"} SECTION WIREPATHS\n");
    }

    if(cellDef->cd_labels)
    {
      FPRINTF(f,"\nSECTION LABELS {\n");
      if(!dbWriteLabels(cellDef,f)) goto ioerror;
      FPRINTF(f,"} SECTION LABELS\n");
    }

    if(DBGroupsQ(cellDef))
    {
      FPRINTF(f,"\nSECTION GROUPS {\n");
      if(!dbGroupsWrite(cellDef,f)) goto ioerror;
      FPRINTF(f,"} SECTION GROUPS\n");
    }

    if(cellDef->cd_kids)
    {
      FPRINTF(f,"\nSECTION INSTANCES {\n");
      if(!dbInstancesWrite(cellDef,f)) goto ioerror;
      FPRINTF(f,"} SECTION INSTANCES\n");
    }

    if(cellDef->cd_flyLines && dbFlylinesSave)
    {
      FPRINTF(f,"\nSECTION FLYLINES {\n");
      if(!dbFlyLinesWrite(cellDef,f)) goto ioerror;
      FPRINTF(f,"} SECTION FLYLINES\n");
    }

    return (TRUE);

ioerror:
    MsgErrorF("Warning: I/O error in writing file\n");
    return (FALSE);
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbCellWriteFileGCells1 --
 *
 * Does the real work for dbCellWriteFileGCells
 *
 * defs are written before references (post order).
 *
 * list kept on cd_client field to avoid multiple writes.
 *
 * ----------------------------------------------------------------------------
 */
/* list of gcells already written (linked by cd_client) */
static CellDef *dbGCellsWritten = NULL; 

static void
dbCellWriteFileGCells1(CellDef *mainDef, FILE *f)
{
  CellKid *kid;

  for(kid=mainDef->cd_kids;kid;kid=kid->ck_next) 
  {
    CellDef *def = kid->ck_def;
    char *name = def->cd_name;
    char nameBuf[BUFSIZ];
    char *showName = def->cd_showName;
    char showNameBuf[BUFSIZ];
    bool hasVersion; 

    /* GCells only */
    if(!(def->cd_flags&CD_GENERATED)) continue;

    /* avoid redundant writes */
    if(def->cd_client) continue;
    def->cd_client = dbGCellsWritten;
    dbGCellsWritten = def;

    /* recursively write sub-gcells */
    dbCellWriteFileGCells1(def,f);

    /* check if gcell name already has version prop */
    {
      char buf[BUFSIZ];
      hasVersion = (StrPropGet(name, "-_version", buf)!=NULL);
    }

    /* if no version prop, add one to name */
    if(!hasVersion) 
    {
      char buf[BUFSIZ];
      sprintf(nameBuf,"%s!-_version!%d",
	      name,
	      def->cd_vMAIN.vs_time);
      name = nameBuf;
	  
      /* also append "(S)" (for saved) to showName. 
       * except for cells with -_edit property (e.g GROUP cells)
       */
      if(StrPropGet(name, "-_edit", buf)==NULL)
      {
	char *s = def->cd_showName;
	char *d = showNameBuf;
	
	while(*s && *s!='\0') *d++ = *s++;
	strcpy(d," (S)");
	showName = showNameBuf;
      }
    }

    /* write out gcell */
    dbCellWriteFileDef(def,
		       f,
		       name,      /* name signals dependent def */
		       showName,  /* show name to store for cell */
		       def->cd_showInst ? def->cd_showInst : "");
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbCellWriteFileGCells --
 *
 * Called by dbCellWriteFile() to write out all GCells referenced by a def.
 *
 * defs are written before references (post order).
 *
 * ----------------------------------------------------------------------------
 */

static void
dbCellWriteFileGCells(CellDef *mainDef, FILE *f)
{
  ASSERT(dbGCellsWritten==NULL,"dbCellWriteFileGCells");

  /* check that all cd_client fields are clear */
  DBCellClearDefClients(TRUE);

  /* write the gcells */
  dbCellWriteFileGCells1(mainDef, f);

  /* clean up */
  while(dbGCellsWritten)
  {
    CellDef *this = dbGCellsWritten;
    dbGCellsWritten = (CellDef *) this->cd_client;
    this->cd_client = 0;
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbCellWriteFile --
 *
 * Called by DBCellWrite() below, once the actual file to write has been opened.
 *
 * Write out a cell to the specified file.
 * Mark the cell as having been written out.  Before calling this
 * procedure, the caller should make sure that timestamps have been
 * updated where appropriate.
 *
 * Results:
 *	TRUE if the cell could be written successfully, FALSE otherwise.
 *
 * Side effects:
 *	Writes a file to disk.
 * 	Does NOT close the file 'f', but does fflush(f) before
 * 	returning.
 *
 *	If successful, clears the CDMODIFIED
 *	 bit in cellDef->cd_flags.
 *
 *	In the event of an error while writing out the cell,
 *	the external integer errno is set to the UNIX error
 *	encountered, and the above bits are not cleared in
 *	cellDef->cd_flags.
 *
 * ----------------------------------------------------------------------------
 */

static bool
dbCellWriteFile(CellDef *cellDef, 
			/* Pointer to definition of cell to be written out */
		FILE *f)
                	/* The FILE to write to */
{
    bool result;

    if (f == NULL) return FALSE;

    /* propagate all changes in subcells */
    DBUpdate(cellDef);

    /* If interrupts are left enabled, a partial file could get written.
     * This is not good.
     */
    SigDisableInterrupts();

    DBFileOffset = 0;

    /* write out warning comment */
    FPRINTF(f, "# WARNING:\n");
    FPRINTF(f, "#\n");
    FPRINTF(f, "# The .max file format continues to evolve.\n");
    FPRINTF(f, "#\n");
    FPRINTF(f, "# Micro Magic recommends you do not write or parse .max files directly.\n");
    FPRINTF(f, "# Instead use the Max API (e.g. 'db_search' and 'db_paint' commands).\n");
    FPRINTF(f, "# The API is also easier to interface to.  See 'Text Commands' under\n"); 
    FPRINTF(f, "# the Max 'Help' menu for full documentation on the API.\n\n");

    /* write out file headers */
    {
        char headerstring[BUFSIZ];

        sprintf(headerstring, "max %d\n", 
		3); /* max file format version */
	FPRINTF(f,headerstring);

	sprintf(headerstring, "tech %s\n",
		DBTechName);
	FPRINTF(f,headerstring);

	sprintf(headerstring, "resolution %g\n",
		CIFDBRes);
	FPRINTF(f,headerstring);
    }

    /* write out all GCells referenced by main def (directly and indirectly) */
    dbCellWriteFileGCells(cellDef,f);

    /* write out contents of main celldef */
    result = dbCellWriteFileDef(cellDef,
				f,
				NULL,  /* NULL signals main def */
				NULL,  /* show name not stored for main def */
				NULL); /* show inst not stored for main def */


    /* clean up */
    if (fflush(f) == EOF || ferror(f)) goto ioerror;
    cellDef->cd_flags &= ~CDMODIFIED;
    SigEnableInterrupts();

    return result;

ioerror:
    MsgErrorF("Warning: I/O error in writing File.\n");
    SigEnableInterrupts();
    return (FALSE);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellWrite --
 *
 * Write a cell to its associated disk file.
 * Mark the cell as having been written out. 
 *
 * Results:
 *	TRUE if the cell could be written successfully, FALSE otherwise.
 *
 * Side effects:
 *	Writes a file to disk.
 *	If successful, clears the CDMODIFIED
 *	in cellDef->cd_flags.
 *
 *	In the event of an error while writing out the cell,
 *	the external integer errno is set to the UNIX error
 *	encountered, and the above bits are not cleared in
 *	cellDef->cd_flags.
 *
 * BUG:  Currently on some errors CDMODIFIED is set.   2/17/95 mha
 * BUG:  (cont.) other flags are left cleared.         2/17/95 mha 
 *
 * ----------------------------------------------------------------------------
 */

bool
DBCellWrite(CellDef *cellDef, 
                     	/* Pointer to definition of cell to be written out */
	    char *fileName, 
                   	/* If non null, File to write (sans suffix), if null
			 * the name associated with the CellDef is used
			 */
	    char *suffix
	               /*  If non NULL, file suffix to use.
			*/
	    )
{
#define NAME_SIZE	1000
    char *realname, *expandname;
    char *cp1, *cp2;
    char expandbuf[NAME_SIZE];
    FILE *f;
    bool result;

    result = FALSE;


    /* Don't allow read only cell buffers to be written to 
     * the file attached to the cell.
     */
    if(cellDef->cd_flags&CDREADONLY && 
       fileName == NULL &&               /* ok to write to alternate file */
       suffix == NULL)                   /* ok to write with alternate suffix */
    {
      MsgErrorF("Write aborted.  Cell '%s' is read-only!\n",
		cellDef->cd_name);
      return FALSE;
    }

    /*
     * Figure out the name of the file we will eventually write.
     */
    if (fileName)
    {
	 MALLOC(char *, realname, strlen(fileName)+strlen(DBSuffix)+1);
	 (void) sprintf(realname, "%s%s", fileName, DBSuffix);
    }
    else if (cellDef->cd_file)
    {
 	 realname = StrDup((char **) NULL, cellDef->cd_file);	
    }
    else if (cellDef->cd_name)
    {
	MALLOC(char *, realname, strlen(cellDef->cd_name)+strlen(DBSuffix)+1);
	(void) sprintf(realname, "%s%s", cellDef->cd_name, DBSuffix);
    }
    else return (FALSE);

    /* substitute suffix, if any */
    if(suffix)
    {
      char *new;
      char *ext = 0;

      /* "strip" any existing extension */
      if (ext= strrchr(realname,'.' )) *ext = '\0';	

      MALLOC(char *, new, strlen(realname)+strlen(suffix)+1);
      (void) sprintf(new, "%s%s", realname, suffix);
      FREE(realname);
      realname = new;
    }

    /*
     * Expand the filename, removing the leading ~, if any.
     */
    expandname = expandbuf;
    cp1 = realname;
    cp2 = expandname;
    if (PaConvertTilde(&cp1, &cp2, NAME_SIZE) == -1)
	expandname = realname;

    /* Don't allow a write if the file isn't writable! */
    if (access(expandname, F_OK) == 0 && 
	access(expandname, W_OK) < 0)
    {
      perror(expandname);
      goto cleanup;
    }

    /* Critical: disable interrupts while we do our work */
    SigDisableInterrupts();

    /* open the file */
    f = fopen(realname, "w");
    if(!f)
    {
      perror(expandname);

      result = FALSE;
      goto cleanup;
    }

    /* write the file */
    result = dbCellWriteFile(cellDef, f);
    (void) fclose(f);

    if (!result)
    {
      /* write failed, remove partial file */
      (void) unlink(realname);
      goto cleanup;
    }

    /* Everything worked. */
    (void) StrDup(&cellDef->cd_file, expandname);

cleanup:
    SigEnableInterrupts();
    FREE(realname);
    return result;
}



/*
 * ----------------------------------------------------------------------------
 *
 * DBPanicSave --
 *
 * Save all modified cells to disk, in files "cellname.max_panic_save".
 * This is intended as an emergency measure for cases when max
 * has to die (eg, upon receiving a SIGTERM signal).  
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes cells to disk.
 *	Does NOT clear the modified bits.
 *
 * ----------------------------------------------------------------------------
 */
char *DBPanicSuffix = ".max_panic_save";

int
dbPanicFunc(CellDef *def)
                 	/* Pointer to CellDef to be saved */
{
    if (def->cd_flags & (CDINTERNAL|CD_GENERATED)) return 0;
    (void) DBCellWrite(def, NULL, DBPanicSuffix);
    return 0;
}

void
DBPanicSave(void)
{
    (void) DBCellSrDefs(CDMODIFIED, dbPanicFunc, (ClientData) NULL);
}

