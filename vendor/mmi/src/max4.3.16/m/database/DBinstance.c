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
 * DBinstance.c --
 *
 * Cell instance creation, deletion, naming etc.
 *
 * To create an instance:
 *   1. creating and setting up a celluse (using funcs in DBcellUse.c),
 *   2. linking it into a def with DBInstanceAdd() (in DBinstance.c) 
 *
 * To delete an instance:
 *   call DBInstanceDelete()
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

#include <sys/types.h>
#include <stdio.h>
#include <stdio.h>
#include <string.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "memory.h"
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

/* if set, allow identical coincident instances, 
 * tcl linked to DB_INSTANCE_DUP_OK
 */
bool dbInstanceDupOK = TRUE;

/* hash tables used for unique use id generation below */
HashTable dbUniqueDefTable;
HashTable dbUniqueNameTable;


/*
 * ----------------------------------------------------------------------------
 *
 * DBInstanceNameCheck --
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
DBInstanceNameCheck(char *name)
{
  if(!name)
  {
    MsgErrorF("Instance id must be nonempty!\n");
    return FALSE;
  }

  /*
   *
   * NOTE: allowing array subscript chars in names: "[,]",
   *       only problematic if foo is an array and instance foo[3] also
   *       exists!
   */
  return StrCheckChars(name, " ","Instance id");
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBInstanceFindByName --
 *
 * Find the instance with the given id in the supplied parent CellDef.
 *
 * Results:
 *	Returns a pointer to the found CellUse, or NULL if it was not
 *	found.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

CellUse *
DBInstanceFindByName(char *id, CellDef *parentDef)
{
  return IHashLookUp(parentDef->cd_idHash, &id);
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbUseIdSet --
 *
 * Update the use-id hash table in parentDef to reflect the fact
 * that 'use' now has instance-id use->cu_id.
 *
 * Notfiy flyline (sub)module of instance change.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */

static void dbUseIdSet(CellUse *use, CellDef *parentDef)
{
    IHashAdd(parentDef->cd_idHash, use);
    DBFlyLineNotifyInstanceChanged(use,parentDef);
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbUseIdDelete --
 *
 * update use-id hash table in parentDef to reflect the fact
 * that 'use' no longer has instance-id use->cu_id.
 *
 * Notfiy flyline (sub)module of instance change.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */

static void dbUseIdDelete(CellUse *use, CellDef *parentDef)
{
    /* remove use from instance name table */
    IHashDelete(parentDef->cd_idHash, use);

    /* update flylines */
    DBFlyLineNotifyInstanceChanged(use, parentDef);
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbInstanceFindDup --
 *
 * 	This local procedure checks whether a particular cell is already
 *	present at a particular point in a particular parent.  It is
 *	used to avoid placing duplicate copies of a cell on top of
 *	each other.
 *
 *      NOTE: duplicate means same cu_bbox, but we don't update bboxes here,
 *            so check is only sure if bboxes are up-to-date. 
 *
 * Results:
 *	The return value is NULL if there is not already a CellUse in parent
 *	that is identical to use (same bbox and def).  If there is a duplicate
 *	already in parent, then the return value is a pointer to its CellUse.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

static CellUse *
dbInstanceFindDup(CellUse *use, 
                 		/* Use that is about to be placed in parent.
				 * Is it a duplicate?
				 */
		  CellDef *parent)
                    		/* Parent definiton:  does it already have
				 * something identical to use?
				 */
{
  BPEnum bpe;
  CellUse *dupUse;

  BPEnumInit(&bpe,
	     parent->cd_cellPlane,
	     &use->cu_bbox,
	     BPE_EQUAL,
	     "dbInstanceFindDup");
  while(dupUse = BPEnumNext(&bpe))
  {
    if(dupUse->cu_def == use->cu_def) break;
  }
  BPEnumTerm(&bpe);

  return dupUse;

}


/*
 * ----------------------------------------------------------------------------
 *
 * DBIsChild --
 *
 * Test to see if cu1 is a child of cu2.
 *
 * Results:
 *	TRUE if cu1 is a child of cu2, FALSE otherwise.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

bool
DBIsChild(register CellUse *cu1, register CellUse *cu2)
{
    return (cu1->cu_kid && (cu1->cu_kid->ck_parent == cu2->cu_def));
}

/*
 *-----------------------------------------------------------------------------
 *
 * DBIsAncestor --
 *
 * Determine if cellDef1 is an ancestor of cellDef2.
 *
 * Results:
 *	TRUE if cellDef1 is an ancestor of cellDef2, FALSE if not.
 *
 * Side effects:
 *	None.
 *
 *-----------------------------------------------------------------------------
 */

bool
DBIsAncestor(CellDef *cellDef1, 
                      		/* Potential ancestor */
	     CellDef *cellDef2)
                      		/* Potential descendant (search starts here) */
{
    CellPar *pars;

    if (cellDef1 == cellDef2) return TRUE;

    for (pars = cellDef2->cd_pars; pars!=NULL; pars=pars->cp_next)
    {
      if(DBIsAncestor(cellDef1, pars->cp_def)) return TRUE;
    }
    return FALSE;
}



/*
 * ----------------------------------------------------------------------------
 *
 * dbInstancePlace --
 *
 * Add a CellUse to the cell bplane of a CellDef.
 *
 * Called from DBInstanceAdd() and DBUpdate() (when bbox changes)
 *
 * Assumes prior check that the new CellUse is not an exact duplicate
 *     of one already in place.
 *
 *        (use DBInstanceAdd() instead)
 *
 * ----------------------------------------------------------------------------
 */

void
dbInstancePlace(CellUse *use) 
                        	/* celluse to add to subcell bplane */

{
  CellDef *def;

  /* mark the passage of time */
  MnTic(10);

  /* use created ? */
  ASSERT(use != (CellUse *) NULL, "dbInstancePlace");

  def = DBCellUseParent(use); 

  /* use linked into target cell ? */
  ASSERT(def, "dbInstancePlace");

  /*
    fprintf(stderr,"DEBUG:  dbInstancePlace, '%s' in def '%s'\n",
	    use->cu_id, def->cd_name);
  */

  /* Be careful not to permit interrupts during this, or the
   * database could be left in a trashed state.
   */
  SigDisableInterrupts();

  BPAdd(def->cd_cellPlane, use);
  DBUndoCellUse(use, UNDO_CELL_PLACE);

  SigEnableInterrupts();
}


/*
 * ----------------------------------------------------------------------------
 * dbInstanceUnplace --
 *
 * Called by DBInstanceDelete() and DBUpdate() (when bbox changes) 
 *
 * Remove a CellUse from the cell plane of a CellDef.
 *
 * ----------------------------------------------------------------------------
 */

void
dbInstanceUnplace(CellUse *use) 
{
    ASSERT(use != (CellUse *) NULL, "dbInstanceUnplace");
    
    /* It's important that this code run with interrupts disabled,
     * or else we could leave the subcell tile plane in a weird
     * state.
     */
    SigDisableInterrupts();

    BPDelete(DBCellUseParent(use)->cd_cellPlane, use);
    DBUndoCellUse(use, UNDO_CELL_DELETE);

    SigEnableInterrupts();
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBInstanceAdd --
 *
 * Make a celluse an instance.
 *
 * flags:
 *  DBIA_INFOMSG_ON_RENAME - print message when changing instance id
 *                           (to make it unique).
 *
 *  DBIA_ERROR_ON_RENAME   - generate error, if instance id not unique.
 *
 *  DBIA_INFOMSG_ON_DUP    - print message when not adding instance, since
 *                           exact duplicate already present.
 *
 *  DBIA_ERROR_ON_DUP      - generate error if exact dupicate instance already
 *                           present.
 *
 *  DBIA_DUP_OK         - allow duplicate instances exactly on top of
 *                           each other (useful when dragging stuff around,
 *                           to avoid things being deleted when they are
 *                           dragged over their cousins. 
 *
 *  DBIA_ERROR_ON_CIRCULAR
 *                          
 *
 * cellkid and cellpar sturctures are also updated.
 *
 * undo info generated by dbInstancePlace() (called from here). 
 *
 * Results:
 *	TRUE on success, FALSE on failure
 *
 * Deletes use on failure.
 *
 * ----------------------------------------------------------------------------
 */
bool
DBInstanceAdd(CellUse *use, 
	      CellDef *parentDef,
	      int flags)
{
    char *origId = use->cu_id;
    CellKid *kid = IHashLookUp(parentDef->cd_kidHash, &(use->cu_def)); 
    CellDef *def = use->cu_def;

    /*
    fprintf(stderr,"DEBUG DBInstanceAdd():  adding instance '%s' to '%s'\n",
	    use->cu_id, parentDef->cd_name);
    */

    /* check that instance name is unique */
    if (origId && DBInstanceFindByName(origId, parentDef))
    {
      if(flags & DBIA_ERROR_ON_RENAME)
      {
	MsgErrorF("Can not link '%s' into '%s':"
		  "  instance id '%s' already in use.\n",
		  origId, parentDef->cd_name, origId);
	goto fail;
      }
      else
      {
	/* null out use id, to force assignement of new unique
	 * name below.
	 */
	use->cu_id = NULL;
      }
    }

    /* check for circular instance references */
    if(!kid && DBIsAncestor(use->cu_def, parentDef))
    {

       if(flags & DBIA_ERROR_ON_CIRCULAR)
       {
	 MsgErrorF("Can not make %s an instance of %s.  "
		   "%s is an ancestor of %s!\n",
		   def->cd_name,
		   parentDef->cd_name,
		   def->cd_name,
		   parentDef->cd_name);
       }
       else
       {
	 MsgInfoF("Can not make %s an instance of %s.  "
		 "%s is an ancestor of %s!\n",
		 def->cd_name,
		 parentDef->cd_name,
		 def->cd_name,
		 parentDef->cd_name);
       }
       goto fail;
    }

    /* check for duplicate instances 
     * (i.e. don't place identical instances on top of each other)
     */
    if(!dbInstanceDupOK && 
       !(flags & DBIA_DUP_OK) && 
       dbInstanceFindDup(use, parentDef))
    {
      if(flags & DBIA_ERROR_ON_DUP)
      {
	MsgErrorF("Can't place a cell on an exact copy of itself.\n");
	return FALSE;
      }

      if(flags & DBIA_INFOMSG_ON_DUP)
      {
	MsgInfoF("Attempt to place a cell on an exact copy of itself ignored.\n");
      }
      goto fail;
    }
    
    /* create kid and corresponding parent strucs, if necessary */
    if(!kid)
    {
      CellPar *par;

      /* kid */
      MALLOC_TAG(CellKid *, kid, sizeof(CellKid),"CellKid");
      kid->ck_def = def;
      kid->ck_parent = parentDef;
      kid->ck_uses = NULL;
      kid->ck_idLastSuffix = -1;
      kid->ck_version = DBVStampInvalid;
      kid->ck_userBBox = GeoNullRect;
      kid->ck_next = parentDef->cd_kids;

      parentDef->cd_kids = kid;
      IHashAdd(parentDef->cd_kidHash, (void *) kid);

      /* parent */
      MALLOC_TAG(CellPar *, par, sizeof(CellPar),"CellPar");
      par->cp_def = parentDef;
      par->cp_next = def->cd_pars;
      def->cd_pars = par;
      IHashAdd(def->cd_parHash, (void *) par);
    }

    /* link use to kid */
    use->cu_kid = kid;
    use->cu_prev = NULL;
    use->cu_next = kid->ck_uses;
    if(kid->ck_uses) kid->ck_uses->cu_prev = use;
    kid->ck_uses = use;
    
    /* assign unique id, (if necessary) */	
    if(!use->cu_id)
    {
      char useId[1000];

      /* find unused id */
      do
      {
	sprintf(useId, "%s_%d", 
		def->cd_name, 
		++kid->ck_idLastSuffix);
      }
      while (DBInstanceFindByName(useId, parentDef));

      /* print rename msg */
      if(origId && (flags & DBIA_INFOMSG_ON_RENAME))
      {
        MsgInfoF("cell '%s' already has instance '%s', "
		 "renaming new instance to '%s'.\n",
		 parentDef->cd_name, origId, useId);
      }

      /* set new id and free old one */
      use->cu_id = StrDup(0,useId);
      if(origId) FREE_TAG(origId,"char *origId");
    }

    /* add instance id to hash table */
    dbUseIdSet(use, parentDef);

    /* place instance (in subcell bplane) */
    dbInstancePlace(use);

    return TRUE;

fail:
    DBCellUseDelete(use);	
    return FALSE; 	
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBInstanceDelete --
 *
 * rm celluse from def.
 *
 * cellkid and cellpar sturctures are also updated.
 *
 * undo info generated by ... (called from here). 
 *
 *
 * ----------------------------------------------------------------------------
 */
void
DBInstanceDelete(CellUse *use)
{
  CellKid *kid = use->cu_kid;
  CellDef *parentDef = DBCellUseParent(use);
  HashEntry *he;

  /* remove from bplane */
  dbInstanceUnplace(use);

  /* remove use from instance name table */
  dbUseIdDelete(use,parentDef);

  /* unlink use from kid structure */
  {
    CellUse *next = use->cu_next;
    CellUse *prev = use->cu_prev;

    if(prev)
    {
      prev->cu_next = next;
    }
    else
    {
      kid->ck_uses = next;
    }

    if(next) next->cu_prev = prev;
  }
    
  /* if this was last use of kid def, in parentDef 
   * remove "kid" from parentDef and "parent" from kid def
   */
  if(!kid->ck_uses)
  {
    /* unlink kid */
    {
      CellKid **pp;
      for(pp=&(parentDef->cd_kids); (*pp)!=kid; pp=&((*pp)->ck_next));
      (*pp) = kid->ck_next;
    }

    /*** DEBUG
	 fprintf(stderr,
	 "DEBUG DBInstanceDelete, deleteing %s from %s->cd_kidHash\n",
	 use->cu_def->cd_name, 
	 parentDef->cd_name);
    ***/

    IHashDelete(parentDef->cd_kidHash, (void *) kid);
    FREE_TAG((void *) kid, "CellKid");

    /* unlink parent */
    {
      CellPar **pp;
      CellDef *def = use->cu_def;
      CellPar *par = IHashLookUp(def->cd_parHash, &parentDef);
      ASSERT(par,"DBInstanceDelete");

      for(pp=&(def->cd_pars); (*pp)!=par; pp=&((*pp)->cp_next));
      (*pp) = par->cp_next;
	
      IHashDelete(def->cd_parHash, (void *) par);
      FREE_TAG((void *) par,"CellPar");
    }
  }

  /* delete the use */
  DBCellUseDelete(use);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBInstanceRename --
 *
 * Change the instance id of the supplied CellUse.
 * If the instance id is non-NULL, and the new id is the same
 * as the old one, we do nothing.
 *
 * Results:
 *	Returns TRUE if successful, FALSE if the new name was not
 *	unique within the parent def.
 *
 * Side effects:
 *	May modify the cu_id of the supplied CellUse.
 * ----------------------------------------------------------------------------
 */

bool
DBInstanceRename(CellUse *cellUse, char *newName)
{
    if (cellUse->cu_id && strcmp(cellUse->cu_id, newName) == 0)
	return (TRUE);

    if (DBInstanceFindByName(newName, DBCellUseParent(cellUse)))
	return (FALSE);

    /* Old id (may be NULL) */
    if (cellUse->cu_id) dbUseIdDelete(cellUse, DBCellUseParent(cellUse));
    DBUndoCellUse(cellUse, UNDO_CELL_CLRID);

    /* New id */
    (void) StrDup(&cellUse->cu_id, newName);
    dbUseIdSet(cellUse, DBCellUseParent(cellUse));
    DBUndoCellUse(cellUse, UNDO_CELL_SETID);
    return (TRUE);
}


/* 
 * ==============================================================================
 *
 * INSTANCE I/O
 *
 * ==============================================================================
 */
#define FPRINTR(f,s)\
{\
     if (fprintf(f,s) == EOF) return 1;\
     DBFileOffset += strlen(s);\
}

/*
 * ----------------------------------------------------------------------------
 *
 * dbInstancesWrite --
 *
 * Output body of INSTANCES section of .max file
 *
 * Results:
 *	Normally returns TRUE; returns FALSE on I/O error.
 *
 * Side effects:
 *	Writes to the disk file.
 *
 * ----------------------------------------------------------------------------
 */

/* helper func for dbInstancesWrite()
 * writes list of instances refering to same child def 
 */
static int
dbInstancesWriteKidUses(CellKid *kid, 
		              /* kid to output */
		    FILE *f) 
                              /* File to output to */
{
    char     cstring[1024];
    CellUse *use;
    char *defName = kid->ck_def->cd_name;

    /* list header */
    FPRINTR(f,"uses {");

    /* list */
    for(use=kid->ck_uses; use; use=use->cu_next)
    {
      char *s1 = defName;
      char *s2 = use->cu_id;
      Transform *t = &use->cu_transform;

      /* find common prefix of def name and id */
      while(*s1!='\0' && *s1==*s2)
      {
	s1++; 
	s2++;
      }

      if(*s1=='\0' && *s2!='\0')
      {
	/* id is defname + unique suffix so just write out suffix */
	sprintf(cstring,"\n\t%s %d %d %d %d %d %d",
		s2, t->t_a, t->t_b, t->t_c, t->t_d, t->t_e, t->t_f);
      }
      else
      {
	/* id doesn't match def name, so write out full name */
	sprintf(cstring,"\n\t/%s %d %d %d %d %d %d",
		use->cu_id, t->t_a, t->t_b, t->t_c, t->t_d, t->t_e, t->t_f);
      }
      FPRINTR(f,cstring);

      /* array ? */ 
      if(DBIsArray(use))
      {
	sprintf(cstring, " array %d %d %d %d %d %d",
		use->cu_xlo, use->cu_xhi, use->cu_xsep,
		use->cu_ylo, use->cu_yhi, use->cu_ysep);
	FPRINTR(f,cstring);
      }
    } 

    /* close list */
    FPRINTR(f,"\n}\n");

    return 0;
}

/* helper func for dbInstancesWrite()
 * writes out all uses for one kid (child def) 
 */
static int
dbInstancesWriteKid(CellKid *kid, 
		              /* kid to output */
		    FILE *f) 
                              /* File to output to */
{
    char     cstring[1024];
    CellDef *def = kid->ck_def;

    if(def->cd_flags&CD_GENERATED)
    {
      /* compact def/version info for gcells 
       * (since groups can lead to large # of 'kids')
       */
      sprintf(cstring, "gcell %d %s\n", 
	      def->cd_vMAIN.vs_time,
	      def->cd_name);

      FPRINTR(f,cstring);
    }
    else
    {
      /* def */
      sprintf(cstring, "def %s\n", def->cd_name);
      FPRINTR(f,cstring);

      /* version stamps */
      sprintf(cstring, "vMAIN %d %d\n",
	      def->cd_vMAIN.vs_time, def->cd_vMAIN.vs_rev);
      FPRINTR(f,cstring);
      sprintf(cstring, "vDRC %d %d\n",
	      def->cd_vDRC.vs_time, def->cd_vDRC.vs_rev);
      FPRINTR(f,cstring);
      /* vBBOX no longer kept separatly */
      sprintf(cstring, "vBBOX %d %d\n",
	      def->cd_vMAIN.vs_time,def->cd_vMAIN.vs_rev);
      FPRINTR(f,cstring);
    }

    /* bbox */
    ASSERT(DBBBoxValid(def),"dbWriteInstancesKid");
    sprintf(cstring, "bbox %d %d %d %d\n",
	    def->cd_bbox.r_xbot, 
	    def->cd_bbox.r_ybot,
	    def->cd_bbox.r_xtop, 
	    def->cd_bbox.r_ytop);
    FPRINTR(f,cstring);

    /* user bbox */
    ASSERT(DBBBoxValid(def),"dbWriteInstancesKid");
    sprintf(cstring, "bbox_user %d %d %d %d\n",
	    def->cd_userBBox.r_xbot, 
	    def->cd_userBBox.r_ybot,
	    def->cd_userBBox.r_xtop, 
	    def->cd_userBBox.r_ytop);
    FPRINTR(f,cstring);

    /* instances */
    return dbInstancesWriteKidUses(kid,f);
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbInstancesWrite --
 *
 * Output body of INSTANCES section of .max file 
 *
 * Results:
 *	Normally returns TRUE; returns FALSE on I/O error.
 *
 * Side effects:
 *	Writes to the disk file.
 *
 * ----------------------------------------------------------------------------
 */

bool
dbInstancesWrite(CellDef *def, FILE *f)
{
  CellKid *kid;

  for(kid=def->cd_kids; kid; kid=kid->ck_next)
  {
    if(dbInstancesWriteKid(kid,f)) return FALSE;
  }  

  return TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbInstancesRead3 --
 *
 * FORMAT VERSION 3 and up.
 *
 * Starting with the line "SECTION INSTANCES {", read INSTANCES section of 
 * max file.  
 *
 * Results:
 *	Returns TRUE normally, or FALSE on error or EOF.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */
bool
dbInstancesRead3(CellDef *cellDef, 
                     	/* Cell whose instances are being read */
		char *line, 
               		/* Line buffer */
		int len, 
            		/* Size of line buffer */
		FILE *f)
            		/* Input file */
{
  char defName[1024];
  VStamp vMAIN, vDRC, vBBOX;
  Rect bbox;
  Rect userBBox;
  CellDef *subCellDef;
  CellUse *subCellUse = NULL;

 nextdef:

  if(dbReadNextLine(line, len, f) == NULL) return FALSE;
  if(line[0] == '}') goto end;

  if(line[0]=='g')
  {
    int version;

    /* gcell line */
    if(sscanf(line,"gcell %d %1023s\n", &version, &defName) != 2) goto error;
    
    vMAIN.vs_time = version;
    vMAIN.vs_rev = 1000;
    vDRC = vMAIN;
    vBBOX = vMAIN;
  }
  else
  {
    /* def line */
    if(sscanf(line,"def %1023s\n", &defName) != 1) goto error;

    /* vMAIN line */
    if(dbReadNextLine(line, len, f) == NULL) return FALSE;
    if (sscanf(line, "vMAIN %d %d", &vMAIN.vs_time, &vMAIN.vs_rev) != 2)
    {
      MsgErrorF("Malformed \"vMAIN\" line: %s", line);
      return FALSE;
    }

    /* vDRC line */
    if(dbReadNextLine(line, len, f) == NULL) return FALSE;
    if (sscanf(line, "vDRC %d %d", &vDRC.vs_time, &vDRC.vs_rev) != 2)
    {
      MsgErrorF("Malformed \"vDRC\" line: %s", line);
      return FALSE;
    }

    /* vBBOX line */
    if (dbReadNextLine(line, len, f) == NULL) return (FALSE);
    if (sscanf(line, "vBBOX %d %d", &vBBOX.vs_time, &vBBOX.vs_rev) != 2)
    {
      MsgErrorF("Malformed \"vBBOX\" line: %s", line);
      return FALSE;
    }
  }

  /* bbox line */
  if (dbReadNextLine(line, len, f) == NULL) return (FALSE);
  if (sscanf(line, "bbox %d %d %d %d",
	     &bbox.r_xbot, &bbox.r_ybot, &bbox.r_xtop, &bbox.r_ytop) != 4)
  {
    MsgErrorF("Malformed instance bbox line: %s", line);
    return FALSE;
  }

  /* check for degenerate bbox */
  if (GEO_RECTNULL(&bbox))
  {
    MsgErrorF("Subcell has degenerate bounding box: %d %d %d %d\n",
	      bbox.r_xbot, bbox.r_ybot, bbox.r_xtop, bbox.r_ytop);
    return FALSE;
  }

  /* scale bbox to internal DB coordinates */
  GeoScaleRect(&bbox, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);  

  /* bbox_user line */
  if(DBReadMaxFormat<=3)
  {
    /* no bbox_user line */
    userBBox = bbox;
  }
  else    
  {
    if (dbReadNextLine(line, len, f) == NULL) return (FALSE);
    if (sscanf(line, "bbox_user %d %d %d %d",
	       &userBBox.r_xbot, 
	       &userBBox.r_ybot, 
	       &userBBox.r_xtop, 
	       &userBBox.r_ytop) != 4)
    {
      MsgErrorF("Malformed instance user bbox line: %s", line);
      return FALSE;
    }

    /* check for degenerate user bbox */
    if (GEO_RECTNULL(&userBBox))
    {
      MsgErrorF("Subcell has degenerate user bounding box: %d %d %d %d\n",
		userBBox.r_xbot, 
		userBBox.r_ybot, 
		userBBox.r_xtop, 
		userBBox.r_ytop);
      return FALSE;
    }

    /* scale user bbox to internal DB coordinates */
    GeoScaleRect(&userBBox, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);  
  }

  /* Find the subcell Def
   *
   *If the definition for this use has not been read in,
   * make a skeleton def that's not marked CD_AVAILABLE. 
   */
  subCellDef = DBCellLookDef(defName);
  if (subCellDef == (CellDef *) NULL)
  {
    subCellDef = DBCellNewDef(defName, (char *) NULL);
    subCellDef->cd_bbox = bbox;
    subCellDef->cd_userBBox = userBBox; 
    subCellDef->cd_version = vMAIN;
    subCellDef->cd_vMAIN = vMAIN;
    subCellDef->cd_vDRC = vDRC;
  }

  /* uses line */
  if (dbReadNextLine(line, len, f) == NULL) return FALSE;
  if (strcmp(line,"uses {\n") != 0) goto error;

  /* process list of uses */
  if (dbReadNextLine(line, len, f) == NULL) return FALSE;
  while(line[0]!='}')
  {
    char idRead[1024];
    char idBuf[2048];
    char *id;
    Transform t;
    int absa, absb, absd, abse;
    int xlo = 0;
    int ylo = 0;
    int xhi = 0;
    int yhi = 0;
    int xsep = 0;
    int ysep = 0;
    int n;

    n = sscanf(line,"\t%1023s %d %d %d %d %d %d array %d %d %d %d %d %d",
	       idRead,
	       &t.t_a, &t.t_b, &t.t_c, &t.t_d, &t.t_e, &t.t_f,
	       &xlo, &xhi, &xsep, &ylo, &yhi, &ysep);
    if(n!= 7 && n!= 13) goto error;

    /*
     * Sanity check for transform.
     * Either a == e == 0 and both abs(b) == abs(d) == 1,
     *     or b == d == 0 and both abs(a) == abs(e) == 1.
     */
    if (t.t_a == 0)
    {
	absb = t.t_b > 0 ? t.t_b : -t.t_b;
	absd = t.t_d > 0 ? t.t_d : -t.t_d;
	if (t.t_e != 0 || absb != 1 || absd != 1)
	{
	  MsgErrorF("Malformed or illegal use transform: %s", line);
	  return FALSE;
	}
    }
    else
    {
	absa = t.t_a > 0 ? t.t_a : -t.t_a;
	abse = t.t_e > 0 ? t.t_e : -t.t_e;
	if (t.t_b != 0 || t.t_d != 0 || absa != 1 || abse != 1)
	{
	  MsgErrorF("Malformed or illegal use transform: %s", line);
	  return FALSE;
	}
    }    
    /* scale transform and array seps to internal DB coords */
    if(dbRdScaleFile2DB != 1.0)
    {
      GeoScaleInt(&t.t_c, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);
      GeoScaleInt(&t.t_f, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);
      GeoScaleInt(&xsep, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);
      GeoScaleInt(&ysep, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);
    }

    /* construct id */
    if(*idRead == '/')
    {
      id = idRead+1;
    }
    else
    {
      char *p,*q;

      /* create id by appending idRead to the defName */
      id = idBuf;
      p=idBuf; 
      q=defName;
      while(*q!='\0') *(p++) = *(q++);
      q=idRead;
      while(*q!='\0') *(p++) = *(q++);
      *p='\0';
    }
    
    /* create celluse */
    if(xlo!=xhi || ylo!=yhi)
    {
      subCellUse = DBCellUseNewArray(subCellDef, 
				     id[0] ? id : (char *) NULL);
      DBMakeArray(subCellUse, 
		  &GeoIdentityTransform,
		  xlo, 
		  ylo, 
		  xhi, 
		  yhi, 
		  xsep, 
		  ysep);
    }
    else
    {
      subCellUse = DBCellUseNew(subCellDef, 
				id[0] ? id : (char *) NULL);
    }

    DBCellUseSetTrans(subCellUse, &t);
	   
    /* create instance */
    DBInstanceAdd(subCellUse, cellDef, DBIA_INFOMSG_ON_RENAME);

    /* read next line */
    if (dbReadNextLine(line, len, f) == NULL) return FALSE;
  } /* while uses */

  /* set kid versions to .max file values */ 
  if(subCellUse)
  {
    CellKid *kid = subCellUse->cu_kid;
    ASSERT(kid,"DBInstancesRead3");

    kid->ck_version = vMAIN;
    kid->ck_vDRC = vDRC;
    kid->ck_userBBox = userBBox;
  }

  goto nextdef;

 end:
  if (strcmp(line,"} SECTION INSTANCES\n") == 0) return TRUE;

 error: 
  MsgWarnF("Parse error in INSTANCES section of %s: `%s'\n",
	   cellDef->cd_name, line);
  return FALSE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbInstancesRead1 --
 *
 * FORMAT VERSION 1 or 2.
 *
 * Starting with the line "SECTION INSTANCES {", read INSTANCES section of 
 * max file.  
 *
 * Results:
 *	Returns TRUE normally, or FALSE on error or EOF.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */
bool
dbInstancesRead1(CellDef *cellDef, 
                     	/* Cell whose instances are being read */
		char *line, 
               		/* Line buffer */
		int len, 
            		/* Size of line buffer */
		FILE *f)
            		/* Input file */
{
  char defName[1024];
  VStamp vMAIN, vDRC, vBBOX;
  Rect bbox;
  CellDef *subCellDef;
  CellUse *subCellUse = NULL;

 nextdef:

  if(dbReadNextLine(line, len, f) == NULL) return FALSE;
  if(line[0] == '}') goto end;

  /* def line */
  if(sscanf(line,"def %1023s\n", &defName) != 1) goto error;

  /* vMAIN line */
  if(dbReadNextLine(line, len, f) == NULL) return FALSE;
  if (sscanf(line, "vMAIN %d %d", &vMAIN.vs_time, &vMAIN.vs_rev) != 2)
  {
    MsgErrorF("Malformed \"vMAIN\" line: %s", line);
    return FALSE;
  }

  /* vDRC line */
  if(dbReadNextLine(line, len, f) == NULL) return FALSE;
  if (sscanf(line, "vDRC %d %d", &vDRC.vs_time, &vDRC.vs_rev) != 2)
  {
    MsgErrorF("Malformed \"vDRC\" line: %s", line);
    return FALSE;
  }

  /* vBBOX line */
  if (dbReadNextLine(line, len, f) == NULL) return (FALSE);
  if (sscanf(line, "vBBOX %d %d", &vBBOX.vs_time, &vBBOX.vs_rev) != 2)
  {
    MsgErrorF("Malformed \"vBBOX\" line: %s", line);
    return FALSE;
  }

  /* bbox line */
  if (dbReadNextLine(line, len, f) == NULL) return (FALSE);
  if (sscanf(line, "bbox %d %d %d %d",
	     &bbox.r_xbot, &bbox.r_ybot, &bbox.r_xtop, &bbox.r_ytop) != 4)
  {
    MsgErrorF("Malformed use bbox line: %s", line);
    return FALSE;
  }

  /* check for degenerate bbox */
  if (GEO_RECTNULL(&bbox))
  {
    MsgErrorF("Subcell has degenerate bounding box: %d %d %d %d\n",
	      bbox.r_xbot, bbox.r_ybot, bbox.r_xtop, bbox.r_ytop);
    return FALSE;
  }

  /* scale bbox to internal DB coordinates */
  GeoScaleRect(&bbox, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);  

  /* Find the subcell Def
   *
   *If the definition for this use has not been read in,
   * make a skeleton def that's not marked CD_AVAILABLE. 
   */
  subCellDef = DBCellLookDef(defName);
  if (subCellDef == (CellDef *) NULL)
  {
    subCellDef = DBCellNewDef(defName, (char *) NULL);

    subCellDef->cd_bbox = bbox;
    /* only guess at user bbox we have in this case 
     * is the actual bbox 
     */
    subCellDef->cd_userBBox = bbox; 
    subCellDef->cd_version = vMAIN;
    subCellDef->cd_vMAIN = vMAIN;
    subCellDef->cd_vDRC = vDRC;
  }

  /* uses line */
  if (dbReadNextLine(line, len, f) == NULL) return FALSE;
  if (strcmp(line,"uses {\n") != 0) goto error;

  /* process list of uses */
  if (dbReadNextLine(line, len, f) == NULL) return FALSE;
  while(line[0]!='}')
  {
    char idRead[1024];
    char idBuf[2048];
    char *id;
    Transform t;
    int absa, absb, absd, abse;
    int xlo = 0;
    int ylo = 0;
    int xhi = 0;
    int yhi = 0;
    int xsep = 0;
    int ysep = 0;
    int n;

    n = sscanf(line,"\t%1023s %d %d %d %d %d %d array %d %d %d %d %d %d",
	       idRead,
	       &t.t_a, &t.t_b, &t.t_c, &t.t_d, &t.t_e, &t.t_f,
	       &xlo, &xhi, &xsep, &ylo, &yhi, &ysep);
    if(n!= 7 && n!= 13) goto error;

    /*
     * Sanity check for transform.
     * Either a == e == 0 and both abs(b) == abs(d) == 1,
     *     or b == d == 0 and both abs(a) == abs(e) == 1.
     */
    if (t.t_a == 0)
    {
	absb = t.t_b > 0 ? t.t_b : -t.t_b;
	absd = t.t_d > 0 ? t.t_d : -t.t_d;
	if (t.t_e != 0 || absb != 1 || absd != 1)
	{
	  MsgErrorF("Malformed or illegal use transform: %s", line);
	  return FALSE;
	}
    }
    else
    {
	absa = t.t_a > 0 ? t.t_a : -t.t_a;
	abse = t.t_e > 0 ? t.t_e : -t.t_e;
	if (t.t_b != 0 || t.t_d != 0 || absa != 1 || abse != 1)
	{
	  MsgErrorF("Malformed or illegal use transform: %s", line);
	  return FALSE;
	}
    }    
    /* scale transform and array seps to internal DB coords */
    if(dbRdScaleFile2DB != 1.0)
    {
      GeoScaleInt(&t.t_c, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);
      GeoScaleInt(&t.t_f, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);
      GeoScaleInt(&xsep, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);
      GeoScaleInt(&ysep, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);
    }

    /* construct id */
    if(*idRead == '/')
    {
      id = idRead+1;
    }
    else
    {
      char *p,*q;

      /* create id by appending idRead to the defName */
      id = idBuf;
      p=idBuf; 
      q=defName;
      while(*q!='\0') *(p++) = *(q++);
      q=idRead;
      while(*q!='\0') *(p++) = *(q++);
      *p='\0';
    }
    
    /* create celluse */
    if(xlo!=xhi || ylo!=yhi)
    {
      subCellUse = DBCellUseNewArray(subCellDef, 
				     id[0] ? id : (char *) NULL);
      DBMakeArray(subCellUse, 
		  &GeoIdentityTransform,
		  xlo, 
		  ylo, 
		  xhi, 
		  yhi, 
		  xsep, 
		  ysep);
    }
    else
    {
      subCellUse = DBCellUseNew(subCellDef, 
				id[0] ? id : (char *) NULL);
    }
    DBCellUseSetTrans(subCellUse, &t);
	   
    /* create instance */
    DBInstanceAdd(subCellUse, cellDef, DBIA_INFOMSG_ON_RENAME);

    /* read next line */
    if (dbReadNextLine(line, len, f) == NULL) return FALSE;
  } /* while uses */

  /* set kid versions to .max file values */
  if(subCellUse)
  {
    CellKid *kid = subCellUse->cu_kid;
    ASSERT(kid,"DBInstancesRead3");

    kid->ck_version = vMAIN;
    kid->ck_vDRC = vDRC;
  }

  goto nextdef;

 end:
  if (strcmp(line,"} SECTION INSTANCES\n") == 0) return TRUE;

 error: 
  MsgWarnF("Parse error in INSTANCES section of %s: `%s'\n",
	   cellDef->cd_name, line);
  return FALSE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbReadUse0 --
 *
 * FORMAT 0 VERSION
 *
 * Read a single cell use specification.  Create a new cell
 * use that is a child of cellDef.  Create the def for this
 * child use if it doesn't already exist.
 *
 * On input, 'line' contains the "use" line; on exit, 'line'
 * contains the next line in the input after the "use".
 *
 * Results:
 *	Returns TRUE normally, or FALSE on error or EOF.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */

static __inline__ bool
dbReadUse0(CellDef *cellDef, char *line, int len, FILE *f)
                     	/* Cell whose cells are being read */
               		/* Line containing "use ..." */
            		/* Size of buffer pointed to by line */
            		/* Input file */
{
    int xlo, xhi, ylo, yhi, xsep, ysep, childStamp;
    int absa, absb, absd, abse;
    VStamp vMAIN, vDRC, vBBOX;
    char cellname[1024], useid[1024];
    CellUse *subCellUse;
    CellDef *subCellDef;
    Transform t;
    Rect bbox;
    char *lp;  /* pointer into input line */

/*
 * PARSE INSTANCE SPECIFICATION
 */
    /* use line (required) */
    if (strncmp(line, "use", 3) != 0)
    {
	MsgErrorF("Expected \"use\" line but saw: %s", line);
	return (FALSE);
    }

    useid[0] = '\0';
    if (sscanf(line, "use %1023s %1023s {", cellname, useid) < 1)
    {
	MsgErrorF("Malformed \"use\" line: %s", line);
	return (FALSE);
    }

    if (dbReadNextLine(line, len, f) == NULL)
	return (FALSE);
    for(lp=line; *lp==' ' || *lp=='\t'; lp++);

    /* array line (optional) */
    if (strncmp(lp, "array", 5) == 0)
    {
	if (sscanf(lp, "array %d %d %d %d %d %d",
		&xlo, &xhi, &xsep, &ylo, &yhi, &ysep) != 6)
	{
	    MsgErrorF("Malformed \"array\" line: %s", line);
	    return (FALSE);
	}
	if (dbReadNextLine(line, len, f) == NULL)
	    return (FALSE);
        for(lp=line; *lp==' ' || *lp=='\t'; lp++);

	/* scale array seps to internal DB coords */
	if(dbRdScaleFile2DB != 1.0)
        {
	  GeoScaleInt(&xsep, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);
	  GeoScaleInt(&ysep, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);
	}
    }
    else
    {
	xlo = ylo = 0;
	xhi = yhi = 0;
	xsep = ysep = 0;
    }

    /* version stamps */
    {
      int timestamp;

      if (sscanf(lp, "timestamp %d", &timestamp) != 1)
      {
	MsgErrorF("Malformed \"timestamp\" line: %s", line);
	return (FALSE);
      }
      if (dbReadNextLine(line, len, f) == NULL) return (FALSE);
      for(lp=line; *lp==' ' || *lp=='\t'; lp++);

      vMAIN.vs_time = timestamp;
      vMAIN.vs_rev = 0;
      vDRC.vs_time = timestamp;
      vDRC.vs_rev = 0;
      vBBOX.vs_time = timestamp;
      vBBOX.vs_rev = 0;
    }

    /* transform line (required) */
    if (sscanf(lp, "transform %d %d %d %d %d %d",
	    &t.t_a, &t.t_b, &t.t_c, &t.t_d, &t.t_e, &t.t_f) != 6)
    {
badTransform:
	MsgErrorF("Malformed or illegal \"transform\" line: %s", line);
	return (FALSE);
    }
    /*
     * Sanity check for transform.
     * Either a == e == 0 and both abs(b) == abs(d) == 1,
     *     or b == d == 0 and both abs(a) == abs(e) == 1.
     */
    if (t.t_a == 0)
    {
	absb = t.t_b > 0 ? t.t_b : -t.t_b;
	absd = t.t_d > 0 ? t.t_d : -t.t_d;
	if (t.t_e != 0 || absb != 1 || absd != 1)
	    goto badTransform;
    }
    else
    {
	absa = t.t_a > 0 ? t.t_a : -t.t_a;
	abse = t.t_e > 0 ? t.t_e : -t.t_e;
	if (t.t_b != 0 || t.t_d != 0 || absa != 1 || abse != 1)
	    goto badTransform;
    }
    if (dbReadNextLine(line, len, f) == NULL)
	return (FALSE);
    for(lp=line; *lp==' ' || *lp=='\t'; lp++);
    /* scale transform to internal DB coords */	
    if(dbRdScaleFile2DB != 1.0)
    {
      GeoScaleInt(&t.t_c, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);
      GeoScaleInt(&t.t_f, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);
    }

    /* box line (required) */
    if (sscanf(lp, "bbox %d %d %d %d",
	    &bbox.r_xbot, &bbox.r_ybot, &bbox.r_xtop, &bbox.r_ytop) != 4)
    {
	MsgErrorF("Malformed use bbox line: %s", line);
	return (FALSE);
    }
    /* check for degenerate bbox */
    if (GEO_RECTNULL(&bbox))
    {
        MsgErrorF("Subcell has degenerate bounding box: %d %d %d %d\n",
		  bbox.r_xbot, bbox.r_ybot, bbox.r_xtop, bbox.r_ytop);
	return FALSE;
    }
    /* scale box to internal DB coordinates */
    GeoScaleRect(&bbox, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);

    /* closing bracket (required) */
    if (dbReadNextLine(line, len, f) == NULL) return (FALSE);
    if(strcmp(line,"}\n")!=0)
    {
      MsgErrorF("Improperly closed use specification: '%s'\n",
		line);
      return FALSE;
    }

    /*
     * DONE WITH PARSING, NOW CREATE THE INSTANCE!
     */

    /* If the definition for this use has not been read in,
     * make a dummy one that's marked not available. 
     */
    subCellDef = DBCellLookDef(cellname);
    if (subCellDef == (CellDef *) NULL)
    {
	subCellDef = DBCellNewDef(cellname, (char *) NULL);
	subCellDef->cd_bbox = bbox;
	subCellDef->cd_version = vMAIN;
	subCellDef->cd_vMAIN = vMAIN;
	subCellDef->cd_vDRC = vDRC;
    }
    
    /* create celluse  */
    if(xlo!=xhi || ylo!=yhi)
    {
      subCellUse = DBCellUseNewArray(subCellDef, 
				     useid[0] ? useid : (char *) NULL);
      DBMakeArray(subCellUse, 
		  &GeoIdentityTransform,
		  xlo, 
		  ylo, 
		  xhi, 
		  yhi, 
		  xsep, 
		  ysep);
    }
    else
    {
      subCellUse = DBCellUseNew(subCellDef, 
				useid[0] ? useid : (char *) NULL);
    }
    DBCellUseSetTrans(subCellUse, &t);

    /* create instance */
    return DBInstanceAdd(subCellUse, cellDef, DBIA_INFOMSG_ON_RENAME);

    /* not safe to set kid versions, since use values may vary? 
     * so if this obsolete format is read, versions are assumed
     * inconsistent.
     */
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbInstancesRead0 --
 *
 * FORMAT 0 version.
 *
 * Starting with the line "SECTION INSTANCES {", read INSTANCES section of 
 * max file.  
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
dbInstancesRead0(CellDef *cellDef, 
                     	/* Cell whose labels are being read */
		char *line, 
               		/* Line buffer */
		int len, 
            		/* Size of line buffer */
		FILE *f)
            		/* Input file */
{
    while (dbReadNextLine(line, len, f))
    {
	if (line[0] == 'u')
	{
	    if(!dbReadUse0(cellDef,line,len,f))
	    {
	        return FALSE;
	    }
        }
	else if (strcmp(line,"} SECTION INSTANCES\n") == 0)
	{
	    return TRUE;
	}
	else
	{
 	    MsgWarnF("Parse error in INSTANCES section of %s: `%s'\n",
		     cellDef->cd_name, line);
	    return FALSE;
        }
    }
    return (FALSE);
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbInstancesRead --
 *
 * Starting with the line "SECTION INSTANCES {", read INSTANCES section of 
 * max file.  
 *
 * Results:
 *	Returns TRUE normally, or FALSE on error or EOF.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */
bool
dbInstancesRead(CellDef *cellDef, 
                     	/* Cell whose labels are being read */
		char *line, 
               		/* Line buffer */
		int len, 
            		/* Size of line buffer */
		FILE *f)
            		/* Input file */
{
  if(DBReadMaxFormat==0)
  {
    /* format 0 version (original) */
    return dbInstancesRead0(cellDef,line,len,f);
  }
  else if (DBReadMaxFormat < 3)
  {
    /* format 1 and 2 version (new vstamps) */
    return dbInstancesRead1(cellDef,line,len,f);
  }
  else
  {
    /* saved gcells */
    return dbInstancesRead3(cellDef,line,len,f);
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBInstanceParsePath --
 *
 * Removes any tcl quotes to convert instance path to space separated
 * name list.
 *
 * Intended for converting command line args.
 *
 * Return:  TRUE on success, FALSE if trouble.
 *
 *-------------------------------------------------------------------
 */
bool
DBInstanceParsePath(char *in,  /* string to convert */
		    char *buf)  /* put result here */
{
  static Tcl_Interp *privInterp = NULL;
  int argc;
  char **argv;
  int result = FALSE;

  /* use private interpeter so we don't mess up result codes in real interp */
  if(!privInterp) privInterp = Tcl_CreateInterp();

  /* parse input string into (newly malloced) elements */
  if(Tcl_SplitList(privInterp, in, &argc, &argv) != TCL_OK)
  {
    MsgErrorF("%s\n", privInterp->result);
    Tcl_ResetResult(privInterp);
    MsgErrorF("Could not parse instance path:  %s\n",
	      in);
    *buf = '\0';
    goto cleanup;
  }

  /* copy to result buffer */
  {
    int i;
    char *out = buf;

    for(i=0;i<argc;i++) 
    {
      char *p = argv[i];
      if(i!=0) *out++ = ' ';
      while(*p) *out++ = *p++;
    }
    *out = '\0';
  }

  /* success */
  result = TRUE;

 cleanup:
  if(argc) free(argv);

  return result;
}





