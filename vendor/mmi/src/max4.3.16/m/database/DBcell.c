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
 * DBcell.c --
 *
 * Cell management routines.
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
#include <string.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "hash.h"
#include "utils.h"
#include "geometry.h"
#include "tile.h"
#include "signals.h"
#include "undo.h"
#include "memory.h"
#include "layout.h"
#include "message.h"
#include "main.h"
#include "ihash.h"
#include "select.h"

/* Cell Def "symbol table" */
#define	NCELLDEFBUCKETS	64	/* Initial number of buckets for CellDef tbl */
HashTable dbCellDefTable;
CellDef *DBCellDefs = NULL;


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellName2File --
 *
 * Map cell name to corresponding file name:
 *
 *   / -> {FS}
 *   \ -> {BS}
 *   { -> {FC}
 *   } -> {BC}
 *
 * Also initial . mapped to {DT}  
 *
 * ----------------------------------------------------------------------------
 */
void
DBCellName2File(char *name,
		                /* input name */
		char *buf)
                                /* build result here */
{
  ASSERT(name&&buf,"DBCellName2File");

  /* map initial '.' */
  if(*name == '.')
  {
    *buf++ = '{';
    *buf++ = 'D';
    *buf++ = 'T';
    *buf++ = '}';

    name++;
  }

  for(; *name!='\0'; name++)
  {
    if(*name == '/')
    {
      *buf++ = '{';
      *buf++ = 'F';
      *buf++ = 'S';
      *buf++ = '}';
    }
    else if(*name == '\\')
    {
      *buf++ = '{';
      *buf++ = 'B';
      *buf++ = 'S';
      *buf++ = '}';
    }
    else if(*name == '{')
    {
      *buf++ = '{';
      *buf++ = 'B';
      *buf++ = 'C';
      *buf++ = '}';
    }
    else if(*name == '}')
    {
      *buf++ = '{';
      *buf++ = 'E';
      *buf++ = 'C';
      *buf++ = '}';
    }
    else
    {
      *buf++=*name;
    }
  }
  *buf = '\0';
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellNameCheck --
 *
 * Check that prospective name is legal.
 *
 * Results:
 *	TRUE on success, FALSE on failure.
 *
 * Side effects:
 *	Generates error message if name is bad.
 *
 * ----------------------------------------------------------------------------
 */

bool
DBCellNameCheck(char *name)
{
  if(!name)
  {
    MsgErrorF("Cell name must be nonempty!\n");
    return FALSE;
  }

  /*
   * NOTE: allowing "/" in def name, must map slashes to obtain
   *       file names!
   *
   * NOTE: allowing array subscript chars in names: "[,]",
   *       only problematic if foo is an array and instance foo[3] also
   *       exists!
   */
  return StrCheckChars(name, " ","Cell name");
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellFileOpen --
 *
 * Open a file associated with a cell. 
 * (need not be a .max file, e.g could be '.ntl').
 * 
 * Searches cell path for file.
 * Maps special characters in cellName.
 *
 * Results:  file pointer on success, NULL on failure.
 *
 * ----------------------------------------------------------------------------
 */

FILE *
DBCellFileOpen(CellDef *def, 
	                    /* Cell whose file we are to open,
			     * may be NULL, if file non-null.
			     */
			       
	       char *file, 
               		/* If non-NULL, open 'file' 
			 * If no extension, suffix added.
			 * If not absolute, cell path searched.
			 *
			 * If NULL file associated with def is used.
			 * 
			 */

	       char *suffix,
	                 /* defaul suffix, including '.' 
			  * (e.g. ".max" or ".ntl") 
			  * (may be NULL when used with file above) 
			  */
 	       
	       char *mode, 
               		/* Either "r" or "w", the mode in which the .ext
			 * file is to be opened.
			 */

	       char **prealfile)
                     	/* If this is non-NULL, it gets set to point to
			 * a string holding the name of the file opened.
			 */
{
  char name[BUFSIZ];

  /*
  fprintf(stderr,"DEBUG DBCellFileOpen top, cd_name=%s cd_file='%s' file='%s' mode=%s\n",
	  def->cd_name,
	  def->cd_file,
	  file,
	  mode);
  */
	  
  /* compute name of file to open */
  if (file)
  {
    /* explicit name given */
    strcpy(name,file);
  }
  else if (def->cd_file)
  {
    /* file already associated with def */
    if(suffix && strcmp(suffix,DBSuffix) == 0)
    {
      /* actual .max file, use cd_file without modification */
      strcpy(name, def->cd_file); 
      suffix = NULL;
    }
    else
    {
      /* not .max file, replace suffix */
      char base[BUFSIZ]; 
      char ext[BUFSIZ]; /* tossed */ 
      
      PaSplitName(def->cd_file,name,base,ext);
      strcat(name,base);  /* append base name to dir part */

      /* append suffix explicitly to avoid confusion if filename
       * contains "."
       */
      if(suffix) strcat(name,suffix); 
      suffix = NULL;
    }
  }
  else 
  {
    /* derive file name from cell name */
    DBCellName2File(def->cd_name, name);

    /* append suffix explicitly to avoid confusion if filename
     * contains "."
     */
    if(suffix) strcat(name,suffix); 
    suffix = NULL;
  }

  return PaOpen(name, 
		mode, 
		suffix,
		MnPathCell, 
		prealfile);
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbCellInit --
 *
 * Initialize cell def symbol table.
 *
 * Called by DBInit() at Max startup time.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Sets up the symbol tables for CellDefs and CellUses.
 *
 * ----------------------------------------------------------------------------
 */

void
dbCellInit(void)
{
    HashInit(&dbCellDefTable, NCELLDEFBUCKETS, 0);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellLookDef --
 *
 * Find the definition of the cell with the given name.
 *
 * Results:
 *	Returns a pointer to the CellDef with the given name if it
 *	exists.  Otherwise, returns (CellDef *) NULL.
 *
 * Side effects:
 *	None.
 * ----------------------------------------------------------------------------
 */

CellDef *
DBCellLookDef(char *cellName)
{
    HashEntry *entry;

    entry = HashFind(&dbCellDefTable, cellName);
    return ((CellDef *) HashGetValue(entry));
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbCellDefAlloc --
 *
 * Helper func for DBCellNewDef()
 *
 * Creates a new cell definition structure.  The new def is not added
 * to any symbol tables.
 *
 * Results:
 *	Returns a pointer to the newly created CellDef.  The CellDef
 *	is completely initialized, showing no uses and having all
 *	tile planes initialized via TiNewPlane() to contain a single
 *	space tile.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

static CellDef *
dbCellDefAlloc(void)
{
    CellDef *cellDef;
    int pNum;

    MALLOC(CellDef *, cellDef, sizeof (CellDef));
    cellDef->cd_refCnt = 0;
    cellDef->cd_flags = 0;
    cellDef->cd_version = DBVStampInvalid;
    cellDef->cd_vMAIN = DBVStampInvalid;
    cellDef->cd_vDRC = DBVStampInvalid;
    DBBoxCellInitial(cellDef);
    cellDef->cd_name = (char *) NULL;
    cellDef->cd_file = (char *) NULL;
    cellDef->cd_showName = NULL;
    cellDef->cd_showInst = NULL;
    cellDef->cd_pars = (CellPar *) NULL;
    cellDef->cd_parHash = IHashInit(4, /* initial buckets */
				       OFFSET(CellPar,cp_def),  /* key */
				       OFFSET(CellPar,cp_hashLink), 
				       IHashWordKeyHash, /* keys are pointers */
				       IHashWordKeyEq);	
    cellDef->cd_kids = (CellKid *) NULL;
    cellDef->cd_kidHash = IHashInit(4, /* initial buckets */
				       OFFSET(CellKid,ck_def),  /* key */
				       OFFSET(CellKid,ck_hashLink), 
				       IHashWordKeyHash, /* keys are pointers */
				       IHashWordKeyEq);	

    cellDef->cd_polygons = (Polygon *) NULL;
    cellDef->cd_wirePaths = (WirePath *) NULL;
    cellDef->cd_cellPlane = BPNew();
    cellDef->cd_idHash = 
      IHashInit(4, /* initial buckets */
		OFFSET(CellUse,cu_id),      /* key */
		OFFSET(CellUse,cu_hashLink), 
		IHashStringPKeyHash, 
		IHashStringPKeyEq);	
    cellDef->cd_labels = (Label *) NULL;
    cellDef->cd_lastLabel = (Label *) NULL;
    cellDef->cd_labelTextHash = 
      IHashInit(4, /* initial buckets */
		OFFSET(Label,lab_text),      /* key */
		OFFSET(Label,lab_hashLink), 
		IHashStringKeyHash, 
		IHashStringKeyEq);	
    cellDef->cd_labelHash = 
      IHashInit(4, /* initial buckets */
		0,      /* key offset (whole label is key) */
		OFFSET(Label,lab_hashLoc), 
		dbLabelKeyHash,
		dbLabelKeyEq);

    cellDef->cd_flyLines = (FlyLine *) NULL;
    cellDef->cd_groupTable = IHashInit(4, /* initial buckets */
				       OFFSET(Group,g_name),  /* key */
				       OFFSET(Group,g_hashLink), 
				       IHashStringPKeyHash, /* string keys */
				       IHashStringPKeyEq);	
    cellDef->cd_activeGroup = 0;

    /* cd_props */
    DBPropInitDef(cellDef);

    cellDef->cd_coarseDB = (ClientData) NULL;
    cellDef->cd_pixelValue = (ClientData) NULL;
    cellDef->cd_imageCache = (ClientData) NULL;

    cellDef->cd_drcNumChanges = 0;

    cellDef->cd_client = (ClientData) 0;

    /* netlist fields */
    cellDef->cd_nodes = (ClientData) NULL;
    cellDef->cd_portList = (ClientData) NULL;
    cellDef->cd_portCount = 0;
    cellDef->cd_nodeCount = 0;

    for (pNum = PL_PAINTBASE; pNum < DBNumPlanes; pNum++)
    {
      cellDef->cd_planes[pNum] = DBPlaneNew((ClientData) TT_SPACE);

    }
    return (cellDef);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellNewDef --
 *
 * Create a new cell definition with the given name.  There must not
 * be any cells already known with the same name.
 *
 * Results:
 *	Returns a pointer to the newly created CellDef.  The CellDef
 *	is completely initialized, showing no uses and having all
 *	tile planes initialized via TiNewPlane() to contain a single
 *	space tile.  The filename associated with the cell is set to
 *	the name supplied, but no attempt is made to open it or create
 *	it.
 *
 *	If the cellName supplied is NULL, the cell is entered into
 *	the symbol table with a name of UNNAMED.
 *
 *	Returns NULL if a cell by the given name already exists.
 *
 * Side effects:
 *	The name of the CellDef is entered into the symbol table
 *	of known cells.
 *
 * ----------------------------------------------------------------------------
 */

CellDef *
DBCellNewDef(char *cellName, 
                   		/* Name by which the cell is known */
	     char *cellFileName)
                       		/* Name of disk file in which the cell 
				 * should be kept when written out.
				 */
{
    CellDef *cellDef;
    HashEntry *entry;

    if (cellName == (char *) NULL)
	cellName = UNNAMED;

    entry = HashFind(&dbCellDefTable, cellName);
    if (HashGetValue(entry) != (ClientData) NULL)
	return ((CellDef *) NULL);

    cellDef = dbCellDefAlloc();

    /* link into cell list */
    cellDef->cd_next = DBCellDefs;
    DBCellDefs = cellDef;

    HashSetValue(entry, (ClientData) cellDef);
    cellDef->cd_name = StrDup((char **) NULL, cellName);
    if (cellFileName == (char *) NULL)
    {
	cellDef->cd_file = cellFileName;
    }
    else
    {
	cellDef->cd_file = StrDup((char **) NULL, cellFileName);
    }

    /* generated? */
    if(*cellName == '#') 
      cellDef->cd_flags |= (CD_GENERATED|
			    CD_DRC_WITH_PARENT);
    /*			    CD_NO_UNDO); */

    return (cellDef);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellRenameDef --
 *
 * Renames the indicated CellDef.
 *
 * Results:
 *	TRUE if successful, FALSE if the new name was not unique.
 *
 * Side effects:
 *	The name of the CellDef is entered into the symbol table
 *	of known cells.  The CD_MODIFIED bit is set in the flags
 *	of each of the parents of the CellDef to force them to
 *	be written out using the new name.
 *
 * ----------------------------------------------------------------------------
 */

bool
DBCellRenameDef(CellDef *cellDef, 
     		                /* Pointer to CellDef being renamed */
		char *newName)
                                /* Pointer to new name */
{
    HashEntry *oldEntry, *newEntry;

    oldEntry = HashFind(&dbCellDefTable, cellDef->cd_name);
    ASSERT(HashGetValue(oldEntry) == (ClientData) cellDef, "DBCellRenameDef");

    newEntry = HashFind(&dbCellDefTable, newName);
    if (HashGetValue(newEntry) != (ClientData) NULL)
	return (FALSE);

    HashSetValue(oldEntry, (ClientData) NULL);
    HashSetValue(newEntry, (ClientData) cellDef);
    (void) StrDup(&cellDef->cd_name, newName);

    /* mark all cells referencing this one as modified */
    {
      CellPar *par;

      for (par = cellDef->cd_pars; par; par = par->cp_next)
      {
	par->cp_def->cd_flags |= CD_MODIFIED;
      }
    }

    return TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellDeleteDef --
 *
 * Removes the CellDef from the symbol table of known CellDefs and
 * frees the storage allocated to the CellDef.  
 * 
 * If the CellDef is referenced (has uses), its contents are cleared
 * and it is marked unavailable, but the def is not actually removed. 
 *
 * NOTE:  If the cell is removed, the undo stack is flushed, since it
 *        could contain references to the def (unless cell is CD_NO_UNDO)
 *
 * Results:
 *	TRUE if successful, FALSE if there were any outstanding
 *	CellUses found.
 *
 * ----------------------------------------------------------------------------
 */
bool
DBCellDeleteDef(CellDef *cellDef)
                     		/* Pointer to CellDef to be deleted */
{
    HashEntry *entry;
    int pNum;
    register Label *lab;

    /*
     * We don't want to get interrupted half way!
     */
    if(SigInterruptPending) return FALSE;
    SigDisableInterrupts();

    /* 
     *  First clear contents. 
     *  (also does undo flush and select clear (when necessary) 
     */
    DBCellClearContentsUp(cellDef);

    /* free strings */
    if (cellDef->cd_file != (char *) NULL)
    {
	FREE(cellDef->cd_file);
	cellDef->cd_file = NULL;
    }
    if (cellDef->cd_showName != (char *) NULL)
    {
	FREE(cellDef->cd_showName);
	cellDef->cd_showName = NULL;
    }
    if (cellDef->cd_showInst != (char *) NULL)
    {
	FREE(cellDef->cd_showInst);
	cellDef->cd_showInst = NULL;
    }
    
    /* clear available and modified = not yet read in */
    cellDef->cd_flags &= ~CD_MODIFIED;
    DBCellClearAvail(cellDef);

    /* if any references remain, don't delete it! */
    if (cellDef->cd_refCnt != 0) return FALSE;

    /* remove from def symbol table */
    entry = HashFind(&dbCellDefTable, cellDef->cd_name);
    ASSERT(HashGetValue(entry) == (ClientData) cellDef, "DBCellDeleteDef");
    HashSetValue(entry, (ClientData) NULL);

    /* remove from celldef list */
    {
      CellDef **defpp = &DBCellDefs;
      while(*defpp != cellDef) defpp = &((*defpp)->cd_next);
      *defpp = cellDef->cd_next;
    }

    /* free name string */
    if (cellDef->cd_name != (char *) NULL)
    {
	FREE(cellDef->cd_name);
	cellDef->cd_name = NULL;
    }

    /* kid and par hash tables */
    IHashFree(cellDef->cd_parHash);
    IHashFree(cellDef->cd_kidHash);
    
    /* instance plane */
    BPFree(cellDef->cd_cellPlane);

    /* paint planes */
    for (pNum = PL_PAINTBASE; pNum < DBNumPlanes; pNum++)
    {
	TiFreePlane(cellDef->cd_planes[pNum]);
    }

    /* instance hash table */
    IHashFree(cellDef->cd_idHash);

    /* label hash tables */
    IHashFree(cellDef->cd_labelTextHash);
    IHashFree(cellDef->cd_labelHash);

    /* group hash table */
    IHashFree(cellDef->cd_groupTable);

    /* properties */
    DBPropFreeDef(cellDef);

    /* the cell def itself */
    FREE((char *) cellDef);

    SigEnableInterrupts();

    return TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBNewYank --
 *
 * Create a new yank buffer with name 'yname'.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Fills in *pydef with a newly created CellDef by that name, and
 *	*pyuse with a newly created CellUse pointing to the new def.
 *	The CellDef pointed to by *pydef has the CD_INTERNAL flag
 *	set, and is marked as being available.
 *
 * ----------------------------------------------------------------------------
 */

void DBNewYank(char *yname, 
                	/* Name of yank buffer */
	  CellUse **pyuse, 
                    	/* Pointer to new cell use is stored in *pyuse */
	  CellDef **pydef)
                    	/* Similarly for def */
{
    *pydef = DBCellLookDef(yname);
    if (*pydef == (CellDef *) NULL)
    {
	*pydef = DBCellNewDef(yname,(char *) NULL);
	ASSERT(*pydef != (CellDef *) NULL, "DBNewYank");
	DBCellSetAvail(*pydef);
	(*pydef)->cd_flags |= CD_INTERNAL;
    }
    *pyuse = DBCellUseNewTop(*pydef, (char *) NULL);
    DBCellUseSetTrans(*pyuse, &GeoIdentityTransform);
    (*pyuse)->cu_expandMask = (~0);	/* This is always expanded. */
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbDeleteInstances --
 *
 * Remove all instances from the cell.
 * (Frees up all related storage) 
 *
 * Results:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

static void
dbDeleteInstances(CellDef *def)
{
  CellKid *kid;

  while(kid=def->cd_kids)
  {
    CellUse *use = kid->ck_uses;
    if(use) DBInstanceDelete(use);
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellClearContents --
 *
 * Empties out all the contents of the indicated CellDef, making it
 * as though the def had been newly allocated.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The paint and subcells stored in the CellDef are all deleted.
 *	Sets the bounding box to the degenerate (0,0)::(1,1) box.
 *
 * ----------------------------------------------------------------------------
 */

void
DBCellClearContents(CellDef *cellDef)
                     		/* Pointer to CellDef to be deleted */
{


    /* Make sure we don't get interrupted half way */
    SigDisableInterrupts();
    UndoDisable();
    DBUpdate(cellDef);

    /* delete instances */
    dbDeleteInstances(cellDef);

    /* Reduce clutter by reinitializing the id hash table */
    IHashFree(cellDef->cd_idHash);
    cellDef->cd_idHash = 
      IHashInit(4, /* initial buckets */
		OFFSET(CellUse,cu_id),      /* key */
		OFFSET(CellUse,cu_hashLink), 
		IHashStringPKeyHash, 
		IHashStringPKeyEq);	

    /* clear paint planes */
    {
      int pNum;

      for (pNum = PL_PAINTBASE; pNum < DBNumPlanes; pNum++)
      {
	Plane *plane = cellDef->cd_planes[pNum];
	Tile *tile = TR(plane->pl_left);

	if (TiGetBody(tile) != TT_SPACE
	    || LB(tile) != plane->pl_bottom
	    || TR(tile) != plane->pl_right
	    || RT(tile) != plane->pl_top)
	{
	  DBPlaneClearPaint(plane);
	}
      }
    }

    /* delete polygons */
    DBPolyClear(cellDef);

    /* delete wirepaths */
    DBWPathsClear(cellDef);

    /* delete labels */
    DBLabelsClear(cellDef);

    /* delete flylines */
    if(cellDef->cd_flyLines)
    {
      dbFlyLineDelete(cellDef, NULL, NULL);
    }

    /* DEBUG TODO delete groups */
    /* dbGroupsFree(cellDef); */

    /* clear properties */
    DBPropClearDef(cellDef);

    /* reinitial bounding box */
    DBBoxCellInitial(cellDef);

    UndoEnable();

    SigEnableInterrupts();
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellClearContentsUp --
 *
 * Wrapper around DBCellClearContents that does all appropriate updates,
 * e.g. display and drc.
 *
 * Empties out all tile planes of the indicated CellDef, making it
 * as though the def had been newly allocated.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The paint and subcells stored in the CellDef are all deleted.
 *	Sets the bounding box to the degenerate (0,0)::(1,1) box.
 *
 * ----------------------------------------------------------------------------
 */
void
DBCellClearContentsUp(CellDef *def) 
{
    CellUse *parentUse;

    /* clear selection, if necessary */
    if(DBIsAncestor(SelectRootDef, def)) SelectClear();

    /* invalidate undo info, if necessary */
    if(!(def->cd_flags&CD_NO_UNDO)) UndoFlush();

    /* clear def */
    DBCellClearContents(def);

    /* propagate database change info */
    DBChangedArea(def, NULL, &DBAllButSpaceBits, 0);

}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellSetAvail --
 * DBCellClearAvail --
 *
 * Mark a cell as available/unavailable.
 * These exist mainly to create a cell for the first time, and to
 * allow a cell to be 'flushed' via the "flush" command.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies flags in cellDef.
 *
 * ----------------------------------------------------------------------------
 */

void
DBCellSetAvail(CellDef *cellDef)
                     		/* Pointer to definition of cell we wish to
				 * mark as available.
				 */
{
    cellDef->cd_flags &= ~CD_NOT_FOUND;
    cellDef->cd_flags |= CD_AVAILABLE;
}

void
DBCellClearAvail(CellDef *cellDef)
                     		/* Pointer to definition of cell we wish to
				 * mark as available.
				 */
{
    cellDef->cd_flags &= ~(CD_NOT_FOUND|CD_AVAILABLE);
}



/*
 * ----------------------------------------------------------------------------
 *
 * DBCellSrDefs --
 *
 * Search for all cell definitions matching a given pattern.
 * For each cell definition whose flag word contains any of the
 * bits in pattern, the supplied procedure is invoked.
 *
 * The procedure should be of the following form:
 *	int
 *	func(cellDef, cdata)
 *	    CellDef *cellDef;
 *	    ClientData cdata;
 *	{
 *	}
 * Func should normally return 0.  If it returns 1 then the
 * search is aborted.
 *
 * Results:
 *	Returns 1 if the search completed normally, 1 if it aborted.
 *
 * Side effects:
 *	Whatever the user-supplied procedure does.
 *
 * ----------------------------------------------------------------------------
 */

int
DBCellSrDefs(int pattern, int (*func) (/* ??? */), ClientData cdata)
                	/* Used for selecting cell definitions.  If any
			 * of the bits in the pattern are in a def->cd_flags,
			 * or if pattern is 0, the user-supplied function
			 * is invoked.  
			 */
                  	/* Function to be applied to each matching CellDef */
                     	/* Client data also passed to function */
{
    CellDef *cellDef;

    for(cellDef=DBCellDefs; cellDef; cellDef=cellDef->cd_next)
    {
	if ((pattern != 0) && !(cellDef->cd_flags & pattern))
	    continue;
	if ((*func)(cellDef, cdata)) return 1;
    }
    return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellClearDefClients -- 
 *
 * Clear all cd_client fields back to 0.
 *
 * If check set (and PARANOID), coredump if any cd_client not already cleared.
 *
 * ----------------------------------------------------------------------------
 */
void
DBCellClearDefClients(bool check)
{
  CellDef *cellDef;

  if(check)
  {
#ifdef PARANOID
    for(cellDef=DBCellDefs; cellDef; cellDef=cellDef->cd_next)
    {
      ASSERT(cellDef->cd_client == 0, "DBCellClearDefClients");
    }
#endif PARANOID    
  }
  else
  {
    for(cellDef=DBCellDefs; cellDef; cellDef=cellDef->cd_next)
    {
      cellDef->cd_client = (ClientData) 0;
    }
  }
}
